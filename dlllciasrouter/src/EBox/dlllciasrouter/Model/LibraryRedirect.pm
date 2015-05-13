package EBox::dlllciasrouter::Model::LibraryRedirect;

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
use Try::Tiny;

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

# ---------------------------------------

sub addRedirects
{
    my ($self, $row) = @_;

    # 加入HTTP
    if ($self->isProtocolEnable($row, 'HTTP')) {
        my %param = $self->getRedirectParamHTTP($row);
        $self->addRedirectRow(%param);
    }

    # 加入HTTPS
    if ($self->isProtocolEnable($row, 'HTTPS')) {
        my %param = $self->getRedirectParamHTTPS($row);
        $self->addRedirectRow(%param);
    }

    # 加入SSH
    if ($self->isProtocolEnable($row, 'SSH')) {
        my %param = $self->getRedirectParamSSH($row);
        $self->addRedirectRow(%param);
    }

    # 加入RDP
    if ($self->isProtocolEnable($row, 'RDP')) {
        my %param = $self->getRedirectParamRDP($row);
        $self->addRedirectRow(%param);
    }

    my $redirOther = $row->subModel('redirOther');
    
    try {
        for my $subId (@{$redirOther->ids()}) {
            my $redirRow = $redirOther->row($subId);
            $self->addOtherPortRedirect($row, $redirRow);
        }
    } catch { }
}

sub deleteRedirects
{
    my ($self, $row) = @_;
    
    my %param;
    if ($self->hasProtocolRedirect($row, 'HTTP')) {
        %param = $self->getRedirectParamHTTP($row);
        $self->deleteRedirectRow(%param);
    }

    if ($self->hasProtocolRedirect($row, 'HTTPS')) {
        %param = $self->getRedirectParamHTTPS($row);
        $self->deleteRedirectRow(%param);
    }
    
    if ($self->hasProtocolRedirect($row, 'SSH')) {
        %param = $self->getRedirectParamSSH($row);
        $self->deleteRedirectRow(%param);
    }

    if ($self->hasProtocolRedirect($row, 'RDP')) {
        %param = $self->getRedirectParamRDP($row);
        $self->deleteRedirectRow(%param);
    }
    
    # 刪除Other Redir
    my $redirOtherForMod = $row->valueByName('redirOther_ForMod'); 
    my @redirOtherForModAry = split(/\n/, $redirOtherForMod);
    for my $redirDesc (@redirOtherForModAry) {
        %param = (
            'description' => $row->valueByName('domainName') 
                . ' ' 
                . '(' . $row->valueByName('ipaddr') . '): Other (' . $redirDesc . ')'
        );
        
        $self->deleteRedirectParam(%param);
    }
}

sub addOtherPortRedirect
{
    my ($self, $row, $redirRow) = @_;

    if (! ($self->getLibrary()->isEnable($row) &&  $self->getLibrary()->isEnable($redirRow))) {
        return;
    }

    my %param = $self->getRedirectParamOther($row, $redirRow);
    $self->addRedirectRow(%param);
}

sub deleteOtherPortRedirect
{
    my ($self, $row, $redirRow) = @_;

    my %param = $self->getRedirectParamOther($row, $redirRow);
    $self->deleteRedirectRow(%param);
}

sub updateOtherPortRedirectPorts
{
    my ($self, $row, $redirRow, $oldRedirRow) = @_;

    $self->deleteOtherPortRedirect($row, $oldRedirRow);
    $self->addOtherPortRedirect($row, $redirRow);
    $self->updateRedirectPorts($row);
    $row->store();
}

# -----------------------------

#Zentyal: 10.0.0.254
#Proxmox VE: 10.6.0.{1..99} 最多99臺PVE
#- 對外連線的PVE為 10.6.0.254
#- 連接埠轉遞：10.6.0.1 > 60013 (HTTPS 443)
#NAS: 10.6.1.{1..99} 最多99臺NAS
#- 連接埠轉遞：10.6.1.1 > 61013
#虛擬機器: 10.{1..5}.{0..9}.{1..99}
#- VMID 1001: 10.1.0.1 > 1 0 01 8 [最小] (HTTP 80)
#- VMID 2132: 10.2.1.32 > 2 1 32 8
#- VMID 5999: 10.5.9.99 > 5 9 998 [最大]
#- 總共可供 4950 臺虛擬機器運作

