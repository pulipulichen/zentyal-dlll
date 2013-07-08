package EBox::SSH;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;

my $CONFFILE = '/etc/ssh/sshd_config';

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
        name => 'ssh',
        printableName => __('SSH'),
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
        url => 'SSH/View/Settings',
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
            'name' => 'ssh',                                               
            'type' => 'init.d',                                                 
            'pidfiles' => ['/var/run/sshd.pid']
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
        "ssh/service.conf.mas",
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
              'file' => '/etc/ssh/sshd_config',
              'module' => 'ssh',
              'reason' => __('To configure the ssh port')
            },
           ];
}

1;
