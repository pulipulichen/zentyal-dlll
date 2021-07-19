package EBox::dlllciasrouter;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;
use EBox::CGI::SaveChanges;

use EBox::Exceptions::Internal;
use EBox::Sudo;

use Try::Tiny;
use File::Slurp;

use POSIX;

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
    
    # 20150519* Pulipuli Chen
    # 不可以在此初始化，這會導致無法安裝
    #$self->dlllciasrouter_init();

    return $self;
}

sub dlllciasrouter_init
{
    my ($self) = @_;

    # 初始化安裝
    try {
        $self->initLighttpd();
        $self->initApache();
        $self->initRootCrontab();
        $self->initNFSClient();
        $self->initMooseFS();
        $self->startMooseFS();
        $self->initNFSServer();
        $self->startNFSServer();
        $self->setPublicCSS();

        $self->initTemplateMas();
        $self->chmodJS();
        $self->copyPackageIcons();
        $self->copyTextSetter();
        
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.1 )');
    };

    try {
        $self->initDefaultPound();

        $self->model("LibraryLogs")->enableLogs();
        $self->model("LibraryDomainName")->initDefaultDomainName();
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.2 )');
    };

    try {
        $self->model("LibraryService")->getPoundService();
        $self->model("LibraryService")->getZentyalAdminService();
        $self->model("LibraryService")->getDNSServerService();
        $self->model("LibraryService")->getNFSService();
        $self->model("LibraryService")->getMFSService();

        $self->model("RouterSettings")->initServicePort();
        $self->model("MfsSetting")->initServicePort();
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.3 )');
    };

    try {
        $self->model('LibraryMAC')->initAdministorNetworkMember();
        $self->model('LibraryMAC')->initWorkplaceNetworkMember();
        $self->model('LibraryMAC')->initBlackListMember();
        $self->model("LibraryMAC")->initDHCPfixedIP();
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.4 )');
    };

    try {
        $self->model("LibraryFilter")->initZentyalAdminFilter();
        $self->model("LibraryFilter")->initDNSServerFilter();
        $self->model("LibraryFilter")->initNFSFilter();
        $self->model("LibraryFilter")->initMFSFilter();
        $self->model("LibraryFilter")->initPoundFilter();
        $self->model("LibraryFilter")->initPoundLogFilter();
        $self->model("LibraryFilter")->initBlackListFilter();

    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.5 )');
    };
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

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/StorageServerComposite',
                                      'text' => __('Storage')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/VEServerSetting',
                                      'text' => __('VE Main Server')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/VEServerComposite',
                                      'text' => __('Virtual Environment')));

    
    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/VMServerComposite',
                                      'text' => __('Virtual Machine')));

    
    #$folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/PoundServices',
    #                                  'text' => __('Pound Back End')));
    #$folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/Composite/OtherRoutingSettingComposite',
    #                                  'text' => __('Other Routing Setting')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/DNS',
                                      'text' => __('DNS')));

    $folder->add(new EBox::Menu::Item('url' => 'dlllciasrouter/View/URLRedirect',
                                      'text' => __('URL Redirect')));
    
    
    $root->add($folder);
}

