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
        printableName => __('Pound'),
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
        separator => 'Infrastructure',
        order => 421
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

    my $services = $self->model('Services');

    # Iterate over table
    my @paramsArray = ();
    for my $id (@{$services->ids()}) {
        my $row = $services->row($id);
        
        my $domainNameValue = $row->valueByName('domainName');
        my $ipaddrValue = $row->valueByName('ipaddr');
        my $descriptionValue = $row->valueByName('description');
        my $portValue = $row->valueByName('port');
        my $enbaledValue = $row->valueByName('enabled');

        my @params = (
            domainNameValue => $domainNameValue,
            ipaddrValue => $ipaddrValue,
            portValue => $portValue,
            descriptionValue => $descriptionValue,
            enbaledValue => $enbaledValue,
        );

        push (@paramsArray, {
            domainNameValue => $domainNameValue,
            ipaddrValue => $ipaddrValue,
            portValue => $portValue,
            descriptionValue => $descriptionValue,
            enbaledValue => $enbaledValue,
        });
    }

    my $settings = $self->model('Settings');
    my $address = $settings->value('address');
    my $port = $settings->value('port');


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
