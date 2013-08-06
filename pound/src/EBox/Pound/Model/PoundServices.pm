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
            'populate' => \&populateHTTP,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirHTTPS',
            'printableName' => __('HTTPS Redirect'),
            'subtypes' =>
            [
            new EBox::Types::Port(
                'fieldName' => 'redirHTTPS_default',
                'printableName' => __('Default HTTPS port (443)'),
                'defaultValue' => 443,
                'hidden' => 1,
                'editable' => 0,),
            new EBox::Types::Port(
                'fieldName' => 'redirHTTPS_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            new EBox::Types::Union::Text(
                'fieldName' => 'redirHTTPS_disable',
                'printableName' => __('Disable')),
            ]
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirSSH',
            'printableName' => __('SSH Redirect'),
            'subtypes' =>
            [
            new EBox::Types::Port(
                'fieldName' => 'redirSSH_default',
                'printableName' => __('Default SSH port (22)'),
                'defaultValue' => 22,
                'hidden' => 1,
                'editable' => 0,),
            new EBox::Types::Port(
                'fieldName' => 'redirSSH_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            new EBox::Types::Union::Text(
                'fieldName' => 'redirSSH_disable',
                'printableName' => __('Disable')),
            ]
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirRDP',
            'printableName' => __('RDP Redirect'),
            'subtypes' =>
            [
            new EBox::Types::Port(
                'fieldName' => 'redirRDP_default',
                'printableName' => __('Default RDP port (3389)'),
                'defaultValue' => 3389,
                'hidden' => 1,
                'editable' => 0,),
            new EBox::Types::Port(
                'fieldName' => 'redirRDP_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            new EBox::Types::Union::Text(
                'fieldName' => 'redirRDP_disable',
                'printableName' => __('Disable')),
            ]
        ),

        # ==============================
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

# ---------------------------------------

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

    $self->deletedRedirects($row);
    $self->addRedirects($row);
}

# ---------------------------------------

sub addDomainName
{
    my ($self, $row) = @_;

    if ($row->valueByName('boundLocalDns') && $row->valueByName('enabled')) {
        my $domainName = $row->valueByName('domainName');
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        $dns->addDomain({
            domain_name => $domainName,
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
    if (defined($id)) 
    {
        $domModel->removeRow($id);
    }
}

# -----------------------------

sub addRedirects
{
    my ($self, $row) = @_;

    if ($row->valueByName('enabled')) {
        # 加入HTTP
        if ($row->valueByName('redirHTTP') ne 'redirHTTP_disable') {
            my %param = $self->getRedirectParamHTTP($row);
            $self->addRedirectRow(%param);
        }

        # 加入HTTPS
        if ($row->valueByName('redirHTTPS') ne 'redirHTTPS_disable') {
            my %param = $self->getRedirectParamHTTPS($row);
            $self->addRedirectRow(%param);
        }
        
        # 加入SSH
        if ($row->valueByName('redirSSH') ne 'redirSSH_disable') {
            my %param = $self->getRedirectParamSSH($row);
            $self->addRedirectRow(%param);
        }
        
        # 加入RDP
        if ($row->valueByName('redirRDP') ne 'redirRDP_disable') {
            my %param = $self->getRedirectParamRDP($row);
            $self->addRedirectRow(%param);
        }
    }
}

sub deletedRedirects
{
    my ($self, $row) = @_;

    my %param = $self->getRedirectParamHTTP($row);
    $self->deleteRedirectRow(%param);

    %param = $self->getRedirectParamHTTPS($row);
    $self->deleteRedirectRow(%param);
    
    %param = $self->getRedirectParamSSH($row);
    $self->deleteRedirectRow(%param);

    %param = $self->getRedirectParamRDP($row);
    $self->deleteRedirectRow(%param);
}

# -----------------------------

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


sub getRedirectParamHTTP
{
    my ($self, $row) = @_;

    my $portHeader = $self->getPortHeader($row);

    my $extPort = $portHeader . '80';
    my $intPort = $row->valueByName('port');

    return $self->getRedirectParameter($row, $extPort, $intPort);
}

sub getRedirectParamHTTPS
{
    my ($self, $row) = @_;

    my $portHeader = $self->getPortHeader($row);

    my $extPort = $portHeader . '43';
    my $intPort = 443;
    if ($row->valueByName('redirHTTPS') eq 'redirHTTPS_other') 
    {
        $intPort = $row->valueByName('redirHTTPS_other');
    }

    return $self->getRedirectParameter($row, $extPort, $intPort);
}

sub getRedirectParamSSH
{
    my ($self, $row) = @_;

    my $portHeader = $self->getPortHeader($row);

    my $extPort = $portHeader . '22';
    my $intPort = 22;
    if ($row->valueByName('redirSSH') eq 'redirSSH_other') 
    {
        $intPort = $row->valueByName('redirSSH_other');
    }

    return $self->getRedirectParameter($row, $extPort, $intPort);
}

sub getRedirectParamRDP
{
    my ($self, $row) = @_;

    my $portHeader = $self->getPortHeader($row);

    my $extPort = $portHeader . '89';
    my $intPort = 3389;
    if ($row->valueByName('redirRDP') eq 'redirRDP_other') 
    {
        $intPort = $row->valueByName('redirRDP_other');
    }

    return $self->getRedirectParameter($row, $extPort, $intPort);
}

sub getRedirectParameter
{
    my ($self, $row, $extPort, $intPort) = @_;

    my $iface = $self->getExternalIface();
    my $localIpaddr = $row->valueByName('ipaddr');

    return (
        interface => $iface,
        origDest_selected => "origDest_ebox",
        protocol => "tcp/udp",
        external_port_range_type => 'single',
        external_port_single_port => $extPort,
        source_selected => 'source_any',
        destination => $localIpaddr,
        destination_port_selected => "destination_port_other",
        destination_port_other => $intPort,
        description => 'Created by Pound Moudle',
        snat => 1,
        log => 0,
    );
}

sub addRedirectRow
{
    my ($self, %params) = @_;
    
    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    $redirMod->addRow(%params);
}

sub deleteRedirectRow
{
    my ($self, %param) = @_;
    
    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    my $id = $redirMod->findId(%param);
    if (defined($id)) {
        $redirMod->removeRow($id);
    }
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
