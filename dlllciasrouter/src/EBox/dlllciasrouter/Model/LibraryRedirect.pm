package EBox::dlllciasrouter::Model::LibraryRedirect;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
#use EBox::Types::Text;
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
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# ---------------------------------------

sub addRedirects
{
    my ($self, $row) = @_;

    # 20150514 Pulipuli Chen 如果不啟用，那就不加入
    if (! ($self->getLibrary()->isEnable($row))) {
        return;
    }

    # 加入Pound
    $self->addPoundRedirect($row);

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

    if ($row->elementExists("redirOther")) {
        my $redirOther = $row->subModel('redirOther');
        try {
            for my $subId (@{$redirOther->ids()}) {
                my $redirRow = $redirOther->row($subId);
                $self->addOtherPortRedirect($row, $redirRow);
            }
        } catch {
            $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->addRedirects() ) ');
        };
    }
}

# 20150514 Pulipuli Chen
 sub addPoundRedirect 
{
    my ($self, $row) = @_;

    # 加入Pound
    #my $redirPound_scheme = $row->valueByName('redirPOUND_scheme');
    #if ($redirPound_scheme eq 'https' 
    #    || ( $redirPound_scheme eq 'http' && $row->valueByName('redirPOUND_secure') == 1 ) ) {
    if ($self->isProtocolEnable($row, "POUND")) {
        my %param = $self->getProtocolRedirectParam($row, 'POUND');
        $self->addRedirectRow(%param);
    }

}

sub deleteRedirects
{
    my ($self, $row) = @_;
    
    my %param;

    # 刪除PoundRedirect
    %param = $self->getProtocolRedirectParam($row, 'POUND');
    $self->deleteRedirectRow(%param);

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
    if ($row->elementExists("redirOther_subMod")) {
        my $redirOtherForMod = $row->valueByName('redirOther_subMod'); 
        if (defined($redirOtherForMod) && $redirOtherForMod ne '') {

            my @redirOtherForModAry = split(/\n/, $redirOtherForMod);
            for my $redirDesc (@redirOtherForModAry) {
                %param = (
                    'description' => $row->valueByName('domainName') 
                        . ' ' 
                        . '(' . $row->valueByName('ipaddr') . '): Other (' . $redirDesc . ')'
                );

                $self->deleteRedirectParam(%param);
            }

        }   # if (defined($redirOtherForMod) && $redirOtherForMod ne '') {}
    }   # if ($row->elementExists("redirOther_subMod")) {
}

sub addOtherPortRedirect
{
    my ($self, $row, $redirRow) = @_;

    try {
        if (! ($self->getLibrary()->isEnable($row) &&  $self->getLibrary()->isEnable($redirRow))) {
            return;
        }

        my %param = $self->getRedirectParamOther($row, $redirRow);
        $self->addRedirectRow(%param);
    }
    catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->addOtherPortRedirect() ) ');
    }
}

sub deleteOtherPortRedirect
{
    my ($self, $row, $redirRow) = @_;

    try {
        my %param = $self->getRedirectParamOther($row, $redirRow);
        $self->deleteRedirectRow(%param);
    }
    catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->deleteOtherPortRedirect() ) ');
    }
}

sub updateOtherPortRedirectPorts
{
    my ($self, $row, $redirRow, $oldRedirRow) = @_;

    try {
        $self->deleteOtherPortRedirect($row, $oldRedirRow);
        $self->addOtherPortRedirect($row, $redirRow);
        $self->updateRedirectPorts($row);
        $row->store();
    }
    catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->updateOtherPortRedirectPorts() ) ');
    }
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
    # 20150515 改到Model裡面自己檢查
    #if ( !($partA == 10)
    #    || !($partB > 0 && $partB < 6)
    #    || !($partC < 9)
    #    || !($partD > 0 && $partD < 100) ) {
    #    throw EBox::Exceptions::External("Error IP address format (".$ipaddr."). " 
    #        . "For example: 10.1.0.1. <br />"
    #        . "The 1st part shout be 10, <br />"
    #        . "the 2nd part should be between 1~5, <br />"
    #        . "the 3rd part should be between 0~9, and <br />"
    #        . "the 4th part should be between 1~99");
    #}
    
    # 重新組合
    $partB = substr($partB, -1);
    if ($partB eq "0") {
        $partB = "";
    }

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
    my ($self, $ipaddr) = @_;

    # 變成ID前幾碼
    #my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    my $partC = $parts[2];
    my $partD = $parts[3];

    # 重新組合
    $partB = substr($partB, -1);
    if ($partB eq "0") {
        $partB = "";
    }

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
    my ($self, $ipaddr) = @_;
    my $extPort = $self->getPortHeaderWithoutCheck($ipaddr) . '0';
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
    elsif ($protocol eq 'POUND') {
        return 0;
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

##
# 20170731 Pulipuli Chen
# 取得要設定連接埠的參數
## 
sub getProtocolRedirectParam
{   
    my ($self, $row, $protocol) = @_;

    my $extPort = $self->getProtocolExtPort($row, $protocol);
    my $intPort = $self->getProtocolIntPort($row, $protocol);
    my $log = $self->getProtocolLog($row, $protocol);

    my $secure = $self->getRedirectSecureLevel($row, $protocol);
    if ($secure > 0) {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, $protocol, $log, $secure);
    }
    else {
        return $self->getRedirectParameter($row, $extPort, $intPort, $protocol, $log);
    }
}

