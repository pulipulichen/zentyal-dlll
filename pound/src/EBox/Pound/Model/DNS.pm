package EBox::Pound::Model::DNS;

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
            printableName => __('IP Address'),
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
            help => 
                '<button onclick="window.open(\'http://email-km.dlll.nccu.edu.tw/wp-admin/post-new.php?post_title=[CLOUD-SERVICE]\', \'_blank\')">'
                . __('Create New Post') 
                . '</button><br />'
                . __('Please using EMAIL-KM to create a host post and input URL in this field. '),
        ),
        new EBox::Types::Text(
            fieldName => 'expiry',
            printableName => __('Expiry Date'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),       

        new EBox::Types::HTML(
            fieldName => 'createDate',
            printableName => __('Create Date'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'createDateField',
            printableName => __('Create Date'),
            editable => 1,
            optional=>1,
                hiddenOnSetter => 1,
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
    );

    my $dataTable =
    {
        tableName => 'DNS',
        printableTableName => __('DNS'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        modelDomain => 'Pound',
        tableDescription => \@fields,

        'pageTitle' => __('DNS'),
        printableRowName => __('DNS'),
        #sortedBy => 'domainName',
        'HTTPUrlView'=> 'Pound/View/DNS',
        'enableProperty' => 1,
        defaultEnabledValue => 1,
        'order' => 1,
    };

    return $dataTable;
}

# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;
    
    $self->updateDomainNameLink($row);

    $self->parentModule()->model("Redirect")->setCreateDate($row);
    $self->parentModule()->model("Redirect")->setUpdateDate($row);

    $self->parentModule()->model("Redirect")->setContactLink($row);

    $self->addDomainName($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->deletedDomainName($row);
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        $self->deletedRowNotify($oldRow);
        
        $self->updateDomainNameLink($row);
    
        $self->parentModule()->model("Redirect")->setCreateDate($row);
        $self->parentModule()->model("Redirect")->setUpdateDate($row);

        $self->parentModule()->model("Redirect")->setContactLink($row);

        $self->addDomainName($row);

        $row->store();
        $ROW_NEED_UPDATE = 0;
    }
}

# ---------------------------------------

sub addDomainName
{
    my ($self, $row) = @_;

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
        description => $params{description}
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
        description => $param{description}
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