sub getPortHeader 
{
    my ($self, $row) = @_;

    # 變成ID前幾碼
    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    my $partC = $parts[2];
    my $partD = $parts[3];

    # 檢查
    if ( !($partA == 10)
        || !($partB > 0 && $partB < 6)
        || !($partC < 9)
        || !($partD > 0 && $partD < 100) ) {
        throw EBox::Exceptions::External("Error IP address format (".$ipaddr."). " 
            . "For example: 10.1.0.1. <br />"
            . "The 1st part shout be 10, <br />"
            . "the 2nd part should be between 1~5, <br />"
            . "the 3rd part should be between 0~9, and <br />"
            . "the 4th part should be between 1~99");
    }
    
    # 重新組合
        $partB = substr($partB, -1);
    
        if (length($partD) == 1) {
            $partD = "0" . $partD;
        }
        else {
            $partB = substr($partB, -2);
        }
     my $portHeader = $partB.$partC.$partD;
     
     return $portHeader;
}

sub getPortHeaderWithoutCheck 
{
    my ($self, $row) = @_;

    # 變成ID前幾碼
    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    my $partC = $parts[2];
    my $partD = $parts[3];

    # 重新組合
        $partB = substr($partB, -1);
    
        if (length($partD) == 1) {
            $partD = "0" . $partD;
        }
        else {
            $partB = substr($partB, -2);
        }
     my $portHeader = $partB.$partC.$partD;
     
     return $portHeader;
}

sub getServerMainPort
{
    my ($self, $row) = @_;
    my $extPort = $self->getPortHeaderWithoutCheck($row) . '0';
    return $extPort;
} 

# -------------------------------
# HTTP Redirect Param

sub getRedirectParamHTTP
{
    my ($self, $row) = @_;
    return $self->getProtocolRedirectParam($row, 'HTTP');
}

sub getHTTPextPort
{
    my ($self, $row) = @_;
    return $self->getProtocolExtPort($row, 'HTTP');
}

# -------------------------------
# HTTPS Redirect Param

sub getRedirectParamHTTPS
{
    my ($self, $row) = @_;
    return $self->getProtocolRedirectParam($row, 'HTTPS');
}

sub getHTTPSextPort
{
    my ($self, $row) = @_;
    return $self->getProtocolExtPort($row, 'HTTPS');
}

# -------------------------------
# RDP Redirect Param

sub getRedirectParamSSH
{
    my ($self, $row) = @_;
    return $self->getProtocolRedirectParam($row, 'SSH');
}

sub getSSHextPort
{
    my ($self, $row) = @_;
    return $self->getProtocolExtPort($row, 'SSH');
}

# -------------------------------
# RDP Redirect Param

sub getRedirectParamRDP
{
    my ($self, $row) = @_;
    return $self->getProtocolRedirectParam($row, 'RDP');
}

sub getRDPextPort
{
    my ($self, $row) = @_;
    return $self->getProtocolExtPort($row, 'RDP');
}

# --------------------------------------
# protocol Redirect Param

sub getProtocolDefaultExtPort 
{
    my ($self, $protocol) = @_;

    if ($protocol eq 'HTTP') {
        return 8;
    }
    elsif ($protocol eq 'HTTPS') {
        return 3;
    }
    elsif ($protocol eq 'SSH') {
        return 2;
    }
    elsif ($protocol eq 'RDP') {
        return 9;
    }
    else {
        return 8;
    }
}

##
# 20150513 Pulipuli Chen
##
sub hasProtocolRedirect
{   
    my ($self, $row, $protocol) = @_; 
    return $row->elementExists('redir' . $protocol . '_enable');
}

sub getProtocolRedirectParam
{   
    my ($self, $row, $protocol) = @_;

    my $extPort = $self->getProtocolExtPort($row, $protocol);
    my $intPort = $self->getProtocolIntPort($row, $protocol);
    my $log = $self->getProtocolLog($row, $protocol);

    if ($row->valueByName('redir'.$protocol.'_secure') == 1) {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, $protocol, $log);
    }
    else {
        return $self->getRedirectParameter($row, $extPort, $intPort, $protocol, $log);
    }
}

sub getProtocolIntPort 
{
    my ($self, $row, $protocol) = @_;

    my $fieldName = 'redir'.$protocol.'_intPort';
    if ($protocol eq 'HTTP') {
        $fieldName = 'port';
    }
    my $intPort = $row->valueByName($fieldName);

    return $intPort;
}

sub getProtocolExtPort
{
    my ($self, $row, $protocol) = @_;

    my $extPort = $row->valueByName('redir'.$protocol.'_extPort');
    
    if ($extPort 
        eq 'redir'.$protocol.'_extPort_default')
    {
        my $portHeader = $self->getPortHeader($row);    

        my $port = $self->getProtocolDefaultExtPort($protocol);
        $extPort = $portHeader . $port;
    }

    return $extPort;
}

