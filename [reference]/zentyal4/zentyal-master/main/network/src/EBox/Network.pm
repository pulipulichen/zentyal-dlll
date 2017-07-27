# Copyright (C) 2004-2007 Warp Networks S.L.
# Copyright (C) 2008-2014 Zentyal S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use warnings;

package EBox::Network;

use base qw(EBox::Module::Service);

# Group: Constants

# Interfaces list which will be ignored
use constant ALLIFACES => qw(sit tun tap lo irda eth wlan vlan);
use constant IGNOREIFACES => qw(sit tun tap lo irda virbr vboxnet vnet);
use constant IFNAMSIZ => 16; #Max length name for interfaces
use constant INTERFACES_FILE => '/etc/network/interfaces';
use constant RESOLV_FILE => '/etc/resolv.conf';
use constant DHCLIENTCONF_FILE => '/etc/dhcp/dhclient.conf';
use constant APT_PROXY_FILE => '/etc/apt/apt.conf.d/99proxy';
use constant ENV_FILE       => '/etc/environment';
use constant SYSCTL_FILE => '/etc/sysctl.conf';
use constant RESOLVCONF_INTERFACE_ORDER => '/etc/resolvconf/interface-order';
use constant RESOLVCONF_BASE => '/etc/resolvconf/resolv.conf.d/base';
use constant RESOLVCONF_HEAD => '/etc/resolvconf/resolv.conf.d/head';
use constant RESOLVCONF_TAIL => '/etc/resolvconf/resolv.conf.d/tail';

use Net::IP;
use IO::Interface::Simple;
use Perl6::Junction qw(any);
use EBox::NetWrappers qw(:all);
use EBox::Validate qw(:all);
use EBox::Config;
use EBox::Service;
use EBox::ServiceManager;
use EBox::Exceptions::InvalidData;
use EBox::Exceptions::DataExists;
use EBox::Exceptions::DataInUse;
use EBox::Exceptions::Internal;
use EBox::Exceptions::External;
use EBox::Exceptions::MissingArgument;
use EBox::Exceptions::Lock;
use EBox::Exceptions::DataNotFound;
use TryCatch::Lite;
use EBox::Dashboard::Widget;
use EBox::Dashboard::Section;
use EBox::Dashboard::CounterGraph;
use EBox::Dashboard::GraphRow;
use EBox::Dashboard::Value;
use EBox::Menu::Item;
use EBox::Menu::Folder;
use EBox::Sudo;
use EBox::Gettext;
use EBox::Common::Model::EnableForm;
use EBox::Util::Lock;
use EBox::Util::Version;
use EBox::DBEngineFactory;
use File::Basename;
use File::Slurp;

use constant CHECKIP_CHAIN => 'CHECKIP-TEST';

# Group: Public methods

# Method: localGatewayIP
#
#       Return the local IP address that may be used as the gateway for the given IP or undef if Zentyal is not
#       directly connected with the given IP.
#
# Parameters:
#
#       ip - String the IP address for the client that will use the returning IP address as gateway.
#
# Returns:
#
#       String - Zentyal's IP address that would act as the gateway. undef if not reachable.
#
# Exceptions:
#
#       <EBox::Exceptions::MissingArgument> - thrown if any compulsory argument is missing
#
sub localGatewayIP
{
    my ($self, $ip) = @_;

    $ip or throw EBox::Exceptions::MissingArgument('ip');

    my $iface = $self->gatewayReachable($ip);
    return undef unless ($iface);
    return $self->ifaceAddress($iface);
}

sub _create
{
    my $class = shift;
    my $self = $class->SUPER::_create(name => 'network',
                    printableName => __('Network'),
                    @_);
    $self->{'actions'} = {};

    bless($self, $class);

    return $self;
}

# Method: actions
#
#   Override EBox::Module::Service::actions
#
sub actions
{
    return [
    {
        'action' => __('Add default routers to the default table'),
        'reason' => __('This is needed to work with a multigateway ' .
                    'configuration. Note that to list the default routes you ' .
                    'must execute: ') . ' ip route ls table default ',
        'module' => 'network'
    },
    {
        'action' => __('Enable Zentyal DHCP hook'),
        'reason' => __('It will take care of adding the default route' .
                ' given by a DHCP server to the default route table. '),
        'module' => 'network'
    },
    {
        'action' => __('Disable IPv6'),
        'reason' => __('Zentyal does not support yet IPv6, having v6 ' .
                       'addresses asigned to interfaces can cause problems ' .
                       'on some services'),
        'module' => 'network'
    },
    ];
}

# Method: usedFiles
#
#   Override EBox::Module::Service::usedFiles
#
sub usedFiles
{
    my ($self) = @_;

    my @files = (
    {
        'file' => INTERFACES_FILE,
        'reason' => __('Zentyal will set your network configuration'),
        'module' => 'network'
    },
    {
        'file' => RESOLVCONF_INTERFACE_ORDER,
        'reason' => __('Zentyal will set the order of systems resolvers'),
        'module' => 'network'
    },
    {
        'file' => RESOLVCONF_BASE,
        'reason' => __('Zentyal will set the resolvconf configuration'),
        'module' => 'network'
    },
    {
        'file' => RESOLVCONF_HEAD,
        'reason' => __('Zentyal will set the resolvconf configuration'),
        'module' => 'network'
    },
    {
        'file' => RESOLVCONF_TAIL,
        'reason' => __('Zentyal will set the resolvconf configuration'),
        'module' => 'network'
    },
    {
        'file' => DHCLIENTCONF_FILE,
        'reason' => __('Zentyal will set your DHCP client configuration'),
        'module' => 'network'
    },
    {
        'file' => SYSCTL_FILE,
        'reason' => __('Zentyal will disable IPV6 on this system'),
        'module' => 'network'
    },
    );

    my $proxy = $self->model('Proxy');
    if ($proxy->serverValue() and $proxy->portValue()) {
        push (@files, { 'file' => ENV_FILE,
                        'reason' => __('Zentyal will set HTTP proxy for all users'),
                        'module' => 'network' });
        push (@files, { 'file' => APT_PROXY_FILE,
                        'reason' => __('Zentyal will set HTTP proxy for APT'),
                        'module' => 'network' });
    }

    return \@files;
}

# Method: initialSetup
#
# Overrides:
#   EBox::Module::Base::initialSetup
#
sub initialSetup
{
    my ($self, $version) = @_;

    # Import network configuration from system
    # only if installing the first time
    unless ($version) {
        try {
            $self->importInterfacesFile();
            $self->_importDHCPAddresses();
            if ($self->changed()) {
                $self->saveConfigRecursive();
            }
        } catch {
            EBox::warn('Network configuration import failed');
        }
    }
}

# Method: enableActions
#
#   Override EBox::Module::Service::enableActions
#
sub enableActions
{
    my ($self) = @_;

    # Disable IPv6 if it is enabled
    if (-d  '/proc/sys/net/ipv6') {
        my @cmds;
        push (@cmds, 'sed -ri "/net\.ipv6\.conf\.all\.disable_ipv6/d" ' . SYSCTL_FILE);
        push (@cmds, 'sed -ri "/net\.ipv6\.conf\.default\.disable_ipv6/d" ' . SYSCTL_FILE);
        push (@cmds, 'sed -ri "/net\.ipv6\.conf\.lo\.disable_ipv6/d" ' . SYSCTL_FILE);

        push (@cmds, 'echo "net.ipv6.conf.all.disable_ipv6 = 1" >> ' . SYSCTL_FILE);
        push (@cmds, 'echo "net.ipv6.conf.default.disable_ipv6 = 1" >> ' . SYSCTL_FILE);
        push (@cmds, 'echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> ' . SYSCTL_FILE);

        push (@cmds, 'sysctl -p');

        EBox::Sudo::root(@cmds);
    }
    $self->_importDHCPAddresses();
}

# Method: wizardPages
#
#   Override EBox::Module::Base::wizardPages
#
sub wizardPages
{
    my ($self) = @_;

    return [
        { page => '/Network/Wizard/Ifaces', order => 100 },
        { page => '/Network/Wizard/Network', order => 101 },
    ];
}

# Method: ExternalIfaces
#
#   Returns  a list of all external interfaces
#
# Returns:
#
#      array ref - holding the external interfaces
#
sub ExternalIfaces
{
    my $self = shift;
    my @ifaces = @{$self->ifaces};
    my @array = ();
    foreach (@ifaces) {
        ($self->ifaceMethod($_) eq 'notset') and next;
        ($self->ifaceMethod($_) eq 'trunk') and next;
        if ($self->ifaceIsExternal($_)) {
            push(@array, $_);
        }
    }
    return \@array;
}

# Method: externalIpAddresses
#
#   Returs a list of external IP addresses
#
# Returns:
#
#   array ref - Holding the external IP's
#
sub externalIpAddresses
{
    my ($self) = @_;

    my $ips = [];

    my $externalInterfaces = $self->ExternalIfaces();
    foreach my $interface (@{$externalInterfaces}) {
        foreach my $interfaceInfo (@{$self->ifaceAddresses($interface)}) {
            next unless (defined $interfaceInfo);
            push @{$ips}, $interfaceInfo->{address};
        }
    }

    return $ips;
}

# Method: InternalIfaces
#
#   Returns  a list of all internal interfaces
#
# Returns:
#
#      array ref - holding the internal interfaces
#
sub InternalIfaces
{
    my $self = shift;
    my @ifaces = @{$self->ifaces};
    my @array = ();
    foreach (@ifaces) {
        ($self->ifaceMethod($_) eq 'notset') and next;
        ($self->ifaceMethod($_) eq 'trunk') and next;
        unless ($self->ifaceIsExternal($_)) {
            push(@array, $_);
        }
    }
    return \@array;
}

# Method: internalIpAddresses
#
#   Returs a list of internal IP addresses
#
# Returns:
#
#   array ref - Holding the internal IP's
#
sub internalIpAddresses
{
    my ($self) = @_;

    my $ips = [];

    my $internalInterfaces = $self->InternalIfaces();
    foreach my $interface (@{$internalInterfaces}) {
        foreach my $interfaceInfo (@{$self->ifaceAddresses($interface)}) {
            next unless (defined $interfaceInfo);
            push @{$ips}, $interfaceInfo->{address};
        }
    }

    return $ips;
}

# Method: internalNetworks
#
#   Returs a list of internal networks
#
# Returns:
#
#   array ref - Holding the internal network IP addresses using CIDR
#
sub internalNetworks
{
    my ($self) = @_;

    my @intNets;

    foreach my $iface (@{$self->InternalIfaces()}) {
        my $net = $self->ifaceNetwork($iface);
        if ($net) {
            my $fullmask = $self->ifaceNetmask($iface);
            my $mask = EBox::NetWrappers::bits_from_mask($fullmask);
            push(@intNets, "$net/$mask");
        }
    }
    return \@intNets;
}

# Method: ifaceExists
#
#   Checks if a given interface exists
#
# Parameters:
#
#   interface - the name of a network interface
#
# Returns:
#
#   boolean - true, if the interface exists, otherwise false
sub ifaceExists # (interface)
{
    my ($self, $name) = @_;
    defined($name) or return undef;
    if ($self->vifaceExists($name)) {
        return 1;
    }
    if (iface_exists($name)) {
        return 1;
    }
    my $ifaces = $self->ifaces;
    if (grep(/^$name$/, @{$ifaces})) {
        return 1;
    }
    return undef;
}

# Method: ifaceIsExternal
#
#   Checks if a given iface exists and is external
#
# Parameters:
#
#   interface - the name of a network interface
#
# Returns:
#
#   boolean - true, if the interface is external, otherwise false
sub ifaceIsExternal # (interface)
{
    my ($self, $iface) = @_;
    defined($iface) or return undef;

    if ($self->vifaceExists($iface)) {
        my @aux = $self->_viface2array($iface);
        $iface = $aux[0];
    }
    return $self->get_hash('interfaces')->{$iface}->{external} ? 1 : 0;
}

# Method: ifaceOnConfig
#
#   Checks if a given iface is configured
#
# Parameters:
#
#   interface - the name of a network interface
#
# Returns:
#
#   boolean - true, if the interface is configured, otherwise false
#
sub ifaceOnConfig
{
    my ($self, $name) = @_;

    defined($name) or return undef;
    if ($self->vifaceExists($name)) {
        return 1;
    }

    return defined($self->get_hash('interfaces')->{$name}->{method});
}

