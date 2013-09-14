package EBox::Pound;

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
                                      'text' => __('Back End')));
    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/Redirect',
                                      'text' => __('Redirect')));
    $folder->add(new EBox::Menu::Item('url' => 'Pound/View/DNS',
                                      'text' => __('DNS')));
    
    # 不要Port Forwarding了，留給Pound去設定就好                                  
    #$folder->add(new EBox::Menu::Item('url' => 'Pound/View/PortForwarding',
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

    # ----------------------------
    # 設定
    # ----------------------------

    my $settings = $self->model('Settings');
    my $port = $settings->value('port');
    my $alive = $settings->value('alive');
    my $enableError = $settings->value('enableError');
    my $error = $settings->value('error');
    my $file = "/etc/pound/error.html";

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
     if ($enableError == 1) {
        my $file = "/etc/pound/error.html";
        system('rm -f '.$file);
        system('wget ' . $error . ' -O '.$file);
         system('date > /home/test.log');
    }
    # ----------------------------
    # Back End
    # ----------------------------

    my $services = $self->model('PoundServices');

    # Iterate over table
    my @paramsArray = ();
    my $domainHash = ();
    my $i = 0;
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

        # ---------
        # 開始Hash

        my @backEndArray;
        if ( exists $domainHash->{$domainNameValue}  ) {
            # 如果Hash已經有了這個Domain Name
            @backEndArray = @{$domainHash->{$domainNameValue}};
        }

        my $backEnd = ();
        $backEnd->{ipaddrValue} = $ipaddrValue;
        $backEnd->{portValue} = $portValue;
        $backEnd->{descriptionValue} = $descriptionValue;
        $backEnd->{httpToHttpsValue} = $httpToHttpsValue;
        $backEnd->{httpsPortValue} = $httpsPortValue;

        $backEndArray[$#backEndArray+1] = $backEnd;

        $domainHash->{$domainNameValue} = \@backEndArray;

        # ----------
        $i++;

    }

    # ----------------------------
    # 轉址
    # ----------------------------

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

    # ----------------------------
    # 準備把值傳送到設定檔去
    # ----------------------------

    my @servicesParams = ();
    push(@servicesParams, 'address' => $address);
    push(@servicesParams, 'port' => $port);
    push(@servicesParams, 'alive' => $alive);
    push(@servicesParams, 'enableError' => $enableError);
    push(@servicesParams, 'error' => $error);
    push(@servicesParams, 'file' => $file);

    push(@servicesParams, 'services' => \@paramsArray);
    push(@servicesParams, 'domainHash' => $domainHash);

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
