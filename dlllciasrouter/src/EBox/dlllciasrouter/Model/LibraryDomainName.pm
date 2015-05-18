package EBox::dlllciasrouter::Model::LibraryDomainName;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::MACAddr;
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
use EBox::Exceptions::DataExists;

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;

##
# 讀取PoundLibrary
# @author Pulipuli Chen
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
}

sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# 20150506 Pulipuli Chen
# 新增Domain Name
sub addDomainName
{
    my ($self, $domainName) = @_;

    my $libNetwork = $self->loadLibrary('LibraryNetwork');
    my $ipaddr = $libNetwork->getExternalIpaddr();
    $self->addDomainNameWithIP($domainName, $ipaddr);
}

# 20150506 Pulipuli Chen
# 指定IP
sub addDomainNameWithIP
{
    my ($self, $domainName, $ipaddr) = @_;

    if ($domainName eq '') {
        return;
    }

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

    # 刪掉多餘的Hostname
    my $hostnameTable = $domainRow->subModel("hostnames");
    my $zentyalHostnameID = $hostnameTable->findId("hostname"=> 'zentyal');
    my $zentyalRow = $hostnameTable->row($zentyalHostnameID);
    my $zentyalIpTable = $zentyalRow->subModel("ipAddresses");
    $zentyalIpTable->removeAll();

    # 幫ipTable加上指定的IP
    $ipTable->addRow(
        ip => , $ipaddr
    );

    # 幫zentyalIpTalbe加上指定的IP
    $zentyalIpTable->addRow(
        ip => , $ipaddr
    );
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

    if ($hasDomainName == 0 && $excludeModel ne 'PoundServices') {
        $hasDomainName = $self->modelHasDomainName('PoundServices', $domainName);
        if ($hasDomainName == 0) {
            $hasDomainName = $self->modelHasDomainName('OtherDomainNames', $domainName);
        }
    }

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

        $self->getLibrary()->show_exceptions($_ . '<a href="/DHCP/View/Interfaces">DHCP Module</a> (LibraryDomainName->deleteDomainName() )');
    };
}

# 20150515 Pulipuli Chen
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

sub modelHasDomainName
{
    my ($self, $modelName, $domainName) = @_;

    my $model = $self->parentModule()->model($modelName);
    my $domainNameId = $model->findId(
        'domainName' => $domainName
    );

    return defined($domainNameId);
}

# -----------------------------------
# Field Setter

sub setLinkWithDomainName
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName('domainName');
    my $url = $row->valueByName('url');
    my $enable = $self->getLibrary()->isEnable($row);

    my $domainNameLink = $self->domainNameToLink($domainName, $enable);
    my $urlLink = $self->urlToLink($url);

    $row->elementByName('domainNameLink')->setValue($domainNameLink);
    $row->elementByName('urlLink')->setValue($urlLink);

    #$row->store();
}

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

    my $link = $url;
    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
        $link = "http://" . $link . "/";
    }

    if (length($url) > 20) 
    {
        $url = substr($url, 0, 20) . "...";
    }

    $link = '<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$url.'</a>';

    return $link;
}

sub setServerMainLink
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();

    my $ipaddr = $row->valueByName('ipaddr');
    my $extPort = $self->loadLibrary('LibraryRedirect')->getServerMainPort($ipaddr);

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

    my $enable = $self->getLibrary()->isEnable($row);
    my $secure = 0;
    if ($row->elementExists('redirPOUND_secure')) {
        $secure = $row->valueByName('redirPOUND_secure');
    }
    my $link = $self->updateDomainNameLinkDeco($domainName, $enable, $secure, $doBreakUrl);
    
    # -----------------
    # 20150514 Pulipuli Chen
    # 如果有底下的OtherDomainNames的情況
    if ($row->elementExists('otherDomainName')) {

        my $subMod = "";

        # 把資訊更新到自己裡面
        my $otherDN = $row->subModel('otherDomainName');
        for my $dnId (@{$otherDN->ids()}) {
            my $dnRow = $otherDN->row($dnId);
            $enable = $self->getLibrary()->isEnable($dnRow);
            if ($enable == 0) {
                next;
            }
            $secure = $dnRow->valueByName('redirPOUND_secure');
            my $otherDomainName = $dnRow->valueByName("domainName");
            my $otherLink = $self->updateDomainNameLinkDeco($otherDomainName, $enable, $secure, $doBreakUrl);
            $link = $link . "<br />" . $otherLink;

            if ($subMod ne '') {
                $subMod = $subMod . "\n";
            }
            $subMod = $subMod . $otherDomainName;
        }   # for my $dnId (@{$otherDN->ids()}) {

        $row->elementByName('otherDomainName_subMod')->setValue($subMod);
    }

    $row->elementByName("domainNameLink")->setValue($link);

    #$row->store();
}

sub updateDomainNameLinkDeco
{
    my ($self, $domainName, $enable, $secure, $doBreakUrl) = @_;

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
    my $link = "http\://" . $domainName . $port . "/";

    my $textDecoration = "underline";
    if ($enable == 0) {
        $textDecoration = "line-through";
    }

    $link = '<a href="'.$link.'" ' 
        . 'target="_blank" ' 
        . 'style="background: none;text-decoration: '.$textDecoration.';color: #A3BD5B;">' 
        . $brokenDomainName 
        . '</a>';

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
    if ($secure) {
        $desc = '[' . $desc . ']';
    }

    my $schema = $redirRow->valueByName("redirOther_scheme");
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
            $extPort = $self->loadLibrary('LibraryRedirect')->getOtherExtPort($row, $redirRow);

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
    if (defined($id)) {
        return 0;
    }
    $domModel->addDomain({
        'domain_name' => $domainName,
    });

    return $domainName;
}

##
# 20150513 Pulipuli Chen
# 在DNS中新增一個預設的Domain Name
## 
sub getDefaultDomainName
{
    return 'default-domain-name.dlll.nccu.edu.tw';
}

1;