# Method: netInitRange
#
#   Return the initial host address range for a given interface
#
# Parameters:
#
#   iface - String interface name
#
# Returns:
#
#   String - containing the initial range
#
sub netInitRange # (interface)
{
    my ($self, $iface) = @_;

    my $address = $self->ifaceAddress($iface);
    my $netmask = $self->ifaceNetmask($iface);

    my $network = ip_network($address, $netmask);
    my ($first, $last) = $network =~ /(.*)\.(\d+)$/;
    my $init_range = $first . "." . ($last + 1);

    return $init_range;
}

# Method: netEndRange
#
#   Return the final host address range for a given interface
#
# Parameters:
#
#   iface - String interface name
#
# Returns:
#
#   string - containing the final range
#
sub netEndRange # (interface)
{
    my ($self, $iface) = @_;

    my $address = $self->ifaceAddress($iface);
    my $netmask = $self->ifaceNetmask($iface);

    my $broadcast = ip_broadcast($address, $netmask);
    my ($first, $last) = $broadcast =~ /(.*)\.(\d+)$/;
    my $end_range = $first . "." . ($last - 1);

    return $end_range;
}

sub _ignoreIface
{
    my ($self, $name) = @_;

    my $ignore_ifaces = EBox::Config::configkey('ifaces_to_ignore');
    my @ifaces_to_ignore;
    if (defined($ignore_ifaces)) {
        @ifaces_to_ignore = split(',', $ignore_ifaces);
    } else {
        @ifaces_to_ignore = IGNOREIFACES;
    }
    foreach my $ignore (@ifaces_to_ignore) {
        return 1 if  ($name =~ /$ignore.?/);
    }

    return undef;
}

# given a list of network interfaces appends to it any existing vlan interface
# not already in the list and removes from it any vlan interface which has been
# deleted from the configuration.
sub _vlanIfaceFilter # (\array)
{
    my ($self, $ifaces) = @_;
    my @array = ();

    foreach my $if (@{$ifaces}) {
        unless ($if =~ /^vlan/) {
            push(@array, $if);
        }
    }

    my $vlans = $self->vlans();
    foreach my $id (@{$vlans}) {
        push(@array, "vlan$id");
    }
    return \@array;
}

# given a list of network interfaces appends to it any existing vlan interface
# not already in the list
sub _vlanIfaceFilterWithRemoved # (\array)
{
    my ($self, $ifaces) = @_;
    my $vlans = $self->vlans();
    foreach my $id (@{$vlans}) {
        unless (grep(/^vlan$id$/, @{$ifaces})) {
            push(@{$ifaces}, "vlan$id");
        }
    }
    return $ifaces;
}

sub _cleanupVlanIfaces
{
    my $self = shift;
    my @iflist = list_ifaces();
    my @cmds;
    foreach my $iface (@iflist) {
        if ($iface =~ /^vlan/) {
            $iface =~ s/^vlan//;
            my $vlans = $self->get_hash('vlans');
            unless (exists $vlans->{$iface}) {
                push (@cmds, "/sbin/vconfig rem vlan$iface");
            }
        }
    }
    EBox::Sudo::root(@cmds);
}

sub _ifaces
{
    my $self = shift;
    my @iflist = list_ifaces();
    my @array = ();
    foreach my $iface (@iflist) {
        next if $self->_ignoreIface($iface);
        push(@array, $iface);
    }
    return \@array;
}

# Method: ifaces
#
#   Returns the name of all real interfaces, including vlan interfaces
#
# Returns:
#
#   array ref - holding the names
sub ifaces
{
    my $self = shift;
    my $ifaces = $self->_ifaces();
    $ifaces = $self->_vlanIfaceFilter($ifaces);
    return $ifaces;
}

# Method: ifacesWithRemoved
#
#   Returns the name of all real interfaces, including
#   vlan interfaces (both existing ones and those that are going to be
#   removed when the configuration is saved)
# Returns:
#
#   array ref - holding the names
sub ifacesWithRemoved
{
    my $self = shift;
    my $ifaces = $self->_ifaces();
    $ifaces = $self->_vlanIfaceFilterWithRemoved($ifaces);
    return $ifaces;
}

# Method: ifaceAddresses
#
#   Returns an array of hashes with "address" and "netmask" fields, the
#   array may be empty (i.e. for a dhcp interface that did not get an
#   address)
#
# Parameters:
#
#   iface - the name of a interface
#
# Returns:
#
#   an array ref - holding hashes with keys 'address' and 'netmask'
#
sub ifaceAddresses
{
    my ($self, $iface) = @_;
    my @array = ();

    if ($self->vifaceExists($iface)) {
        return \@array;
    }

    if ($self->ifaceMethod($iface) eq 'static') {
        my $addr = $self->get_hash('interfaces')->{$iface}->{address};
        my $mask = $self->get_hash('interfaces')->{$iface}->{netmask};
        push(@array, {address => $addr, netmask => $mask});
        my $virtual = $self->get_hash('interfaces')->{$iface}->{virtual};
        foreach my $name (keys %{$virtual}) {
            my $viface = $virtual->{$name};
            push(@array, { address => $viface->{address},
                           netmask => $viface->{netmask},
                           name => $name });
        }
    } elsif ($self->ifaceMethod($iface) eq 'dhcp') {
        my $addr = $self->DHCPAddress($iface);
        my $mask = $self->DHCPNetmask($iface);
        if ($addr) {
            push(@array, {address => $addr, netmask => $mask});
        }
    }
    return \@array;
}

# Method: ifaceByAddress
#
# given a IP address it returns the interface which has it local address
# or undef if it is nothing. Loopback interface is also acknowledged
#
#  Parameters:
#    address - IP address
#
#  Limitations:
#    only checks interfaces managed by the network module, with the exception
#    of loopback
sub ifaceByAddress
{
    my ($self, $address) = @_;
    EBox::Validate::checkIP($address) or
          throw EBox::Exceptions::External(__('Argument must be a IP address'));

    foreach my $iface (@{ $self->allIfaces() }) {
        my @addrs = @{ $self->ifaceAddresses($iface) };
        foreach my $addr_r (@addrs) {
            if ($addr_r->{address}  eq $address) {
                return $iface;
            }
        }
    }

    if ($address =~ m/^127\.*/) {
        return 'lo';
    }

    return undef;
}

# Method: vifacesConf
#
#   Gathers virtual interfaces from a real interface with their conf
#   arguments
#
# Parameters:
#
#   iface - the name of a interface
#
# Returns:
#
#   an array ref - holding hashes with keys 'address' and 'netmask'
#                  'name'
#
sub vifacesConf
{
    my ($self, $iface) = @_;
    defined($iface) or return;

    my $vifaces = $self->get_hash('interfaces')->{$iface}->{virtual};
    my @array = ();
    foreach my $name (keys %{$vifaces}) {
        my $viface = $vifaces->{$name};
        if (defined $viface->{'address'}) {
            $viface->{name} = $name;
            push (@array, $viface);
        }
    }
    return \@array;
}

# Method: vifaceNames
#
#       Gathers all the  virtual interface names  from a real interface
#
# Parameters:
#
#       iface - the name of a interface
#
# Returns:
#
#       an array ref - holding the name of the virtual interfaces. Each name
#       is a composed name like this: realinterface:virtualinterface
#       (i.e: eth0:foo)
#
sub vifaceNames
{
    my ($self, $iface) = @_;
    my @array;

    foreach (@{$self->vifacesConf($iface)}) {
        push @array, "$iface:" . $_->{'name'};
    }
    return \@array;
}

sub _allIfaces
{
    my ($self, $ifaces) = @_;
    my @array;
    my @vifaces;

    @array = @{$ifaces};
    foreach (@array) {
        if ($self->ifaceMethod($_) eq 'static') {
            push @vifaces, @{$self->vifaceNames($_)};
        }
    }
    push @array, @vifaces;
    @array = sort @array;
    return \@array;
}

# Method: allIfaces
#
#       Returns all the names for all the interfaces, both real and virtual.
#
# Returns:
#
#       an array ref - holding the name of the interfaces.
#
sub allIfaces
{
    my $self = shift;
    return $self->_allIfaces($self->ifaces());
}

# Method: dhcpIfaces
#
#       Returns the names for all the DHCP interfaces.
#
# Returns:
#
#       an array ref - holding the name of the interfaces.
#
sub dhcpIfaces
{
    my ($self) = @_;
    my @dhcpifaces;

    foreach my $iface (@{$self->ifaces()}) {
        if ($self->ifaceMethod($iface) eq 'dhcp') {
            push (@dhcpifaces, $iface);
        }
    }
    return \@dhcpifaces;
}

# Method: allIfacesWithRemoved
#
#   Return  the names of all (real and virtual) interfaces. This
#   method is similar to the ifacesWithRemoved method, it includes in the
#   results vlan interfaces which are going to be removed when the
#   configuration is saved.
#
# Returns:
#
#       an array ref - holding the name of the interfaces.
sub allIfacesWithRemoved
{
    my $self = shift;
    return $self->_allIfaces($self->ifacesWithRemoved());
}

# arguments
#   - the name of the real network interface
#   - the name of the virtual interface
# returns
#   - true if exists
#   - false if not
# throws
#   - Internal
#       - If real interface is not configured as static
#
sub _vifaceExists
{
    my ($self, $iface, $viface) = @_;

    unless ($self->ifaceMethod($iface) eq 'static') {
        throw EBox::Exceptions::Internal("Could not exist a virtual " .
                                         "interface in non-static interface");
    }

    return exists $self->get_hash('interfaces')->{$iface}->{virtual}->{$viface};
}

# split a virtual iface name in real interface and virtual interface
# arguments
#   - the composed virtual iface name
# returns
#   - an array with the split name
sub _viface2array # (interface)
{
    my ($self, $name) = @_;
    my @array = $name =~ /(.*):(.*)/;
    return @array;
}

# Method: vifaceExists
#
#   Checks if a given virtual interface exists
#
# Parameters:
#
#   interface - the name of  virtual interface composed by
#   realinterface:virtualinterface
#
# Returns:
#
#   boolean - true, if the interface is virtual and exists, otherwise false
#
sub vifaceExists # (interface)
{
    my ($self, $name) = @_;

    my ($iface, $viface) = $self->_viface2array($name);
    if (not $iface) {
        return undef;
    }
    if (not $viface and ($viface ne '0')) {
        return undef;
    }

    return $self->_vifaceExists($iface, $viface);
}

# Method: setViface
#
#   Configure a virtual  interface with ip and netmask
#   arguments
#
# Parameters:
#
#   iface - the name of a real network interface
#   viface - the name of the virtual interface
#   address - the IP address for the virtual interface
#   netmask - the netmask
#
# Exceptions:
#
#   DataExists - If interface already exists
#   Internal - If the real interface is not configured as static
#
sub setViface
{
    my ($self, $iface, $viface, $address, $netmask) = @_;

    unless ($self->ifaceMethod($iface) eq 'static') {
        throw EBox::Exceptions::Internal("Could not add virtual " .
                       "interface in non-static interface");
    }
    if ($self->_vifaceExists($iface, $viface)) {
        throw EBox::Exceptions::DataExists(
                    'data' => __('Virtual interface name'),
                    'value' => "$viface");
    }
    checkIPNetmask($address, $netmask, __('IP address'), __('Netmask'));
    checkVifaceName($iface, $viface, __('Virtual interface name'));

    my $ifaceSameAddress = $self->ifaceByAddress($address);
    if ($ifaceSameAddress) {
        throw EBox::Exceptions::DataExists(
            text => __x("Address {ip} is already in use by interface {iface}",
                ip => $address,
                iface => $ifaceSameAddress
               )
           );
    }

    # Check the virtual interface IP  address is not a HA floating IP
    $self->_checkHAFloatingIPCollision($iface, $address);

    my $global = EBox::Global->getInstance();
    my @mods = @{$global->modInstancesOfType('EBox::NetworkObserver')};
    foreach my $mod (@mods) {
        $mod->vifaceAdded($iface, $viface, $address, $netmask);
    }

    my $ifaces = $self->get_hash('interfaces');
    $ifaces->{$iface}->{virtual}->{$viface}->{address} = $address;
    $ifaces->{$iface}->{virtual}->{$viface}->{netmask} = $netmask;
    $ifaces->{$iface}->{changed} = 1;
    $self->set('interfaces', $ifaces);
}

