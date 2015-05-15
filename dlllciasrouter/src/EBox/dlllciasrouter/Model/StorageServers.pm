package EBox::dlllciasrouter::Model::StorageServers;

use base 'EBox::dlllciasrouter::Model::PoundServices';

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

sub getPageTitle
{
    return __('Storage Servers');
}

sub getTableName
{
    return 'StorageServer';
}

sub getIPHelp
{
    return  'The 1st part should be 10, <br />'
                . 'the 2nd part should be 6, <br />'
                . 'the 3rd part should be 1, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.6.1.4';
}

sub getPoundScheme
{
    return 'https';
}

sub getInternalPortDefaultValue 
{
    return 443;
}

sub checkInternalIP
{
    my ($self, $row) = @_;

    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    my $partC = $parts[2];
    my $partD = $parts[3];

    if (!($partA == 10) 
        || !($partB == 6) 
        || !($partC == 1) 
        || !($partD > 0 && $partD < 100) ) {
        $self->getLibrary()->show_exceptions('The 1st part should be 10, <br />'
                    . 'the 2nd part should be 6, <br />'
                    . 'the 3rd part should be 1, and <br />'
                    . 'the 4th part should be between 1~99. <br />'
                    . 'Example: 10.6.1.1');
    }
}

1