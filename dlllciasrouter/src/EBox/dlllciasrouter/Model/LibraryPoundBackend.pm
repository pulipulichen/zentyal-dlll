package EBox::dlllciasrouter::Model::LibraryPoundBackend;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;

##
# 讀取LibraryToolkit
# @author Pulipuli Chen
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# ------------------------------------------------
# Date Setter


# 20150519 Pulipuli Chen
sub initDefaultPound
{
     my ($self) = @_;

    if ( !(-e '/etc/default/pound') ) {
        throw EBox::Exceptions::Internal("You have not install pound! Cannot found /etc/default/pound ");
    }

    my @nullParams = ();
    $self->parentModule()->writeConfFile(
        '/etc/default/pound',
        "dlllciasrouter/default-pound.mas",
        \@nullParams,
        { uid => '0', gid => '0', mode => '740' }
    );

    # ------------------
    # 確認是否存在
    my $poundCertFolder = "/etc/pound/cert";
    if (-d $poundCertFolder) {
      # ok. moving on.
    }
    else {
      EBox::Sudo::root("mkdir -p " . $poundCertFolder);
    }

    system('chmod 755 /etc/pound/cert/');
    system('chmod 755 /etc/letsencrypt/live/');

}

# ----------------------------------------------------

# 20150517 Pulipuli Chen
sub setUpdatePoundCfg
{
    my ($self) = @_;

      

      
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

      # ----------------------------
      # Back End
      # ----------------------------

      my ($domainHash, $domainHTTPSHash, $vmHash) = $self->buildDomainHash();

      # --------------------

      $self->writePoundConfig($domainHash, $domainHTTPSHash, $domainHTTPSHash);
      $self->updateVMIDConfig($vmHash);

      # --------------------

      # 20170731 Pulipuli Chen
      # 一併更新PoundSettings
      $self->getLoadLibrary("PoundSettings")->setUpdateCfg();
    
}   # sub setUpdatePoundCfg

sub buildDomainHash
{
  # Iterate over table
  #my @paramsArray = ();
  my ($self) = @_;

  my $domainHash = (); 
  my $domainHTTPSHash = (); 
  my $vmHash = ();
  my $i = 0;

  ($domainHash, $i) = $self->getTestServiceParam($domainHash, $i);
  ($domainHash, $vmHash, $i) = $self->getServiceParam("VEServer", $domainHash, $vmHash, $i, 0);
  ($domainHash, $vmHash, $i) = $self->getServiceParam("StorageServer", $domainHash, $vmHash, $i, 0);
  ($domainHash, $vmHash, $i) = $self->getServiceParam("VMServer", $domainHash, $vmHash, $i, 0);

  ($domainHTTPSHash) = $self->getLoadLibrary('LibrarySSLCert')->checkSSLCert($domainHash, $domainHTTPSHash);

  return ($domainHash, $domainHTTPSHash, $vmHash);
}

sub writePoundConfig
{
  my ($self, $domainHash, $domainHTTPSHash) = @_;

  # ----------------------------
  # 設定
  # ----------------------------

  my $settings = $self->getLoadLibrary('RouterSettings');

  my $port = $settings->value('port');
  my $portHTTPS = $settings->value('portHTTPS');
  my $alive = $settings->value('alive');

  my $timeout = $settings->value('timeout');
  my $primaryDomainName = $settings->value('primaryDomainName');
  
  my $address = $settings->getExtIPAddress();

  my $restarterIP;
  if ($settings->row->elementExists('restarterIP')) {
      $restarterIP = $settings->value('restarterIP');
  }
  my $restarterPort;
  if ($settings->row->elementExists('restarterPort')) {
      $restarterPort = $settings->value('restarterPort');
  }
  my $testDomainName;
  if ($settings->row->elementExists('testDomainName')) {
      $testDomainName = $settings->value('testDomainName');
  }

  # ----------------------------
  # 準備把值傳送到設定檔去
  # ----------------------------

  my @servicesParams = ();

  push(@servicesParams, 'address' => $address);
  push(@servicesParams, 'port' => $port);
  push(@servicesParams, 'portHTTPS' => $portHTTPS);
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
  push(@servicesParams, 'primaryDomainName' => $primaryDomainName);

  
  # ----------------------------
  # 轉址
  # ----------------------------

  # Iterate over table
  my @redirArray = $self->getURLRedirectParam();

  push(@servicesParams, 'redir' => \@redirArray);


  # ----------------------------
  # 取得certs
  # ----------------------------
  my @certs = $self->getPoundCerts();

  push(@servicesParams, 'certs' => \@certs);


  # ----------------------------
  # 寫入
  # ----------------------------
  $self->parentModule()->writeConfFile(
      '/etc/pound/pound.cfg',
      "dlllciasrouter/pound.cfg.mas",
      \@servicesParams,
      { uid => '0', gid => '0', mode => '644' }
  );
}

sub updateVMIDConfig
{
  my ($self, $vmHash) = @_;

  my $settings = $self->getLoadLibrary('RouterSettings');

  my $notifyEmail;
  if ($settings->row->elementExists('notifyEmail')) {
      $notifyEmail = $settings->value('notifyEmail');
  }
  my $senderEmail;
  if ($settings->row->elementExists('senderEmail')) {
      $senderEmail = $settings->value('senderEmail');
  }

  my @vmParams = ();
  push(@vmParams, 'vmHash' => $vmHash);
  push(@vmParams, 'notifyEmail' => $notifyEmail);
  push(@vmParams, 'senderEmail' => $senderEmail);
  $self->parentModule()->writeConfFile(
      '/etc/pound/vmid-config.php',
      #'/var/www/vmid-config.php',
      "dlllciasrouter/vmid-config.php.mas",
      \@vmParams,
      { uid => '0', gid => '0', mode => '770' }
  );
}

