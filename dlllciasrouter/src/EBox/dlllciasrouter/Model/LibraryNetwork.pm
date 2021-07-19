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
use EBox::NetWrappers qw(:all);

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;

##
# 讀取LibraryToolkit
# @author Pulipuli Chen
##
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
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# ------------------------------

# 20150517 Pulipuli Chen
sub getExternalIpaddr
{
    my ($self) = @_;

    my $libSettings = $self->loadLibrary('RouterSettings');
    my $ipaddr = $libSettings->value("anotherDNSIP");
    if (!defined($ipaddr)) {
        #$self->loadLibrary('LibraryToolkit')->show_exceptions(__('Another DNS IP') 
        #    . '<a href="/Network/Ifaces">'.__('Setup Network Interfaces').'</a>');
        
    }

    system("echo 'no ip addr " . $ipaddr . "'");

    my $network = EBox::Global->modInstance('network');
    my $address;
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
            last;
        }
    }
    
    if (!defined($address)) {
        $self->loadLibrary('LibraryToolkit')->show_exceptions(__('External Interface should be static.') 
            . '<a href="/Network/Ifaces">'.__('Setup Network Interfaces').'</a>');
    }

    return $address;
}

# 20150518 Pulipuli Chen
sub getInternalIface
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('network');
    my $iface;
    foreach my $if (@{$network->InternalIfaces()}) {
        if (!$network->ifaceIsExternal($if)) {
            $iface = $if;
            last;
        }
    }

    #if (!defined($iface)) {
    #    $self->loadLibrary('LibraryToolkit')->show_exceptions(__('You should set an Internal Interface.') 
    #        . '<a href="/Network/Ifaces">'.__('Setup Network Interfaces').'</a>');
    #}

    return $iface;
}

# 20150518 Pulipuli Chen
# 設定時會有問題，所以不使用
sub initInternalIface
{
    my ($self) = @_;
    return;

    my $iface;
    try {
    my $network = EBox::Global->modInstance('network');
    foreach my $if (@{$network->allIfaces()}) {
        if (!$network->ifaceIsExternal($if)) {
            #$self->loadLibrary('LibraryToolkit')->show_exceptions($if);
            if ($network->ifaceAddress($if) ne "10.0.0.253") {
                my $name = $if;
                my $address = "10.0.0.254";
                my $netmask = "255.255.0.0";
                my $ext = 0;
                my $force = 1;
                $network->setIfaceStatic($name, $address, $netmask, $ext, $force);
                $network->saveConfig();
                #$self->loadLibrary('LibraryToolkit')->show_exceptions("OK: ". $if);
            }
            #last;
            return;
        }
    }

    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryNetwork->initInternalIface() )');
    };
    #if (!defined($iface)) {
    #    $self->loadLibrary('LibraryToolkit')->show_exceptions('(LibraryNetwork->initInternalIface())))');
    #}

    return $iface;
}

# 20150517 Pulipuli Chen
sub getExternalIface
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('network');
    my $iface;
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $iface = $if;
            last;
        }
    }

    if (!defined($iface)) {
        $self->loadLibrary('LibraryToolkit')->show_exceptions(__('You should set an External Interface.') 
            . '<a href="/Network/Ifaces">'.__('Setup Network Interfaces').'</a>');
    }

    return $iface;
}

# 20150517 Pulipuli Chen
# 取得外部網路的netmask
sub getExternalMask
{
    my ($self) = @_;
    my $sourceMask = '255.255.255.0';

    my $network = EBox::Global->modInstance('network');
    
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $sourceMask = $network->ifaceNetmask($if);
            last;
        }
    }
    return $sourceMask;
}

# 20150517 Pulipuli Chen
sub getExternalMaskBit
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('network');
    my $sourceMask = $self->getExternalMask();
    return EBox::NetWrappers::bits_from_mask($sourceMask);
}

# 20150517 Pulipuli Chen
sub setVirtualInterface
{
    my ($self, $name, $ipaddr, $mask) = @_;

    my $network = EBox::Global->modInstance('network');
    $name = substr(lc($name), 0, 4);

    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            try {
                $network->setViface($if, $name, $ipaddr, $mask);
            } catch {
                $network->removeViface($if, $name, 1);
                $network->setViface($if, $name, $ipaddr, $mask);
            };
            
            last;
        }
    }
    
}

# 20150519 Pulipuli Chen
# http://www.perlmonks.org/bare/?node_id=402228
sub bitwiseShiftMask
{
    my ($self, $cidr) = @_;
    my $mask = "1" x ( 32 - $cidr ) . "0" x $cidr;
    $mask = join ".", ( unpack "C4", ( pack "B*", $mask ) );
    return $mask;
}

1;
