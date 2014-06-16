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

    for my $subId (@{$row->subModel('redirOther')->ids()}) {
        my $redirRow = $row->subModel('redirOther')->row($subId);
        my $redirModel = $row->subModel('redirOther');
        $redirModel->addRedirect($row, $redirRow);
    }
}

sub deleteRedirects
{
    my ($self, $row) = @_;

    my %param;
    #try {
        #%param = $self->getRedirectParamHTTP($row);
    #} catch {
        #$self->test($_);
    #};

    %param = $self->getRedirectParamHTTP($row);
    $self->deleteRedirectRow(%param);


    %param = $self->getRedirectParamHTTPS($row);
    $self->deleteRedirectRow(%param);
    
    %param = $self->getRedirectParamSSH($row);
    $self->deleteRedirectRow(%param);

    %param = $self->getRedirectParamRDP($row);
    $self->deleteRedirectRow(%param);

    for my $subId (@{$row->subModel('redirOther')->ids()}) {
        my $redirRow = $row->subModel('redirOther')->row($subId);
        my $redirModel = $row->subModel('redirOther');
        $redirModel->deleteRedirect($row, $redirRow);
    }
}

# -----------------------------

# 20140208 Pulipuli Chen
# 似乎沒有用到，廢棄
#sub populateHTTP
#{
#    my @opts = ();
#    push (@opts, { value => 'redirHTTP_default', printableValue => 'Use Internal Port' });
#    push (@opts, { value => 'redirHTTP_disable', printableValue => 'Disable' });
#    return \@opts;
#}

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
        return 80;
    }
    elsif ($protocol eq 'HTTPS') {
        return 43;
    }
    elsif ($protocol eq 'SSH') {
        return 22;
    }
    elsif ($protocol eq 'RDP') {
        return 89;
    }
    else {
        return 80;
    }
}

sub getProtocolRedirectParam
{   
    my ($self, $row, $protocol) = @_;

    my $extPort = $self->getProtocolExtPort($row, $protocol);
    my $intPort = $self->getProtocolIntPort($row, $protocol);
    my $log = $self->getProtocolLog($row, $protocol);

    if ($row->valueByName('redir'.$protocol.'_secure') == 1)
    {
        return $self->getRedirectParameterSecure($row, $extPort, $intPort, $protocol, $log);
    }
    else
    {
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

    #my $extPort = $redirRow->valueByName('extPort');
    #my $portHeader = $self->getPortHeader($row);
    #$extPort = $portHeader . $extPort;
    my $extPort = $self->getOtherExtPort($row, $redirRow);

    my $intPort = $redirRow->valueByName('intPort');
    my $desc = $redirRow->valueByName('description');
    $desc = "Other (".$desc.")";
    my $log = $redirRow->valueByName('log');

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
    if ($extPort < 10) {
        $extPort = "0" . $extPort;
    }
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

sub getRedirectParameterFind
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();
    my $libNET = $self->loadLibrary('LibraryNetwork');

    my $domainName = $row->valueByName("domainName");
    my $iface = $libNET->getExternalIface();
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
    for my $subId (@{$row->subModel('redirOther')->ids()}) {
        my $redirRow = $row->subModel('redirOther')->row($subId);
        #my %param = $self->getRedirectParamOther($row, $redirRow);
        #my $extPort = $redirRow->valueByName('extPort');
        #my $portHeader = $self->getPortHeader($row);
        #$extPort = $portHeader . $extPort;
        my $extPort = $self->getOtherExtPort($row, $redirRow);
        my $intPort = $redirRow->valueByName('intPort');
        my $desc = $redirRow->valueByName('description');
        my $secure = $redirRow->valueByName('secure');

        if ($secure) {
            $desc = '[' . $desc . ']';
        }

        if ($hint ne '')
        {
            $hint = $hint . "<br />";
        }
        
        $hint = $hint . "<strong>" . $desc . "</strong>: <br />" . $extPort ." &gt; " . $intPort."";   
    }

    # 最後結尾
    if ($hint ne '')
    {
        $hint = "<div style='text-align:left;'>". $hint . "</div>";
    }
    else
    {
        $hint = "<span>-</span>";
    }

    $row->elementByName('redirPorts')->setValue($hint);
    #$row->store();
}

sub isProtocolEnable 
{
    my ($self, $row, $protocol) = @_;

    return ($row->valueByName('redir'.$protocol.'_enable') == 1);
}

sub getProtocolHint
{
    my ($self, $row, $protocol) = @_;

    my $hint = "";

    my $lib = $self->getLibrary();
    my $libNET = $self->loadLibrary('LibraryNetwork');


    my $extPort = $self->getProtocolExtPort($row, $protocol);

    my $intPort = $self->getProtocolIntPort($row, $protocol);
    my $note = "";

    $note = $row->valueByName('redir'.$protocol.'_note');

    my $protocolTitle = $protocol;

    if (defined $note && $note ne '') {
        $protocolTitle = $protocolTitle . '*';
    }

        my $secure = $row->valueByName('redir'.$protocol.'_secure');
        if ($secure == 1) {
            $protocolTitle = '[' .$protocolTitle . ']';
        }

        $hint = "<strong>".$protocolTitle."</strong>: "
            . "<br />" 
            . $extPort ." &gt; " . $intPort."";

        if ( ($protocol eq 'HTTP') || ($protocol eq 'HTTPS') ) {

            my $ipaddr = $libNET->getExternalIpaddr();

            my $url = "http\://" . $ipaddr . "\:".$extPort."/";
            if ($protocol eq 'HTTPS') {
                $url = "https\://" . $ipaddr . "\:".$extPort."/";
            }
            $hint = "<a "
                . "style='background: none;text-decoration: underline;color: #A3BD5B;' "
                . "href=\"".$url."\" target=\"_blank\">"
                . $hint
                . "</a>";  
        }

        if (defined $note && $note ne '') {
            $hint = '<em title="'.$note.'">'.$hint.'</em>';
        }

#    try {
#
#    }   # try {
#    catch {
#        my $lib = $self->getLibrary();
#        $lib->show_exceptions($_);
#    }   # catch {

    return $hint;
}

1;