# Method: removeViface
#
#   Removes a virtual interface
#
# Parameters:
#
#   iface - the name of a real network interface
#   viface - the name of the virtual interface
#   force - force deletion if in use
#
# Returns:
#
#   boolean - true if exists, otherwise false
#
# Exceptions:
#
#   Internal - If the real interface is not configured as static
#
sub removeViface
{
    my ($self, $iface, $viface, $force) = @_;

    unless ($self->ifaceMethod($iface) eq 'static') {
        throw EBox::Exceptions::Internal("Could not remove virtual " .
                              "interface from a non-static interface");
    }
    unless ($self->_vifaceExists($iface, $viface)) {
        return undef;
    }

    $self->_routersReachableIfChange("$iface:$viface");

    my $global = EBox::Global->getInstance();
    my @mods = @{$global->modInstancesOfType('EBox::NetworkObserver')};
    foreach my $mod (@mods) {
        if ($mod->vifaceDelete($iface, $viface)) {
            if ($force) {
                $mod->freeViface($iface, $viface);
            } else {
                throw EBox::Exceptions::DataInUse();
            }
        }
    }

    my $ifaces = $self->get_hash('interfaces');
    delete $ifaces->{$iface}->{virtual}->{$viface};
    $ifaces->{$iface}->{changed} = 1;
    $self->set('interfaces', $ifaces);

    return 1;
}

# Method: vifaceAddress
#
#   Returns the configured address for a virutal interface
#
# Parameters:
#
#   interface - the composed name of a virtual interface
#
#  Returns:
#
#   If interface exists it returns its IP, otherwise it returns undef
#
#   string - IP if it exists
sub vifaceAddress # (interface)
{
    my ($self, $name) = @_;
    my $address;

    unless ($self->vifaceExists($name)) {
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    }

    my ($iface, $viface) = $self->_viface2array($name);
    foreach (@{$self->vifacesConf($iface)}) {
        if ($_->{'name'} eq $viface) {
            return $_->{'address'};
        }
    }
    return undef;
}

# Method: vifaceNetmask
#
#   Returns the configured netmask for a virutal interface
#
# Parameters:
#
#   interface - the composed name of a virtual interface
#
#  Returns:
#
#   If interface exists it returns its netmask, otherwise it returns undef
#
#   string - IP if it exists
sub vifaceNetmask # (interface)
{
    my ($self, $name) = @_;
    my $address;

    unless ($self->vifaceExists($name)) {
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    }

    my ($iface, $viface) = $self->_viface2array($name);
    foreach (@{$self->vifacesConf($iface)}) {
        if ($_->{'name'} eq $viface) {
            return $_->{'netmask'};
        }
    }
    return undef;
}

# Method: setIfaceAlias
#
#   Sets the alias for a given interface
#
# Parameters:
#
#   iface - the name of a network interface
#   alias - the alias for the interface
#
sub setIfaceAlias
{
    my ($self, $iface, $alias) = @_;

    my $ifaces = $self->get_hash('interfaces');

    if ($iface eq $alias) {
        # alias == iface name, no problems
        $ifaces->{$iface}->{alias} = $alias;
        $self->set('interfaces', $ifaces);
        return;
    }

    # check that the alias is not repeated or is the same that any interface
    # name
    foreach my $if (@{ $self->allIfaces() }) {
        if ($alias eq $if) {
            throw EBox::Exceptions::External(
                __x('There is already an interface called {al}',
                    al => $alias)
            );
        }

        if ($iface eq $if) {
            next;
        }

        my $ifAlias = $self->ifaceAlias($if);
        if ($ifAlias and ($ifAlias eq $alias)) {
            throw EBox::Exceptions::External(
                __x('There is already a interface with the alias {al}',
                    al => $alias)
            );
        }
    }

    if ($alias =~ m/:/) {
        throw EBox::Exceptions::External(
            __(q{Cannot set an alias with the character ":". This character is reserved for virtual interfaces})
                                        );
    }

    $ifaces->{$iface}->{alias} = $alias;
    $self->set('interfaces', $ifaces);
}

# Method: ifaceAlias
#
#   Returns the alias for a given interface
#
# Parameters:
#
#   iface - the name of a network interface
#
# Returns:
#
#   string - alias for the interface
#
sub ifaceAlias # (iface)
{
    my ($self, $iface) = @_;
    my $viface = undef;
    unless ($self->ifaceExists($iface)) {
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $iface);
    }
    if($self->vifaceExists($iface)) {
        my @aux = $self->_viface2array($iface);
        $iface = $aux[0];
        $viface = $aux[1];
    }
    my $alias = $self->get_hash('interfaces')->{$iface}->{alias};
    defined($alias) or $alias = $iface;
    defined($viface) and $alias = $alias . ":" . $viface;
    return $alias;
}

# Method: ifaceMethod
#
#   Returns the configured method for a given interface
#
# Parameters:
#
#   interface - the name of a network interface
#
# Returns:
#
#   string - dhcp|static|notset|trunk
#           dhcp -> the interface is configured via dhcp
#           static -> the interface is configured with a static ip
#           notset -> the interface exists but has not been
#                 configured yet
#           trunk -> vlan aware interface
#
sub ifaceMethod
{
    my ($self, $name) = @_;

    unless ($self->ifaceExists($name)) {
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                                             value => $name);
    }
    if ($self->vifaceExists($name)) {
        return 'static';
    }
    $self->ifaceOnConfig($name) or return 'notset';

    return $self->get_hash('interfaces')->{$name}->{method};
}

# Method: setIfaceDHCP
#
#   Configure an interface via DHCP
#
# Parameters:
#
#   interface - the name of a network interface
#   external - boolean to indicate if it's  a external interface
#   force - boolean to indicate if an exception should be raised when
#   method is changed or it should be forced
#
sub setIfaceDHCP
{
    my ($self, $name, $ext, $force) = @_;
    defined $ext or $ext = 0;

    $self->ifaceExists($name) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);

    my $oldm = $self->ifaceMethod($name);
    if ($oldm eq 'dhcp') {
        $self->DHCPCleanUp($name);
    } elsif ($oldm eq 'trunk') {
        $self->_trunkIfaceIsUsed($name);
    } elsif ($oldm eq 'static') {
        $self->_routersReachableIfChange($name);
        $self->_checkStatic($name, $force);
    }

    my $global = EBox::Global->getInstance();
    my @observers = @{$global->modInstancesOfType('EBox::NetworkObserver')};

    if ($ext != $self->ifaceIsExternal($name) ) {
      # Tell observers the interface way has changed
      foreach my $obs (@observers) {
        if ($obs->ifaceExternalChanged($name, $ext)) {
          if ($force) {
        $obs->changeIfaceExternalProperty($name, $ext);
          }
          else {
        throw EBox::Exceptions::DataInUse();
          }
        }
      }
    }
    if ($oldm ne 'dhcp') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'dhcp',
            action => 'prechange',
            force  => $force,
        );
    } else {
        my $oldm = $self->ifaceIsExternal($name);

        if ((defined($oldm) and defined($ext)) and ($oldm == $ext)) {
            return;
        }
    }

    if ($oldm eq 'trunk') {
        $self->_removeTrunkIfaceVlanes($name);
    }

    my $ifaces = $self->get_hash('interfaces');
    $ifaces->{$name}->{external} = $ext;
    delete $ifaces->{$name}->{address};
    delete $ifaces->{$name}->{netmask};
    $ifaces->{$name}->{method} = 'dhcp';
    $ifaces->{$name}->{name} = $name;
    $ifaces->{$name}->{changed} = 1;
    $self->set('interfaces', $ifaces);

    if ($oldm ne 'dhcp') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'dhcp',
            action => 'postchange'
        );
    }
}

# Method: setIfaceStatic
#
#   Configure with a static ip address
#
# Parameters:
#
#   interface - the name of a network interface
#   address - IPv4 address
#   netmask - network mask
#   external - boolean to indicate if it's an external interface
#   force - boolean to indicate if an exception should be raised when
#   method is changed or it should be forced
#
sub setIfaceStatic
{
    my ($self, $name, $address, $netmask, $ext, $force) = @_;
    defined $ext or $ext = 0;

    $self->ifaceExists($name) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);

    checkIPNetmask($address, $netmask, __('IP address'), __('Netmask'));

    $self->_checkStaticIP($name, $address, $netmask);

    my $oldm = $self->ifaceMethod($name);
    my $oldaddr = $self->ifaceAddress($name);
    my $oldmask = $self->ifaceNetmask($name);
    my $oldext = $self->ifaceIsExternal($name);

    if (($oldm eq 'static') and
        ($oldaddr eq $address) and
        ($oldmask eq $netmask) and
        (! ($oldext xor $ext))) {
        return;
    }

    if ($oldm eq 'trunk') {
        $self->_trunkIfaceIsUsed($name);
    }

    if ((!defined($oldaddr) or ($oldaddr ne $address))) {
        my $ifaceSameAddress = $self->ifaceByAddress($address);
        if ($ifaceSameAddress) {
            throw EBox::Exceptions::DataExists(
                text => __x(
                    'The IP {ip} is already assigned to interface {iface}',
                    ip => $address,
                    iface => $ifaceSameAddress,
                   ));
        }
    }

    # Check the interface IP  address is not a HA floating IP
    $self->_checkHAFloatingIPCollision($name, $address);

    if ($oldm eq 'dhcp') {
        $self->DHCPCleanUp($name);
    } elsif ($oldm eq 'static') {
        $self->_routersReachableIfChange($name, $address, $netmask);
    }

    # Calling observers
    my $global = EBox::Global->getInstance();
    my @observers = @{$global->modInstancesOfType('EBox::NetworkObserver')};

    if (defined $ext and $ext != $self->ifaceIsExternal($name) ) {
        # Tell observers the interface way has changed
        foreach my $obs (@observers) {
            if ($obs->ifaceExternalChanged($name, $ext)) {
                if ($force) {
                    $obs->changeIfaceExternalProperty($name, $ext);
                } else {
                    throw EBox::Exceptions::DataInUse();
                }
            }
        }
    }

    if ($oldm ne 'static') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'static',
            action => 'prechange',
            force => $force
        );
    } else {
        foreach my $obs (@observers) {
            if ($obs->staticIfaceAddressChanged($name,
                            $oldaddr,
                            $oldmask,
                            $address,
                            $netmask)) {
                if ($force) {
                    $obs->freeIface($name);
                } else {
                    throw EBox::Exceptions::DataInUse();
                }
            }
        }
    }

    if ($oldm eq 'trunk') {
        $self->_removeTrunkIfaceVlanes($name);
    }

    my $ifaces = $self->get_hash('interfaces');
    $ifaces->{$name}->{external} = $ext;
    $ifaces->{$name}->{method} = 'static';
    $ifaces->{$name}->{address} = $address;
    $ifaces->{$name}->{netmask} = $netmask;
    $ifaces->{$name}->{name}    = $name;
    $ifaces->{$name}->{changed} = 1;
    $self->set('interfaces', $ifaces);

    if ($oldm ne 'static') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'static',
            action => 'postchange'
        );
    } else {
        foreach my $obs (@observers) {
            $obs->staticIfaceAddressChangedDone($name,
                                                $oldaddr,
                                                $oldmask,
                                                $address,
                                                $netmask);
        }
    }
}

sub _checkStatic # (iface, force)
{
    my ($self, $iface, $force) = @_;

    my $global = EBox::Global->getInstance();
    my @mods = @{$global->modInstancesOfType('EBox::NetworkObserver')};

    foreach my $vif (@{$self->vifaceNames($iface)}) {
        foreach my $mod (@mods) {
            my ($tmp, $viface) = $self->_viface2array($vif);
            if ($mod->vifaceDelete($iface, $viface)) {
                if ($force) {
                    $mod->freeViface($iface, $viface);
                } else {
                    throw EBox::Exceptions::DataInUse();
                }
            }
        }
    }
}

# check that no IP are in the same network
# limitation: we could only check against the current
# value of dynamic addresses
sub _checkStaticIP
{
    my ($self, $iface, $address, $netmask) = @_;
    my $network = EBox::NetWrappers::ip_network($address, $netmask);
    foreach my $if (@{$self->allIfaces()} ) {
        if ($if eq $iface) {
            next;
        }

        foreach my $addr_r (@{ $self->ifaceAddresses($if)} ) {
            my $ifNetwork =  EBox::NetWrappers::ip_network($addr_r->{address},
                                                            $addr_r->{netmask});
            if ($ifNetwork eq $network) {
                throw EBox::Exceptions::External(
                 __x('Cannot use the address {addr} because interface {if} has already an address in the same network',
                     addr => $address,
                     if => $if
                    )
                );
            }
        }
    }
}

