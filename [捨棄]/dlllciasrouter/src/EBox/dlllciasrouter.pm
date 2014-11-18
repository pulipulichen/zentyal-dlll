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
#        url => 'Pound/Composite/Global',
#        text => $self->printableName(),
#        separator => 'Virtual Router',
#        order => 0
#    );

    #$root->add($item);

    my ($self, $root) = @_;

    my $folder = new EBox::Menu::Folder('name' => 'dlllciasrouter',
                                        'text' => "Router",
                                        'separator' => 'DLLL-CIAS',
                                        'order' => 0);

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/Settings',
                                      'text' => __('Settings')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/PoundServices',
                                      'text' => __('Back End')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/URLRedirect',
                                      'text' => __('URL Redirect')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/DNS',
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

    my $lib = $self->getLibrary();

    # ----------------------------
    # 設定
    # ----------------------------

    my $settings = $self->model('Settings');
    my $port = $settings->value('port');
    if (!defined $port) {
        $port = 80;
    }
    my $alive = $settings->value('alive');
    if (!defined $alive) {
        $alive = 30;
    }
    my $enableError = $settings->value('enableError');
    if (!defined $enableError) {
        $enableError = 0;
    }
    my $errorURL = $settings->value('error');
    my $file = "/etc/pound/error.html";
    my $fileTemp = "/tmp/error.html";
    #my $file = "/tmp/error.html";

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

     if ($enableError == 1 && defined $errorURL) {
        system('wget ' . $errorURL . ' -O '.$fileTemp);

        # 讀取
        #my $errorPage = system('cat '.$fileTemp);
        open FILE, "<".$fileTemp;
        my $errorPage = do { local $/; <FILE> };
        
        # 寫入
        my @errorPageParams = ();
        push(@errorPageParams, 'errorPage' => $errorPage);

        $self->writeConfFile(
            '/etc/pound/error.html',
            "dlllciasrouter/error.html.mas",
            \@errorPageParams,
            { uid => '0', gid => '0', mode => '740' }
        );

        unlink $fileTemp;
    }

    my $restarterIP = $settings->value('restarterIP');
    my $restarterPort = $settings->value('restarterPort');
    my $notifyEmail = $settings->value('notifyEmail');
    my $senderEmail = $settings->value('senderEmail');

    # ----------------------------
    # Back End
    # ----------------------------

    my $services = $self->model('PoundServices');
    my $libRedir = $self->model('LibraryRedirect');

    # Iterate over table
    my @paramsArray = ();
    my $domainHash = ();
    my $vmHash = ();
    my $i = 0;
    for my $id (@{$services->ids()}) {
        my $row = $services->row($id);
        
        #if ($row->valueByName('enabled') == 0)
        if ($lib->isEnable($row) == 0)
        {
            next;
        }

        my $domainNameValue = $row->valueByName('domainName');
        my $ipaddrValue = $row->valueByName('ipaddr');
        my $descriptionValue = $row->valueByName('description');
        my $portValue = $row->valueByName('port');
        my $httpToHttpsValue = $row->valueByName('httpToHttps');
        my $httpsPortValue = $libRedir->getHTTPSextPort($row);

        my $httpSecurityValue = $row->valueByName('redirHTTP_secure');
        my $httpPortValue = $libRedir->getHTTPextPort($row);
        
        my $emergencyValue = $row->valueByName('emergencyEnable');
        my $redirHTTP_enable = $row->valueByName('redirHTTP_enable');

        push (@paramsArray, {
            domainNameValue => $domainNameValue,
            ipaddrValue => $ipaddrValue,
            portValue => $portValue,
            descriptionValue => $descriptionValue,
            
            httpToHttpsValue => $httpToHttpsValue,
            httpsPortValue => $httpsPortValue,

            httpSecurityValue => $httpSecurityValue,
            httpPortValue => $httpPortValue,

            emergencyValue => $emergencyValue,
            redirHTTP_enable => $redirHTTP_enable,
        });

        # ---------
        # 開始Hash

        my @backEndArray;
        my $vmidConfig = $self->ipaddrToVMID($ipaddrValue);
        if ( exists $domainHash->{$domainNameValue}  ) {
            # 如果Hash已經有了這個Domain Name
            @backEndArray = @{$domainHash->{$domainNameValue}};
            $vmidConfig = $vmidConfig.",".$vmHash->{$domainNameValue};
        }

        my $backEnd = ();
        $backEnd->{ipaddrValue} = $ipaddrValue;
        $backEnd->{portValue} = $portValue;
        $backEnd->{descriptionValue} = $descriptionValue;
        $backEnd->{httpToHttpsValue} = $httpToHttpsValue;
        $backEnd->{httpsPortValue} = $httpsPortValue;

        $backEnd->{httpSecurityValue} = $httpSecurityValue;
        $backEnd->{httpPortValue} = $httpPortValue;

        $backEnd->{emergencyValue} = $emergencyValue;
        $backEnd->{redirHTTP_enable} = $redirHTTP_enable;

        $backEndArray[$#backEndArray+1] = $backEnd;

        $domainHash->{$domainNameValue} = \@backEndArray;
        $vmHash->{$domainNameValue} = $vmidConfig;

        # ----------
        $i++;

    }

    # ----------------------------
    # 轉址
    # ----------------------------

    my $redirect = $self->model('URLRedirect');

    # Iterate over table
    my @redirArray = ();
    for my $id (@{$redirect->ids()}) {
        my $row = $redirect->row($id);

        #if ($row->valueByName('enabled') == 0)
        if ($lib->isEnable($row) == 0)
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
    push(@servicesParams, 'errorURL' => $errorURL);
    push(@servicesParams, 'file' => $file);

    push(@servicesParams, 'restarterIP' => $restarterIP);
    push(@servicesParams, 'restarterPort' => $restarterPort);

    push(@servicesParams, 'services' => \@paramsArray);
    push(@servicesParams, 'domainHash' => $domainHash);

    push(@servicesParams, 'redir' => \@redirArray);
    

    $self->writeConfFile(
        $CONFFILE,
        "dlllciasrouter/pound.cfg.mas",
        \@servicesParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    my @nullParams = ();

    $self->writeConfFile(
        '/etc/apache2/ports.conf',
        "dlllciasrouter/ports.conf.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    $self->writeConfFile(
        '/etc/default/pound',
        "dlllciasrouter/default-pound.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '740' }
    );

    my @vmParams = ();
    push(@vmParams, 'vmHash' => $vmHash);
    push(@vmParams, 'notifyEmail' => $notifyEmail);
    push(@vmParams, 'senderEmail' => $senderEmail);
    $self->writeConfFile(
        '/etc/pound/vmid-config.php',
        #'/var/www/vmid-config.php',
        "dlllciasrouter/vmid-config.php.mas",
        \@vmParams,
        { uid => '0', gid => '0', mode => '770' }
    );
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
