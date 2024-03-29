package EBox::dlllciasrouter::Model::LibraryDomainName;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::MACAddr;
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
use EBox::Exceptions::DataExists;

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;
use EBox::Sudo;

##
# 讀取LibraryToolkit
# @author Pulipuli Chen
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# 20150506 Pulipuli Chen
# 新增Domain Name
sub addDomainName
{
    my ($self, $domainName) = @_;

    my $libSettings = $self->getLoadLibrary('RouterSettings');
    my $ipaddr = $libSettings->value("primaryDomainNameIP");

    if (!defined($ipaddr) || $ipaddr eq '') {
      my $libNetwork = $self->getLoadLibrary('LibraryNetwork');
      $ipaddr = $libNetwork->getExternalIpaddr();
    }

    $self->addDomainNameWithIP($domainName, $ipaddr);
}

# 20150506 Pulipuli Chen
# 指定IP
sub addDomainNameWithIP
{
    # my ($self, $domainName, $ipaddr, $enableWildcardDNS) = @_;
    my ($self, $domainName, $ipaddr) = @_;

    if ($domainName eq '') {
        #return;
        $self->getLibrary()->show_exceptions($_ 
            . ' Domain name is empty. '
            . '(LibraryDomainName->addDomainNameWithIP() )');
        return;
    }

    try {
        # 建立預設的DomainName
        #my $defaultDomainName = $self->setupDefaultDomainName();

        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        my $domModel = $dns->model('DomainTable');
        my $id = $domModel->findId(domain => $domainName);
        if (defined($id)) {
            $domModel->removeRow($id);
        }
        $domModel->addDomain({
            'domain_name' => $domainName,
        });

        $id = $domModel->findId(domain => $domainName);
        my $domainRow = $domModel->row($id);

        # 刪掉多餘的IP
        my $ipTable;
        $ipTable = $domainRow->subModel("ipAddresses");
        $ipTable->removeAll();

        # 幫ipTable加上指定的IP
        $ipTable->addRow(
            ip => , $ipaddr
        );

        # 刪掉多餘的Hostname
        my $hostnameTable = $domainRow->subModel("hostnames");
        #my $zentyalHostnameID = $hostnameTable->findId("hostname"=> 'zentyal');
        my $zentyalHostnameID;
        my $zentyalRow;
        for $zentyalHostnameID (@{$hostnameTable->ids()}) {
            $zentyalRow = $hostnameTable->row($zentyalHostnameID);
            
            if (defined($zentyalRow)) {
                # my $aliasModel = $zentyalRow->subModel('alias');
                # my $row = $aliasModel->find(alias => "*." . $domainName);
                # unless (defined $row) {
                #     $aliasModel->addRow(alias => "*." . $domainName);
                # }
                last;
            }
        }
        # $hostnameTable->addRow({
        #     "name" => "*",
        #     "ip" => $ipaddr
        # });
        #my @ipaddrArray = @{( $ipaddr )};
        # my @ipaddrArray = ($ipaddr);
        # my @ipaddrArray = [$ipaddr];
        # $domModel->addHost($domainName, {
        #     "name" => "*",
        #     #"readOnly" => 0,
        #     #"ipAddresses" => @ipaddrArray
        # });

        #if (!defined($zentyalRow)) {
        #    $zentyalRow = $hostnameTable->row();
        #}

        my $zentyalIpTable = $zentyalRow->subModel("ipAddresses");
        $zentyalIpTable->removeAll();

        # 幫zentyalIpTalbe加上指定的IP
        $zentyalIpTable->addRow(
            ip => , $ipaddr
        );
    } catch {

        $self->getLibrary()->show_exceptions($_ 
            . ' <a href="/DHCP/View/Interfaces">DHCP Module</a> '
            . '(LibraryDomainName->addDomainNameWithIP() )');

    }
}

