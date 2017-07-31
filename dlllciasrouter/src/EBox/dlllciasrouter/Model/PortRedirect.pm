package EBox::dlllciasrouter::Model::PortRedirect;

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
use EBox::Types::Text;
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


##
# 20170731 Pulipuli Chen
# 網頁標題
##
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
        
        $libFactory->createFieldPortExtPortSelection("Please enter external port last 1 number, only allow 1,4,5,6, or 7. <br />For example, 4 means ****4. **** is based on internal IP address."),
        $libFactory->createFieldPortExtPortDisplay(),

        $libFactory->createFieldPortIntPort(),

        $libFactory->createFieldProtocolScheme('Other', 0, 'http'),

        #$libFactory->createFieldPortOnlyForLan(),
        $libFactory->createFieldPortSecureSelection(0),

        $libFactory->createFieldPortEnableLog(),
    );

    my $dataTable =
    {
        'tableName' => 'PortRedirect',
        'printableTableName' => __('Port Redirect'),
        'printableRowName' => __('Port Redirect') . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-backview.js"></script>',
        'pageTitle' => $self->pageTitle(),
        'modelDomain' => 'dlllciasrouter',
        'automaticRemove' => 1,
        'defaultController' => '/dlllciasrouter/Controller/PortRedirect',
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
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}


my $ROW_NEED_UPDATE = 0;

##
# 20170731 Pulipuli Chen
# 新增欄位
##
sub addedRowNotify
{
    my ($self, $redirRow) = @_;

    try {

        #my $row = $self->parentRow();
        my $row = $self->getLibrary()->getParentRow($self);

        $ROW_NEED_UPDATE = 1;

        my $libDomainName = $self->loadLibrary('LibraryDomainName');
        $libDomainName->updatePortDescription($row, $redirRow);

        $self->checkExternalPort($redirRow);

        my $libRe = $self->loadLibrary("LibraryRedirect");
        $libRe->addOtherPortRedirect($row, $redirRow);
        $libRe->updateRedirectPorts($row);

        $self->updateExtPortHTML($row, $redirRow);

        $redirRow->store();
    
    } catch {
        $self->getLibrary()->show_exceptions($_ . 'Please add port again. ( PortRedirect->addedRowNotify() )');
    };

    $ROW_NEED_UPDATE = 0;
}

##
# 20170731 Pulipuli Chen
# 刪除欄位
##
sub deletedRowNotify
{
    my ($self, $redirRow) = @_;
    
    try {

        #my $row = $self->parentRow();
        my $row = $self->getLibrary()->getParentRow($self);

        my $libRe = $self->parentModule()->model("LibraryRedirect");
        $libRe->deleteOtherPortRedirect($row, $redirRow);
        $libRe->updateRedirectPorts($row);

    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( PortRedirect->deletedRowNotify() )');
    };
}

##
# 20170731 Pulipuli Chen
# 更新欄位
##
sub updatedRowNotify
{
    my ($self, $redirRow, $oldRedirRow) = @_;

    try {

        $self->checkExternalPort($redirRow);
        #my $row = $self->parentRow();
        my $row = $self->getLibrary()->getParentRow($self);

        if (!defined($row)) {
            $self->getLibrary()->show_exceptions("row is not defined");
        }

        my $libRe = $self->parentModule()->model("LibraryRedirect");
        $libRe->updateOtherPortRedirectPorts($row, $redirRow, $oldRedirRow);

        if ($ROW_NEED_UPDATE == 0) {
            $ROW_NEED_UPDATE = 1;

            my $libDomainName = $self->loadLibrary('LibraryDomainName');
            $libDomainName->updatePortDescription($row, $redirRow);

            $self->updateExtPortHTML($row, $redirRow);
            $ROW_NEED_UPDATE = 0;
        }

    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( PortRedirect->updatedRowNotify() ) ');
    };
}

# --------------------------------

sub checkExternalPort
{
    my ($self, $redirRow) = @_;

    my $extPort = $redirRow->valueByName("extPort");

    if ( $extPort > 9 
        ||  $extPort == 2
        ||  $extPort == 3
        ||  $extPort == 8
        ||  $extPort == 9
        ||  $extPort == 0) {
        throw EBox::Exceptions::External("Error External Port Last 1 Numbers format (".$extPort."). Only allow 1,4,5,6, or 7");
    }
}

##
# 20170731 Pulipuli Chen
# 更新連接埠顯示的HTML
##
sub updateExtPortHTML
{
    my ($self, $row, $redirRow) = @_;

    my $libRe = $self->parentModule()->model("LibraryRedirect");
    my %param = $libRe->getRedirectParamOther($row, $redirRow);

    my $secure = $redirRow->valueByName("secure");

    my $extPort = $param{external_port_single_port};
    if ($secure == 1) {
        $extPort = '[' . $extPort . ']';
    }
    elsif ($secure == 2) {
        $extPort = '(' . $extPort . ')';
    }
    $extPort = "<span>".$extPort."</span>";

    $redirRow->elementByName('extPortHTML')->setValue($extPort);
}

1;