sub _daemons
{
    my ($self) = @_;

    $self->dlllciasrouter_init();

    my @daemons = [];
    my $i = 0;

    if (-e '/var/run/apache2.pid') {
        $daemons[$i] = {
                name => 'apache2',
                type => 'init.d',
                pidfiles => ['/var/run/apache2.pid']
            };
        $i++;
    }
    
    $daemons[$i] = {
        'name' => 'pound',
        'type' => 'init.d',
        'pidfiles' => ['/var/run/pound.pid']
    };
    $i++;

    $daemons[$i] = {
        'name' => 'lighttpd',
        'type' => 'init.d',
        'pidfiles' => ['/var/run/lighttpd.pid']
    };
    $i++;

    # 20150528 Pulipuli Chen 加入MooseFS的控制
    
    #$daemons[$i] = {
    #            name => 'moosefs-master',
    #            type => 'init.d',
    #            pidfiles => ['/var/lib/mfs/.mfsmaster.lock']
    #        };
    #$i++;

    #$daemons[$i] = {
    #            name => 'moosefs-cgiserv',
    #            type => 'init.d',
    #            pidfiles => ['/var/lib/mfs/.mfscgiserv.lock']
    #        };
    #$i++;

    #$daemons[$i] = {
    #            name => 'moosefs-chunkserver',
    #            type => 'init.d',
    #            pidfiles => ['/var/lib/mfs/.mfschunkserver.lock']
    #        };
    #$i++;

    #$daemons[$i] = {
    #            name => 'moosefs-metalogger',
    #            type => 'init.d',
    #            pidfiles => ['/var/lib/mfs/.mfsmetalogger.lock']
    #        };
    #$i++;
    
    # -------------------

    #$daemons[$i] = {
    #            name => 'nfs-kernel-server',
    #            type => 'init.d',
    #            pidfiles => ['/var/run/nfsd.pid']
    #        };
    #$i++;

    return \@daemons;
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

    #  更新錯誤訊息
    $self->updatePoundErrorMessage();
    $self->updatePoundCfg();
    $self->updateXRDPCfg();
    my $mountChanged = $self->updateMountServers();
    if ($self->model("MfsSetting")->value("mfsEnable") == 1) {
        # 20150528 測試使用，先關閉
        if ($mountChanged == 1) {
            $self->restartMooseFS();
            $self->remountChunkserver();
        }

        my $exportChanged =  $self->updateNFSExports();
        if ($exportChanged == 1) {
            $self->restartNFSServer();
        }
    }
    else {
        $self->stopMount();
    }
    
    # 20181028 試著加入儲存設定看看？
    #EBox::CGI::SaveChanges->saveAllModulesAction();
    #$self->saveModuleChange();
    # 20181028 還是不行，放棄
}

