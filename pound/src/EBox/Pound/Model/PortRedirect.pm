package EBox::Pound::Model::PortRedirect;

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

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
}

sub pageTitle
{
    my ($self) = @_;
    my $row = $self->parentRow();
    if ($row ne undef)
    {
        my $domainName = $self->parentRow()->printableValueByName('domainName');
        my $ip = $self->parentRow()->printableValueByName('ipaddr');
        return $domainName . " (" . $ip . ")";
    }
    else {
        return __("Port Redirect");
    } 
}

sub _table
{

    my ($self) = @_;  

    my @fields = (
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
            'editable' => 1,
            optional=>0,
        ),
    );

    my $dataTable =
    {
        'tableName' => 'PortRedirect',
        'printableTableName' => __('Port Redirect'),
        'printableRowName' => __('Port Redirect'),
        'pageTitle' => $self->pageTitle(),
        'modelDomain' => 'Pound',
        automaticRemove => 1,
        defaultController => '/Pound/Controller/PortRedirect',
        'defaultActions' => ['add', 'del', 'editField', 'changeView' ],
        'tableDescription' => \@fields,
        'sortedBy' => 'extPort',
        class => 'dataTable',
        'enableProperty' => 1,
        defaultEnabledValue => 1,
    };

    return $dataTable;
}

# --------------------------------

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

    #my $row = $self->parentRow();

    if ($row ne undef)
    {
        my $poundModel = $self->parentModule()->model("PoundServices");
        my %param = $poundModel->getRedirectParamOther($row, $redirRow);
        
        my $extPort = $param{external_port_single_port};
        $extPort = "<span>".$extPort."</span>";

        $redirRow->elementByName('extPortHTML')->setValue($extPort);
        $redirRow->store();
    }
}

1;