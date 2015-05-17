package EBox::dlllciasrouter::Model::LibraryNetwork;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

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

# ------------------------------

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

sub getExternalMask
{
    my $network = EBox::Global->modInstance('network');
    my $sourceMask = '24';
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $sourceMask = $network->ifaceNetmask($if);
            last;
        }
    }
    return $sourceMask;
}

1;
