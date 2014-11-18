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
    my ($self) = @_;
    my $network = EBox::Global->modInstance('network');
    my $address = "127.0.0.1";
#    foreach my $if (@{$network->ExternalIfaces()}) {
#        if ($network->ifaceIsExternal($if)) {
#            $address = $network->ifaceAddress($if);
#            last;
#        }
#    }
    my $iface = $self->getExternalIface();
    $address = $network->ifaceAddress($iface);
    return $address;
}

sub getExternalIface
{
    my $network = EBox::Global->modInstance('network');
#    my $iface = "eth9";
#    foreach my $if (@{$network->ExternalIfaces()}) {
#        if ($network->ifaceIsExternal($if)) {
#            $iface = $if;
#            last;
#        }
#    }
    my $iface = "eth0";
    for (my $i = 0; $i < 20; $i++) {
        $iface = "eth".$i;
        if ($network->ifaceExists($iface) && $network->ifaceIsExternal($iface)) {
            return $iface;
        }
    }
    
    throw EBox::Exceptions::External("No external (WAN) network interface found. <a href='/Network/Ifaces'>Please set an external (wan) network interface</a>.");
}

1;
