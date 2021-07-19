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
sub loadLibrary
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
}

# ----------------------------------------------------

# 20150517 Pulipuli Chen
sub updatePoundCfg
{
    my ($self) = @_;

      # ----------------------------
      # 設定
      # ----------------------------

      my $settings = $self->loadLibrary('RouterSettings');

      # 設定SSH
      $self->parentModule()->setConfSSH($settings->value('adminPort'));

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

      ($domainHTTPSHash) = $self->loadLibrary('LibrarySSLCert')->checkSSLCert($domainHash, $domainHTTPSHash);

      # ----------------------------
      # 轉址
      # ----------------------------

      # Iterate over table
      my @redirArray = $self->getURLRedirectParam();

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
      push(@servicesParams, 'domainHTTPSHash' => $domainHTTPSHash);

      push(@servicesParams, 'redir' => \@redirArray);

      $self->parentModule()->writeConfFile(
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
      $self->parentModule()->writeConfFile(
          '/etc/pound/vmid-config.php',
          #'/var/www/vmid-config.php',
          "dlllciasrouter/vmid-config.php.mas",
          \@vmParams,
          { uid => '0', gid => '0', mode => '770' }
      );

      # --------------------

      # 20170731 Pulipuli Chen
      # 一併更新PoundSettings
      $self->loadLibrary("PoundSettings")->updateCfg();
    
}   # sub updatePoundCfg

sub getServiceParam
{
    my ($self, $modName, $domainHash, $vmHash, $i) = @_;

    my $libRedir = $self->loadLibrary('LibraryRedirect');
    my $lib = $self->getLibrary();

    my $services = $self->loadLibrary($modName);
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

      my $settings = $self->loadLibrary('RouterSettings');

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

    my $redirect = $self->loadLibrary('URLRedirect');
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

# -----------------------------------------------

1;
