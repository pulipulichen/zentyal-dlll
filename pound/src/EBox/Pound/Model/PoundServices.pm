package EBox::Pound::Model::PoundServices;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::Boolean;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Select;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

# Method: _table
#
# Overrides:
#
#       <EBox::Model::DataTable::_table>
#
sub _table
{
    my ($self) = @_;

    my @fields = (
        new EBox::Types::DomainName(
            fieldName => 'domainName',
            printableName => __('Domain Name'),
            editable => 1,
        ),
        new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
        ),
        new EBox::Types::Port(
            fieldName => 'port',
            printableName => __('Internal Port'),
            defaultValue => 80,
            editable => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'boundLocalDns',
            printableName => __('Bound Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'),
        ),
        new EBox::Types::Select(
            'fieldName' => 'redirHTTP',
            'printableName' => __('HTTP Redirect'),
            'editable' => 1,
            'populate' => \&populateHTTP
#            'populate' => (
#                {
#                    'value' => 'redirHTTP_default',
#                    'printableValue' => __("Use Internal Port"),
#                },
#                {
#                    'value' => 'redirHTTP_disable',
#                    'printableValue' => __("Disable"),
#                },
#            ),
        ),

        # Enable Keep Last
        new EBox::Types::Boolean(
            fieldName => 'enabled',
            printableName => __('Enabled'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
        ),
    );

    my $dataTable =
    {
        tableName => 'PoundServices',
        printableTableName => __('Services'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        modelDomain => 'Pound',
        tableDescription => \@fields,
        printableRowName => __('Pound Service'),
        sortedBy => 'domainName',
        'HTTPUrlView'=> 'Pound/Composite/Global',
        help => __('This is the help of the model'),
    };

    return $dataTable;
}

sub populateHTTP
{
    my @opts = ();
    push (@opts, { value => 'redirHTTP_default', printableValue => 'Use Internal Port' });
    push (@opts, { value => 'redirHTTP_disable', printableValue => 'Disable' });
    return \@opts;
}

sub getExternalIpaddr
{
    my $network = EBox::Global->modInstance('network');
    my $address;
    foreach my $if (@{$network->allIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
        }
    }
    my @ipaddr=($address);
    return \@ipaddr;
}

sub getExternalIface
{
    my $network = EBox::Global->modInstance('network');
    my $iface;
    foreach my $if (@{$network->allIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $iface = $if;
            last;
        }
    }
    return $iface;
}

sub getPortHeader 
{
    my ($self, $row) = @_;

    # 變成ID前幾碼
    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partC = $parts[2];
    my $partD = $parts[3];

    # 檢查
    if ( !($partC > 0 && $partC < 5)
        || !($partD > 0 && $partD < 100) ) {
        throw EBox::Exceptions::External("Error IP address format (".$ipaddr."). The third part should be between 1~5, and the forth part should be between 1~99");
    }
    
    # 重新組合
        $partC = substr($partC, -1);
    
        if (length($partD) == 1) {
            $partD = "0" . $partD;
        }
        else {
            $partC = substr($partC, -2);
        }
     my $portHeader = $partC.$partD;
     
     return $portHeader;
}

sub addedRowNotify
{
    my ($self, $row) = @_;
    $self->addDomainName($row);
    $self->addRedirects($row);
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->deletedDomainName($row);
    $self->deletedRedirects($row);
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    $self->deletedRowNotify($oldRow);
    $self->addedRowNotify($row);
}

sub addDomainName
{
    my ($self, $row) = @_;

    if ($row->valueByName('boundLocalDns') && $row->valueByName('enabled')) {
        my $domainName = $row->valueByName('domainName');
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        $dns->addDomain({
            domain_name => $domainName,
            #ipAddresses => $self->getExternalIpaddr(),
        });
    }
}

sub deletedDomainName
{
    my ($self, $row) = @_;
    my $domainName = $row->valueByName('domainName');

    my $gl = EBox::Global->getInstance();
    my $dns = $gl->modInstance('dns');
    my $domModel = $dns->model('DomainTable');
    my $id = $domModel->findId(domain => $domainName);
    $domModel->removeRow($id);
}

sub addRedirects
{
    my ($self, $row) = @_;

    if ($row->valueByName('enabled')) {
        my $portHeader = $self->getPortHeader($row);
        
        my $gl = EBox::Global->getInstance();
        my $firewall = $gl->modInstance('firewall');
        my $redirMod = $firewall->model('RedirectsTable');
        
        # 加入HTTP
        if ($row->valueByName('redirHTTP') ne 'redirHTTP_disable') {
            my $extPort = $portHeader . '80';
            my $intPort = $row->valueByName('port');
            $self->addRedirectRow($row, $redirMod, $extPort, $intPort);
        }

    }
}

sub addRedirectRow
{
    my ($self, $row, $redirMod, $extPort, $intPort) = @_;
    
    my $iface = $self->getExternalIface();
    my $localIpaddr = $row->valueByName('ipaddr');

    $redirMod->addRow(
        interface => $iface,
        origDest_selected => "origDest_ebox",
        protocol => "tcp/udp",
        external_port_range_type => 'single',
        external_port_single_port => $extPort,
        source_selected => 'source_any',
        destination => $localIpaddr,
        destination_port_selected => "destination_port_other",
        destination_port_other => $intPort,
        snat => 1,
        log => 0,
    );
}

sub deletedRedirects
{
    my ($self, $row) = @_;

    
}

# 找尋row用
#sub hostDomainChangedDone
#{
#    my ($self, $oldDomainName, $newDomainName) = @_;
#
#    my $domainModel = $self->model('DomainTable');
#    my $row = $domainModel->find(domain => $oldDomainName);
#    if (defined $row) {
#        $row->elementByName('domain')->setValue($newDomainName);
#        $row->store();
#    }
#}

# 新增row用
#    for my $mod (@modsToAdd) {
#        $self->add( module => $mod, enabled => 1 );
#    }
1;
