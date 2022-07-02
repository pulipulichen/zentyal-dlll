package EBox::dlllciasrouter::Model::ServerPortRedirect;

use base 'EBox::Model::DataTable';

use EBox::Global;
use EBox::Gettext;
use EBox::Validate qw(:all);
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::Port;
#use EBox::Types::Text;
use EBox::Types::Boolean;
use EBox::Types::Int;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;

use Try::Tiny;

# Group: Public methods

#sub new
#{
#    my $class = shift;
#    my %parms = @_;
#
#    my $self = $class->SUPER::new(@_);
#    bless ($self, $class);
#
#    return $self;
#}

sub new
{
    my $class = shift;
    my %parms = @_;

    my $self = $class->SUPER::new(@_);
    bless ($self, $class);

    return $self;
}

sub pageTitle
{
    my ($self) = @_;
    try {
        my $lib = $self->getLibrary();
        my $row = $lib->getParentRow($self);

        my $domainName = $row->printableValueByName('domainName');
        my $ip = $row->printableValueByName('ipaddr');
        return $domainName . " (" . $ip . ")";
    }
    catch {
        return __("Port Redirect");
    }
}

sub _table
{

    my ($self) = @_;  
    
    my $libFactory = $self->parentModule()->model('LibraryFields');

    my @fields = (
        $libFactory->createFieldConfigEnableHidden(),

        $libFactory->createFieldPortDescription(),
        $libFactory->createFieldPortDescriptionDisplay(),
        
        $libFactory->createFieldPortExtPortSelection("Please enter external port last 1 number, only allow 0,1,4,5,6, or 7. <br />For example, 4 means ****4. **** is based on internal IP address."),
        $libFactory->createFieldPortExtPortDisplay(),

        $libFactory->createFieldPortIntPort(),

        $libFactory->createFieldProtocolScheme('Other', 0, 'http'),

        $libFactory->createFieldPortSecureSelection(),
        $libFactory->createFieldPortEnableLog(),

        #$libFactory->createFieldDescription()
    );

    my $dataTable =
    {
        'tableName' => 'ServerPortRedirect',
        'printableTableName' => __('Port Redirect') . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-backview.js"></script>',
        'printableRowName' => __('Port Redirect'),
        'pageTitle' => $self->pageTitle(),
        'modelDomain' => 'dlllciasrouter',
        'automaticRemove' => 1,
        'defaultController' => '/dlllciasrouter/Controller/ServerPortRedirect',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView'],
        'tableDescription' => \@fields,
        'sortedBy' => 'extPort',
        'class' => 'dataTable',
    };

    return $dataTable;
}

# --------------------------------

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}


my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $redirRow) = @_;

    my $row = $self->getLibrary()->getParentRow($self);

    $ROW_NEED_UPDATE = 1;
    
    my $libDomainName = $self->getLoadLibrary('LibraryDomainName');
    $libDomainName->updatePortDescription($row, $redirRow);

    $self->checkExternalPort($redirRow);
    $self->updateRedirectPorts($redirRow);
    $self->addRedirect($row, $redirRow);
    $self->updateExtPortHTML($row, $redirRow);


    $ROW_NEED_UPDATE = 0;
}
sub deletedRowNotify
{
    my ($self, $redirRow) = @_;
    
    try {

        $self->updateRedirectPorts($redirRow);

        my $row = $self->getLibrary()->getParentRow($self);
        $self->deleteRedirect($row, $redirRow);

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

sub updatedRowNotify
{
    my ($self, $redirRow, $oldRedirRow) = @_;

    try {

        $self->checkExternalPort($redirRow);
        my $row = $self->getLibrary()->getParentRow($self);

        if (!defined($row)) {
            $self->getLibrary()->show_exceptions("row is not defined");
        }

        $self->deleteRedirect($row, $oldRedirRow);
        $self->addRedirect($row, $redirRow);

        $self->updateRedirectPorts($redirRow);

        if ($ROW_NEED_UPDATE == 0) {
            $ROW_NEED_UPDATE = 1;

            my $libDomainName = $self->getLoadLibrary('LibraryDomainName');
            $libDomainName->updatePortDescription($row, $redirRow);

            $self->updateExtPortHTML($row, $redirRow);
            $ROW_NEED_UPDATE = 0;
        }

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

# --------------------------------

sub addRedirect
{
    my ($self, $row, $redirRow) = @_;

    #throw EBox::Exceptions::External("Try to add redirect", defined($row));

    if ($self->getLibrary()->isEnable($row) == 0) {
        return;
    }

    my $poundModel;
    my %param;
    
    try {
        $poundModel = $self->parentModule()->model("LibraryRedirect");
    } catch {
        $self->getLibrary()->show_exceptions(51 . $_);
    };
    try {
        %param = $poundModel->getRedirectParamOther($row, $redirRow);
    } catch {
        $self->getLibrary()->show_exceptions(52 . $_);
    };
    try {
        $poundModel->addRedirectRow(%param);
    } catch {
        $self->getLibrary()->show_exceptions(53 . $_);
    };
    
}

sub deleteRedirect
{
    my ($self, $row, $redirRow) = @_;

    #my $row = $self->parentRow();

    if (defined($row))
    {
        my $poundModel = $self->parentModule()->model("LibraryRedirect");
        my %param = $poundModel->getRedirectParamOther($row, $redirRow);
        $poundModel->deleteRedirectRow(%param);
    
        # throw EBox::Exceptions::External("Try to delete redirect: " .  $param{description});
    }
}

sub updateRedirectPorts
{
    my ($self, $redirRow) = @_;

    my $row = $self->getLibrary()->getParentRow($self);
    #my $row = $redirRow->parentRow();

    if (defined($row))
    {
        $self->addRedirect($row, $redirRow);

        $self->parentModule()->model("LibraryRedirect")->updateRedirectPorts($row);
        $row->store();
    }
}

sub checkExternalPort
{
    my ($self, $redirRow) = @_;

    my $extPort = $redirRow->valueByName("extPort");

    if ( $extPort > 9 
        ||  $extPort == 2
        ||  $extPort == 3
        ||  $extPort == 8
        ||  $extPort == 9) {
        throw EBox::Exceptions::External("Error External Port Last 1 Numbers format (".$extPort."). Only allow 0,1,4,5,6, or 7");
    }
}

sub updateExtPortHTML
{
    my ($self, $row, $redirRow) = @_;

    if (defined($row))
    {
        my $poundModel = $self->parentModule()->model("LibraryRedirect");
        my %param = $poundModel->getRedirectParamOther($row, $redirRow);
        
        my $secure = $redirRow->valueByName("secure");
        #my $description = $redirRow->valueByName("description");

        my $extPort = $param{external_port_single_port};
        if ($secure == 1) {
            $extPort = '[' . $extPort . ']';
        }
        elsif ($secure == 2) {
            $extPort = '(' . $extPort . ')';
        }

        if ($self->getLibrary()->isEnable($row) == 1) {
            $extPort = "<span>".$extPort."</span>";
        }
        else {
            $extPort = '<span style="text-decoration: line-through">'.$extPort."</span>";
        }

        $redirRow->elementByName('extPortHTML')->setValue($extPort);
        $redirRow->store();
    }
}

1;