# Method: setIfaceTrunk
#
#   configures an interface in trunk mode, making it possible to create vlan
#   interfaces on it.
#
# Parameters:
#
#   interface - the name of a network interface
#   force - boolean to indicate if an exception should be raised when
#   method is changed or it should be forced
#
sub setIfaceTrunk # (iface, force)
{
    my ($self, $name, $force) = @_;

    unless ($self->ifaceExists($name)) {
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    }

    if ($name =~ /^vlan/) {
        throw EBox::Exceptions::External(__('This interface cannot '.
            'be put in trunk mode, it is an vlan interface.'));
    }

    my $oldm = $self->ifaceMethod($name);

    ($oldm eq 'trunk') and return;

    if ($oldm eq 'dhcp') {
        $self->DHCPCleanUp($name);
    } elsif ($oldm eq 'static') {
        $self->_routersReachableIfChange($name);
        $self->_checkStatic($name, $force);
    }

    if ($oldm ne 'notset') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'notset',
            action => 'prechange',
            force => $force,
        );
    }

    my $ifaces = $self->get_hash('interfaces');
    delete $ifaces->{$name}->{address};
    delete $ifaces->{$name}->{netmask};
    $ifaces->{$name}->{method}  = 'trunk';
    $ifaces->{$name}->{changed} = 1;
    $ifaces->{$name}->{name}    = $name;
    $self->set('interfaces', $ifaces);

    if ($oldm ne 'notset') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'notset',
            action => 'postchange'
        );
    }
}

# returns true if the given interface is in trunk mode an has at least one vlan
# interface added to it which is configured as dhcp or static.
sub _trunkIfaceIsUsed # (iface)
{
    my ($self, $iface) = @_;
    my $vlans = $self->ifaceVlans($iface);
    foreach my $vlan (@{$vlans}) {
        defined($vlan) or next;
        ($iface eq $vlan->{interface}) or next;
        my $meth = $self->ifaceMethod("vlan$vlan->{id}");
        if ($meth ne 'notset') {
            throw EBox::Exceptions::External(
                __('This interface is in trunk mode, you '.
                   'should unconfigure all the vlan '.
                   'interfaces in this trunk before changing '.
                   'its configuration mode.'));
        }
    }
    return undef;
}

# remove all vlanes from a trunk interface
sub _removeTrunkIfaceVlanes
{
    my ($self, $iface) = @_;
    my $vlans = $self->ifaceVlans($iface);
    foreach my $vlan (@{$vlans}) {
        defined($vlan) or next;
        $self->removeVlan($vlan->{id});
    }
}

# Method: createVlan
#
#   creates an vlan on a trunk interface.
#
# Parameters:
#
#   id - vlan identifier
#   name - name
#   interface - the name of a network interface
#
sub createVlan # (id, name, iface)
{
    my ($self, $id, $name, $iface) = @_;

    checkVlanID($id, __('VLAN Id'));
    defined($name) or $name = '';

    my $vlans = $self->get_hash('vlans');
    if (exists $vlans->{$id}) {
        throw EBox::Exceptions::DataExists('data' => 'vlan',
                          'value' => "$id");
    }

    if ($self->ifaceMethod($iface) ne 'trunk') {
        throw EBox::Exceptions::External(__('Network interfaces need '.
            'to be in trunk mode before adding vlans to them.'));
    }

    $vlans->{$id}->{id} = $id;
    $vlans->{$id}->{name} = $name;
    $vlans->{$id}->{interface} = $iface;
    $self->set('vlans', $vlans);
}

# Method: removeVlan
#
#   Removes a vlan
#
# Parameters:
#
#   id - vlan identifier
#
sub removeVlan # (id)
{
    my ($self, $id, $force) = @_;
    checkVlanID($id, __('VLAN Id'));

    my $vlans = $self->get_hash('vlans');
    delete $vlans->{$id};
    $self->set_hash('vlans', $vlans);
}

# Method: vlans
#
#   Returns a reference to an array with all existing vlan ID's
#
# Returns:
#
#   an array ref - holding the vlan ID's
sub vlans
{
    my ($self) = @_;

    my @ids = keys %{$self->get_hash('vlans')};
    return \@ids;
}

#
# Method: vlanExists
#
#   Checks if a given vlan id exists
#
# Parameters:
#
#   id - vlan identifier
#
#  Returns:
#
#   boolean - true if it exits, otherwise false
sub vlanExists # (vlanID)
{
    my ($self, $vlan) = @_;

    return exists $self->get_hash('vlans')->{$vlan};
}

# Method: ifaceVlans
#
#   Returns information about every vlan that exists on the given trunk
#   interface.
#
# Parameters:
#
#   iface - interface name
#
#  Returns:
#
#   array ref - The elements of the array are hashesh. The hashes contain
#   these keys: 'id' (vlan ID), 'name' (user given description for the vlan)
#   and 'interface' (the name of the trunk interface)
#
sub ifaceVlans
{
    my ($self, $name) = @_;

    my @array = ();
    my $vlans = $self->get_hash('vlans');
    foreach my $id (keys %{$vlans}) {
        my $vlan = $vlans->{$id};
        if ($vlan->{interface} eq $name) {
            $vlan->{id} = $id;
            push(@array, $vlan);
        }
    }
    return \@array;
}

sub vlan
{
    my ($self, $vlan) = @_;

    defined($vlan) or return undef;
    if ($vlan =~ /^vlan/) {
        $vlan =~ s/^vlan//;
    }
    if ($vlan =~ /:/) {
        $vlan =~ s/:.*$//;
    }
    my $vlans = $self->get_hash('vlans');
    unless (exists $vlans->{$vlan}) {
        return undef;
    }
    $vlans->{$vlan}->{id} = $vlan;
    return $vlans->{$vlan};
}

# Method: unsetIface
#
#   Unset an interface
#
# Parameters:
#
#   interface - the name of a network interface
#   force - boolean to indicate if an exception should be raised when
#   interface is changed or it should be forced
sub unsetIface # (interface, force)
{
    my ($self, $name, $force) = @_;
    unless ($self->ifaceExists($name)) {
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    }
    unless ($self->ifaceOnConfig($name)) {
        return;
    }

    my $oldm = $self->ifaceMethod($name);
    if ($oldm eq 'dhcp') {
        $self->DHCPCleanUp($name);
    } elsif ($oldm eq 'trunk') {
        $self->_trunkIfaceIsUsed($name);
    } elsif ($oldm eq 'static') {
        $self->_routersReachableIfChange($name);
        $self->_checkStatic($name, $force);
    }

    if ($oldm ne 'notset') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'notset',
            action => 'prechange',
            force  => $force,
        );
    }

    if ($oldm eq 'trunk') {
        $self->_removeTrunkIfaceVlanes($name);
    }

    my $ifaces = $self->get_hash('interfaces');
    delete $ifaces->{$name}->{address};
    delete $ifaces->{$name}->{netmask};
    $ifaces->{$name}->{method} = 'notset';
    $ifaces->{$name}->{name} = $name;
    $ifaces->{$name}->{changed} = 1;
    $self->set('interfaces', $ifaces);

    if ($oldm ne 'notset') {
        $self->_notifyChangedIface(
            name => $name,
            oldMethod => $oldm,
            newMethod => 'notset',
            action => 'postchange',
            force  => $force,
        );
    }

}

# Method: ifaceAddress
#
#   Returns the configured address for a real interface
#
# Parameters:
#
#   name - interface name
#
#  Returns:
#
#   - For static interfaces: the configured IP Address of the interface.
#   - For dhcp interfaces:
#       - the current address if the interface is up
#       - undef if the interface is down
#   - For not-yet-configured interfaces
#       - undef
sub ifaceAddress # (name)
{
    my ($self, $name) = @_;

    my $address;
    $self->ifaceExists($name) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    if ($self->vifaceExists($name)) {
        return $self->vifaceAddress($name);
    }
    if ($self->ifaceMethod($name) eq 'static') {
        return $self->get_hash('interfaces')->{$name}->{address};
    } elsif ($self->ifaceMethod($name) eq 'dhcp') {
        return $self->DHCPAddress($name);
    }
    return undef;
}

# Method: ifaceNetmask
#
#   Returns the configured network mask for a real interface
#
# Parameters:
#
#   interface - interface name
#
#  Returns:
#
#   - For static interfaces: the configured network mask  of the interface.
#   - For dhcp interfaces:
#       - the current network mask the interface is up
#       - undef if the interface is down
#   - For not-yet-configured interfaces
#       - undef
#
sub ifaceNetmask
{
    my ($self, $name) = @_;
    my $address;
    $self->ifaceExists($name) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);

    if ($self->vifaceExists($name)) {
        return $self->vifaceNetmask($name);
    }
    if ($self->ifaceMethod($name) eq 'static') {
        return $self->get_hash('interfaces')->{$name}->{netmask};
    } elsif ($self->ifaceMethod($name) eq 'dhcp') {
        return $self->DHCPNetmask($name);
    }

    return undef;
}

# Method: ifaceNetwork
#
#   Returns the configured network address  for a real interface
#
# Parameters:
#
#   interface - interface name
#
#  Returns:
#
#   - For static interfaces: the configured network address of the interface.
#   - For dhcp interfaces:
#       - the current network address the interface is up
#       - undef if the interface is down
#   - For not-yet-configured interfaces
#       - undef
sub ifaceNetwork # (interface)
{
    my ($self, $name) = @_;
    $self->ifaceExists($name) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    my $address;
    my $netmask;

    $address = $self->ifaceAddress($name);
    $netmask = $self->ifaceNetmask($name);
    if ($address) {
        return ip_network($address, $netmask);
    }
    return undef;
}

# Method: ifaceBroadcast
#
#   Returns the configured broadcast address  for a real interface
#
# Parameters:
#
#   interface - interface name
#
#  Returns:
#
#   - For static interfaces: the configured broadcast address of the
#   interface.
#   - For dhcp interfaces:
#       - the current broadcast address if the interface is up
#       - undef if the interface is down
#   - For not-yet-configured interfaces
sub ifaceBroadcast # (interface)
{
    my ($self, $name) = @_;
    $self->ifaceExists($name) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $name);
    my $address;
    my $netmask;

    $address = $self->ifaceAddress($name);
    $netmask = $self->ifaceNetmask($name);
    if ($address) {
        return ip_broadcast($address, $netmask);
    }
    return undef;
}

# Method: nameservers
#
#   Return a list of the configured name servers
#
#  Returns:
#
#   Array ref - each element contains a string holding the nameserver
#
sub nameservers
{
    my ($self) = @_;
    my $samba = $self->global()->modInstance('samba');
    if ($samba) {
        return ['127.0.0.1']
    }

    return $self->model('DNSResolver')->nameservers();
}

sub searchdomain
{
    my ($self) = @_;

    return $self->model('SearchDomain')->domainValue();
}

# Method: nameserverOne
#
#   Return the primary nameserver's IP address
#
#  Returns:
#
#   String - nameserver's IP address
#
#       empty string - if there is not primary nameserver
#
sub nameserverOne
{
    my ($self) = @_;

    my $nss = $self->nameservers();
    return $nss->[0] if (scalar(@{$nss}) >= 1);
    return '';
}

# Method: nameserverTwo
#
#   Return the secondary nameserver's IP address
#
#  Returns:
#
#   string - nameserver's IP address
#
#       empty string - if there is not secondary nameserver
#
sub nameserverTwo
{
    my ($self) = @_;

    my $nss = $self->nameservers();
    return $nss->[1] if (scalar(@{$nss}) >= 2);
    return '';
}

# Method: gateway
#
#       Returns the default gateway's ip address
#
# Returns:
#
#       If the gateway has not been set it will return undef
#
#   string - the default gateway's ip address (undef if not set)
sub gateway
{
    my $self = shift;

    return  $self->model('GatewayTable')->defaultGateway();
}

# Method: routes
#
#       Return the configured static routes
#
# Returns:
#
#   array ref - each element contains a hash ref with keys:
#
#          network - an IP block in CIDR format
#          gateway - an IP address
#
sub routes
{
    my ($self) = @_;

    my $staticRouteModel = $self->model('StaticRoute');
    my @routes;
    for my $id (@{$staticRouteModel->ids()}) {
        my $row = $staticRouteModel->row($id);
        push (@routes, { network => $row->printableValueByName('network'),
                         gateway => $row->printableValueByName('gateway')});
    }
    return \@routes;
}

