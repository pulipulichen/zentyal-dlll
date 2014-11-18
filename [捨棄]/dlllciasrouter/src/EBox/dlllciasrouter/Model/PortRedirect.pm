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
    
    if (defined $row && $row ne undef)
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
            'printableName' => __('External Port Last 2 Numbers'),
            'unique' => 1,
            'editable' => 1,
            optional=>0,
            help => "Please enter external port last 2 number, from 0 to 99. For example, 64 means ***64. *** is based on internal IP address.",
            
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
        'defaultActions' => ['add', 'del', 'editField', 'changeView' ],
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

    $ROW_NEED_UPDATE = 1;

    $self->checkExternalPort($redirRow);

    $self->updateRedirectPorts($redirRow);
    
    my $row = $self->parentRow();

    $self->addRedirect($row, $redirRow);

    $self->updateExtPortHTML($row, $redirRow);

    $ROW_NEED_UPDATE = 0;
}
sub deletedRowNotify
{
    my ($self, $redirRow) = @_;
    
    $self->updateRedirectPorts($redirRow);

    my $row = $self->parentRow();
    $self->deleteRedirect($row, $redirRow);
}

sub updatedRowNotify
{
    my ($self, $redirRow, $oldRedirRow) = @_;

    

    $self->checkExternalPort($redirRow);
    my $row = $self->parentRow();

    $self->deleteRedirect($row, $oldRedirRow);
    $self->addRedirect($row, $redirRow);

    $self->updateRedirectPorts($redirRow);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        $self->updateExtPortHTML($row, $redirRow);
        $ROW_NEED_UPDATE = 0;
    }
}

# --------------------------------

sub addRedirect
{
    my ($self, $row, $redirRow) = @_;

    #my $row = $self->parentRow();

    if ($row ne undef)
    {
        my $poundModel = $self->parentModule()->model("PoundServices");
        my %param = $poundModel->getRedirectParamOther($row, $redirRow);
        $poundModel->addRedirectRow(%param);
    }
}

sub deleteRedirect
{
    my ($self, $row, $redirRow) = @_;

    #my $row = $self->parentRow();

    if ($row ne undef)
    {
        my $poundModel = $self->parentModule()->model("PoundServices");
        my %param = $poundModel->getRedirectParamOther($row, $redirRow);
        $poundModel->deleteRedirectRow(%param);
    
    #    throw EBox::Exceptions::External("Try to delete redirect: " .  $param{description});
    }
}

sub updateRedirectPorts
{
    my ($self, $redirRow) = @_;

    my $row = $self->parentRow();
    #my $row = $redirRow->parentRow();

    if ($row ne undef)
    {
        $self->addRedirect($row, $redirRow);

        $self->parentModule()->model("PoundServices")->updateRedirectPorts($row);
        $row->store();
    }
}

sub checkExternalPort
{
    my ($self, $redirRow) = @_;

    my $extPort = $redirRow->valueByName("extPort");

    if ( $extPort > 99 ) {
        throw EBox::Exceptions::External("Error External Port Last 2 Numbers format (".$extPort."). Please enter 0~99");
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

    if ($row ne undef)
    {
        my $poundModel = $self->parentModule()->model("PoundServices");
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