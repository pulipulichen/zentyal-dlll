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

sub pageTitle
{
    my ($self) = @_;
    my $row = $self->parentRow();
    
    if (defined($row))
    {
        my $domainName = $row->printableValueByName('domainName');
        my $ip = $row->printableValueByName('ipaddr');
        return $domainName . " (" . $ip . ")";
    }
    else {
        return __("Port Redirect");
    } 
}

sub _table
{

    my ($self) = @_;  
    
    my $fieldsFactory = $self->loadLibrary('LibraryFields');
    my @fields = (
        $fieldsFactory->createFieldConfigEnable(),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
            optional=>0,
            'unique'=>1,
        ),
        
        new EBox::Types::Port(
            'fieldName' => 'extPort',
            'printableName' => __('External Port Last 1 Numbers'),
            'unique' => 1,
            'editable' => 1,
            optional=>0,
            help => "Please enter external port last 1 number, from 0 to 9. For example, 4 means ****4. **** is based on internal IP address.",
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),

        new EBox::Types::HTML(
            fieldName => 'extPortHTML',
            printableName => __('External Port'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        ),
        new EBox::Types::Port(
            'fieldName' => 'intPort',
            'printableName' => __('Internal Port'),
            'unique' => 1,
            'editable' => 1,
            optional=>0,
        ),
        new EBox::Types::Boolean(
            'fieldName' => 'secure',
            'printableName' => __('Only for LAN'),
            help => __('Only for local lan, like 140.119.61.0/24.'),
            'editable' => 1,
            optional=>0,
        ),
        new EBox::Types::Boolean(
            fieldName => 'log',
            printableName => __('Enable Zentyal Log'),
            #help => __('Only for local lan, like 140.119.61.0/24.'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
        ),
    );

    my $dataTable =
    {
        'tableName' => 'PortRedirect',
        'printableTableName' => __('Port Redirect'),
        'printableRowName' => __('Port Redirect'),
        'pageTitle' => $self->pageTitle(),
        'modelDomain' => 'dlllciasrouter',
        automaticRemove => 1,
        defaultController => '/dlllciasrouter/Controller/PortRedirect',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView'],
        'tableDescription' => \@fields,
        'sortedBy' => 'extPort',
        class => 'dataTable',
        
        # 20140219 Pulipuli Chen
        # 關閉enable選項，改成自製的
        #'enableProperty' => 0,
        #defaultEnabledValue => 1,
    };

    return $dataTable;
}

# --------------------------------

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
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

sub addedRowNotify
{
    my ($self, $redirRow) = @_;

    my $row = $self->parentRow();

    try {

    $ROW_NEED_UPDATE = 1;
    } catch {
        $self->getLibrary()->show_exceptions(1 . $_);
    };
    try {
    $self->checkExternalPort($redirRow);
    } catch {
        $self->getLibrary()->show_exceptions(2 . $_);
    };
    try {
    $self->updateRedirectPorts($redirRow);
    } catch {
        $self->getLibrary()->show_exceptions(3 . $_);
    };
    try {
    
    } catch {
        $self->getLibrary()->show_exceptions(4 . $_);
    };
    try {
    $self->addRedirect($row, $redirRow);
    } catch {
        $self->getLibrary()->show_exceptions(5 . $_);
    };
    try {
    $self->updateExtPortHTML($row, $redirRow);

    $ROW_NEED_UPDATE = 0;

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}
sub deletedRowNotify
{
    my ($self, $redirRow) = @_;
    
    try {

    $self->updateRedirectPorts($redirRow);

    my $row = $self->parentRow();
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
    my $row = $self->parentRow();

    if (!defined($row)) {
        $self->getLibrary()->show_exceptions("row is not defined");
    }

    $self->deleteRedirect($row, $oldRedirRow);
    $self->addRedirect($row, $redirRow);

    $self->updateRedirectPorts($redirRow);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
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

    my $poundModel;
    my $param;
    
    try {
    $poundModel = $self->parentModule()->model("LibraryRedirect");
    } catch {
        $self->getLibrary()->show_exceptions(51 . $_);
    };
    try {
    $param = $poundModel->getRedirectParamOther($row, $redirRow);
    } catch {
        $self->getLibrary()->show_exceptions(52 . $_);
    };
    try {
    #$poundModel->addRedirectRow(%param);
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

    my $row = $self->parentRow();
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

    #throw EBox::Exceptions::External($redirRow->parentRow()->id());
    #try {
    #    my $id = $redirRow->parentRow()->id();
    #}
    #catch {
    #    throw EBox::Exceptions::External($_);
    #};
    

    #my $row = $self->parentRow();

    if (defined($row))
    {
        my $poundModel = $self->parentModule()->model("LibraryRedirect");
        my %param = $poundModel->getRedirectParamOther($row, $redirRow);
        
        my $secure = $redirRow->valueByName("secure");
        #my $description = $redirRow->valueByName("description");

        my $extPort = $param{external_port_single_port};
        if ($secure) {
            $extPort = '[' . $extPort . ']';
        }
        $extPort = "<span>".$extPort."</span>";

        $redirRow->elementByName('extPortHTML')->setValue($extPort);
        $redirRow->store();
    }
}

1;