sub deleteDomainName
{
    my ($self, $domainName, $excludeModel) = @_;
    #my $domainName = $row->valueByName('domainName');

    if ($domainName eq '') {
        return;
    }

    try {

        # 先找找看有沒有
        my $hasDomainName = 0;

        if ($hasDomainName == 0 && $excludeModel ne 'dlllciasrouter-pound') {
            $hasDomainName = $self->modelHasDomainName('LibraryServices', $domainName);
            if ($hasDomainName == 0) {
                $hasDomainName = $self->modelHasDomainName('OtherDomainNames', $domainName);
            }
        }

        #if ($hasDomainName == 0 && $excludeModel ne 'PoundServices') {
        #    $hasDomainName = $self->modelHasDomainName('PoundServices', $domainName);
        #}

        if ($hasDomainName == 0 && $excludeModel ne 'URLRedirect') {
            $hasDomainName = $self->modelHasDomainName('URLRedirect', $domainName);
        }

        if ($hasDomainName == 0 && $excludeModel ne 'DNS') {
            $hasDomainName = $self->modelHasDomainName('DNS', $domainName);
        }

        if ($hasDomainName == 0) 
        {
            my $gl = EBox::Global->getInstance();
            my $dns = $gl->modInstance('dns');
            my $domModel = $dns->model('DomainTable');
            my $id = $domModel->findId(domain => $domainName);
            if (defined($id)) {
                $domModel->removeRow($id);
            }
        }

    } catch {

        #my $defaultDomainName = $self->getDefaultDomainName();
        ## DHCP的Dynamic DNS模組模組
        #my $gl = EBox::Global->getInstance();
        #my $dhcp = $gl->modInstance('dhcp');
        #my $interfaces = $dhcp->model('Interfaces');
        #for my $ifId (@{$interfaces->ids()}) {
        #    my $ifRow = $interfaces->row($ifId);
        #    my $configuration = $ifRow->subModel('configuration');
        #   my $dynamicDNS = $configuration->componentByName('DynamicDNS', 1);
        #    #$dynamicDNS->setValue('dynamic_domain', $defaultDomainName);
        #}
        #$self->deleteDomainName($domainName, $excludeModel);

        $self->getLibrary()->show_exceptions($_ 
            . ' <a href="/DHCP/View/Interfaces">DHCP Module</a> '
            . '(LibraryDomainName->deleteDomainName() )');
    };
}

# 20220705 Pulipuli Chen
# 新增Wildcard Domain Name
sub addWildcardDomainName
{
    my ($self, $domainName, $mainIpaddr, $ipaddr, $diffIpaddr) = @_;

    if (!defined($ipaddr) || $ipaddr eq '') {
      $ipaddr = $mainIpaddr
    }

    my @dbparams = ();
    my $sysinfo = EBox::Global->modInstance('sysinfo');
    push(@dbparams, 'primaryNameServer' => $sysinfo->hostName());
    push(@dbparams, 'ns' => $sysinfo->hostName());

    push(@dbparams, 'domainName' => $domainName);
    push(@dbparams, 'ip' => $mainIpaddr);
    push(@dbparams, 'subip' => $ipaddr);
    push(@dbparams, 'diffIpaddr' => $diffIpaddr);
    

    $self->parentModule()->writeConfFile(
        '/etc/bind/db.' . $domainName,
        "dlllciasrouter/dns/db.wildcard.mas",
        \@dbparams,

        # uid 111 bind
        # gid 118 bind
        { uid => '111', gid => '118', mode => '644' }
    );

    # 加上檔案
    # /var/lib/bind/db._acme-challenge.test-zentyal-2022a.pulipuli.info
    my $dbPath = '/var/lib/bind/db._acme-challenge.' . $domainName;

    my @params = ();
    push(@params, 'domainName' => $domainName);

    $self->parentModule()->writeConfFile(
        $dbPath,
        "dlllciasrouter/dns/rfc2136-db._acme-challenge.mas",
        \@params,

        # uid 111 bind
        # gid 118 bind
        { uid => '111', gid => '118', mode => '644' }
    );
}

##
# 20220705 Pulipuli Chen
##
sub deleteWildcardDomainName
{
    my ($self, $domainName) = @_;

    # $self->deleteDomainName($domainName);
    # '/etc/bind/db.' . $domainName
    EBox::Sudo::root( 'rm -f /etc/bind/db.' . $domainName );

    if ($domainName eq '') {
        return 1;
    }

    # my $dbPath = '/var/lib/bind/db._acme-challenge.' . $domainName;
    
    # unlink($dbPath, $dbPath . ".jnl");
    # system('sudo rm -f ' . $dbPath . '*' );
    EBox::Sudo::root( 'rm -f /var/lib/bind/db._acme-challenge.' . $domainName );
}

