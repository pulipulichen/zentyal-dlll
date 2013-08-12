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
    my ($self, $root) = @_;

    my $item = new EBox::Menu::Item(
        url => 'Pound/Composite/Global',
        text => $self->printableName(),
        separator => 'Virtual Router',
        order => 0
    );

    $root->add($item);
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
        
        if ($row->valueByName('enabled') == 0) {
            next;
        }

        my $domainNameValue = $row->valueByName('domainName');
        my $ipaddrValue = $row->valueByName('ipaddr');
        my $descriptionValue = $row->valueByName('description');
        my $portValue = $row->valueByName('port');
        my $enbaledValue = $row->valueByName('enabled');
        my $httpToHttpsValue = $row->valueByName('httpToHttps');
        my $httpsPortValue = $services->getHTTPSextPort($row);

#        my @params = (
#            domainNameValue => $domainNameValue,
#            ipaddrValue => $ipaddrValue,
#            portValue => $portValue,
#            descriptionValue => $descriptionValue,
#            enbaledValue => $enbaledValue,
#            httpToHttpsValue => $httpToHttpsValue,
#            httpsPortValue => $httpsPortValue,
#        );

        push (@paramsArray, {
            domainNameValue => $domainNameValue,
            ipaddrValue => $ipaddrValue,
            portValue => $portValue,
            descriptionValue => $descriptionValue,
            enbaledValue => $enbaledValue,
            httpToHttpsValue => $httpToHttpsValue,
            httpsPortValue => $httpsPortValue,
        });
    }

    my $redirect = $self->model('Redirect');

    # Iterate over table
#    my @paramsArray = ();
#    for my $id (@{$services->ids()}) {
#        my $row = $services->row($id);
#        
#        if ($row->valueByName('enabled') == 0) {
#            next;
#        }
#
#        my $domainNameValue = $row->valueByName('domainName');
#        my $ipaddrValue = $row->valueByName('ipaddr');
#        my $descriptionValue = $row->valueByName('description');
#        my $portValue = $row->valueByName('port');
#        my $enbaledValue = $row->valueByName('enabled');
#        my $httpToHttpsValue = $row->valueByName('httpToHttps');
#        my $httpsPortValue = $services->getHTTPSextPort($row);

#        push (@paramsArray, {
#            domainNameValue => $domainNameValue,
#            ipaddrValue => $ipaddrValue,
#            portValue => $portValue,
#            descriptionValue => $descriptionValue,
#            enbaledValue => $enbaledValue,
#            httpToHttpsValue => $httpToHttpsValue,
#            httpsPortValue => $httpsPortValue,
#        });
#    }

    my $settings = $self->model('Settings');
#    my $address = $settings->value('address');
    my $port = $settings->value('port');

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
    push(@servicesParams, 'services' => \@paramsArray);

    $self->writeConfFile(
        $CONFFILE,
        "pound/pound.cfg.mas",
        \@servicesParams,
        { uid => '0', gid => '0', mode => '644' }
    );
}

1;
