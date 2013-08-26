package EBox::Pound::Model::PoundServices;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::HTML;
use EBox::Types::Boolean;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Select;
use EBox::Types::HasMany;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use LWP::Simple;

# 20130812 Pulipuli Chen
# 想要寫出切換功能，可是失敗了。
#use EBox::Validate qw(:all);

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
            'unique' => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            #'help' => get($domainNameHelpURL) . 'Format Help: <a href="'.$domainNameHelpURL.'" target="_blank">'.$domainNameHelpURL.'</a>',
        ),
        new EBox::Types::HTML(
            fieldName => 'domainNameLink',
            printableName => __('Domain Name'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 1,
                hiddenOnViewer => 0,
        ),
        new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
            #'unique' => 1,
            help => __('The third part should be between 1~5, and the forth part should be between 1~99'),
        ),
        new EBox::Types::Port(
            fieldName => 'port',
            printableName => __('Internal Port'),
            defaultValue => 80,
            editable => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'contactName',
            printableName => __('Contact Name'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'contactEmail',
            printableName => __('Contact Email'),
            editable => 1,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'expiry',
            printableName => __('Expiry Date'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'httpToHttps',
            printableName => __('HTTP Redirect to HTTPS'),
            editable => 1,
            optional => 0,
            defaultValue => 0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'boundLocalDns',
            printableName => __('Bound Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'),
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        

        new EBox::Types::Boolean(
            fieldName => 'redirHTTP_enable',
            printableName => __('Enable HTTP Redirect'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'redirHTTP_secure',
            printableName => __('Only For LAN'),
            editable => 1,
            optional => 0,
            defaultValue => 0,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirHTTP_extPort',
            'printableName' => __('HTTP External Port'),
            #'unique' => 1,
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'redirHTTP_extPort_default',
                'printableName' => __('Default: Based on IP address.')),
            new EBox::Types::Port(
                'fieldName' => 'redirHTTP_extPort_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            'fieldName' => 'redirHTTP_intPort',
            'printableName' => __('HTTP Internal Port'),
            'editable' => 0,
            'defaultValue' => "Use reverse proxy internal port",
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        # ----------------------
        new EBox::Types::Boolean(
            fieldName => 'redirHTTPS_enable',
            printableName => __('Enable HTTPS Redirect'),
             editable => 1,
            optional => 0,
            defaultValue => 1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'redirHTTPS_secure',
            printableName => __('Only For LAN'),
            editable => 1,
            optional => 0,
            defaultValue => 0,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirHTTPS_extPort',
            'printableName' => __('HTTPS External Port'),
            'unique' => 1,
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'redirHTTPS_extPort_default',
                'printableName' => __('Default: Based on IP address.')),
            new EBox::Types::Port(
                'fieldName' => 'redirHTTPS_extPort_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirHTTPS_intPort',
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
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        # --------------------------------
        new EBox::Types::Boolean(
            fieldName => 'redirSSH_enable',
            printableName => __('Enable SSH Redirect'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'redirSSH_secure',
            printableName => __('Only For LAN'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirSSH_extPort',
            'printableName' => __('SSH External Port'),
            'unique' => 1,
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'redirSSH_extPort_default',
                'printableName' => __('Default: Based on IP address.')),
            new EBox::Types::Port(
                'fieldName' => 'redirSSH_extPort_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirSSH_intPort',
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
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        # --------------------------------
        new EBox::Types::Boolean(
            fieldName => 'redirRDP_enable',
            printableName => __('Enable RDP Redirect'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'redirRDP_secure',
            printableName => __('Only For LAN'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirRDP_extPort',
            'printableName' => __('RDP External Port'),
            'unique' => 1,
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'redirRDP_extPort_default',
                'printableName' => __('Default: Based on IP address.')),
            new EBox::Types::Port(
                'fieldName' => 'redirRDP_extPort_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Union(
            'fieldName' => 'redirRDP_intPort',
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
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        # --------------------------------

        new EBox::Types::HTML(
            fieldName => 'redirPorts',
            printableName => __('Redirect Ports'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 1,
                hiddenOnViewer => 0,
        ),
        new EBox::Types::HTML(
            fieldName => 'createDate',
            printableName => __('Create Date'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::HTML(
            fieldName => 'updateDate',
            printableName => __('Last Update Date'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),

        new EBox::Types::HTML(
            fieldName => 'contactLink',
            printableName => __('Contact & Last Update Date'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        ),

        # ----------------------------------

# 不知道為什麼加入HasMany之後就不能用了，只能說是傷心啊，不採用了
#        new EBox::Types::HasMany(
#            'fieldName' => 'redirOther',
#            'printableName' => __('Other Redirect Ports'),
#            'foreignModel' => 'Redirections',
#            'view' => '/Pound/View/Redirections',
#            'backView' => '/Pound/View/Global',
#            'size' => '1',
#            optional=>1,
#                hiddenOnSetter => 1,
#                hiddenOnViewer => 0,
#       ),

        # ==============================
        # Enable Keep Last
        #new EBox::Types::Boolean(
        #    fieldName => 'enabled',
        #    printableName => __('Enabled'),
        #    editable => 1,
        #    optional => 0,
        #    defaultValue => 1,
        #),
    );

    my $dataTable =
    {
        tableName => 'PoundServices',
        printableTableName => __('Pound Services'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        modelDomain => 'Pound',
        tableDescription => \@fields,
        printableRowName => __('Pound Service'),
        sortedBy => 'domainName',
        'HTTPUrlView'=> 'Pound/Composite/Global',
        'enableProperty' => 1,
        defaultEnabledValue => 1,
    };

    return $dataTable;
}

# --------------------------------------
# 20130812 Pulipuli Chen
# 想要寫出切換功能，可是失敗了。

#sub viewCustomizer
#{
#    my ($self) = @_;
#
#    my $customizer = $self->SUPER::viewCustomizer();
#
#    # disable port selection in protless protocols
#    my $httpFields = [qw(redirHTTP_secure)];
#    $customizer->setOnChangeActions({
#        redirHTTPS_enable => {
#            1 => {show => $httpFields},
#            0 => {hide => $httpFields},
#        }
#    });
#
#    return $customizer;
#}


# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;
    
    $self->updateDomainNameLink($row);
    
    $self->updateRedirectPorts($row);

    $self->parentModule()->model("Redirect")->setCreateDate($row);
    $self->parentModule()->model("Redirect")->setUpdateDate($row);

    $self->parentModule()->model("Redirect")->setContactLink($row);

    $self->addDomainName($row);
    $self->addRedirects($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;
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

    if ($ROW_NEED_UPDATE == 0) {
        $self->deletedRowNotify($oldRow);
        $self->addedRowNotify($row);
    }
}

# ---------------------------------------

sub addDomainName
{
    my ($self, $row) = @_;

    if ($row->valueByName('boundLocalDns')) {
        my $domainName = $row->valueByName('domainName');
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        my $domModel = $dns->model('DomainTable');
        my $id = $domModel->findId(domain => $domainName);
        if (defined($id) == 0) 
        {
            $domModel->addDomain({
                'domain_name' => $domainName,
            });
        }
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

    # 加入HTTP
    if ($row->valueByName('redirHTTP_enable') == 1) {
        my %param = $self->getRedirectParamHTTP($row);
        $self->addRedirectRow(%param);
    }

    # 加入HTTPS
    if ($row->valueByName('redirHTTPS_enable') == 1) {
        my %param = $self->getRedirectParamHTTPS($row);
        $self->addRedirectRow(%param);
    }

    # 加入SSH
    if ($row->valueByName('redirSSH_enable') == 1) {
        my %param = $self->getRedirectParamSSH($row);
        $self->addRedirectRow(%param);
    }

    # 加入RDP
    if ($row->valueByName('redirRDP_enable') == 1) {
        my %param = $self->getRedirectParamRDP($row);
        $self->addRedirectRow(%param);
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

sub getExternalIpaddrs
{
    my $network = EBox::Global->modInstance('network');
    my $address = "127.0.0.1";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
            last;
        }
    }
    my @ipaddr=($address);
    return \@ipaddr;
}

sub getExternalIpaddr
{
    my $network = EBox::Global->modInstance('network');
    my $address = "127.0.0.1";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
            last;
        }
    }
    return $address;
}

sub getExternalIface
{
    my $network = EBox::Global->modInstance('network');
    my $iface = "eth0";
    foreach my $if (@{$network->ExternalIfaces()}) {
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
    if ( !($partC > 0 && $partC < 6)
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

    my $extPort = $self->getHTTPextPort($row);
    #my $portHeader = $self->getPortHeader($row);
    #my $extPort = $portHeader . '80';

    my $intPort = $row->valueByName('port');

    if ($row->valueByName('redirHTTP_secure') == 1)
    {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, "HTTP");
    }
    else
    {
        return $self->getRedirectParameter($row, $extPort, $intPort, "HTTP");
    }
}

sub getHTTPextPort
{
    my ($self, $row) = @_;

    my $extPort = $row->valueByName('redirHTTP_extPort');
    if ($row->valueByName('redirHTTP_extPort') eq 'redirHTTP_extPort_default')
    {
        my $portHeader = $self->getPortHeader($row);    
        $extPort = $portHeader . '80';
    }

    return $extPort;
}

sub getRedirectParamHTTPS
{
    my ($self, $row) = @_;

    my $extPort = $self->getHTTPSextPort($row);
    
    #my $portHeader = $self->getPortHeader($row);
    #my $extPort = $portHeader."43";

    my $intPort = $row->valueByName('redirHTTPS_intPort');

    if ($row->valueByName('redirHTTPS_secure') == 1)
    {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, "HTTPS");
    }
    else
    {
        return $self->getRedirectParameter($row, $extPort, $intPort, "HTTPS");
    }
    
}

sub getHTTPSextPort
{
    my ($self, $row) = @_;
    
    my $extPort = $row->valueByName('redirHTTPS_extPort');
    if ($row->valueByName('redirHTTPS_extPort') eq 'redirHTTPS_extPort_default')
    {
        my $portHeader = $self->getPortHeader($row);    
        $extPort = $portHeader . '43';
    }

    return $extPort;
}

sub getRedirectParamSSH
{
    my ($self, $row) = @_;

    my $extPort = $self->getSSHextPort($row);
    
    #my $portHeader = $self->getPortHeader($row);
    #my $extPort = $portHeader.'22';

    my $intPort = $row->valueByName('redirSSH_intPort');

    if ($row->valueByName('redirSSH_secure') == 1)
    {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, "SSH");
    }
    else
    {
        return $self->getRedirectParameter($row, $extPort, $intPort, "SSH");
    }
}

sub getSSHextPort
{
    my ($self, $row) = @_;

    my $extPort = $row->valueByName('redirSSH_extPort');
    if ($row->valueByName('redirSSH_extPort') eq 'redirSSH_extPort_default')
    {
        my $portHeader = $self->getPortHeader($row);    
        $extPort = $portHeader . '22';
    }

    return $extPort;
}

sub getRedirectParamRDP
{
    my ($self, $row) = @_;

    my $extPort = $self->getRDPextPort($row);
    
    #my $portHeader = $self->getPortHeader($row);
    #my $extPort = $portHeader.'89';

    my $intPort = $row->valueByName('redirRDP_intPort');

    if ($row->valueByName('redirRDP_secure') == 1)
    {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, "RDP");
    }
    else
    {
        return $self->getRedirectParameter($row, $extPort, $intPort, "RDP");
    }
}

sub getRDPextPort
{
    my ($self, $row) = @_;

    my $extPort = $row->valueByName('redirRDP_extPort');
    if ($row->valueByName('redirRDP_extPort') eq 'redirRDP_extPort_default')
    {
        my $portHeader = $self->getPortHeader($row);    
        $extPort = $portHeader . '89';
    }

    return $extPort;
}

sub getRedirectParameter
{
    my ($self, $row, $extPort, $intPort, $desc) = @_;

    my $domainName = $row->valueByName("domainName");
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
        description => 'Created by Pound Moudle for '.$domainName. " " . $desc,
        snat => 1,
        log => 0,
    );
}

sub getRedirectParameterSecure
{
    my ($self, $row, $extPort, $intPort, $desc) = @_;

    my $domainName = $row->valueByName("domainName");
    my $iface = $self->getExternalIface();
    my $localIpaddr = $row->valueByName('ipaddr');

    my $sourceIp = '192.168.11.0';
    my $sourceMask = '24';

    my $network = EBox::Global->modInstance('network');
    my $address = "127.0.0.1";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
            $sourceMask = $network->ifaceNetmask($if);
            last;
        }
    }
    
    #把address轉換成source
    
    # 變成ID前幾碼
    my $ipaddr = $address;
    my @parts = split('\.', $ipaddr);

    # 重新組合
    if ($sourceMask eq '255.255.255.0')
    {
        $sourceIp = $parts[0].".".$parts[1].".".$parts[2].".0";
        $sourceMask = "24";
    }
    elsif ($sourceMask eq '255.255.0.0')
    {
        $sourceIp = $parts[0].".".$parts[1].".0.0";
        $sourceMask = "16";
    }
    elsif ($sourceMask eq '255.0.0.0')
    {
        $sourceIp = $parts[0].".0.0.0";
        $sourceMask = "8";
    }
    elsif ($sourceMask eq '0.0.0.0')
    {
        $sourceIp = "0.0.0.0";
        $sourceMask = "1";
    }

    return (
        interface => $iface,
        origDest_selected => "origDest_ebox",
        protocol => "tcp/udp",
        external_port_range_type => 'single',
        external_port_single_port => $extPort,
        source_selected => 'source_ipaddr',
        source_ipaddr_ip => $sourceIp,
        source_ipaddr_mask => $sourceMask,
        destination => $localIpaddr,
        destination_port_selected => "destination_port_other",
        destination_port_other => $intPort,
        description => 'Created by Pound Moudle for '.$domainName. " " . $desc,
        snat => 1,
        log => 0,
    );
}

sub getRedirectParameterFind
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName("domainName");
    my $iface = $self->getExternalIface();
    my $localIpaddr = $row->valueByName('ipaddr');

    return (
        #interface => $iface,
        #origDest_selected => "origDest_ebox",
        #protocol => "tcp/udp",
        #external_port_range_type => 'single',
        destination => $localIpaddr,
        destination_port_selected => "destination_port_other",
        #destination_port_other => $intPort,
        #snat => 1,
        #log => 0,
    );
}

sub addRedirectRow
{
    my ($self, %params) = @_;
    
    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    my $id = $redirMod->findId(
        description => %params->{description}
    );
    
    if (defined($id) == 0) {
        $redirMod->addRow(%params);
    }
}

sub deleteRedirectRow
{
    my ($self, %param) = @_;
    
    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    my $id = $redirMod->findId(
        description => %param->{description}
    );
    if (defined($id) == 1) {
        $redirMod->removeRow($id);
    }
}

sub updateRedirectPorts
{
    my ($self, $row) = @_;

    my $hint = '';
        
        my $ipaddr = $self->getExternalIpaddr();

        my $portHeader = $self->getPortHeader($row);
        # 加入HTTP
        if ($row->valueByName('redirHTTP_enable') == 1) {
            
            my $extPort = $self->getHTTPextPort($row); 
            #my $extPort = $portHeader.80;
            my $intPort = $row->valueByName('port');
            my $url = "http\://" . $ipaddr . "\:".$extPort."/";
            $hint = $hint . "<li><a style='background: none;text-decoration: underline;color: #A3BD5B;' href=\"".$url."\" target=\"_blank\"><strong>HTTP</strong>: <br />" . $extPort ." &gt; " . $intPort."</a></li>";  
        }

        # 加入HTTPS
        if ($row->valueByName('redirHTTPS_enable') == 1) {
        
            my $extPort = $self->getHTTPSextPort($row);
            #my $extPort = $portHeader.43;
            my $intPort = $row->valueByName('redirHTTPS_intPort');
            my $url = "https\://" . $ipaddr . "\:".$extPort."/";
            $hint = $hint . "<li><a style='background: none;text-decoration: underline;color: #A3BD5B;' href=\"".$url."\" target=\"_blank\"><strong>HTTPS</strong>: <br />" . $extPort ." &gt; " . $intPort."</a></li>";  
        }

        
        # 加入SSH
        if ($row->valueByName('redirSSH_enable') == 1) {
        
            my $extPort = $self->getSSHextPort($row);
            #my $extPort = $portHeader.22;
            my $intPort = $row->valueByName('redirSSH_intPort');
            $hint = $hint . "<li><strong>SSH</strong>: <br />" . $extPort ." &gt; " . $intPort."</li>";   
        }

        
        # 加入RDP
        if ($row->valueByName('redirRDP_enable') == 1) {
        
            my $extPort = $self->getRDPextPort($row);
            #my $extPort = $portHeader.89;
            my $intPort = $row->valueByName('redirRDP_intPort');
            $hint = $hint . "<li><strong>RDP</strong>: <br />" . $extPort ." &gt; " . $intPort."</li>";  
        }

        if ($hint ne '')
        {
            $hint = "<ul style='text-align:left;'>". $hint . "</ul>";
        }
        else
        {
            $hint = "<span>-</span>";
        }

        $row->elementByName('redirPorts')->setValue($hint);
        #$row->store();

}

sub updateDomainNameLink
{
    my ($self, $row) = @_;
    
    my $domainName = $row->valueByName("domainName");
    my $port = $self->parentModule()->model("Settings")->value("port");

    if ($port == 80) 
    {
        $port = "";
    }
    else 
    {
        $port = ":" . $port;
    }
    my $link = "http\://" . $domainName . $port . "/";

    $domainName = $self->breakUrl($domainName);

    $link = '<a href="'.$link.'" target="_blank" style="background: none;text-decoration: underline;color: #A3BD5B;">'.$domainName.'</a>';
    $row->elementByName("domainNameLink")->setValue($link);

    #$row->store();
}

sub breakUrl
{
    my ($self, $url) = @_;

     my $result = index($url, ".");
    $url = substr($url, 0, $result) . "<br />" . substr($url, $result);
    return $url;
}

# 找尋row用
#sub hostDomainChangedDonepa
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