##
# 20150515 Pulipuli Chen
# 考慮到OtherDomainName，刪除他們
##
sub deleteOtherDomainNames
{
    my ($self, $subMod, $excludeModel) = @_;
    
    if (!defined($subMod) || $subMod eq '') {
        return;
    }

    my @subModAry = split(/\n/, $subMod);
    for my $domainName (@subModAry) {
        $self->deleteDomainName($domainName, $excludeModel);
    }
}

##
# 20170731 Pulipuli Chen
# 考慮到OtherDomainName，增加他們
##
sub addOtherDomainNames
{
    my ($self, $subMod) = @_;
    
    if (!defined($subMod) || $subMod eq '') {
        return;
    }

    my @subModAry = split(/\n/, $subMod);
    for my $domainName (@subModAry) {
        $self->addDomainName($domainName);
    }
}

sub modelHasDomainName
{
    my ($self, $modelName, $domainName) = @_;

    try {

        my $model = $self->parentModule()->model($modelName);
        my $domainNameId = $model->findId(
            'domainName' => $domainName
        );

        return defined($domainNameId);
    }
    catch {
        #$self->getLibrary()->show_exceptions($_ . ' ( LibraryDomainName->modelHasDomainName() )');
        return 0;
    }
}

# -----------------------------------
# Field Setter

# 20170727 Pulipuli Chen
# @departed
# 此方法廢棄不用
#sub setLinkWithDomainName
#{
#    my ($self, $row) = @_;
#
#    my $domainName = $row->valueByName('domainName');
#    my $url = $row->valueByName('url');
#    my $enable = $self->getLibrary()->isEnable($row);
#
#    my $domainNameLink = $self->domainNameToLink($domainName, $enable);
#    my $urlLink = $self->urlToLink($url);
#
#    $row->elementByName('domainNameLink')->setValue($domainNameLink);
#    $row->elementByName('urlLink')->setValue($urlLink);
#
#    #$row->store();
#}

sub setLink
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();

    my $domainName = $row->valueByName('domainName');
    my $url = $row->valueByName('url');
    my $enable = $lib->isEnable($row);

    my $urlLink = $self->urlToLink($url);

    $row->elementByName('urlLink')->setValue($urlLink);

    #$row->store();
}

sub urlToLink
{
    my ($self, $url) = @_;

    my $originalUrl = $url;
    my $link = $url;
    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
        $link = "http://" . $link . "/";
    }

    if (length($url) > 20) 
    {
        $url = substr($url, 0, 20) . "...";
    }

    $link = '<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$url.'</a>' 
      . '<br /><a target="_blank" href="https://www.whatsmydns.net/#A/' . $originalUrl . '" style="background: none;border-width: 0"><img src="/data/dlllciasrouter/images/dns.png" border="0" /></a>';

    return $link;
}

sub setServerMainLink
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();

    my $ipaddr = $row->valueByName('ipaddr');
    my $extPort = $self->getLoadLibrary('LibraryRedirect')->getServerMainPort($ipaddr);

    my $url = $ipaddr . ':' . $extPort;

    my $link = "https://";
    if (!$row->valueByName('isHttps')) {
        $link = "http://"
    }     
    $link = $link . $ipaddr . ':' . $extPort;
    
    $link = '<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$ipaddr.'</a>';

    $row->elementByName('ipaddrLink')->setValue($link);

    #$row->store();
}

##
# 廢棄不使用的方法
#sub domainNameToLink
#{
#    my ($self, $url, $enable) = @_;
#
#    my $link = $url;
#    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
#        $link = "http://" . $link . "/";
#    }
#
#    $url = $self->breakUrl($url);
#
#    my $textDecoration = "underline";
#    if ($enable == 0) {
#        $textDecoration = "line-through";
#    }
#
#    $link = '<a style="background: none;text-decoration: '.$textDecoration.';color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$url.'</a>';
#
#    return $link;
#}