# Method: gatewayDeleted
#
#    Mark an interface as changed for a route delete. The selected
#    interface to be restarted must be the one which the gateway is
#    in.
#
# Parameters:
#
#    gateway - String the gateway IP address
#
# Exceptions:
#
#    <EBox::Exceptions::MissingArgument> - thrown if any compulsory
#    argument is missing
#
sub gatewayDeleted
{
    my ($self, $gw) = @_;

    $gw or throw EBox::Exceptions::MissingArgument('gateway');

    foreach my $iface (@{$self->allIfaces()}) {
        my $host = $self->ifaceAddress($iface);
        my $mask = $self->ifaceNetmask($iface);
        my $meth = $self->ifaceMethod($iface);
        (defined($meth) eq 'static') or next;
        (defined($host) and defined($mask)) or next;
        if (isIPInNetwork($host,$mask,$gw)) {
            $self->_setChanged($iface);
        }
    }

}

#returns true if the interface has been marked as changed
sub _hasChanged
{
    my ($self, $iface) = @_;

    my $real = $iface;
    if ($self->vifaceExists($iface)) {
        ($real) = $self->_viface2array($iface);
    }
    my $ifaces = $self->get_hash('interfaces');
    if (exists $ifaces->{$real}) {
        return $ifaces->{$real}->{changed};
    } else {
        return 1; # deleted => has changed
    }
}

#returns true if the interface is empty (ready to be removed)
sub _isEmpty
{
    my ($self, $ifc) = @_;

    if ($self->vifaceExists($ifc)) {
        my ($real, $vir) = $self->_viface2array($ifc);
        return (not defined($self->get_hash('interfaces')->{$real}->{virtual}->{$vir}->{address}));
    } else {
        return (not defined($self->get_hash('interfaces')->{$ifc}->{method}));
    }
}

sub _removeIface
{
    my ($self, $iface) = @_;

    my $ifaces = $self->get_hash('interfaces');
    if ($self->vifaceExists($iface)) {
        my ($real, $virtual) = $self->_viface2array($iface);
        delete $ifaces->{$real}->{virtual}->{$virtual};
    } else {
        delete $ifaces->{$iface};
    }
    $self->set('interfaces', $ifaces);
}

sub _unsetChanged # (interface)
{
    my ($self, $iface) = @_;
    if ($self->vifaceExists($iface)) {
        return;
    }

    my $ifaces = $self->get_hash('interfaces');
    delete $ifaces->{$iface}->{changed};
    $self->set('interfaces', $ifaces);
}

sub _setChanged # (interface)
{
    my ($self, $iface) = @_;

    my $ifaces = $self->get_hash('interfaces');
    if ($self->vifaceExists($iface)) {
        my ($real, $vir) = $self->_viface2array($iface);
        $ifaces->{$real}->{changed} = 1;
    } else {
        $ifaces->{$iface}->{changed} = 1;
    }
    $self->set('interfaces', $ifaces);
}

# Method: _generateResolvconfConfig
#
#   This method write the /etc/resolvconf/interface-order file. This file
#   contain the order in which the files under /var/run/resolvconf/interfaces
#   are processes and finally result en the resolver order in /etc/resolv.conf
#
#   After write the order, resolvers manually configured in the webadmin
#   (those which interface field is zentyal.<row id>) are removed or added
#   to the resolvconf configuration.
#
sub _generateResolvconfConfig
{
    my ($self) = @_;

    # Generate base, head and tail
    $self->writeConfFile(RESOLVCONF_BASE,
        'network/resolvconf-base.mas', [],
        { mode => '0644', uid => 0, gid => 0 });
    $self->writeConfFile(RESOLVCONF_HEAD,
        'network/resolvconf-head.mas', [],
        { mode => '0644', uid => 0, gid => 0 });
    $self->writeConfFile(RESOLVCONF_TAIL,
        'network/resolvconf-tail.mas', [],
        { mode => '0644', uid => 0, gid => 0 });

    # First step, write the order list
    my $interfaces = [];
    my $model = $self->model('DNSResolver');
    foreach my $id (@{$model->ids()}) {
        my $row = $model->row($id);
        my $interface = $row->valueByName('interface');
        next unless defined $interface and length $interface;
        push (@{$interfaces}, $interface);
    }

    # TODO SearchDomain should be a table model. Multiple search domains
    #      can be defined
    my $searchDomainModel = $self->model('SearchDomain');
    my $searchDomain = $searchDomainModel->value('domain');
    my $searchDomainIface = $searchDomainModel->value('interface');
    if ($searchDomainIface) {
        push (@{$interfaces}, $searchDomainIface);
    }

    my $ifaces = $self->ifaces();
    foreach my $iface (@{$ifaces}) {
        next unless $self->ifaceMethod($iface) eq 'dhcp';

        $iface = "$iface.dhclient";
        next if grep (/$iface/, @{$interfaces});

        push (@{$interfaces}, $iface);
    }

    my $array = [];
    push (@{$array}, interfaces => $interfaces);
    $self->writeConfFile(RESOLVCONF_INTERFACE_ORDER,
        'network/resolvconf-interface-order.mas', $array,
        { mode => '0644', uid => 0, gid => 0 });

    # Second step, trigger the updates
    foreach my $id (@{$model->ids()}) {
        my $row = $model->row($id);
        my $interface = $row->valueByName('interface');
        next unless defined $interface and length $interface;

        my $resolver = $row->valueByName('nameserver');
        next unless defined $resolver and length $resolver;

        next unless ($interface =~ m/^zentyal\..+$/);
        EBox::Sudo::root("resolvconf -d '$interface'");
        EBox::Sudo::root("echo 'nameserver $resolver' | resolvconf -a '$interface'");
    }

    if ($searchDomainIface and ($searchDomainIface =~ m/^zentyal\..+$/)) {
        EBox::Sudo::root("resolvconf -d '$searchDomainIface'");
        if ($searchDomain) {
            EBox::Sudo::root("echo 'search $searchDomain' | resolvconf -a '$searchDomainIface'");
        }
    }

    my $sysinfo = EBox::Global->modInstance('sysinfo');
    my $domain = $sysinfo->hostDomain();
    EBox::Sudo::root("echo 'domain $domain' | resolvconf -a 'zentyal.domain'");
}