sub getProtocolLog
{
    my ($self, $row, $protocol) = @_;

    my $fieldName = 'redir'.$protocol.'_log';
    my $value = $row->valueByName($fieldName);

    return $value;
}

# --------------------------------------
# Other Port Redirect

sub getRedirectParamOther
{
    my ($self, $row, $redirRow) = @_;

    my $extPort;
    my $intPort;
    my $desc;
    my $log;

    try {
        $extPort = $self->getOtherExtPort($row, $redirRow);
    } catch {
        $self->getLibrary()->show_exceptions(1 . $_);
    };
    try {
    $intPort = $redirRow->valueByName('intPort');
    } catch {
        $self->getLibrary()->show_exceptions(2 . $_);
    };
    
    try {

    $desc = $redirRow->valueByName('description');
    #$desc = "Other";
    $desc = "Other (" . $desc . ")";
    $log = $redirRow->valueByName('log');

    } catch {
        $self->getLibrary()->show_exceptions(25 . $_);
    };

    if ($redirRow->valueByName('secure') == 1)
    {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, $desc, $log);
    }
    else
    {
        return $self->getRedirectParameter($row, $extPort, $intPort, $desc, $log);
    }
}

sub getOtherExtPort
{
    my ($self, $row, $redirRow) = @_;

    my $extPort = $redirRow->valueByName('extPort');
    my $portHeader = $self->getPortHeader($row);

    $extPort = $portHeader . $extPort;

    return $extPort;
}

# --------------------------------------

sub getRedirectParameter
{
    my ($self, $row, $extPort, $intPort, $desc, $log) = @_;

    my $lib = $self->getLibrary();
    my $libNET = $self->loadLibrary('LibraryNetwork');

    my $domainName = $row->valueByName("domainName");
    my $iface = $libNET->getExternalIface();
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
        description => $domainName. " (" . $localIpaddr . "): " . $desc,
        snat => 0,
        log => $log,
    );
}

sub getRedirectParameterSecure
{
    my ($self, $row, $extPort, $intPort, $desc, $log) = @_;

    my $lib = $self->getLibrary();
    my $libNET = $self->loadLibrary('LibraryNetwork');

    my $domainName = $row->valueByName("domainName");
    my $iface = $libNET->getExternalIface();
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
        description => $domainName. " (" . $localIpaddr . "): " . $desc,
        snat => 0,
        log => $log,
    );
}

