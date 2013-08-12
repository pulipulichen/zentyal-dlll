package EBox::Pound::Model::Settings;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Link;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;

use EBox::Network;

# Group: Public methods

# Constructor: new
#
#      Create a new Text model instance
#
# Returns:
#
#      <EBox::DNS::Model::Settings> - the newly created model
#      instance
#
sub new
{
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless($self, $class);

    return $self;
}

# Group: Protected methods

# Method: _table
#
# Overrides:
#
#     <EBox::Model::DataForm::_table>
#
sub _table
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('network');
    my $address = "127.0.0.1";
    my $external_iface = "eth0";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $external_iface = $if;
            $address = $network->ifaceAddress($if);
            last;
        }
    }

    my @tableDesc =
      (
#          new EBox::Types::HostIP(
#              fieldName     => 'address',
#              printableName => __('External IP Address'),
#              editable      => 0,
#              unique        => 1,
#              defaultValue  => $address,
#              help          => '<a href="/Network/Ifaces?iface='.$external_iface.'">'.__('Modify External Network').'</a>',
#              allowUnsafeChars => 1,
#             ),
          new EBox::Types::Union(
            'fieldName' => 'address',
            'printableName' => __('External IP Address'),
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'address_extIface',
                'printableName' => $external_iface." (".$address.")"),
            new EBox::Types::HostIP(
                'fieldName' => 'address_custom',
                'printableName' => __('Custom'),
                'editable' => 1,),
            ]
          ),
          new EBox::Types::Port(
              fieldName     => 'port',
              printableName => __('External Port'),
              editable      => 1,
              unique        => 1,
              help          => #"<ul>"
                                #. '<li><a href="/Firewall/View/ExternalToEBoxRuleTable">' . __("Please add rule to allow this port from external networks link to Zentyal") . "</a></li>"
                                #. '<li><a href="/Firewall/View/ExternalToInternalRuleTable">' . __("Please add rule to allow port 10000~60000 from external networks link to internal networks") . "</a></li>"
                                #. '</ul>'
                                
             ),
          new EBox::Types::Text(
                fieldName => 'helpURL',
                printableName => __('Set Help Link'),
                editable => 1,
                defaultValue=> "https://github.com/pulipulichen/zentyal-dlll/wiki/domain-name-help",
                optional => 0,
            ),
        new EBox::Types::HTML(
            fieldName => 'helpLink',
            printableName => __('Help Link'),
            editable => 0,
            defaultValue => '<a href="https://github.com/pulipulichen/zentyal-dlll/wiki/domain-name-help" target="_blank">https://github.com/pulipulichen/zentyal-dlll/wiki/domain-name-help</a>',
        ),
          new EBox::Types::HTML(
            fieldName => 'portForwarding',
            printableName => __('Port Forwarding Setup'),
            editable => 0,
            defaultValue => '<a href="/Firewall/View/RedirectsTable" target="_blank">'.__('Custom Port Forwarding').'</a>',
        ),
      );

    my $dataTable =
        {
            tableName => 'Settings',
            printableTableName => __('Settings'),
            modelDomain     => 'Pound',
            defaultActions => [ 'editField',  'changeView' ],
            tableDescription => \@tableDesc,
            'HTTPUrlView'=> 'Pound/Composite/Global',
        };

    return $dataTable;
}

# -----------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    my $poundService = $self->getServicePortModel();
    if ($self->checkServicePort($oldRow) == 1)
    {
        $self->deleteServicePort($oldRow);
    }
    if ($self->checkServicePort($row) == 0)
    {
        $self->addServicePort($row);
    }

    if ($self->checkFilter() == 0) 
    {
        $self->addFilter();
    }

    my $url  = $self->value('helpURL');
    $url = '<a href="'.$url.'" target="_blank">'.$url.'</a>';
    $self->setValue('helpLink', $url);
}

# --------------------------

sub getServiceModel
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('services');
    return $network->model('ServiceTable');
}

sub getFilterModel
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('firewall');
    return $network->model('ExternalToEBoxRuleTable');
}

# --------------------------

sub getServiceParam
{
    my ($self) = @_;

    return (
        # 寫入參數
        'internal' => 'pound',
        'name' => 'pound',
        'printableName' => 'pound',
        'description' => 'For Reverse Proxy use',
    );
}

sub checkService
{
    my ($self) = @_;

    # 確認服務是否存在
    my %param = $self->getServiceParam();

    my $serviceMod = $self->getServiceModel();

    # 確認
    my $id = $serviceMod->findId(%param);

    my $existed = 0;
    if (defined $id)
    {
        $existed = 1;
    }
    return $existed;
}

sub addService
{
    my ($self) = @_;
    
    my %param = $self->getServiceParam();

    # 新增服務
    my $serviceMod = $self->getServiceModel();
    $serviceMod->addRow(%param);
}

sub getServiceRowId
{
     my ($self) = @_;
    
    my %param = $self->getServiceParam();
    my $serviceMod = $self->getServiceModel();
    my $id = $serviceMod->findId(%param);
    
    return $id;
}

sub getServiceRow
{
     my ($self) = @_;
     
     if ($self->checkService() == 0) {
        $self->addService();
    }

     my $serviceMod = $self->getServiceModel();
     my $id = $self->getServiceRowId();

     return $serviceMod->row($id);
}

# ------------------

sub getServicePortModel
{
    my ($self) = @_;

    my $serviceRow = $self->getServiceRow();
    return $serviceRow->subModel('configuration');
}

sub getServicePortParam
{
    my ($self, $port) = @_;

    # 不確定，有可能錯誤
    return (
        # 設定連接埠參數
        'protocol' => 'tcp/udp',
        'source_range_type' => 'any',
        'destination_range_type' => 'single',
        'destination_single_port' => $port,
    );
}


sub checkServicePort
{
    my ($self, $row) = @_;

    my $portMod = $self->getServicePortModel();
    my $port = $row->valueByName("port");
    my %param = $self->getServicePortParam($port);

    my $id = $portMod->findId(%param);
    
    my $existed = 0;
    if (defined $id)
    {
        $existed = 1;
    }
    return $existed;
}

sub addServicePort
{
    my ($self, $row) = @_;

    my $portMod = $self->getServicePortModel();
    my $port = $row->valueByName("port");
    my %param = $self->getServicePortParam($port);

    $portMod->addRow(%param);
}

sub deleteServicePort
{
    my ($self, $row) = @_;

    my $portMod = $self->getServicePortModel();
    my $port = $row->valueByName("port");
    my %param = $self->getServicePortParam($port);

    my $id = $portMod->findId(%param);

    $portMod->removeRow($id);
}

# ----------------------

sub checkFilter
{
    my ($self) = @_;

    my $filterMod = $self->getFilterModel();
    my %param = $self->getFilterParam();

    #my $id = $filterMod->findId(%param);
    #
    my $existed = 0;
    #if (defined $id)
    #{
    #    $existed = 1;
    #}
    return $existed;
}

sub addFilter
{
    my ($self) = @_;

    my $filterMod = $self->getFilterModel();
    my %param = $self->getFilterParam();

    $filterMod->addRow(%param);
}

sub getFilterRow
{
    my ($self) = @_;    

    my $filterMod = $self->getFilterModel();
    my %param = $self->getFilterParam();

    my $id = $filterMod->findId(%param);

    return $filterMod->row($id);
}

sub getFilterParam
{
    my ($self) = @_;

    return (
        # 設定連接埠參數
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->getServiceRowId(),
        'description' => 'For Reverse Proxy use.',
    );
}


1;