sub getProtocolIntPort 
{
    my ($self, $row, $protocol) = @_;

    my $fieldName = 'redir'.$protocol.'_intPort';
    #if ($protocol eq 'HTTP') {
    #    $fieldName = 'port';
    #}

    # 20150515 為 POUND做的調整
    if ($protocol eq 'POUND') {
        $fieldName = 'port';
    }
    my $intPort = $row->valueByName($fieldName);

    return $intPort;
}

sub getProtocolExtPort
{
    my ($self, $row, $protocol) = @_;
    
    my $extPort;
    # 20150515 為 POUND 做得調整
    if ($protocol eq 'POUND') {
        my $portHeader = $self->getPortHeader($row);    

        my $port = $self->getProtocolDefaultExtPort($protocol);
        $extPort = $portHeader . $port;
        return $extPort;
    }

    $extPort = $row->valueByName('redir'.$protocol.'_extPort');
    
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

    if ($protocol eq 'POUND') {
        return 1;
    }

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
        $self->getLibrary()->show_exceptions(1 . $_  . ' ( LibraryRedirect->getRedirectParamOther() ) ');
    };
    try {
        $intPort = $redirRow->valueByName('intPort');
    } catch {
        $self->getLibrary()->show_exceptions(2 . $_  . ' ( LibraryRedirect->getRedirectParamOther() ) ');
    };
    
    try {

        $desc = $redirRow->valueByName('description');
        #$desc = "Other";
        $desc = "Other (" . $desc . ")";
        $log = $redirRow->valueByName('log');

    } catch {
        $self->getLibrary()->show_exceptions(25 . $_  . ' ( LibraryRedirect->getRedirectParamOther() ) ');
    };

    my $secure = $redirRow->valueByName('secure');
    if ($secure > 0) {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, $desc, $log, $secure);
    }
    else {
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
    my $libNET = $self->getLoadLibrary('LibraryNetwork');

    my $domainName = $row->valueByName("domainName");
    my $iface = $libNET->getExternalIface();
    my $localIpaddr = $row->valueByName('ipaddr');

    return (
        'interface' => $iface,
        'origDest_selected' => "origDest_ebox",
        'protocol' => "tcp/udp",
        'external_port_range_type' => 'single',
        'external_port_single_port' => $extPort,
        'source_selected' => 'source_any',
        'destination' => $localIpaddr,
        'destination_port_selected' => "destination_port_other",
        'destination_port_other' => $intPort,
        'description' => $domainName. " (" . $localIpaddr . "): " . $desc,
        'snat' => 0,
        'log' => $log,
    );
}

sub getRedirectParameterSecure
{
    my ($self, $row, $extPort, $intPort, $desc, $log, $secure) = @_;

    my $lib = $self->getLibrary();
    my $libNET = $self->getLoadLibrary('LibraryNetwork');

    my $domainName = $row->valueByName("domainName");
    my $iface = $libNET->getExternalIface();
    my $localIpaddr = $row->valueByName('ipaddr');

    #my $source = $self->getSecureIpSource();
    my $objectRowId;
    if ($secure == 1) {
        $objectRowId = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id();
    }
    elsif ($secure == 2) {
        # 20170731 加入Workplace的設定
        $objectRowId = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Workplace-List')->id();
    }

    return (
        'interface' => $iface,
        'origDest_selected' => "origDest_ebox",
        'protocol' => "tcp/udp",
        'external_port_range_type' => 'single',
        'external_port_single_port' => $extPort,
        'source_selected' => 'source_object',
        'source_object' => $objectRowId,
        #'source_ipaddr_ip => $source->{sourceIp},
        #'source_ipaddr_mask => $source->{sourceMask},
        'destination' => $localIpaddr,
        'destination_port_selected' => "destination_port_other",
        'destination_port_other' => $intPort,
        'description' => $domainName. " (" . $localIpaddr . "): " . $desc,
        'snat' => 0,
        'log' => $log,
    );
}