sub addRedirectRow
{
    my ($self, %params) = @_;
    
    try {

    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    my $id = $redirMod->findId(
        description => $params{description},
    );
    
    if (defined($id) == 0) {
        $redirMod->addRow(%params);
    }

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

sub deleteRedirectRow
{
    my ($self, %params) = @_;
    
    try {

    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    my $id = $redirMod->findId(
        description => $params{description},
    );

    if (defined($id) == 1) {
        $redirMod->removeRow($id);
    }

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

sub deleteRedirectParam
{
    my ($self, %param) = @_;
    
    try {

    my $gl = EBox::Global->getInstance();
    my $firewall = $gl->modInstance('firewall');
    my $redirMod = $firewall->model('RedirectsTable');

    my $id = $redirMod->findId(%param);
    if (defined($id) == 1) {
        $redirMod->removeRow($id);
    }

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

sub updateRedirectPorts
{
    my ($self, $row) = @_;

    try {

    my $lib = $self->getLibrary();
    my $libNET = $self->loadLibrary('LibraryNetwork');

    my $hint = '';
    my $protocol = '';

    my $ipaddr = $libNET->getExternalIpaddr();

    my $portHeader = $self->getPortHeader($row);

    # 加入HTTP
    $protocol = "HTTP";
    if ($self->isProtocolEnable($row, $protocol)) {
        if ($hint ne ''){
            $hint = $hint . "<br />";
        }
        $hint = $hint. $self->getProtocolHint($row, $protocol);
    }

    # 加入HTTPS
    $protocol = "HTTPS";
    if ($self->isProtocolEnable($row, $protocol)) {
        if ($hint ne ''){
            $hint = $hint . "<br />";
        }
        $hint = $hint. $self->getProtocolHint($row, $protocol);
    }


    # 加入SSH
    $protocol = "SSH";
    if ($self->isProtocolEnable($row, $protocol)) {
        if ($hint ne ''){
            $hint = $hint . "<br />";
        }
        $hint = $hint. $self->getProtocolHint($row, $protocol);
    }

    # 加入RDP
    $protocol = "RDP";
    if ($self->isProtocolEnable($row, $protocol)) {
        if ($hint ne '')
        {
            $hint = $hint . "<br />";
        }
        $hint = $hint . $self->getProtocolHint($row, $protocol);  
    }

    # 取得Other Redirect Ports
    my $domainName = $row->valueByName("domainName");
    my $redirOther = $row->subModel('redirOther');

    my $redirOtherForMod = '';
    for my $subId (@{$redirOther->ids()}) {

        my $redirRow = $redirOther->row($subId);

        my $extPort = $self->getOtherExtPort($row, $redirRow);
        my $intPort = $redirRow->valueByName('intPort');
        my $desc = $redirRow->valueByName('description');
        my $secure = $redirRow->valueByName('secure');

        my $portEnable = $self->getLibrary()->isEnable($redirRow);
        my $schema = $redirRow->valueByName("redirOther_scheme");

        if ($secure) {
            $desc = '[' . $desc . ']';
        }

        $desc = '<strong>' . $desc . "</strong>";
        if ($portEnable == 0) {
            next;
        }
        elsif ($schema ne 'none') {
            my $link = $domainName . ":" . $extPort . "/";
            if ($schema eq "http") {
                $link = "http\://" . $link;
            }
            else {
                $link = "https\://" . $link;
            }
            $link = '<a href="'.$link.'" ' 
                . 'target="_blank" ' 
                . 'style="background: none;text-decoration: underline;color: #A3BD5B;">' 
                . $desc 
                . '</a>';
            $desc = $link;
        }

        if ($hint ne '') {
            $hint = $hint . "<br />";
        }

        $hint = $hint . $desc . ": <br />" . $extPort ." &gt; " . $intPort.""; 

        if ($redirOtherForMod ne '') {
            $redirOtherForMod = $redirOtherForMod . "\n";
        }

        $redirOtherForMod = $redirOtherForMod . $redirRow->valueByName('description');
    }   # for my $subId (@{$row->subModel('redirOther')->ids()}) {
    $row->elementByName('redirOther_ForMod')->setValue($redirOtherForMod);

    # 最後結尾
    if ($hint ne '')
    {
        #$hint = "<ul style='text-align:left;'>". $hint . "</ul>";
        $hint = "<div style='text-align:left;'>". $hint . "</div>";
    }
    else
    {
        $hint = "<span>-</span>";
    }

    $row->elementByName('redirPorts')->setValue($hint);

    #$row->store();

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

sub isProtocolEnable 
{
    my ($self, $row, $protocol) = @_;

    return ($row->elementExists('redir'.$protocol.'_enable') && $row->valueByName('redir'.$protocol.'_enable') == 1);
}

sub getProtocolHint
{
    my ($self, $row, $protocol) = @_;
    my $lib = $self->getLibrary();
    my $libNET = $self->loadLibrary('LibraryNetwork');

    my $hint = "";

    my $extPort = $self->getProtocolExtPort($row, $protocol);

    my $intPort = $self->getProtocolIntPort($row, $protocol);
    my $note = $row->valueByName('redir'.$protocol.'_note');

    my $protocolTitle = $protocol;
    
    if (defined($note) && $note ne '') {
        $protocolTitle = $protocolTitle . '*';
    }

    my $secure = $row->valueByName('redir'.$protocol.'_secure');
    if ($secure == 1) {
        $protocolTitle = '[' .$protocolTitle . ']';
    }

    $hint = "<strong>".$protocolTitle."</strong>: "
        . "<br />" 
        . $extPort ." &gt; " . $intPort."";
    
    # 加入連結的部分
    my $scheme = $row->valueByName('redir'.$protocol.'_scheme');
    if ( ($scheme eq 'http') || ($scheme eq 'https') ) {
        
        my $ipaddr = $libNET->getExternalIpaddr();

        my $url = "http\://" . $ipaddr . "\:".$extPort."/";
        if ($scheme eq 'https') {
            $url = "https\://" . $ipaddr . "\:".$extPort."/";
        }
        $hint = "<a "
            . "style='background: none;text-decoration: underline;color: #A3BD5B;' "
            . "href=\"".$url."\" target=\"_blank\">"
            . $hint
            . "</a>";  
    }

    if (defined($note) && $note ne '') {
        $hint = '<em title="'.$note.'">'.$hint.'</em>';
    }

    return $hint;
}

1;