sub getServiceParam
{
    my ($self, $modName, $domainHash, $vmHash, $i, $certbotMode) = @_;

    my $libRedir = $self->getLoadLibrary('LibraryRedirect');
    my $lib = $self->getLibrary();

    my $services = $self->getLoadLibrary($modName);
    my @customizedDomainName = ();

    for my $id (@{$services->ids()}) {
        my $row = $services->row($id);
        
        #if ($row->valueByName('enabled') == 0)
        if ($lib->isEnable($row) == 0)
        {
            next;
        }

        my $domainNameValue = $row->valueByName('domainName');
        # throw EBox::Exceptions::External("test " . $domainNameValue);
        if ($self->isCustomizedDomainName($domainNameValue)) {
            push(@customizedDomainName, ($domainNameValue));
        }


        my $ipaddrValue = $row->valueByName('ipaddr');
        my $descriptionValue = $row->valueByName('description');
        #my $useTestLocalhost = $row->valueByName('useTestLocalhost');
        my $useTestLocalhost = 0;
        try {
          $useTestLocalhost = ($row->valueByName("vmIdentify") eq '127.0.0.1');
        } catch {
        };
        
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

        try {
            if ($row->valueByName("vmIdentify") eq '127.0.0.1') {
              $ipaddrValue = "127.0.0.1";
              $portValue = 888;
              $httpToHttpsValue = 0;
              $httpPortValue = 888;
            }
        } catch {
        };

        # -------------------------

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

                if ($self->isCustomizedDomainName($domainNameValue)) {
                    push(@customizedDomainName, ($domainNameValue));
                }
                
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

                if ($row->valueByName("vmIdentify") eq '127.0.0.1') {
                  $ipaddrValue = "127.0.0.1";
                  $portValue = 888;
                  $httpPortValue = 888;
                }

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

    $self->setRunCertbot(@customizedDomainName);

    return ($domainHash, $vmHash, $i);
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub getTestServiceParam
{
    my ($self, $domainHash, $i) = @_;

      my $settings = $self->getLoadLibrary('RouterSettings');

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

# -------------------------------------

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

# 20150519 Pulipuli Chen
sub getURLRedirectParam
{
    my ($self) = @_;

    my $redirect = $self->getLoadLibrary('URLRedirect');
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

# 20150519 Pulipuli Chen
sub getPoundCerts
{
    my ($self) = @_;

    opendir my $dir, "/etc/pound/cert" or die "Cannot open directory: $!";
    my @files = grep { /\.pem$/ } readdir $dir;
    closedir $dir;

    return @files;
}

sub end_by($){
    my $string = shift;
    if ($string =~ m/\.ma$/) {
        return 1;
    } else {
        return 0;
    }
}

sub isCustomizedDomainName
{
    my ($self, $domainName) = @_;

    # 先看看尾巴是不是主要domain
    my $settings = $self->getLoadLibrary('RouterSettings');
    my $primaryDomainName = $settings->value('primaryDomainName');

    #throw EBox::Exceptions::External("test [" . $domainName . '-' . $primaryDomainName .  ']');
    if ($primaryDomainName eq '') {
        return ($self->isDomainNameLinkToZentyal($domainName));
    }

    my $domainNameParent = $1 if ($domainName =~ /\.\s*(.+)$/);

    # throw EBox::Exceptions::External("test [" . $domainNameParent . ' - ' . $primaryDomainName .  ']');
    if ($domainNameParent eq $primaryDomainName) {
        return 0;
    }

    # 確認這個domain name對應的ip
    return ($self->isDomainNameLinkToZentyal($domainName));
}

sub resolveip
{
    my ($self, $domainName) = @_;

    #my $ip = qx{resolveip -s ${domainName}};
    my $ip = `dig @8.8.8.8.8 +short ${domainName}`;
    #$ip =~ s/^\s+|\s+$//g;

    return $ip;
}

sub isDomainNameLinkToZentyal
{
    my ($self, $domainName) = @_;

    my $domainNameIp = $self->resolveip($domainName);

    throw EBox::Exceptions::External("test [" . $domainName . ' - ' . $domainNameIp . ']');

    if ($domainNameIp eq '') {
        return 0;
    }

    
    #EBox::Sudo::root('echo "' . $domainName . '-' . $domainNameIp . '"');
    my $address = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();

    #throw EBox::Exceptions::External("test [" . $domainName . ' - ' . $domainNameIp . ' - '  . $address .  ']');

    return ($domainNameIp eq $address);
}

sub setRunCertbot
{
    my ($self, @customizedDomainName) = @_;

    my $scriptPath = '/etc/cron.monthly/run-certbot.sh';

    my $length = @customizedDomainName;
    if ($length == 0) {
        EBox::Sudo::root('rm -f ' . $scriptPath);
        return 1;
    }

    my $customizedDomainNameString = join ',', @customizedDomainName;

    my @params = ();
    push(@params, 'domainNamesList' => $customizedDomainNameString);

    $self->parentModule()->writeConfFile(
      $scriptPath,
      "dlllciasrouter/certbot/run-certbot.sh.mas",
      \@params,
      { uid => '0', gid => '0', mode => '770' }
    );

    #EBox::Sudo::root($scriptPath);
}

# -----------------------------------------------

1;