sub getLibrary
{
    my ($self) = @_;
    return $self->model("LibraryToolkit");
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

##
# 20150519 Pulipuli Chen
##
sub updatePoundErrorMessage
{
    my ($self) = @_;

    my $mod = $self->model('ErrorMessage');

    my @params = ();

    my $address = $self->model('LibraryNetwork')->getExternalIpaddr();
    push(@params, 'baseURL' => "http://" . $address . ":888");

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
sub updatePoundCfg
{
    my ($self) = @_;

    # ----------------------------
    # 設定
    # ----------------------------

    my $settings = $self->model('RouterSettings');

    # 設定SSH
    $self->setConfSSH($settings->value('adminPort'));

    my $port = $settings->value('port');
    my $alive = $settings->value('alive');

    my $timeout = $settings->value('timeout');
    #my $timeout = 1;    # 20150517 測試用，記得要移除

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

    my $address = $settings->getExtIPAddress();

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

    my $testDomainName;
    if ($settings->row->elementExists('testDomainName')) {
        $testDomainName = $settings->value('testDomainName');
    }

    # ----------------------------
    # Back End
    # ----------------------------

    # Iterate over table
    #my @paramsArray = ();
    my $domainHash = (); 
    my $domainHTTPSHash = (); 
    my $vmHash = ();
    my $i = 0;

    ($domainHash, $i) = $self->getTestServiceParam($domainHash, $i);
    ($domainHash, $vmHash, $i) = $self->getServiceParam("VEServer", $domainHash, $vmHash, $i);
    ($domainHash, $vmHash, $i) = $self->getServiceParam("StorageServer", $domainHash, $vmHash, $i);
    ($domainHash, $vmHash, $i) = $self->getServiceParam("VMServer", $domainHash, $vmHash, $i);

    #($domainHTTPSHash) = $self->checkSSLCert($domainHash, $domainHTTPSHash);

    #my $check1 = get "https://script.google.com/macros/s/AKfycbw1gAhCzBvcQ08K-B8r7Ed4SyW0iUBltws8tmC0qrNWG71ARClI0hthNoaEuV6VRmyZUg/exec?q=http://testb.dlll.nccu.edu.tw";
    #my $check2 = get("https://script.google.com/macros/s/AKfycbw1gAhCzBvcQ08K-B8r7Ed4SyW0iUBltws8tmC0qrNWG71ARClI0hthNoaEuV6VRmyZUg/exec?q=https://blog.pulipuli.info");
    #my $check3 = get("https://script.google.com/macros/s/AKfycbw1gAhCzBvcQ08K-B8r7Ed4SyW0iUBltws8tmC0qrNWG71ARClI0hthNoaEuV6VRmyZUg/exec?q=http://blog.pulipuli.info");
    #my $check1 = system("wget -qO- https://script.google.com/macros/s/AKfycbw1gAhCzBvcQ08K-B8r7Ed4SyW0iUBltws8tmC0qrNWG71ARClI0hthNoaEuV6VRmyZUg/exec?q=https://blog.pulipuli.info");
    my $check1 = `wget -qO- https://script.google.com/macros/s/AKfycbw1gAhCzBvcQ08K-B8r7Ed4SyW0iUBltws8tmC0qrNWG71ARClI0hthNoaEuV6VRmyZUg/exec?q=https://ttttttblog.pulipuli.info`;

    # ----------------------------
    # 轉址
    # ----------------------------

    # Iterate over table
    my @redirArray = $self->getURLRedirectParam();

    # ----------------------------
    # 準備把值傳送到設定檔去
    # ----------------------------

    my @servicesParams = ();

    push(@servicesParams, 'check1' => $check1);
    push(@servicesParams, 'check2' => 200);
    push(@servicesParams, 'check3' => 200);

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
    push(@servicesParams, 'domainHTTPSHash' => $domainHTTPSHash);

    push(@servicesParams, 'redir' => \@redirArray);
    
    $self->writeConfFile(
        '/etc/pound/pound.cfg',
        "dlllciasrouter/pound.cfg.mas",
        \@servicesParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    # --------------------

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

    # --------------------

    # 20170731 Pulipuli Chen
    # 一併更新PoundSettings
    $self->model("PoundSettings")->updateCfg();

}   # sub updatePoundCfg

# 20170303 Pulipuli Chen
sub updateXRDPCfg
{
    my ($self) = @_;
    my @servicesParams = ();

    my $settings = $self->model('RouterSettings');

    my $xrdpPort = $settings->value('xrdpPort');
    push(@servicesParams, 'xrdpPort' => $xrdpPort);

    $self->writeConfFile(
        '/etc/xrdp/xrdp.ini',
        "dlllciasrouter/xrdp.ini.mas",
        \@servicesParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    EBox::Sudo::root("/etc/init.d/xrdp restart");
}   # sub updateXRDPCfg

sub getServiceParam
{
    my ($self, $modName, $domainHash, $vmHash, $i) = @_;

    my $libRedir = $self->model('LibraryRedirect');
    my $lib = $self->getLibrary();

    my $services = $self->model($modName);
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
        my $httpToHttpsValue = 0;
        if ($redirPound_scheme eq 'http') {
            $httpToHttpsValue = 0;
        }
        elsif ($redirPound_scheme eq 'https') {
            #$httpToHttpsValue = 1;
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
                    #$httpToHttpsValue = 1;
                    $httpToHttpsValue = 0;
                }
                else {
                    next;
                }
                $httpsPortValue = $libRedir->getServerMainPort($ipaddrValue);
                $httpSecurityValue = $dnRow->valueByName('redirPOUND_secure');
                $httpPortValue = $httpsPortValue;
                #$httpPortValue = $dnRow->valueByName('port');
                #$httpsPortValue = $httpPortValue;
                $portValue = $dnRow->valueByName('port');

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
    }   # for my $id (@{$services->ids()}) {}

    return ($domainHash, $vmHash, $i);
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub getTestServiceParam
{
    my ($self, $domainHash, $i) = @_;

      my $settings = $self->model('RouterSettings');

      my $domainNameValue = $settings->value('testDomainName');
      #printf("test domain name: " . $domainNameValue);
      if ($domainNameValue ne '') {
        my $backEnd = ();
        my @backEndArray;
        $backEnd->{ipaddrValue} = '0.0.0.0';
        $backEnd->{portValue} = 888;
        $backEnd->{descriptionValue} = 'test';
        $backEnd->{httpToHttpsValue} = 0;
        $backEnd->{httpsPortValue} = 0;

        $backEnd->{httpSecurityValue} = 0;
        $backEnd->{httpPortValue} = 888;

        $backEnd->{emergencyValue} = 0;
        $backEnd->{redirHTTP_enable} = 0;

        $backEndArray[$#backEndArray+1] = $backEnd;

        $domainHash->{$domainNameValue} = \@backEndArray;

        $i++;
      }

    return ($domainHash, $i);
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub checkSSLCert
{
  my ($self, $domainHash, $domainHTTPSHash) = @_;

  # 跑迴圈，看每個資料

  # 測試有沒有已經存在的cert

    # 測試能不能連線

      # 如果可以連線，則建立cert

      #($domainHTTPSHash) = $self->setupSSLCert($domainHTTPSHash, $domainNameValue)
      
  # 檢查看看有沒有過期 (必須是距離上次2個月內)
  
  # 

  return ($domainHTTPSHash);
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub setupSSLCert
{
  my ($self, $domainHTTPSHash, $domainNameValue) = @_;

  # 則建立cert

  # 記錄上次更新的時間
  
  # 加入 $domainHTTPSHash

  return ($domainHTTPSHash);
}

# 20150519 Pulipuli Chen
sub getURLRedirectParam
{
    my ($self) = @_;

    my $redirect = $self->model('URLRedirect');
    my $lib = $self->getLibrary();

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

    return @redirArray;
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

sub initLighttpd
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

# 20150519 Pulipuli Chen
sub setConfSSH
{
    my ($self, $port) = @_;
    #return;
    #my $port = $self->model("RouterSettings")->value("sshPort");

    my @params = (
        "port" => $port
    );
    $self->writeConfFile(
        '/etc/ssh/sshd_config',
        "dlllciasrouter/sshd_config.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    EBox::Sudo::root("service ssh restart");
}

# 20150519 Pulipuli Chen
sub initApache
{
     my ($self) = @_;

    if (-e '/etc/apache2/ports.conf') {

        my @nullParams = ();
        $self->writeConfFile(
            '/etc/apache2/ports.conf',
            "dlllciasrouter/ports.conf.mas",
            \@nullParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }
}

##
# 初始化排程工作
# 20170815 Pulipuli Chen
##
sub initRootCrontab
{
     my ($self) = @_;

    #if (-e '/etc/crontab') {

        # ------------------------

        my $dirPath = "/root/dlllciasrouter";

        if (! -d $dirPath) {
            system('sudo mkdir -p ' . $dirPath);
        }

        # ------------------------

        my $settings = $self->model('RouterSettings');
        my @backupParams = ();

        my $extIP = $self->model('LibraryNetwork')->getExternalIpaddr();
        my $port = $self->model('RouterSettings')->value('webadminPort');
        my $date = POSIX::strftime( "%A, %B %d, %Y", localtime());
        # my $date = strftime "%a %b %e %H:%M:%S %Y", gmtime;
        # printf("date and time - $date\n");
        # DateTime->now->ymd;

        my $backupMailAddress = $settings->value('backupMailAddress');
        push(@backupParams, 'backupMailAddress' => $backupMailAddress);

        my $backupMailSubject = $settings->value('backupMailSubject');
        $backupMailSubject =~ s/\{IP\}/$extIP/g;
        $backupMailSubject =~ s/\{PORT\}/$port/g;
        push(@backupParams, 'backupMailSubject' => $backupMailSubject);

        my $backupMailBody = $settings->value('backupMailBody');
        # my $backupMailBody = "Zentyal backup (DLLL-CIAS Router) from {IP}";
        # my $IP = "192.168.11.101";
        
        # print $backupMailBody;
        $backupMailBody =~ s/\{DATE\}/$date/g;
        $backupMailBody =~ s/\{IP\}/$extIP/g;
        $backupMailBody =~ s/\{PORT\}/$port/g;
        push(@backupParams, 'backupMailBody' => $backupMailBody);
        
        push(@backupParams, 'backupLimit' => $settings->value('backupLimit'));
        $self->writeConfFile(
            '/root/dlllciasrouter/backup-zentyal.sh',
            "dlllciasrouter/backup-zentyal.sh.mas",
            \@backupParams,
            { uid => '0', gid => '0', mode => '777' }   #這邊權限必須是7才能執行
        );

        # -------------------------------------

        my @startupParams = ();

        push(@startupParams, 'mailAddress' => $backupMailAddress);

        my $startupMailSubject = $settings->value('startupMailSubject');
        $startupMailSubject =~ s/\{IP\}/$extIP/g;
        $startupMailSubject =~ s/\{PORT\}/$port/g;
        push(@startupParams, 'mailSubject' => $startupMailSubject);

        my $startupMailBody = $settings->value('startupMailBody');
        $startupMailBody =~ s/\{DATE\}/$date/g;
        $startupMailBody =~ s/\{IP\}/$extIP/g;
        $startupMailBody =~ s/\{PORT\}/$port/g;
        my $veDomainName = $self->model('VEServerSetting')->value("domainName");
        if( length $veDomainName ) {
          $startupMailBody =~ s/\{VEDomainName\}/$veDomainName/g;
        }

        push(@startupParams, 'mailBody' => $startupMailBody);

        $self->writeConfFile(
            '/root/dlllciasrouter/startup-message.sh',
            "dlllciasrouter/startup-message.sh.mas",
            \@startupParams,
            { uid => '0', gid => '0', mode => '777' }   #這邊權限必須是7才能執行
        );
    #}  # if (-e '/etc/crontab') {
}

# 20150519 Pulipuli Chen
sub initDefaultPound
{
     my ($self) = @_;

    if ( !(-e '/etc/default/pound') ) {
        throw EBox::Exceptions::Internal("You have not install pound! Cannot found /etc/default/pound ");
    }

    my @nullParams = ();
    $self->writeConfFile(
        '/etc/default/pound',
        "dlllciasrouter/default-pound.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '740' }
    );
}

# 20150519 Pulipuli Chen
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->model($library);
}

# 20150527 Pulipuli Chen
sub initMooseFS
{
    my ($self) = @_;

    my @params = ();
    $self->writeConfFileOnce(
        '/var/lib/mfs/metadata.mfs',
        "dlllciasrouter/mfs/lib/metadata.mfs.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    # 變更權限 
    system('chown mfs:mfs  /var/lib/mfs/metadata.mfs');

    # ---------------------------------------------------------

    #$self->writeConfFile(
    #    '/etc/default/moosefs-cgiserv',
    #    "dlllciasrouter/mfs/default/moosefs-cgiserv.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);
    #$self->writeConfFile(
    #    '/etc/default/moosefs-chunkserver',
    #    "dlllciasrouter/mfs/default/moosefs-chunkserver.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);
    #$self->writeConfFile(
    #    '/etc/default/moosefs-master',
    #    "dlllciasrouter/mfs/default/moosefs-master.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);
    #$self->writeConfFile(
    #    '/etc/default/moosefs-metalogger',
    #    "dlllciasrouter/mfs/default/moosefs-metalogger.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);

    # --------------------------------------------

    $self->writeConfFileOnce(
        '/etc/mfs/mfschunkserver.cfg',
        "dlllciasrouter/mfs/etc/mfschunkserver.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->writeConfFileOnce(
        '/etc/mfs/mfsmaster.cfg',
        "dlllciasrouter/mfs/etc/mfsmaster.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->writeConfFileOnce(
        '/etc/mfs/mfsmetalogger.cfg',
        "dlllciasrouter/mfs/etc/mfsmetalogger.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->writeConfFileOnce(
        '/etc/mfs/mfsmount.cfg',
        "dlllciasrouter/mfs/etc/mfsmount.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->writeConfFileOnce(
        '/etc/mfs/mfstopology.cfg',
        "dlllciasrouter/mfs/etc/mfstopology.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    if (! -e '/etc/mfs/mfsexports.cfg') {
        my @mfsParams = ();
        $self->writeConfFileOnce(
            '/etc/mfs/mfsexports.cfg',
            "dlllciasrouter/mfs/etc/mfsexports.cfg.mas",
            \@mfsParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }

    if (! -e '/etc/exports') {
        my @nfsParams = ();
        push(@nfsParams, 'paths' => []);
        
        $self->writeConfFileOnce(
            '/etc/exports',
            "dlllciasrouter/nfs-server/exports.mas",
            \@nfsParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }

    if (! -e '/etc/mfs/mfshdd.cfg') {
        my @hddParams = ();
        my $mfsMod = $self->model("MfsSetting");
        push(@hddParams, 'size' => $mfsMod->value("localhostSize"));
        push(@hddParams, 'paths' => []);
        $self->writeConfFileOnce(
            '/etc/mfs/mfshdd.cfg',
            "dlllciasrouter/mfs/etc/mfshdd.cfg.mas",
            \@hddParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }
}

# 20150529 Pulipuli Chen
sub startMooseFS
{    
    my ($self) = @_;

    # mfsEnable
    my $mfsMod = $self->model("MfsSetting");
    if ($mfsMod->value("mfsEnable") == 0) {
      return 0;
    }

    try {
        if (readpipe("sudo netstat -plnt | grep '/mfsmaster'") eq "") {
            system('sudo service moosefs-master start');
            system('sudo service moosefs-metalogger start');
        }
        if (readpipe("sudo netstat -plnt | grep '/mfschunkserve'") eq "") {
            system('sudo service moosefs-chunkserver start');
            #system("echo 'chunkserver start a'");
        }
        if (readpipe("sudo netstat -plnt | grep ':9425'") eq "") {
            system('sudo service moosefs-cgiserv start');
        }
        if (readpipe("sudo netstat -plnt | grep '/mfsmount'") eq "") {
            system('sudo mfsmount');
        }
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . '( dlllciasrouter->startMooseFS() )');
    };
}

# 20150528 Pulipuli Chen
sub initNFSServer
{
    my ($self) = @_;

    my @params = ();

    $self->writeConfFile(
        '/etc/default/nfs-kernel-server',
        "dlllciasrouter/nfs-server/nfs-kernel-server.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    $self->writeConfFile(
        '/etc/default/nfs-common',
        "dlllciasrouter/nfs-server/nfs-common.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
}

# 20150529 Pulipuli Chen
sub startNFSServer
{
    if (readpipe("sudo netstat -plnt | grep '/rpc.mountd'") eq "") {
        system('sudo service nfs-kernel-server start');
    }
}

# 20150528 Pulipuli Chen
sub initNFSClient
{
    my ($self) = @_;

    if (! -e '/opt/mfschunkservers/nfs-mount.sh') {
        my @mountParams = ();
        push(@mountParams, 'servers' => []);
        $self->writeConfFileOnce(
            '/opt/mfschunkservers/nfs-mount.sh',
            "dlllciasrouter/nfs-client/nfs-mount.sh.mas",
            \@mountParams,
            { uid => '0', gid => '0', mode => '755' }
        );
    }

    my @params = ();
    $self->writeConfFileOnce(
        '/opt/mfschunkservers/nfs-umount.sh',
        "dlllciasrouter/nfs-client/nfs-umount.sh.mas",
        \@params,
        { uid => '0', gid => '0', mode => '755' }
    );

    $self->writeConfFileOnce(
        '/opt/mfschunkservers/mfs-clear-metaid.sh',
        "dlllciasrouter/nfs-client/mfs-clear-metaid.sh.mas",
        \@params,
        { uid => '0', gid => '0', mode => '755' }
    );
}

sub writeConfFileOnce
{
    my ($self, $file, $compname, $params, $defaults) = @_;
    if (! -e $file) {
        $self->writeConfFile(
            $file,
            $compname,
            $params,
            $defaults
        );
    }
}

##
# 20150528 Pulipuli Chen
# 把NFS掛載到本機伺服器上
##
sub updateNFSExports
{
    # 從這邊取得資料出來
    #my $expMod = $self->model("ExportSettings");
    my ($self) = @_;

    my $mod = $self->model("ExportsSetting");

    my $dirs = ();
    # 第一次迴圈，先取出資料出來
    for my $id (@{$mod->ids()}) {
        my $row = $mod->row($id);

        # /mnt/mfs/pve 10.6.0.0/24(rw,fsid=0,async,no_root_squash,subtree_check)
        my $host = $row->valueByName("host");
        my $ro = $row->valueByName("readOnly");
        if ($ro == 1) {
            $ro = "ro";
        }
        else {
            $ro = "rw";
        }
        my $async = $row->valueByName("async");
        if ($async == 1) {
            $async = "async";
        }
        else {
            $async = "sync";
        }
        my $squash = $row->valueByName("squash");
        
        my $hostConfig = $host."(".$ro.",fsid=0,".$async.",".$squash.",subtree_check".")\t";

        # ---------------------

        my $dir = $row->valueByName("dir");
        my $dirPath = "/mnt/mfs/".$dir;

        if (! -d $dirPath) {
            system('sudo mkdir -p ' . $dirPath);
        }

        if ( ! exists $dirs->{$dir} ) {
            $dirs->{$dir} = $dirPath."\t";
        }
        $dirs->{$dir} = $dirs->{$dir} . $hostConfig;
    }

    my @paths = [];    # 稍後要從StorageServer取出細節
    my $i = 0;
    # 第二次迴圈
    while (my ($dir, $path) = each(%$dirs)) {
        $paths[$i] = $path;
        $i++;
    }
    
    my $pveDirPath = "/mnt/mfs/pve";
    if (! -d $pveDirPath) {
        system('sudo mkdir -p ' . $pveDirPath);
    }

    my @nfsParams = ();
    # 從這邊取得資料出來
    #my $expMod = $self->model("ExportSettings");
    push(@nfsParams, 'paths' => @paths);
    #push(@nfsParams, 'paths' => []);
    
    my $nfsChanged = $self->checkConfigChange(
        '/etc/exports',
        "dlllciasrouter/nfs-server/exports.mas",
        \@nfsParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    # 20150529 本來是要修改的……後來還是算了吧
    my @mfsParams = ();
    my $mfsChanged = $self->checkConfigChange(
        '/etc/mfs/mfsexports.cfg',
        "dlllciasrouter/mfs/etc/mfsexports.cfg.mas",
        \@mfsParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    return ($nfsChanged == 1 || $mfsChanged == 1 );
}

##
# 20150528 Pulipuli Chen
##
sub updateMountServers
{
    my ($self) = @_;

    #system('sudo /opt/mfschunkservers/nfs-umount.sh');

    my @servers = [];    # 稍後要從StorageServer取出細節
    my @paths = [];    # 稍後要從StorageServer取出細節
    my $i = 0;
    my $mod = $self->model('StorageServer');
    for my $id (@{$mod->ids()}) {
        my $row = $mod->row($id);

        if ($row->valueByName("mountEnable") == 0 || !defined($row->valueByName("mountPath")) ) {
            next;
        }

        my $ipaddr = $row->valueByName("ipaddr");
        my $type = $row->valueByName("mountType");
        my $option = $row->valueByName("mountPath");
        if ($type eq "cifs") {
            my $username = $row->valueByName("cifsUsername");
            my $password = $row->valueByName("cifsPassword");
            $option = 'username="'.$username.'",password="'.$password.'" //' . $ipaddr . $option;
        }
        elsif ($type eq "nfs") {
            $option = $ipaddr . ":" . $option;
        }
        
        # 如果沒有目錄，則新增目錄
        my $path = "/opt/mfschunkservers/" . $ipaddr;
        if (!-d $path) {
            system('sudo mkdir -p ' . $path);
            system('sudo chown mfs:mfs ' . $path);
        }
        my $mfsPath = $path . "/mfs";

        # mount -t cifs -o username="Username",password="Password" //10.6.1.1/mnt/smb /opt/mfschunkservers/10.6.1.1
        my $conf = "mount -t " . $type . " " . $option . " " . $path;
        $servers[$i] = $conf;
        $paths[$i] = $mfsPath;

        # 此處進行掛載
        system('sudo ' + $conf + " &");
        
        my $isMounted = readpipe("mountpoint " . $path); #10.6.1.1 is not a mountpoint
        # 建立掛載後的路徑 
        if ($isMounted eq $path . " is a mountpoint" && !-d $mfsPath) {
            system('sudo mkdir -p ' . $mfsPath);
            system('sudo chown mfs:mfs ' . $mfsPath);
        }

        $i++;
    }   # for my $id (@{$mod->ids()}) {}

    # -----------------------------------

    my $mountChanged = 0;

    my @mountParams = ();
    push(@mountParams, 'servers' => @servers);

    
    #$self->writeConfFile(
    my $nfsmountChanged = $self->checkConfigChange(
        '/opt/mfschunkservers/nfs-mount.sh',
        "dlllciasrouter/nfs-client/nfs-mount.sh.mas",
        \@mountParams,
        { uid => '0', gid => '0', mode => '755' }
    );

    system('sudo /opt/mfschunkservers/nfs-mount.sh');

    # -------------------------------------

    my @hddParams = ();
    my $mfsMod = $self->model("MfsSetting");
    push(@hddParams, 'size' => $mfsMod->value("localhostSize"));
    push(@hddParams, 'paths' => @paths);

    
    #$self->writeConfFile(
    my $mfshddChanged = $self->checkConfigChange(
        '/etc/mfs/mfshdd.cfg',
        "dlllciasrouter/mfs/etc/mfshdd.cfg.mas",
        \@hddParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    if ($nfsmountChanged == 1 || $mfshddChanged == 1) {
        $mountChanged = 1;
    }

    return $mountChanged;
    #system('sudo mfsmount');
}

# 20150529 Pulipuli Chen
sub checkConfigChange
{
    my ($self, $file, $compname, $params, $defaults) = @_;

    my $changed = 0;

    my $originVersion = "";
    if (-e $file) {
       $originVersion = read_file( $file ) ;
    }

    $self->writeConfFile(
        $file,
        $compname,
        $params,
        $defaults
    );

    my $writtenVersion = read_file( $file ) ;

    if ($originVersion ne $writtenVersion) {
        $changed = 1;
    }

    return $changed;
}

# 20150528 Pulipuli Chen
sub restartMooseFS
{
    system('sudo service moosefs-master restart');
    system('sudo service moosefs-metalogger restart');
    system('sudo service moosefs-cgiserv restart');
}

# 20150528 Pulipuli Chen
sub remountChunkserver
{
    system('sudo service moosefs-chunkserver stop');
    system('sudo /opt/mfschunkservers/nfs-umount.sh');
    #system('sudo /opt/mfschunkservers/nfs-mount.sh');
    system('sudo service moosefs-chunkserver start');
    #system("echo 'chunkserver start b'");
    if (readpipe("sudo netstat -plnt | grep '/mfschunkserve'") eq "") {
        # 修復後重新掛載
        system('sudo /opt/mfschunkservers/mfs-clear-metaid.sh');
        
        system('sudo service moosefs-chunkserver start');
        #system("echo 'chunkserver start c'");
    }
    system('sudo mfsmount');
}

# 20150528 Pulipuli Chen
sub restartNFSServer
{
    #system('sudo service nfs-kernel-server restart');
    system('sudo exportfs -ar');
}

# 20150528 Pulipuli Chen
sub stopMount
{
    system('sudo service nfs-kernel-server stop');

    system('sudo service moosefs-cgiserv stop');
    system('sudo service moosefs-chunkserver stop');
    system('sudo service moosefs-master stop');
    system('sudo service moosefs-metalogger stop');
    system('sudo umount /mnt/mfs');

    system('sudo service moosefs-chunkserver stop');
    system('sudo /opt/mfschunkservers/nfs-umount.sh');
}

##
# 設定templates的MAS檔案
# 20170816 Pulipuli Chen
## 
sub initTemplateMas
{
    # dlllciasrouter/templates/ajax/setter/textareaSetter.mas
    system('sudo cp -f /usr/share/zentyal/www/dlllciasrouter/templates/ajax/setter/*.mas /usr/share/zentyal/templates/ajax/setter/');
}

##
# 設定js的權限
# 20170817 Pulipuli Chen
## 
sub chmodJS
{
    # dlllciasrouter/templates/ajax/setter/textareaSetter.mas
    system('sudo chmod 777 /usr/share/zentyal/www/dlllciasrouter/js/*.js');
}

# 20181027 Pulipuli Chen
sub setPublicCSS
{
    my ($self, $port) = @_;
    my @params = (
    );
    $self->writeConfFile(
        '/var/lib/zentyal/dynamicwww/css/public.css',
        "dlllciasrouter/public.css.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    EBox::Sudo::root("service ssh restart");
}

# 20181027 Pulipuli Chen
sub copyPackageIcons
{
  system('sudo cp /usr/share/zentyal/www/dlllciasrouter/images/package-icons/*.png /usr/share/zentyal/www/images/package-icons/');
}

# 20181028 Pulipuli Chen
sub copyTextSetter
{
  system('sudo cp -f /usr/share/zentyal/www/dlllciasrouter/local_scripts/textSetter.mas /usr/share/zentyal/templates/ajax/setter/');
}

# 20181027 Pulipuli Chen
sub saveModuleChange
{
  system('sudo chmod +x /usr/share/zentyal/www/dlllciasrouter/local_scripts/SaveAllModules.pm');
  system('sudo /usr/share/zentyal/www/dlllciasrouter/local_scripts/SaveAllModules.pm');
}
1;