sub getSecureIpSource
{
    my ($self) = @_;

    my $sourceIp = '192.168.11.0';

    my $address = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();
    my $sourceMask = $self->getLoadLibrary('LibraryNetwork')->getExternalMask();
    
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

    my $source = ();
    $source->{sourceIp} = $sourceIp;
    $source->{sourceMask} = $sourceMask;

    return $source;
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
        $self->getLibrary()->show_exceptions($_  . ' ( LibraryRedirect->addRedirectRow() ) ');
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
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->deleteRedirectRow() ) ');
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
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->deleteRedirectParam() ) ');
    };
}

##
# 20170731 Pulipuli Chen
# 更新很多連接埠，也很容易出現問題，請小心使用
##
sub updateRedirectPorts
{
    my ($self, $row) = @_;

    try {

        my $lib = $self->getLibrary();
        my $libNET = $self->getLoadLibrary('LibraryNetwork');

        my $hint = '';
        my $protocol = '';

        my $ipaddr = $libNET->getExternalIpaddr();

        my $portHeader = $self->getPortHeader($row);

        # 加入Pound
        $protocol = "POUND";
        if ($self->isProtocolEnable($row, $protocol)) {
            if ($hint ne ''){
                $hint = $hint . "<br />";
            }
            $hint = $hint. $self->getProtocolHint($row, $protocol);
        }

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
        my $redirOtherForMod = '';
        if ($row->elementExists("redirOther_subMod")) {
            my $domainName = $row->valueByName("domainName");
            my $redirOther = $row->subModel('redirOther');

            for my $subId (@{$redirOther->ids()}) {

                my $redirRow = $redirOther->row($subId);

                my $extPort = $self->getOtherExtPort($row, $redirRow);
                my $intPort = $redirRow->valueByName('intPort');
                my $desc = $redirRow->valueByName('description');
                my $secure = $redirRow->valueByName('secure');

                my $portEnable = $self->getLibrary()->isEnable($redirRow);
                my $schema = $redirRow->valueByName("redirOther_scheme");

                if ($secure == 1) {
                    $desc = '[' . $desc . ']';
                }
                elsif ($secure == 2) {
                    $desc = '(' . $desc . ')';
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

                #$hint = $hint . $desc . ": <br />" . $extPort ." &gt; " . $intPort.""; 
                if ($self->getLibrary()->isEnable($row) == 1) {
                    $hint = $hint . $desc . ": " . $extPort ." &gt; " . $intPort.""; 
                }
                else {
                    $hint = $hint . '<span style="text-decoration: line-through">' . $desc . ": " . $extPort ." &gt; " . $intPort . '</span>'; 
                }

                if ($redirOtherForMod ne '') {
                    $redirOtherForMod = $redirOtherForMod . "\n";
                }

                $redirOtherForMod = $redirOtherForMod . $redirRow->valueByName('description');
            }   # for my $subId (@{$row->subModel('redirOther')->ids()}) {
        }   #if ($row->elementExists("redirOther_subMod")) { 

        if ($row->elementExists("redirOther_subMod")) {
            $row->elementByName('redirOther_subMod')->setValue($redirOtherForMod);
        }   # if ($row->elementExists("redirOther_subMod")) {

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
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryRedirect->updateRedirectPorts() ) ');
    };
}

sub isProtocolEnable 
{
    my ($self, $row, $protocol) = @_;

    my $enable = 0;

    # 20150515 加入POUND
    if ($protocol eq "POUND") {
        #my $redirPound_scheme = $row->valueByName('redirPOUND_scheme');
        #my $enable = ($redirPound_scheme eq 'https' 
        #    || ( $redirPound_scheme eq 'http' && $row->valueByName('redirPOUND_secure') == 1 ) );
        #    
        #if ($enable == 0 && $row->elementExists('otherDomainName')) {
        #    my $otherDN = $row->subModel('otherDomainName');
        #    
        #    for my $dnId (@{$otherDN->ids()}) {
        #        my $dnRow = $otherDN->row($dnId);
        #        
        #        my $scheme = $dnRow->valueByName('redirPOUND_scheme');
        #        my $secure = $dnRow->valueByName('redirPOUND_secure');
        #
        #        $enable = ($scheme eq 'https' 
        #            || ( $scheme eq 'http' && $secure == 1) );
        #
        #       if ($enable == 1) {
        #            last;
        #        }
        #    }   # for my $dnId (@{$otherDN->ids()}) {

        #}   # if ($enable == 0 && $row->elementExists('otherDomainName')) {
        $enable = 1;
    }
    else {
        $enable = ($row->elementExists('redir'.$protocol.'_enable') && $row->valueByName('redir'.$protocol.'_enable') == 1);
    }

    return $enable;
}

