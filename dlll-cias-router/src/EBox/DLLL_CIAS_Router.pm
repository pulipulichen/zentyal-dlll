package EBox::DLLL_CIAS_Router;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;

my $CONFFILE = '/tmp/FIXME.conf';

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
        name => 'dlll-cias-router',
        printableName => __('DLLL_CIAS_Router'),
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
        url => 'DLLL_CIAS_Router/View/Settings',
        text => $self->printableName(),
        separator => 'Core',
        order => 1
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
#        {
#            name => 'service',
#            type => 'init.d',
#            pidfiles => ['/var/run/service.pid']
#        },
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

    my $settings = $self->model('Settings');
    my $booleanValue = $settings->value('booleanField');
    my $textValue = $settings->value('textField');

    my @params = (
        boolean => $booleanValue,
        text => $textValue,
    );

    $self->writeConfFile(
        $CONFFILE,
        "dlll-cias-router/service.conf.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
}

1;
