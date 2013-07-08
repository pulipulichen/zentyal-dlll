package EBox::Apache2;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;

#my $CONFFILE = '/etc/ssh/sshd_config';
my $CONFFILE = '/etc/apache2/ports.conf';


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
        name => 'apache2',
        printableName => __('Apache2'),
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
        url => 'Apache2/View/Settings',
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
	{
            'name' => 'apache2',                                                
            'type' => 'init.d',                                                 
            'pidfiles' => ['/var/run/apache2.pid']
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

    my $settings = $self->model('Settings');
    my $port = $settings->value('listeningPort');

    my @params = (
        port => $port,
    );

    $self->writeConfFile(
        $CONFFILE,
        "apache2/service.conf.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
}

# Method: usedFiles
#
#   Override EBox::Module::Service::usedFiles
#
sub usedFiles
{
    return [
            {
              'file' => '/etc/apache2/ports.conf',
              'module' => 'apache2',
              'reason' => __('To configure the apache2 port')
            },
           ];
}

1;