sub updateDomainNameLink
{
    my ($self, $row, $doBreakUrl) = @_;
    
    my $domainName = $row->valueByName("domainName");
    if (!defined($domainName)) {
        $domainName = $row->valueByName('ipaddr');
        $doBreakUrl = 0;
    }

    # if ($row->elementExists('enableWildcardDNS')) {
    #     my $enableWildcardDNS = $row->valueByName("enableWildcardDNS");
    #     if ($enableWildcardDNS == 1) {
    #         $domainName = "*." .$domainName
    #     }
    # }

    my $enable = $self->getLibrary()->isEnable($row);
    my $secure = 0;
    if ($row->elementExists('redirPOUND_secure')) {
        $secure = $row->valueByName('redirPOUND_secure');
    }
    my $schema = "http";
    if ($row->elementExists('redirPOUND_secure')) {
        $schema = $row->valueByName('redirPOUND_scheme');
    }
    my $isHttp = 0;
    if ($schema eq "http") {
        $isHttp = 0;
    }

    my $link = $self->updateDomainNameLinkDeco($domainName, $enable, $secure, $doBreakUrl, $isHttp);
    
    # -----------------
    # 20150514 Pulipuli Chen
    # 如果有底下的OtherDomainNames的情況
    if ($row->elementExists('otherDomainName')) {

        my $subMod = "";

        # 把資訊更新到自己裡面
        my $otherDN = $row->subModel('otherDomainName');
        for my $dnId (@{$otherDN->ids()}) {
            my $dnRow = $otherDN->row($dnId);
            #$enable = $self->getLibrary()->isEnable($dnRow);
            #if ($enable == 0) {
            #    next;
            #}
            $secure = $dnRow->valueByName('redirPOUND_secure');
            my $otherDomainName = $dnRow->valueByName("domainName");

            my $otherLink = $self->updateDomainNameLinkDeco($otherDomainName, $enable, $secure, $doBreakUrl, $isHttp);
            $link = $link . "<br />, " . $otherLink;

            if ($subMod ne '') {
                $subMod = $subMod . "\n";
            }
            $subMod = $subMod . $otherDomainName;
        }   # for my $dnId (@{$otherDN->ids()}) {

        if ($row->elementExists("otherDomainName_subMod")) {
            $row->elementByName('otherDomainName_subMod')->setValue($subMod);
        }
    }

    $row->elementByName("domainNameLink")->setValue($link);

    #$row->store();
}

sub updateDomainNameLinkDeco
{
    my ($self, $domainName, $enable, $secure, $doBreakUrl, $isHttp) = @_;

    my $originalUrl = $domainName;
    my $brokenDomainName = $domainName;
    if ($doBreakUrl == 1) {
        $brokenDomainName = $self->breakUrl($brokenDomainName);
    }

    if ($secure == 1) {
        $brokenDomainName = '[' . $brokenDomainName . ']';
    }

    my $port = $self->parentModule()->model("RouterSettings")->value("port");

    if (!defined($port)) {
        throw EBox::Exceptions::External("Port is not set. Go to <a href='dlllciasrouter/Composite/SettingComposite'>Settings</a>");
    }

    if ($port == 80) {
        $port = "";
    }
    else {
        $port = ":" . $port;
    }
    my $link = $domainName . $port . "/";

    if ($isHttp == 1) {
        $link = "http\://" . $link;
    }
    else {
        $link = "https\://" . $link;
    }
    

    my $textDecoration = "underline";
    if ($enable == 0) {
        $textDecoration = "line-through";
    }

    my $title = "Public link: " . $link;
    if ($secure == 1) {
        $title = "For Administrator: " . $link;
    }
    elsif ($secure == 2) {
        $title = "For Workplace: " . $link;
    }

    # 20181031 加上了DNS即時查詢功能
    $link = '<a href="'.$link.'" ' 
        . ' title="' . $title . '" '
        . 'target="_blank" ' 
        . 'style="background: none;text-decoration: ' . $textDecoration . ';color: #A3BD5B;" '
        . 'id="filter_' . $domainName . '" >' 
        . $brokenDomainName 
        . '</a>'
        . '<br /><a target="_blank" href="https://www.whatsmydns.net/#A/' . $originalUrl . '" style="background: none;border-width: 0"><img src="/data/dlllciasrouter/images/dns.png" border="0" /></a>';

    return $link;
}

