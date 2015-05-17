package EBox::dlllciasrouter;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;
use EBox::CGI::SaveChanges;

use EBox::Exceptions::Internal;

use Try::Tiny;

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
    $self->{inited} = 0;
    
    return $self;
}

sub dlllciasrouter_init
{
    my ($self) = @_;

    if ($self->{inited} == 1) {
        return;
    } 

    # 初始化安裝
    $self->setupLighttpd();
    $self->model("LibraryNetwork")->setupInternalIface();
    $self->model("LibraryMAC")->setupDHCPfixedIP();
    $self->model('LibraryMAC')->setupAdministorNetworkMember();
    $self->model("LibraryDomainName")->setupDefaultDomainName();
    $self->model('LibraryRedirect')->setupZentyalRedirect();

    $self->{inited} = 1;
}

sub menu
{
    my ($self, $root) = @_;

    my $folder = new EBox::Menu::Folder('name' => 'dlllciasrouter',
                                        'text' => $self->printableName(),
                                        #'separator' => 'DLLL-CIAS Router',
                                        'icon' => 'squid',
                                        'tag' => 'system',
                                        'order' => 1);

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/SettingComposite',
                                      'text' => __('Settings')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/VEServerComposite',
                                      'text' => __('Virtual Environment Servers')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/StorageServerComposite',
                                      'text' => __('Storage Servers')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/VMServerComposite',
                                      'text' => __('Virtual Machine Servers')));

    
    #$folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/PoundServices',
    #                                  'text' => __('Pound Back End')));
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/OtherRoutingSettingComposite',
                                      'text' => __('Other Routing Setting')));
    #$folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/URLRedirect',
    #                                  'text' => __('URL Redirect')));
    #$folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/DNS',
    #                                  'text' => __('DNS')));
    
    $root->add($folder);
}

