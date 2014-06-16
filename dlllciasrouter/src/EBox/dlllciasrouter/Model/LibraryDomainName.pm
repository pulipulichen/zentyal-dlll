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

sub addDomainName
{
    my ($self, $row) = @_;
    

    if ($row->valueByName('boundLocalDns')) {

        try {
            my $domainName = $row->valueByName('domainName');
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
            my $ipTable = $domainRow->subModel("ipAddresses");
            $ipTable->removeAll();

            # 刪掉多餘的Hostname
            my $hostnameTable = $domainRow->subModel("hostnames");
            my $zentyalHostnameID = $hostnameTable->findId("hostname"=> 'zentyal');
            my $zentyalRow = $hostnameTable->row($zentyalHostnameID);
            if (defined $zentyalRow) {
                my $zentyalIpTable = $zentyalRow->subModel("ipAddresses");
                $zentyalIpTable->removeAll();

                my $libNetwork = $self->loadLibrary('LibraryNetwork');
                my $ipaddr = $libNetwork->getExternalIpaddr();

                # 幫ipTable加上指定的IP
                $ipTable->addRow(
                    ip => , $ipaddr
                );

                # 幫zentyalIpTalbe加上指定的IP
                $zentyalIpTable->addRow(
                    ip => , $ipaddr
                );
            }

        }   # try {
        catch {
            my $lib = $self->getLibrary();
            $lib->show_exceptions($_);
        }   # catch {
    }
}

sub deleteDomainName
{
    my ($self, $row, $excludeModel) = @_;
    my $domainName = $row->valueByName('domainName');

    try {

    # 先找找看有沒有
    my $hasDomainName = 0;

    if ($hasDomainName == 0 && $excludeModel ne 'PoundServices') 
    {
        $hasDomainName = $self->modelHasDomainName('PoundServices', $domainName);
    }

    if ($hasDomainName == 0 && $excludeModel ne 'URLRedirect') 
    {
        $hasDomainName = $self->modelHasDomainName('URLRedirect', $domainName);
    }
    
    if ($hasDomainName == 0 && $excludeModel ne 'DNS') 
    {
        $hasDomainName = $self->modelHasDomainName('DNS', $domainName);
    }

    if ($hasDomainName == 0) 
    {
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        my $domModel = $dns->model('DomainTable');
        my $id = $domModel->findId(domain => $domainName);
        if (defined($id)) 
        {
            $domModel->removeRow($id);
        }
    }

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
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
    my ($self, $row) = @_;
    
    my $domainName = $row->valueByName("domainName");
    my $port = $self->parentModule()->model("Settings")->value("port");

    if ($port == 80) {
        $port = "";
    }
    else {
        $port = ":" . $port;
    }
    my $link = "http\://" . $domainName . $port . "/";

    $domainName = $self->breakUrl($domainName);

    my $enable = $self->getLibrary()->isEnable($row);
    my $textDecoration = "underline";
    if ($enable == 0) {
        $textDecoration = "line-through";
    }

    $link = '<a href="'.$link.'" ' 
        . 'target="_blank" ' 
        . 'style="background: none;text-decoration: '.$textDecoration.';color: #A3BD5B;">' 
        . $domainName 
        . '</a>';
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

1;