# Generate the configuration if a HTTP proxy has been set
sub _generateProxyConfig
{
    my ($self) = @_;

    my $proxy = $self->model('Proxy');
    my $proxyConf;

    if ($proxy->serverValue() and $proxy->portValue()) {
        $proxyConf = "http://".$proxy->serverValue().":".$proxy->portValue()."/";
        if ($proxy->usernameValue() and $proxy->passwordValue()) {
            $proxyConf = "http://".$proxy->usernameValue().":".$proxy->passwordValue();
            $proxyConf .= "@".$proxy->serverValue().":".$proxy->portValue()."/";
        }
    }

    # Write environment file by edition not overwritting
    my @contents = File::Slurp::read_file(ENV_FILE);
    my @finalContents = ();
    my $inMark = 0;
    foreach my $line (@contents) {
        if ($inMark) {
            $inMark = ($line !~ m/^#\s*END Zentyal Proxy Settings\s*$/);
            next;
        }
        $inMark = ($line =~ m/^#\s*Zentyal Proxy Settings\s*$/);
        push(@finalContents, $line) unless ($inMark);
    }
    if ($proxyConf) {
        push(@finalContents, "# Zentyal Proxy Settings\n",
                             qq{http_proxy="$proxyConf"\n},
                             qq{HTTP_PROXY="$proxyConf"\n},
                             "# END Zentyal Proxy Settings\n");
    }
    EBox::Module::Base::writeFile(ENV_FILE, join("", @finalContents));

    $self->writeConfFile(APT_PROXY_FILE,
                        'network/99proxy.conf.mas',
                        [ proxyConf => $proxyConf ]);
}

# Method: proxySettings
#
#    Return the proxy settings if configured
#
# Returns:
#
#    Hash ref - the following keys are included
#
#        server   - the HTTP proxy's name
#        port     - the HTTP proxy's port
#        username - the username to authenticate (optional)
#        password - the password (optional)
#
#    undef - if there is not proxy settings
#
sub proxySettings
{
    my ($self) = @_;

    my $proxy  = $self->model('Proxy');
    my $server = $proxy->serverValue();
    my $port   = $proxy->portValue();
    if ( $server and $port ) {
        my $retValue = { server => $server, port => $port };
        my $username = $proxy->usernameValue();
        my $password = $proxy->passwordValue();
        if ( $username and $password ) {
            $retValue->{username} = $username;
            $retValue->{password} = $password;
        }
        return $retValue;
    } else {
        return undef;
    }
}

sub generateInterfaces
{
    my ($self) = @_;
    my $iflist = $self->allIfacesWithRemoved();
    $self->writeConfFile(INTERFACES_FILE,
                         'network/interfaces.mas',
                         [
                             iflist => $iflist,
                             networkMod => $self,
                         ],
                         {'uid' => 0, 'gid' => 0, mode => '755' }
                        );
}

# Generate the static routes from routes() with "ip" command
sub _generateRoutes
{
    my ($self) = @_;
    my @routes = @{$self->routes()};

    # clean up unnecesary rotues
    $self->_removeRoutes(\@routes);
    @routes or return;

    my @cmds;
    foreach my $route (@routes) {
        my $net    = $route->{network};
        $net =~ s[/32$][]; # route_is_up needs no /24 mask
        my $gw     = $route->{gateway};
        # check if route already is up
        if (route_is_up($net, $gw)) {
            next;
        }

        my $cmd = "/sbin/ip route add $net via $gw table main";
        EBox::Sudo::root($cmd)
    }
}

# Remove not configured routes
sub _removeRoutes
{
    my ($self, $storedRoutes) = @_;
    my %toKeep = map {
        $_->{network} => $_
    } @{ $storedRoutes  };

    # Delete those routes which are not defined by Zentyal
    my @currentRoutes = list_routes(1, 0); # routes via gateway
    foreach my $currentRoute (@currentRoutes) {
        my $network = $currentRoute->{network};
        unless (($network =~ m{/}) or ($network eq 'default')) {
            # add /32 mask to ips without it so we can compare same format
            $network .= '/32';
        }

        my $gw   = $currentRoute->{router};

        if ((exists $toKeep{$network}) and
            ($toKeep{$network}->{gateway} eq $gw)) {
                next;
        }

        my $cmd =  "/sbin/ip route del $network via $gw";
        EBox::Sudo::root($cmd);
    }
}

# disable reverse path for gateway interfaces
sub _disableReversePath
{
    my ($self) = @_;

    my $routers = $self->gatewaysWithMac();

    my @cmds;
    push (@cmds, '/sbin/sysctl -q -w net.ipv4.conf.all.rp_filter=0');

    my %seen;
    for my $router ( reverse @{$routers} ) {
        my $iface = $router->{'interface'};
        # remove viface portion
        $iface =~ s/:.*$//;

        next if $seen{$iface};
        $seen{$iface} = 1;

        # Skipping vlan interfaces as it seems rp_filter key doesn't
        # exist for them
        next if ($iface =~ /^vlan/);

        push (@cmds, "/sbin/sysctl -q -w net.ipv4.conf.$iface.rp_filter=0");
    }

    EBox::Sudo::root(@cmds);
}

sub _multigwRoutes
{
    my ($self, $dynIfaces) = @_;

    # Flush the rules
    #
    # Add a rule to match every fwmark to pass through its
    # corresponding table.
    #
    # Each table only has a default
    # gateway, and there are as many tables as routers the user
    # has added.
    #
    # To route packets towards local networks, the highest
    # priority rule points to the main table. Note that
    # we do not have a default route in the main table, otherwise
    # we could not do the multipath stuff. Instead, we set the
    # default route within the default table.
    #
    #
    # We enclose iptables rules containing CONNMARK target
    # within a try/catch block because
    # kernels < 2.6.12 do not include such module.

    my $marks = $self->marksForRouters();
    my $routers = $self->gatewaysWithMac();
    my @cmds; # commands to run

    push(@cmds, EBox::Config::share() . 'zentyal-network/flush-fwmarks');
    my %interfaces;
    for my $router ( reverse @{$routers} ) {
        # Skip gateways with unassigned address
        my $ip = $router->{'ip'};
        next unless $ip;

        my $iface = $router->{'interface'};
        $interfaces{$iface}++;
    }

    my @markRules;
    my @addrRules;
    for my $router ( reverse @{$routers} ) {

        # Skip gateways with unassigned address
        my $ip = $router->{'ip'};
        next unless $ip;

        my $iface = $router->{'interface'};
        my $method = $self->ifaceMethod($iface);
        $interfaces{$iface}++;

        my $mark = $marks->{$router->{'id'}};
        my $table = 100 + $mark;

        my $net = $self->ifaceNetwork($iface);
        my $address = $self->ifaceAddress($iface);
        unless ($address) {
            EBox::warn("Interface $iface used by gateway " .
                            $router ->{name} . " has not address." .
                        " Not adding multi-gateway rules for this gateway.");
            next;
        }

        my $route = "via $ip dev $iface src $address";

        # Write mark rules first to avoid local output problems
        push(@cmds, "/sbin/ip route flush table $table");
        push(@markRules, "/sbin/ip rule add fwmark $mark/0xFF table $table");
        push(@addrRules, "/sbin/ip rule add from $ip table $table");

        # Add rule by source in multi interface configuration
        if (scalar keys %interfaces > 1) {
            push(@addrRules, "/sbin/ip rule add from $address table $table");
        }

        push(@cmds, "/sbin/ip route add default $route table $table");
    }

    push(@cmds, @addrRules, @markRules);
    push(@cmds,'/sbin/ip rule add table main');

    # Not in @cmds array because of possible CONNMARK exception
    my @fcmds;
    push(@fcmds, '/sbin/iptables -t mangle -F');
    push(@fcmds, '/sbin/iptables -t mangle -X');
    push(@fcmds, '/sbin/iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark');
    push(@fcmds, '/sbin/iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark');
    if ($dynIfaces) {
        sleep 1;
    }
    EBox::Sudo::silentRoot(@fcmds);

    my $defaultRouterMark;
    foreach my $router (@{$routers}) {

        # Skip gateways with unassigned address
        next unless $router->{'ip'};

        if ($router->{'default'} and $router->{'enabled'}) {
            $defaultRouterMark = $marks->{$router->{'id'}};
        }

        my $mark = $marks->{$router->{'id'}};

        # Match interface instead of mac for dhcp
        my $mac = $router->{'mac'};
        my $iface = $router->{'interface'};
        my $origin;
        if ($mac) {
            # Skip unknown macs for static interfaces
            next if ($mac eq 'unknown');

            $origin = "-m mac --mac-source $mac";
        } else {
            $origin = "-i $iface";
        }
        push(@cmds, '/sbin/iptables -t mangle -A PREROUTING '
                  . "-m mark --mark 0/0xff $origin "
                  . "-j MARK --set-mark $mark");
    }

    # send unmarked packets through default router
    if ($defaultRouterMark) {
        push(@cmds, "/sbin/iptables -t mangle -A PREROUTING  -m mark --mark 0/0xff " .
                    "-j  MARK --set-mark $defaultRouterMark");
        push(@cmds, "/sbin/iptables -t mangle -A OUTPUT -m mark --mark 0/0xff " .
                    "-j  MARK --set-mark $defaultRouterMark");
    }

    # always before CONNMARK save commands
    EBox::Sudo::root(@cmds);

    try {
        my @fcmds;
        push(@fcmds, '/sbin/iptables -t mangle -A PREROUTING -j CONNMARK --save-mark');
        push(@fcmds, '/sbin/iptables -t mangle -A OUTPUT -j CONNMARK --save-mark');

        foreach my $chain (CHECKIP_CHAIN) {
            push(@fcmds, "/sbin/iptables -t mangle -N $chain");
            push(@fcmds, "/sbin/iptables -t mangle -A OUTPUT -j $chain");
        }

        EBox::Sudo::root(@fcmds);
    } catch {
    }
}

sub isRunning
{
    my ($self) = @_;
    return $self->isEnabled();
}

sub _supportActions
{
    return undef;
}

# Method: _preSetConf
#
#   Overrides <EBox::Module::Base::_preSetConf>
#
sub _preSetConf
{
    my ($self, %opts) = @_;

    # Don't do anything during boot to avoid bringing down interfaces
    # which are already bringed up by the networking service
    unless ((exists $ENV{USER}) or (exists $ENV{PLACK_ENV})) {
        return;
    }

    my $file = INTERFACES_FILE;
    my $restart = delete $opts{restart};

    try {
        EBox::Sudo::root(
            '/sbin/modprobe 8021q',
            '/sbin/vconfig set_name_type VLAN_PLUS_VID_NO_PAD'
        );
    } catch (EBox::Exceptions::Internal $e) {
    }

    $self->{restartResolvconf} = 0;

    # Ensure /var/run/resolvconf/resolv.conf exists
    if (not EBox::Sudo::fileTest('-f', '/var/run/resolvconf/resolv.conf')) {
        EBox::info("Creating file /var/run/resolvconf/resolv.conf");
        EBox::Sudo::root('touch /var/run/resolvconf/resolv.conf');
        $self->{restartResolvconf} = 1;
    }

    # Ensure /etc/resolv.conf is a symlink to /var/run/resolvconf/resolv.conf
    if (not EBox::Sudo::fileTest('-L', RESOLV_FILE)) {
        EBox::info("Restoring symlink /etc/resolv.conf");
        EBox::Sudo::root('rm -f ' . RESOLV_FILE);
        EBox::Sudo::root('ln -s /var/run/resolvconf/resolv.conf ' . RESOLV_FILE);
        $self->{restartResolvconf} = 1;
    }

    # Write DHCP client configuration
    my $hostname = $self->global()->modInstance('sysinfo')->hostName();
    $self->writeConfFile(DHCLIENTCONF_FILE, 'network/dhclient.conf.mas', [ hostname =>  $hostname]);

    # Bring down changed interfaces
    my $iflist = $self->allIfacesWithRemoved();
    foreach my $if (@{$iflist}) {
        my $dhcpIface = $self->ifaceMethod($if) eq 'dhcp';
        if ($self->_hasChanged($if) or $dhcpIface) {
            try {
                my @cmds;
                if ($self->ifaceExists($if)) {
                    my $ifname = $if;
                    push (@cmds, "/sbin/ip address flush label $if");
                    push (@cmds, "/sbin/ip address flush label $if:*");
                    push (@cmds, "/sbin/ifdown --force -i $file $ifname");
                }

                EBox::Sudo::root(@cmds);
            } catch (EBox::Exceptions::Internal $e) {
            }
            #remove if empty
            if ($self->_isEmpty($if)) {
                unless ($self->isReadOnly()) {
                    $self->_removeIface($if);
                }
            }
        }
        # Clean up dhcp state if interface is not DHCP or
        # PPPoE it should be done by the dhcp, but sometimes
        # cruft is left
        if ($self->ifaceExists($if)) {
            unless ($self->ifaceMethod($if) eq 'dhcp') {
                $self->DHCPCleanUp($if);
            }
        }
    }

    EBox::NetWrappers::clean_ifaces_list_cache();
}

sub _postServiceHook
{
    my ($self, $enabled) = @_;

    if ($enabled and $self->{restartResolvconf}) {
        EBox::Service::manage('resolvconf', 'restart');
    }

    $self->SUPER::_postServiceHook($enabled);
}

sub _setConf
{
    my ($self) = @_;
    $self->generateInterfaces();
    $self->_generateProxyConfig();
}

# Method: _enforceServiceState
#
#   Overrides base method. It regenerates the network configuration.
#   It will set up the network interfaces, routes, dns...
sub _enforceServiceState
{
    my ($self, %opts) = @_;

    my $restart = delete $opts{restart};

    my $file = INTERFACES_FILE;

    EBox::Sudo::silentRoot("ip addr add 127.0.1.1/8 dev lo");

    my $dynIfaces = 0;
    my @ifups = ();
    my $iflist = $self->allIfacesWithRemoved();
    foreach my $iface (@{$iflist}) {
        my $dhcpIface = $self->ifaceMethod($iface) eq 'dhcp';
        if ($dhcpIface) {
            $dynIfaces = 1;
        }
        if ($self->_hasChanged($iface) or $dhcpIface or $restart) {
            push(@ifups, $iface);
        }
    }

    # Only execute ifups if we are not running from init on boot
    # The interfaces are already up thanks to the networking start
    if ((exists $ENV{USER}) or (exists $ENV{PLACK_ENV})) {
        EBox::Util::Lock::lock('ifup');
        foreach my $iface (@ifups) {
            EBox::Sudo::root(EBox::Config::scripts() .
                    "unblock-exec /sbin/ifup --force -i $file $iface");
            unless ($self->isReadOnly()) {
                $self->_unsetChanged($iface);
            }
        }
        EBox::Util::Lock::unlock('ifup');
        # Notify if ifup has been done
        $self->_flagIfUp(\@ifups);
    }
    EBox::NetWrappers::clean_ifaces_list_cache();

    $self->_generateResolvconfConfig();

    EBox::Sudo::silentRoot('/sbin/ip route del default table default',
                           '/sbin/ip route del default');

    my $cmd = $self->_defaultGatewayCommand();
    if ($cmd) {
        try {
            EBox::Sudo::root($cmd);
        } catch (EBox::Exceptions::Internal $e) {
            throw EBox::Exceptions::External("An error happened ".
                    "trying to set the default gateway. Make sure the ".
                    "gateway you specified is reachable.");
        }
    }

    $self->_generateRoutes();
    $self->_disableReversePath();
    $self->_multigwRoutes($dynIfaces);
    $self->_cleanupVlanIfaces();

    EBox::Sudo::root('/sbin/ip route flush cache');

    $self->SUPER::_enforceServiceState();
}

# Method:  restoreConfig
#
#   Restore its configuration from the backup file.
#
# Parameters:
#  dir - Directory where are located the backup files
#
sub restoreConfig
{
    my ($self, $dir) = @_;

    # Set all configured ifaces as changed
    foreach my $iface (@{$self->allIfaces()}) {
        $self->_setChanged($iface);
    }

    $self->SUPER::restoreConfig();
}

sub _stopService
{
    my ($self) = @_;

    return unless ($self->configured());

    my @cmds;
    my $file = INTERFACES_FILE;
    my $iflist = $self->allIfaces();
    foreach my $if (@{$iflist}) {
        try {
            my $ifname = $if;
            push @cmds, "/sbin/ip address flush label $if";
            push @cmds, "/sbin/ip address flush label $if:*";
            push @cmds, "/sbin/ifdown --force -i $file $ifname";
        } catch (EBox::Exceptions::Internal $e) {
        }
    }

    EBox::Sudo::root(@cmds);

    $self->SUPER::_stopService();
}

sub _routersReachableIfChange # (interface, newaddress?, newmask?)
{
    my ($self, $iface, $newaddr, $newmask) = @_;

    my @routes = @{$self->routes()};
    my @ifaces = @{$self->allIfaces()};
    my @gws = ();
    foreach my $route (@routes) {
        push(@gws, $route->{gateway});
    }

    foreach my $gw (@{$self->model('GatewayTable')->gateways()}) {
        next if $gw->{'auto'};
        my $ip = $gw->{'ip'};
        next unless $ip;
        push (@gws, $ip);
    }

    foreach my $gw (@gws) {
        $gw .= "/32";
        my $reachable = undef;
        foreach my $if (@ifaces) {
            my $host; my $mask; my $meth;
            if ($iface eq $if) {
                $host = $newaddr;
                $mask = $newmask;
            } else {
                $meth = $self->ifaceMethod($if);
                ($meth eq 'static') or next;
                $host = $self->ifaceAddress($if);
                $mask = $self->ifaceNetmask($if);
            }
            (defined($host) and defined($mask)) or next;
            if (isIPInNetwork($host, $mask, $gw)) {
                $reachable = 1;
            }
        }
        ($reachable) or throw EBox::Exceptions::External(
            __('The requested operation will cause one of the '.
               'configured gateways or static routes to become unreachable. ' .
               'Please remove it first if you really want to '.
               'make this change.'));
    }
    return 1;
}

# Method: gatewayReachable
#
#       Check if a given gateway address is reachable with the current
#       network configuration
#
# Parameters:
#
#       gw - String the IP address for the gateway
#
#       name - String A name to be shown if exception is launched. If
#       no given, then an exception is not launched. *(Optional)*
#       Default value: undef
#
# Returns:
#
#       Boolean - name of the interface used to reach the gateway
#                 undef if not reachable
#
# Exceptions:
#
#       <EBox::Exceptions::MissingArgument> - thrown if any compulsory
#       argument is missing
#
#       <EBox::Exceptions::External> - thrown if name is supplied and
#       the gateway is not reachable
#
sub gatewayReachable
{
    my ($self, $gw, $name) = @_;

    $gw or throw EBox::Exceptions::MissingArgument('gw');

    my $reachableByNoStaticIface = undef;

    my $cidr_gw = "$gw/32";
    foreach my $iface (@{$self->allIfaces()}) {
        my $host = $self->ifaceAddress($iface);
        my $mask = $self->ifaceNetmask($iface);

        (defined($host) and defined($mask)) or next;

        checkIPNetmask($gw, $mask) or next;

        if (isIPInNetwork($host,$mask,$cidr_gw)) {
            my $meth = $self->ifaceMethod($iface);
            if ($meth ne 'static') {
                $reachableByNoStaticIface = $iface;
                next;
            }

            return $iface;
        }
    }

    if ($name) {
        if (not $reachableByNoStaticIface) {
        throw EBox::Exceptions::External(
                __x("Gateway {gw} must be in the same network that a static interface", gw => $gw));
        } else {
        throw EBox::Exceptions::External(
                __x("Gateway {gw} must be in the same network that static interface. "
                    . "Currently it belongs to the network of {iface} which is not static",
                    gw => $gw, iface => $reachableByNoStaticIface) );
        }

    } else {
        return undef;
    }
}

# Method: setDHCPAddress
#
#   Sets the parameters for a DHCP configured interface. For instance,
#   this function is primaraly used from a DHCP hook.
#
# Parameters:
#
#   iface - interface name
#   address - IPv4 address
#   mask - networking mask
sub setDHCPAddress # (interface, ip, mask)
{
    my ($self, $iface, $ip, $mask) = @_;

    if (not $iface =~ m{^/dev/pts/}) {
        $self->ifaceExists($iface) or
            throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                                                 value => $iface);
    }
    checkIPNetmask($ip, $mask,  __("IP address"), __('Netmask'));

    my $state = $self->get_state();
    my $oldAddr = $state->{dhcp}->{$iface}->{address};
    my $oldMask = $state->{dhcp}->{$iface}->{mask};
    $state->{dhcp}->{$iface}->{address} = $ip;
    $state->{dhcp}->{$iface}->{mask} = $mask;
    $self->set_state($state);

    # Calling observers
    my $global = EBox::Global->getInstance();
    my @observers = @{$global->modInstancesOfType('EBox::NetworkObserver')};

    # Tell observers the interface way has changed
    foreach my $obs (@observers) {
        if ($self->ifaceIsExternal($iface)) {
            $obs->externalDhcpIfaceAddressChangedDone($iface, $oldAddr, $oldMask, $ip, $mask);
        } else {
            $obs->internalDhcpIfaceAddressChangedDone($iface, $oldAddr, $oldMask, $ip, $mask);
        }
    }
}

# Method: setDHCPGateway
#
#   Sets the obtained gateway via DHCP
#
# Parameters:
#
#   iface   - ethernet interface
#   gateway - gateway's IPv4 address
sub setDHCPGateway # (iface, gateway)
{
    my ($self, $iface, $gw) = @_;
    checkIP($gw, __("IP address"));
    $self->ifaceExists($iface) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                                             value => $iface);


    my $state = $self->get_state();
    $state->{dhcp}->{$iface}->{gateway} = $gw;
    $self->set_state($state);
}