sub _daemons
{
    my ($self) = @_;

    my $daemons;

    if (-e '/var/run/apache2.pid') {
        $daemons = [{
                name => 'pound',
                type => 'init.d',
                pidfiles => ['/var/run/pound.pid']
            }, 
            {
                name => 'lighttpd',
                type => 'init.d',
                pidfiles => ['/var/run/lighttpd.pid']
            }, 
            {
                name => 'apache2',
                type => 'init.d',
                pidfiles => ['/var/run/apache2.pid']
            }
        ];
    }
    else {
        $daemons = [{
                name => 'pound',
                type => 'init.d',
                pidfiles => ['/var/run/pound.pid']
            },
            {
                name => 'lighttpd',
                type => 'init.d',
                pidfiles => ['/var/run/lighttpd.pid']
            }];
    }
    
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

    my $settings = $self->model('RouterSettings');
    my $port = $settings->value('port');
    my $alive = $settings->value('alive');

    #my $timeout = $settings->value('timeout');
    my $timeout = 1;    # 20150517 測試用，記得要移除

    #my $enableError = $settings->value('enableError');
    #my $enableError = 1;
    #my $errorURL = "https://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/error_page/error_example.html";
    #my $errorURL = '/usr/share/zentyal/www/dlllciasrouter';
    #if ($settings->row()->elementExists('error') 
    #        && defined($settings->value('error')) 
    #        && $settings->value('error') ne '') {
    #    $errorURL = $settings->value('error');
    #}
    #my $file = "/etc/pound/error.html";
    #my $fileTemp = "/tmp/error.html";
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

    #  更新錯誤訊息
    $self->updateErrorMessage();

    my $restarterIP;
    if ($settings->row->elementExists('restarterIP')) {
        $restarterIP = $settings->value('restarterIP');
    }
    my $restarterPort;
    if ($settings->row->elementExists('restarterPort')) {
        $restarterPort = $settings->value('restarterPort');
    }
    my $notifyEmail;
    if ($settings->row->elementExists('notifyEmail')) {
        $notifyEmail = $settings->value('notifyEmail');
    }
    my $senderEmail;
    if ($settings->row->elementExists('senderEmail')) {
        $senderEmail = $settings->value('senderEmail');
    }

    # ----------------------------
    # Back End
    # ----------------------------

    my $services = $self->model('VMServer');
    my $libRedir = $self->model('LibraryRedirect');

    # Iterate over table
    #my @paramsArray = ();
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

        # -----------------------------
        my $portValue = $row->valueByName('port');
        #my $httpToHttpsValue = $row->valueByName('httpToHttps');
        my $redirPound_scheme = $row->valueByName('redirPOUND_scheme');
        my $httpToHttpsValue;
        if ($redirPound_scheme eq 'http') {
            $httpToHttpsValue = 0;
        }
        elsif ($redirPound_scheme eq 'https') {
            $httpToHttpsValue = 1;
        }
        else {
            next;
        }
        my $httpsPortValue = $libRedir->getServerMainPort($ipaddrValue);
        my $httpSecurityValue = $row->valueByName('redirPOUND_secure');
        my $httpPortValue = $httpsPortValue;

        # -----------------------------
        
        my $emergencyValue = $row->valueByName('emergencyEnable');
        my $redirHTTP_enable = $row->valueByName('redirHTTP_enable');

        #push (@paramsArray, {
        #    domainNameValue => $domainNameValue,
        #    ipaddrValue => $ipaddrValue,
        #    portValue => $portValue,
        #    descriptionValue => $descriptionValue,
        #    
        #    httpToHttpsValue => $httpToHttpsValue,
        #    httpsPortValue => $httpsPortValue,

        #    httpSecurityValue => $httpSecurityValue,
        #    httpPortValue => $httpPortValue,

        #    emergencyValue => $emergencyValue,
        #    redirHTTP_enable => $redirHTTP_enable,
        #});

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


        # -------------------------------
        # 取得otherDomainNames
        if ($row->elementExists('otherDomainName')) {
            my $otherDN = $row->subModel('otherDomainName');
            for my $dnId (@{$otherDN->ids()}) {
                my $dnRow = $otherDN->row($dnId);
                my $enable = $lib->isEnable($dnRow);
                if ($enable == 0) {
                    next;
                }
                my $domainNameValue = $dnRow->valueByName("domainName");
                
                $redirPound_scheme = $dnRow->valueByName('redirPOUND_scheme');
                if ($redirPound_scheme eq 'http') {
                    $httpToHttpsValue = 0;
                }
                elsif ($redirPound_scheme eq 'https') {
                    $httpToHttpsValue = 1;
                }
                else {
                    next;
                }
                $httpsPortValue = $libRedir->getServerMainPort($ipaddrValue);
                $httpSecurityValue = $dnRow->valueByName('redirPOUND_secure');
                $httpPortValue = $httpsPortValue;

                # -----------------

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

            }   # for my $dnId (@{$otherDN->ids()}) {
        }   # if ($row->elementExists('otherDomainName')) {
        


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
    push(@servicesParams, 'timeout' => $timeout);
    #push(@servicesParams, 'enableError' => $enableError);
    #push(@servicesParams, 'errorURL' => $errorURL);
    #push(@servicesParams, 'file' => $file);

    push(@servicesParams, 'restarterIP' => $restarterIP);
    push(@servicesParams, 'restarterPort' => $restarterPort);

    #push(@servicesParams, 'services' => \@paramsArray);
    push(@servicesParams, 'domainHash' => $domainHash);

    push(@servicesParams, 'redir' => \@redirArray);
    
    $self->writeConfFile(
        $CONFFILE,
        "dlllciasrouter/pound.cfg.mas",
        \@servicesParams,
        { uid => '0', gid => '0', mode => '644' }
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


    # ----------------------------
    # 設定pound自動啟動跟apache
    # ----------------------------
    my @nullParams = ();

    if (-e '/etc/apache2/ports.conf') {
        $self->writeConfFile(
            '/etc/apache2/ports.conf',
            "dlllciasrouter/ports.conf.mas",
            \@nullParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }

    if ( !(-e '/etc/default/pound') ) {
        throw EBox::Exceptions::Internal("You have not install pound! Cannot found /etc/default/pound ");
    }

    $self->writeConfFile(
        '/etc/default/pound',
        "dlllciasrouter/default-pound.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '740' }
    );

    $self->dlllciasrouter_init();
    #EBox::CGI::SaveChanges->saveAllModulesAction();
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

sub updateErrorMessage
{
    my ($self) = @_;

    my $mod = $self->model('ErrorMessage');

    my @params = ();

    my $address = $self->model('LibraryNetwork')->getExternalIpaddr();
    push(@params, 'baseURL' => "http://" . $address . ":88");

    push(@params, 'websiteTitle' => $mod->value('websiteTitle'));
    push(@params, 'homeText' => $mod->value('homeText'));
    push(@params, 'homeURL' => $mod->value('homeURL'));
    push(@params, 'aboutText' => $mod->value('aboutText'));
    push(@params, 'aboutURL' => $mod->value('aboutURL'));    
    push(@params, 'contactText' => $mod->value('contactText'));
    push(@params, 'contactEMAIL' => $mod->value('contactEMAIL'));

    my $errorMessage = $mod->value('errorMessage');
    my $libEnc = $self->model("LibraryEncoding");
    $errorMessage = $libEnc->unescapeFromUtf16($errorMessage);
    push(@params, 'errorMessage' => $errorMessage);

    $self->writeConfFile(
        '/etc/pound/error.html',
        "dlllciasrouter/error.html.mas",
        \@params,
        { uid => '0', gid => '0', mode => '777' }
    );

    $self->writeConfFile(
        '/usr/share/zentyal/www/dlllciasrouter/css/styles.css',
        "dlllciasrouter/styles.css.mas",
        \@params,
        { uid => '0', gid => '0', mode => '777' }
    );
}

# 20150517 Pulipuli Chen
sub initInstall
{
    my ($self, $packageName) = @_;

    my $poundInstalled = readpipe('dpkg --get-selections | grep -v deinstall | grep ' . $packageName);

    #throw EBox::Exceptions::External('poundInstalled: ['.$poundInstalled . ']');
    if (!defined($poundInstalled) || $poundInstalled eq '') {
        system('sudo apt-get -y --force-yes install ' . $packageName);
    }
}

sub setupLighttpd
{
    my ($self, $packageName) = @_;

    my @params = ();
    $self->writeConfFile(
        '/etc/lighttpd/lighttpd.conf',
        "dlllciasrouter/lighttped.conf.mas",
        \@params,
        { uid => '0', gid => '0', mode => '744' }
    );

    # 變更 /usr/share/zentyal/www/dlllciasrouter 權限 
    system('chmod 744  /usr/share/zentyal/www/dlllciasrouter');

}

1;
