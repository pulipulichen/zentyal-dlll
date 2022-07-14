package EBox::dlllciasrouter;

use base qw(EBox::Module::Service);

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::Sudo;
use EBox::CGI::SaveChanges;

use EBox::Exceptions::Internal;
# use EBox::Sudo;

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

    my $initLock = '/opt/dlllciasrouter_init.txt';
    if (-e $initLock) {
        return 1;
    }

    my $log = EBox::logger;
    $log->info("dlllciasrouter_init 1");
    # $self->model("LibraryToolkit")->show_exceptions(' ( dlllciasrouter->dlllciasrouter_init() part.0 )');

    # 初始化安裝
    try {
        $self->model("LibraryServiceLighttpd")->initLighttpd();
        $self->model("LibraryServiceApache")->initApache();
        $self->model("LibraryCrontab")->initRootCrontab();

        my $libStorage = $self->model("LibraryStorage");
        $libStorage->initNFSClient();
        $libStorage->initMooseFS();
        $libStorage->startMooseFS();
        $libStorage->initNFSServer();
        $libStorage->startNFSServer();

        $log->info("dlllciasrouter_init 1.5");

        my $LibraryTestLocalhost = $self->model("LibraryTestLocalhost");
        $LibraryTestLocalhost->startupTestServer();

        my $libHTML = $self->model("LibraryHTML");
        $libHTML->setPublicCSS();
        $libHTML->initTemplateMas();
        $libHTML->chmodJS();
        $libHTML->copyPackageIcons();
        $libHTML->copyTextSetter();
        
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.1 )');
    };

    $log->info("dlllciasrouter_init 2");
    try {
        $self->model("LibraryPoundBackend")->initDefaultPound();

        $self->model("LibraryLogs")->enableLogs();
        $self->model("LibraryDomainName")->initDefaultDomainName();
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.2 )');
    };

    $log->info("dlllciasrouter_init 3");

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

    $log->info("dlllciasrouter_init 4");

    try {
        $self->model('LibraryMAC')->initAdministorNetworkMember();
        $self->model('LibraryMAC')->initWorkplaceNetworkMember();
        $self->model('LibraryMAC')->initBlackListMember();
        $self->model("LibraryMAC")->initDHCPfixedIP();
    } catch {
        $self->model("LibraryToolkit")->show_exceptions($_ . ' ( dlllciasrouter->dlllciasrouter_init() part.4 )');
    };

    $log->info("dlllciasrouter_init 5");

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

    $log->info("dlllciasrouter_init 6");
    EBox::Sudo::root("touch " . $initLock);
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

    my $daemonsLock = '/opt/dlllciasrouter_daemons.txt';
    

    my $log = EBox::logger;
    # $log->info("_daemons 1")
    # $log->info("_daemons 2");
    my @daemons = [];
    if (-e $daemonsLock) {
        return \@daemons;
    }

    $self->dlllciasrouter_init();

    my $i = 0;

    if (-e '/var/run/apache2.pid') {
        $daemons[$i] = {
                name => 'apache2',
                type => 'init.d',
                pidfiles => ['/var/run/apache2.pid']
            };
        $i++;
    }

    $log->info("_daemons 3");
    
    $daemons[$i] = {
        'name' => 'pound',
        'type' => 'init.d',
        'pidfiles' => ['/var/run/pound.pid']
    };
    $i++;

    $log->info("_daemons 4");

    $daemons[$i] = {
        'name' => 'lighttpd',
        'type' => 'init.d',
        'pidfiles' => ['/var/run/lighttpd.pid']
    };
    $i++;

    $log->info("_daemons 5");

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

    EBox::Sudo::root("touch " . $daemonsLock);

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

    my $daemonsLock = '/opt/dlllciasrouter_daemons.txt';
    EBox::Sudo::root("rm -f " . $daemonsLock);

    my $log = EBox::logger;
    $log->info("_setConf 1");

    #  更新錯誤訊息
    $self->model("LibraryPoundErrorMessage")->updatePoundErrorMessage();

    $log->info("_setConf 1.5");

    $self->model("LibraryPoundBackend")->setUpdatePoundCfg();

    $log->info("_setConf 1.7");

    $self->model("LibraryServiceXRDP")->setXRDPCfg();

    $log->info("_setConf 2");
    
    # 設定SSH
    $self->model("LibraryServiceSSH")->setConfSSHAdminPort();

    $log->info("_setConf 3");

    if (0) {
      
      my $libStorage = $self->model("LibraryStorage");
      my $mountChanged = $libStorage->updateMountServers();

      # 先完全不使用moosefs
      if ($self->model("MfsSetting")->value("mfsEnable") == 1) {
          # 20150528 測試使用，先關閉
          if ($mountChanged == 1) {
              $libStorage->restartMooseFS();
              $libStorage->remountChunkserver();
          }

          my $exportChanged =  $libStorage->updateNFSExports();
          if ($exportChanged == 1) {
              $libStorage->restartNFSServer();
          }
      }
      else {
          $libStorage->stopMount();
      }
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

# 20150519 Pulipuli Chen
# 讀取指定的Model
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->model($library);
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

# 20150529 Pulipuli Chen
sub checkConfigChange
{
    my ($self, $file, $compname, $params, $defaults) = @_;

    my $log = EBox::logger;
    $log->info("checkConfigChange 1");

    my $changed = 0;

    my $originVersion = "";
    if (-e $file) {
       $originVersion = read_file( $file ) ;
    }

    $log->info("checkConfigChange 2");

    $self->writeConfFile(
        $file,
        $compname,
        $params,
        $defaults
    );

    $log->info("checkConfigChange 3");

    my $writtenVersion = read_file( $file ) ;

    if ($originVersion ne $writtenVersion) {
        $changed = 1;
    }

    $log->info("checkConfigChange 4");

    return $changed;
}


# 20181027 Pulipuli Chen
sub saveModuleChange
{
  #system('sudo chmod +x /usr/share/zentyal/www/dlllciasrouter/local_scripts/SaveAllModules.pm');
  #system('sudo /usr/share/zentyal/www/dlllciasrouter/local_scripts/SaveAllModules.pm');
  EBox::Sudo::root('chmod +x /usr/share/zentyal/www/dlllciasrouter/local_scripts/SaveAllModules.pm')
  # EBox::Sudo::root('/usr/share/zentyal/www/dlllciasrouter/local_scripts/SaveAllModules.pm');
}
1;