# Method: DHCPCleanUp
#
#   Removes the dhcp configuration for a given interface
#   Also removes the PPPoE iface if exists
#
# Parameters:
#
#   interface - interface name
#
sub DHCPCleanUp # (interface)
{
    my ($self, $iface) = @_;

    if (not $iface =~ m{^/dev/pts/}) {
        $self->ifaceExists($iface) or
            throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                                                 value => $iface);
    }

    my $state = $self->get_state();
    delete $state->{dhcp}->{$iface};
    $self->set_state($state);
}

# Method: selectedDefaultGateway
#
#   Returns the selected default gateway
#
sub selectedDefaultGateway
{
    my ($self) = @_;

    return $self->get('default/gateway');
}

# Method: storeSelectedDefaultGateway
#
#   Store the selected default gateway
#
# Parameters:
#
#   gateway - gateway id
#
sub storeSelectedDefaultGateway
{
    my ($self, $gateway) = @_;
    return $self->set('default/gateway', $gateway);
}

# Method: DHCPGateway
#
#   Returns the gateway from a dhcp configured interface
#
# Parameters:
#
#   iface - interface name (DHCP or PPPoE)
#
# Returns:
#
#   string - gateway
#
sub DHCPGateway
{
    my ($self, $iface) = @_;

    $self->ifaceExists($iface) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                                             value => $iface);

    return $self->get_state()->{dhcp}->{$iface}->{gateway};
}

# Method: DHCPAddress
#
#   Returns the ip address from a dhcp configured interface
#
# Parameters:
#
#   interface - interface name
#
# Returns:
#
#   string - IPv4 address
#
sub DHCPAddress
{
    my ($self, $iface) = @_;

    $self->ifaceExists($iface) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                                             value => $iface);

    return $self->get_state()->{dhcp}->{$iface}->{address};
}

# Method: DHCPNetmask
#
#   Returns the network mask from a dhcp configured interface
#
# Parameters:
#
#   interface - interface name
#
# Returns:
#
#   string - network mask
#
sub DHCPNetmask
{
    my ($self, $iface) = @_;

    $self->ifaceExists($iface) or
        throw EBox::Exceptions::DataNotFound(data => __('Interface'),
                             value => $iface);

    return $self->get_state()->{dhcp}->{$iface}->{mask};
}

# Method: ping
#
#   Performs a ping test and returns the output
#
# Parameters:
#
#   host - host to ping (either ip or hostname)
#
# Returns:
#
#   string - output of the ping command
#
sub ping # (host)
{
    my ($self, $host) = @_;
    (checkIP($host) or checkDomainName($host)) or
        throw EBox::Exceptions::InvalidData
            ('data' => __('Host name'), 'value' => $host);
    return `ping -c 3 $host 2>&1`;
}

# Method: traceroute
#
#   Performs a traceroute test and returns it output
#
# Parameters:
#
#   host - host to trace the route (either ip or hostname)
#
# Returns:
#
#   string - output of the traceroute command
#
sub traceroute # (host)
{
    my ($self, $host) = @_;
    (checkIP($host) or checkDomainName($host)) or
        throw EBox::Exceptions::InvalidData
            ('data' => __('Host name'), 'value' => $host);
    my $out = EBox::Sudo::rootWithoutException("traceroute -I -n $host 2>&1");
    return join("\n", @{$out});
}

# Method: resolv
#
#   Performs a name resolution (using dig) and returns the output
#
# Parameters:
#
#   host - host name to resolve
#
# Returns:
#
#   string - output of the dig command
#
sub resolv # (host)
{
    my ($self, $host) = @_;
    checkDomainName($host, __("host name"));
    # +time=3 sets the timeout (the default is 5), it tries three times
    # so in the worst case it should take 9 seconds to return from this
    # call
    # FIXME: study which options make sense in dig, remove some stuff
    # from the output
    return `dig +time=3 $host 2>&1`;
}

# Method: wakeonlan
#
#   Performs a wakeonlan and returns the output
#
# Parameters:
#
#   broadcast - IP broadcast address to be used
#   macs - Array of MAC addresses of the computers to wake
#
# Returns:
#
#   string - output of the wakeonlan command
#
sub wakeonlan
{
    my ($self, $broadcast, @macs) = @_;
    my $param = "-i '$broadcast'";
    foreach my $mac (@macs) {
        $param .= " '$mac'";
    }

    return `wakeonlan $param 2>&1`;
}

# Method: externalConnectionWarning
#
#   Checks if the given iface is being used to connect to the Zentyal UI.
#   This is used to warn when trying to set is as external in the Interfaces
#   configuration or in the initial wizard.
#
# Parameters:
#
#   iface - name of the iface to check
#   request - Plack::Request reference.
#
sub externalConnectionWarning
{
    my ($self, $iface, $request) =  @_;

    my $remote = $request->address();
    my $command = "/sbin/ip route get to $remote" . ' | head -n 1 | sed -e "s/.*dev \(\w\+\).*/\1/" ';
    my $routeIface = `$command`;
    return 0 unless ($? == 0);
    chop($routeIface);
    if (defined($routeIface) and ($routeIface eq $iface)) {
        return 1;
    }
}

sub interfacesWidget
{
    my ($self, $widget) = @_;

    my @ifaces = @{$self->ifacesWithRemoved()};
    my $size = scalar (@ifaces) * 1.25;
    $size = 0.1 unless defined ($size);
    $widget->{size} = "'$size'";

    my $linkstatus = {};
    EBox::Sudo::silentRoot('/sbin/mii-tool > ' . EBox::Config::tmp . 'linkstatus');
    if (open(LINKF, EBox::Config::tmp . 'linkstatus')) {
        while (<LINKF>) {
            if (/link ok/) {
                my $i = (split(" ",$_))[0];
                chop($i);
                $linkstatus->{$i} = 1;
            } elsif(/no link/) {
                my $i = (split(" ",$_))[0];
                chop($i);
                $linkstatus->{$i} = 0;
            }
        }
    }
    foreach my $iface (@ifaces) {
        iface_exists($iface) or next;
        my $upStr = __("down");
        my $section = new EBox::Dashboard::Section($iface, $self->ifaceAlias($iface));
        $widget->add($section);

        if (iface_is_up($iface)) {
            $upStr = __("up");
        }

        my $externalStr;
        if ($self->ifaceIsExternal($iface)) {
            $externalStr = __('external');
        } else {
            $externalStr = __('internal');
        }

        my $linkStatusStr;
        if (defined($linkstatus->{$iface})) {
            if($linkstatus->{$iface}){
                $linkStatusStr =  __("link ok");
            }else{
                $linkStatusStr =  __("no link");
            }
        }

        my $status = "$upStr, $externalStr";
        if ($linkStatusStr) {
            $status .= ", $linkStatusStr";
        }

        $section->add(new EBox::Dashboard::Value (__("Status"), $status));

        my $ether = iface_mac_address($iface);
        if ($ether) {
            $section->add(new EBox::Dashboard::Value
                (__("MAC address"), $ether));
        }

        my @ips = iface_addresses($iface);
        foreach my $ip (@ips) {
            $section->add(new EBox::Dashboard::Value
                (__("IP address"), $ip));
        }
        my $graphs = new EBox::Dashboard::GraphRow();
        $section->add($graphs);

        my $cmd;

        my $statistics = "/sys/class/net/$iface/statistics";
        my $statsFile;

        open ($statsFile, "$statistics/tx_bytes");
        my $tx_bytes = <$statsFile>;
        close ($statsFile);
        chomp ($tx_bytes);
        $graphs->add(new EBox::Dashboard::CounterGraph
            (__("Tx bytes"),
            $iface . "_txbytes",
            $tx_bytes,
            'small'));

        open ($statsFile, "$statistics/rx_bytes");
        my $rx_bytes = <$statsFile>;
        close ($statsFile);
        chomp ($rx_bytes);
        $graphs->add(new EBox::Dashboard::CounterGraph
            (__("Rx bytes"),
            $iface . "_rxbytes",
            $rx_bytes,
            'small'));
    }
}

sub widgets
{
    return {
        'interfaces' => {
            'title' => __("Network Interfaces"),
            'widget' => \&interfacesWidget,
            'order' => 3,
            'default' => 1
        }
    };
}

# Method: menu
#
#       Overrides EBox::Module method.
#
#
sub menu
{
    my ($self, $root) = @_;

    my $folder = new EBox::Menu::Folder('name' => 'Network',
                                        'icon' => 'network',
                                        'text' => __('Network'),
                                        'tag' => 'system',
                                        'order' => 40);

    $folder->add(new EBox::Menu::Item('url' => 'Network/Ifaces',
                                      'text' => __('Interfaces'),
                                      'order' => 10));

    $folder->add(new EBox::Menu::Item('url' => 'Network/Composite/Gateway',
                                      'text' => __('Gateways'),
                                      'order' => 20));

    $folder->add(new EBox::Menu::Item('url' => 'Network/Composite/DNS',
                                      'text' => 'DNS',
                                      'order' => 30));

    $folder->add(new EBox::Menu::Item('url' => 'Network/View/StaticRoute',
                                      'text' => __('Static Routes'),
                                      'order' => 60));

    $folder->add(new EBox::Menu::Item('url' => 'Network/Diag',
                                      'text' => __('Tools'),
                                      'order' => 80));

    $root->add($folder);
}

