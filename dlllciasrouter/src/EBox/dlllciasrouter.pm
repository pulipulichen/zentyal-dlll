package EBox::dlllciasrouter;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;

#use LWP::Simple;

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
        name => 'dlllciasrouter',
        printableName => __('DLLL-CIAS Router'),
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
#        url => 'dlllciasrouter/Composite/Global',
#        text => $self->printableName(),
#        separator => 'Virtual Router',
#        order => 0
#    );

    #$root->add($item);

    my ($self, $root) = @_;

    my $folder = new EBox::Menu::Folder('name' => 'dlllciasrouter',
                                        'text' => $self->printableName(),
                                        'separator' => 'Virtual Router',
                                        'order' => 0);

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/Settings',
                                      'text' => __('Settings')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/PoundServices',
                                      'text' => __('Back End')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/URLRedirect',
                                      'text' => __('URL Redirect')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/DNS',
                                      'text' => __('DNS')));
    
    # 不要Port Forwarding了，留給dlllciasrouter去設定就好                                  
    #$folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/PortForwarding',
    #                                  'text' => __('Port Forwarding')));

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

    my $lib = $self->getLibrary();

}

sub getLibrary
{
    my ($self) = @_;
    return $self->model("PoundLibrary");
}

sub ipaddrToVMID
{
    my ($self, $ipaddr) = @_;

    # 變成ID前幾碼
    my @parts = split('\.', $ipaddr);
    my $partC = $parts[2];
    my $partD = $parts[3];
    
    # 重新組合
        $partC = substr($partC, -1);
    
        if (length($partD) == 1) {
            $partD = "0" . $partD;
        }
        else {
            $partC = substr($partC, -2);
        }
     my $portHeader = $partC.$partD;
     
     return $portHeader;
}

1;