sub getRedirectSecureLevel
{
    my ($self, $row, $protocol) = @_;

    my $secure = 0;
    if ($row->elementExists('redir' . $protocol . '_secure')) {
        $secure = $row->valueByName('redir'.$protocol.'_secure');
    }
    
    return $secure;
}

sub getProtocolHint
{
    my ($self, $row, $protocol) = @_;
    my $lib = $self->getLibrary();
    my $libNET = $self->getLoadLibrary('LibraryNetwork');

    my $hint = "";

    my $extPort = $self->getProtocolExtPort($row, $protocol);

    my $intPort = $self->getProtocolIntPort($row, $protocol);
    my $note = "";
    if ($row->elementExists('redir'.$protocol.'_note')) {
        $note = $row->valueByName('redir'.$protocol.'_note');
    }

    my $protocolTitle = $protocol;
    
    if (defined($note) && $note ne '') {
        $protocolTitle = $protocolTitle . '*';
    }

    my $secure = $self->getRedirectSecureLevel($row, $protocol);
    
    if ($secure == 1) {
        #$protocolTitle = '[' .$protocolTitle . ']';

        $hint = '<span title="' . $protocolTitle . ' (only for administrators): ' . $extPort ." &gt; " . $intPort . '">' 
            . "<strong>[".$protocolTitle."]</strong>: ". $extPort 
            . "</span>";
    }
    elsif ($secure == 2) {
        #$protocolTitle = '(' .$protocolTitle . ')';

        $hint = '<span title="' . $protocolTitle . ' (only in workplace): ' . $extPort ." &gt; " . $intPort . '">' 
            . "<strong>(".$protocolTitle.")</strong>: ". $extPort 
            . "</span>";
    }
    else {
        $hint = '<span title="' . $protocolTitle . ' (for public): ' . $extPort ." &gt; " . $intPort . '">' 
            . "<strong>".$protocolTitle."</strong>: ". $extPort 
            . "</span>";
    }

#    $hint = "<strong>".$protocolTitle."</strong>: "
#        #. "<br />" 
#        #. $extPort ." &gt; " . $intPort."";
#        . $extPort;
#    $hint = '<span title="' . $protocolTitle . "(secure): " . $extPort ." &gt; " . $intPort . '">' . $hint .  '</span>';
    
    # 加入連結的部分
    my $scheme = "none";
    if ($row->elementExists('redir'.$protocol.'_scheme')) {
        $scheme = $row->valueByName('redir'.$protocol.'_scheme');
    }

    if ( ($scheme eq 'http') || ($scheme eq 'https') ) {
        
        #my $ipaddr = $libNET->getExternalIpaddr();
        my $ipaddr = $row->valueByName('domainName');

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

    my $enable = $self->getLibrary()->isEnable($row);
    if ($enable == 0) {
        $hint = '<del>' . $hint . '</del>';
    }

    return $hint;
}

# --------------------------------------------

# 20150516 Pulipuli Chen
sub getServerRedirectParamDMZ
{
    my ($self, $row, $desc, $extPort, $intPort) = @_;

    my $domainName = $row->valueByName("domainName");
    #my $destIpaddr = $row->elementByName("extIpaddr")->ip();
    my $destIpaddr = $row->valueByName("extIpaddr");
    my $localIpaddr = $row->valueByName("ipaddr");

    my $libNET = $self->getLoadLibrary('LibraryNetwork');
    my $iface = $libNET->getExternalIface();
    my $source = $self->getSecureIpSource();

    #my $intPort = $row->valueByName("port");
    my $objectRowId = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id();

    my %param = (
        interface => $iface,
        origDest_selected => "origDest_ipaddr",
        origDest_ipaddr_ip => $destIpaddr,
        origDest_ipaddr_mask => 32,
        protocol => "tcp/udp",
        external_port_range_type => 'any',

        #source_selected => 'source_ipaddr',
        #source_ipaddr_ip => $source->{sourceIp},
        #source_ipaddr_mask => $source->{sourceMask},
        source_selected => 'source_object',
        source_object => $objectRowId,

        destination => $row->valueByName("ipaddr"),
        destination_port_selected => "destination_port_same",

        description => $domainName. " (" . $localIpaddr . "): " . $desc . ' (DMZ)',
        snat => 1,  # 不做Replace source address，必有它的用意吧
        log => 1,
    );

    return %param;
}

sub getServerRedirectParamOrigin
{
    my ($self, $row, $desc, $extPort, $intPort, $protocol) = @_;

    my $domainName = $row->valueByName("domainName");
    #my $destIpaddr = $row->elementByName("extIpaddr")->ip();
    my $destIpaddr = $row->valueByName("extIpaddr");
    my $localIpaddr = $row->valueByName("ipaddr");

    my $libNET = $self->getLoadLibrary('LibraryNetwork');
    my $iface = $libNET->getExternalIface();
    my $source = $self->getSecureIpSource();

    #my $intPort = $row->valueByName("port");
    my $objectRowId = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id();

    my %param = (
        'interface' => $iface,
        'origDest_selected' => "origDest_ipaddr",
        'origDest_ipaddr_ip' => $destIpaddr,
        'origDest_ipaddr_mask' => 32,
        'protocol' => "tcp/udp",

        'external_port_range_type' => 'single',
        'external_port_single_port' => $extPort,

        source_selected => 'source_object',
        source_object => $objectRowId,
        #source_selected => 'source_ipaddr',
        #source_ipaddr_ip => $source->{sourceIp},
        #source_ipaddr_mask => $source->{sourceMask},

        'destination' => $row->valueByName("ipaddr"),
        
        'destination_port_selected' => "destination_port_other",
        'destination_port_other' => $intPort,

        'description' => $domainName. " (" . $localIpaddr . "): " . $desc . ' ('. $protocol .' Original)',
        'snat' => 1,  # 不做Replace source address，必有它的用意吧
        'log' => 1,
    );

    return %param;
}

sub getServerRedirectParamZentyal
{
    my ($self, $row, $desc, $extPort, $intPort, $protocol) = @_;

    my $domainName = $row->valueByName("domainName");
    #my $destIpaddr = $row->elementByName("extIpaddr")->ip();
    my $destIpaddr = $row->valueByName("extIpaddr");
    my $localIpaddr = $row->valueByName("ipaddr");

    my $libNET = $self->getLoadLibrary('LibraryNetwork');
    my $iface = $libNET->getExternalIface();
    #my $source = $self->getSecureIpSource();
    my $objectRowId = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id();

    #my $intPort = $row->valueByName("port");

    my %param = (
        'interface' => $iface,
        'origDest_selected' => "origDest_ebox",
        'protocol' => "tcp/udp",

        'external_port_range_type' => 'single',
        'external_port_single_port' => $extPort,

        'source_selected' => 'source_object',
        'source_object' => $objectRowId,
        #'source_selected' => 'source_ipaddr',
        #'source_ipaddr_ip' => $source->{sourceIp},
        #'source_ipaddr_mask' => $source->{sourceMask},

        'destination' => $row->valueByName("ipaddr"),
        
        'destination_port_selected' => "destination_port_other",
        'destination_port_other' => $intPort,

        'description' => $domainName. " (" . $localIpaddr . "): " . $desc . ' (' . $protocol . ' Zentyal)',
        'snat' => 1,  # 不做Replace source address，必有它的用意吧
        'log' => 1,
    );

    return %param;
}

# 20150528 Pulipuli Chen
# @departed
# 捨棄不用
#sub setupZentyalRedirect
#{
#    my ($self) = @_;
#    return;
#    my $libNET = $self->getLoadLibrary('LibraryNetwork');
#    my $iface = $libNET->getExternalIface();
#    my $objectRowId = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id();

#    my %paramAdmin = (
#        interface => $iface,
#        origDest_selected => "origDest_ebox",
#        protocol => "tcp/udp",

#        external_port_range_type => 'single',
#        external_port_single_port => 64443,

#        source_selected => 'source_object',
#        source_object => $objectRowId,

#        destination => "10.0.0.254",
        
#        destination_port_selected => "destination_port_other",
#        destination_port_other => 8443,

#        description => __("Zentyal Webadmin (64443->8443)"),
#        snat => 0,
#        log => 1,
#    );

#    $self->addRedirectRow(%paramAdmin);

#    my %paramSSH = (
#        interface => $iface,
#        origDest_selected => "origDest_ebox",
#        protocol => "tcp/udp",

#        external_port_range_type => 'single',
#        external_port_single_port => 64422,

#        source_selected => 'source_object',
#        source_object => $objectRowId,

#        destination => "10.0.0.254",
        
#        destination_port_selected => "destination_port_other",
#        destination_port_other => 22,

#        description => __("Zentyal SSH (64422->22)"),
#        snat => 0,
#        log => 1,
#    );

#    $self->addRedirectRow(%paramSSH);
#}

1;
