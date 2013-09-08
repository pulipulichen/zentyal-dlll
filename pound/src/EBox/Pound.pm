package EBox::Pound;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;

my $CONFFILE = '/etc/pound/pound.cfg';

# Method: _create
#
# Overrides:
#
#       <Ebox::Module::Base::_create>
#
sub _create
{
    my $class = shift;

    my $self = $class->SUPER::_create(
        name => 'pound',
        printableName => __('Reverse Proxy'),
        @_
    );

    bless ($self, $class);

    return $self;
}

# Method: menu
#
# Overrides:
#
#       <EBox::Module::menu>
#
sub menu
{
#    my ($self, $root) = @_;

#   my $item = new EBox::Menu::Item(
#        url => 'Pound/Composite/Global',
#        text => $self->printableName(),
#        separator => 'Virtual Router',
#        order => 0
#    );

    #$root->add($item);

    my ($self, $root) = @_;

    my $folder = new EBox::Menu::Folder('name' => 'Pound',
                                        'text' => $self->printableName(),
                                        'separator' => 'Virtual Router',
                                        'order' => 0);

    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/Settings',
                                      'text' => __('Settings')));
    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/PoundServices',
                                      'text' => __('Pound')));
    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/Redirect',
                                      'text' => __('Redirect')));
    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/DNS',
                                      'text' => __('DNS')));
    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/PortForwarding',
                                      'text' => __('Port Forwarding')));

    $root->add($folder);
}

# Method: _daemons
#
# Overrides:
#
#       <EBox::Module::Service::_daemons>
#
sub _daemons
{
    my $daemons = [
# FIXME: here you can list the daemons to be managed by the module
#        for upstart daemons only the 'name' attribute is needed
#
        {
            name => 'pound',
            type => 'init.d',
            pidfiles => ['/var/run/pound.pid']
        },
        {
            name => 'apache2',
            type => 'init.d',
            pidfiles => ['/var/run/apache2.pid']
        }
    ];

    return $daemons;
}

# Method: _setConf
#
# Overrides:
#
#       <EBox::Module::Base::_setConf>
#
sub _setConf
{
    my ($self) = @_;

    my $services = $self->model('PoundServices');

    # Iterate over table
    my @paramsArray = ();
    for my $id (@{$services->ids()}) {
        my $row = $services->row($id);
        
        if ($row->valueByName('enabled') == 0)
        {
            next;
        }

        my $domainNameValue = $row->valueByName('domainName');
        my $ipaddrValue = $row->valueByName('ipaddr');
        my $descriptionValue = $row->valueByName('description');
        my $portValue = $row->valueByName('port');
        my $httpToHttpsValue = $row->valueByName('httpToHttps');
        my $httpsPortValue = $services->getHTTPSextPort($row);

        push (@paramsArray, {
            domainNameValue => $domainNameValue,
            ipaddrValue => $ipaddrValue,
            portValue => $portValue,
            descriptionValue => $descriptionValue,
            httpToHttpsValue => $httpToHttpsValue,
            httpsPortValue => $httpsPortValue,
        });
    }

    my $redirect = $self->model('Redirect');

    # Iterate over table
    my @redirArray = ();
    for my $id (@{$redirect->ids()}) {
        my $row = $redirect->row($id);

        if ($row->valueByName('enabled') == 0)
        {
            next;
        }

        my $domainNameValue = $row->valueByName('domainName');
        my $urlValue = $row->valueByName('url');

        push (@redirArray, {
            domainNameValue => $domainNameValue,
            urlValue => $urlValue,
        });
    }

    my $settings = $self->model('Settings');
    my $port = $settings->value('port');
    my $alive = $settings->value('alive');

    my $address = "127.0.0.1";
    if ($settings->value("address") eq "address_extIface")
    {
        my $network = EBox::Global->modInstance('network');
        foreach my $if (@{$network->ExternalIfaces()}) {
            if ($network->ifaceIsExternal($if)) {
                $address = $network->ifaceAddress($if);
            }
        }
    }
    else
    {
        $address = $settings->value("address");
    }

    my @servicesParams = ();
    push(@servicesParams, 'address' => $address);
    push(@servicesParams, 'port' => $port);
    push(@servicesParams, 'alive' => $alive);
    push(@servicesParams, 'services' => \@paramsArray);
    push(@servicesParams, 'redir' => \@redirArray);

    $self->writeConfFile(
        $CONFFILE,
        "pound/pound.cfg.mas",
        \@servicesParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    my @nullParams = ();

    $self->writeConfFile(
        '/etc/apache2/ports.conf',
        "pound/ports.conf.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    $self->writeConfFile(
        '/etc/default/pound',
        "pound/default-pound.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '740' }
    );
}

1;