sub breakUrl
{
    my ($self, $url) = @_;

    my $result = index($url, ".");
    $url = substr($url, 0, $result) . "<br />" . substr($url, $result);
    return $url;
}


##
# 20150512 Pulipuli Chen
# 更新新增連接埠的說明
##
sub updatePortDescription
{
    my ($self, $row, $redirRow) = @_;

    my $enable = $self->getLibrary()->isEnable($redirRow);
    my $desc = $redirRow->valueByName("description");

    my $secure = $redirRow->valueByName('secure');
    if ($secure == 1) {
        $desc = '[' . $desc . ']';
    }
    elsif ($secure == 2) {
        $desc = '(' . $desc . ')';
    }

    my $schema = 'none';

    if ($row->elementExists("redirOther_subMod")) {
        $schema = $redirRow->valueByName("redirOther_scheme");
    }
    my $link = $desc;
    
    if ($enable == 0) {
        $link = '<span style="text-decoration: line-through">' . $desc . '</span>';
    }   # if ($enable == 0) {
    else {
        if ($schema eq "none") {
            $link = '<span>' . $desc . '</span>';
        }   # if ($schema eq "none") {
        else {
            my $textDecoration = "underline";
            if ($enable == 0) {
                $textDecoration = "line-through";
            }

            my $extPort = $redirRow->valueByName("extPort");
            $extPort = $self->getLoadLibrary('LibraryRedirect')->getOtherExtPort($row, $redirRow);

            my $domainName = $row->valueByName("domainName");

            $link = $domainName . ":" . $extPort . "/";
            if ($schema eq "http") {
                $link = "http\://" . $link;
            }
            else {
                $link = "https\://" . $link;
            }
            $link = '<a href="'.$link.'" ' 
                . 'target="_blank" ' 
                . 'style="background: none;text-decoration: '.$textDecoration.';color: #A3BD5B;">' 
                . $desc 
                . '</a>';
        }   # if ($schema ne "none") {
    }   # else {

    $redirRow->elementByName("descriptionDisplay")->setValue($link);
}

##
# 20150513 Pulipuli Chen
# 在DNS中新增一個預設的Domain Name
## 
sub initDefaultDomainName
{
    my ($self) = @_;

    my $domainName = $self->getDefaultDomainName();
    my $gl = EBox::Global->getInstance();
    my $dns = $gl->modInstance('dns');
    my $domModel = $dns->model('DomainTable');
    my $id = $domModel->findId(domain => $domainName);
    if (!defined($id)) {
        $domModel->addDomain({
            'domain_name' => $domainName,
        });
        #$domModel->store();
    }
    
    $id = $domModel->findId(domain => $domainName);

    my $defaultDomainName = $self->getDefaultDomainName();
    # DHCP的Dynamic DNS模組模組
    my $dhcp = $gl->modInstance('dhcp');
    my $interfaces = $dhcp->model('Interfaces');
    for my $ifId (@{$interfaces->ids()}) {
        my $ifRow = $interfaces->row($ifId);
        my $configuration = $ifRow->subModel('configuration');
        my $dynamicDNS = $configuration->componentByName('DynamicDNS', 1);
        $dynamicDNS->setValue('dynamic_domain', $id);
        #$dynamicDNS->store();
        #throw EBox::Exceptions::External("D DHCP: " . $id);
    }
    #throw EBox::Exceptions::External("D DHCP: ");
    
    return $domainName;
}

##
# 20150513 Pulipuli Chen
# 在DNS中新增一個預設的Domain Name
## 
sub getDefaultDomainName
{
    #return 'default-domain-name.dlll.nccu.edu.tw';
    return 'dlll.nccu.edu.tw';
    # 20170801 Pulipuli Chen
    # 調整為預設新增dlll.nccu.edu.tw
}

1;