# Method: gateways
#
#   Return the enabled gateways
#
# Returns:
#
#   array ref of hash refs containing name, ip,
#   if it is the default gateway or not and the id  for the gateway.
#
#   Example:
#
#   [
#     {
#       name => 'gw1', ip => '192.168.1.1' , interface => 'eth0',
#       default => '1', id => 'foo1234'
#     }
#   ]
#
sub gateways
{
    my ($self) = @_;

    my $gatewayModel = $self->model('GatewayTable');

    return $gatewayModel->gateways();
}

sub _defaultGwAndIface
{
    my ($self) = @_;

    my $gw = $self->model('GatewayTable')->find('default' => 1);

    if ($gw and $gw->valueByName('enabled')) {
        return ($gw->valueByName('interface'), $gw->valueByName('ip'));
    } else {
        return (undef, undef);
    }
}

# Method: gatewaysWithMac
#
#   Return the enabled gateways and its mac address
#
# Returns:
#
#   array ref of hash refs containing name, ip,
#   if it is the default gateway or not and the id  for the gateway.
#
#   Example:
#
#   [
#     {
#       name => 'gw1', ip => '192.168.1.1' ,
#       defalut => '1', id => 'foo1234', mac => '00:00:fa:ba:da'
#     }
#   ]
#
sub gatewaysWithMac
{
    my ($self) = @_;

    my $gatewayModel = $self->model('GatewayTable');

    return $gatewayModel->gatewaysWithMac();
}

sub marksForRouters
{
    my ($self) = @_;

    my $marks = $self->model('GatewayTable')->marksForRouters();
}

# Method: regenGateways
#
#   Recreate the default route table. This method is currently used
#   for the WAN failover and dynamic multi-gateway.
#
#
sub regenGateways
{
    my ($self) = @_;

    my $global = EBox::Global->getInstance();

    my $timeout = 180;
    my $locked = 0;

    while ((not $locked) and ($timeout > 0)) {
        try {
            EBox::Util::Lock::lock('network');
            $locked = 1;
        } catch (EBox::Exceptions::Lock $e) {
            sleep 5;
            $timeout -= 5;
        }
    }

    unless ($locked) {
        EBox::error('Network module has been locked for 60 seconds');
        return;
    }

    $self->saveConfig();
    my @commands;
    push (@commands, '/sbin/ip route del table default || true');
    my $cmd = $self->_defaultGatewayCommand();
    if ($cmd) {
        push (@commands, $cmd);
    }

    try {
        EBox::Sudo::root(@commands);
    } catch {
        EBox::error('Something bad happened reseting default gateways');
    }
    $self->_multigwRoutes();

    EBox::Sudo::root('/sbin/ip route flush cache');

    $global->modRestarted('network');

    EBox::Util::Lock::unlock('network');
}

# Method: replicationExcludeKeys
#
#      Exclude these keys from replication.
#
# Overrides: <EBox::Module::Config::replicationExcludeKeys>
#
sub replicationExcludeKeys
{
    return [ 'interfaces', 'vlans' ];
}

# Group: Ifup flag methods

# Method: flagIfUp
#
# Returns:
#
#    Array ref - containing the ifaces that have set up in last setConf
#
#    undef - if the flag is not set
sub flagIfUp
{
    my ($self) = @_;

    my $state = $self->get_state();
    if (exists $state->{ifup}) {
        return $state->{ifup};
    }
    return undef;
}

# Method: unsetFlagIfUp
#
#    Delete flag if up
#
sub unsetFlagIfUp
{
    my ($self) = @_;

    my $state = $self->get_state();
    if (exists $state->{ifup}) {
        delete $state->{ifup};
        $self->set_state($state);
    }
}

# Group: Other methods

sub _defaultGatewayCommand
{
    my ($self) = @_;

    my $row = $self->model('GatewayTable')->findValue(default => 1);
    unless ($row) {
        return undef;
    }
    my $ip = $row->valueByName('ip');
    my $iface = $row->valueByName('interface');

    # Skip gateway with unassigned address
    return undef unless $ip;

    my $method = $self->ifaceMethod($iface);

    my $if = new IO::Interface::Simple($iface);
    return undef unless $if->address;

    return "ip route add table default default via $ip dev $iface";
}

# Method: _notifyChangedIface
#
#   Notify network observers the change of a interface has taken place
#
# Parameters:
#   (Named)
#
#   name - interface's name
#   oldMethod - old method
#   newMethod - new method
#   force - force
#   action - 'prechange' or 'postchange'
sub _notifyChangedIface
{
    my ($self, %args) = @_;
    my $name = $args{name};
    my $oldMethod = $args{oldMethod};
    my $newMethod = $args{newMethod};
    my $force = $args{force};
    my $action = $args{action};

    my $global = EBox::Global->getInstance();
    my @observers = @{$global->modInstancesOfType('EBox::NetworkObserver')};
    foreach my $objs (@observers) {
            if ($action eq 'prechange') {
                if ($objs->ifaceMethodChanged($name, $oldMethod, $newMethod)) {
                    if ($force) {
                        $objs->freeIface($name);
                    } else {
                        throw EBox::Exceptions::DataInUse();
                    }
                }
            } else {
                $objs->ifaceMethodChangeDone($name);
            }
    }
}

# Method: importInterfacesFile
#
#   Parses /etc/network/interfaces and imports values
#   to the Zentyal network module configuration
#
sub importInterfacesFile
{
    my ($self) = @_;

    my $DEFAULT_IFACE = 'eth0';
    my $DEFAULT_GW_NAME = 'default';

    my @interfaces = @{$self->_readInterfaces()};
    foreach my $iface (@interfaces) {
        if ($iface->{name} =~ /^vlan/) {
            ($iface->{'vlan-raw-device'}) or
                die "vlan interface '$iface->{name}' needs a ".
                "raw-device declaration";
            $self->setIfaceTrunk($iface->{'vlan-raw-device'}, 1);
            my $vlan = $iface->{name};
            $vlan =~ s/^vlan//;
            $self->createVlan($vlan, undef, $iface->{'vlan-raw-device'});
        }
        if ($iface->{'method'} eq 'static') {
            $self->setIfaceStatic($iface->{'name'}, $iface->{'address'},
                    $iface->{'netmask'}, undef, 1);
            if ($iface->{'gateway'}){
                my $gwModel = $self->model('GatewayTable');
                my $defaultGwRow = $gwModel->find(name => $DEFAULT_GW_NAME);
                if ($defaultGwRow) {
                    EBox::info("Already a default gateway, keeping it");
                } else {
                    $gwModel->add(name      => $DEFAULT_GW_NAME,
                                  ip        => $iface->{'gateway'},
                                  interface => $iface->{'name'},
                                  default   => 1);
                }
            }
        } elsif ($iface->{'method'} eq 'dhcp') {
            $self->setIfaceDHCP($iface->{'name'}, 0, 1);
        }
    }

    my $resolverModel = $self->model('DNSResolver');
    $resolverModel->importSystemResolvers();
    my $searchDomainModel = $self->model('SearchDomain');
    $searchDomainModel->importSystemSearchDomain();

    $self->saveConfig();
}

sub _importDHCPAddresses
{
    my ($self) = @_;
    EBox::NetWrappers::clean_ifaces_list_cache();
    foreach my $iface (@{ $self->allIfaces() }) {
        if ($self->ifaceMethod($iface) eq 'dhcp') {
            my %addr;
            try {
                %addr = %{ iface_addresses_with_netmask($iface) };
            } catch {
                # ignore errors, just skip this interface;
            }
            if (not %addr) {
                next;
            }
            my ($address, $netmask) = each %addr;
            EBox::debug("_importDHCPAdress $iface $address $netmask");
            $self->setDHCPAddress($iface, $address, $netmask);
        }
    }
}

sub _readInterfaces
{
    my ($self) = @_;

    my $ifacesFH;
    unless (open($ifacesFH, INTERFACES_FILE)) {
        warn  "couldn't open " . INTERFACES_FILE;
        return [];
    }

    my @interfaces;
    my $iface;
    my @fields = qw/address netmask gateway vlan-raw-device/;

    for my $line (<$ifacesFH>) {
        $line =~ s/^\s+//g;
        my @toks = split (/\s+/, $line);
        next unless @toks;
        if ($toks[0] eq 'iface' and $toks[2] eq 'inet') {
            next if ($self->_ignoreIface($toks[1]));
            push (@interfaces, $iface) if ($iface);
            $iface = { name   => $toks[1],
                       method => $toks[3]
            };
        }

        if (grep((/^$toks[0]$/), @fields)) {
            $iface->{$toks[0]} = $toks[1];
        }
    }
    close ($ifacesFH);
    push (@interfaces, $iface) if ($iface);

    return \@interfaces;
}

# Check the IP  address is not a HA floating IP
sub _checkHAFloatingIPCollision
{
    my ($self, $iface, $address) = @_;

    my $global = EBox::Global->getInstance();

    if ($global->modExists('ha') and $global->modInstance('ha')->isEnabled()) {
        my $ha = $global->modInstance('ha');
        if ($ha->isFloatingIP($iface, $address)) {
            throw EBox::Exceptions::External("The IP: " . $address . " is already".
                    " a HA floating IP.");
        }
    }
}

# Flag the iface is up
# Only useful to ha by now
sub _flagIfUp
{
    my ($self, $ifups) = @_;

    if (@{$ifups}) {
        my $state = $self->get_state();
        $state->{ifup} = $ifups;
        $self->set_state($state);
    }
}

sub searchContents
{
    my ($self, $searchStringRe) = @_;
    my @matches;
    my ($modelMatches) = $self->_searchRedisConfKeys($searchStringRe);

    push @matches, @{ $self->_interfaceSearchMatch($searchStringRe) };
    push @matches, @{ $self->_vlanSearchMatch($searchStringRe) };

    push @matches, @{ $modelMatches };


    return \@matches;
}

sub _interfaceSearchMatch
{
    my ($self, $searchStringRe) = @_;
    my @matches;
    my $interfaces = $self->get('interfaces', {});
    while (my ($iface, $attrs) = each %{ $interfaces }) {
        my $ifMatchs = 0;
        if ($iface =~ m/$searchStringRe/) {
            $ifMatchs = 1;
        } else {
            while ( my($attrName, $attr) = each %{ $attrs}) {
                if ($attrName eq 'virtual') {
                    while (my ($vname, $vattrs) = each $attr) {
                        if ($vname =~ m/$searchStringRe/) {
                            $ifMatchs = 1;
                            last;
                        }
                        foreach my $vattrVal (values %{ $vattrs }) {
                            if ($vattrVal =~ m/$searchStringRe/) {
                                $ifMatchs = 1;
                                last;
                        }
                        }
                        if ($ifMatchs) {
                            last;
                        }
                    }
                } elsif ($attr =~ m/$searchStringRe/) {
                    $ifMatchs = 1;
                    last;
                }
            }
        }

        if ($ifMatchs) {
            my $ifName = $attrs->{alias} ? $attrs->{alias} : $iface;
            my $linkElements =  [
                {
                    title => $self->printableName(),
                },
                {
                    title => __('Interfaces'),
                    link => '/Network/Ifaces'
                },
                {
                    title => $ifName,
                    link => "/Network/Ifaces?iface=$iface"
                }
              ];
            my $match = {
                module => 'network',
                linkElements => $linkElements
               };
            push @matches, $match;
        }
    }

    return \@matches;
}

sub _vlanSearchMatch
{
    my ($self, $searchStringRe) = @_;
    my @matches;
    my $vlans = $self->get('vlans', {});
    foreach my $vlAttrs (values %{$vlans}) {
        my $vlanMatchs = 0;
        foreach my $attrVal (values %{$vlAttrs}) {
            if ($attrVal =~ m/$searchStringRe/) {
                $vlanMatchs = 1;
                last;
            }
        }

        if ($vlanMatchs) {
            my $linkElements =  [
                {
                    title => $self->printableName(),
                },
                {
                    title => __('Interfaces'),
                    link => '/Network/Ifaces'
                },
                {
                    title => $vlAttrs->{name},
                    link => "/Network/Ifaces?iface=" . $vlAttrs->{name}
                }
              ];
            my $match = {
                module => 'network',
                linkElements => $linkElements,
            };
            push @matches, $match;
        }
    }

    return \@matches;
}

1;
