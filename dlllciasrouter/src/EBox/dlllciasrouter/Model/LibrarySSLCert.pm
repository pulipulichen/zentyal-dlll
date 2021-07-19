package EBox::dlllciasrouter::Model::LibrarySSLCert;

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


# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub checkSSLCert
{
  my ($self, $domainHash, $domainHTTPSHash) = @_;

  # 測試用
  if (1) {
    #return ($domainHTTPSHash);
  }

  try {

    # https://script.google.com/macros/s/AKfycbzn1vBi_yGBZwxiNUMqZEwXjc3qmwaiRCAstfrRw26R2_3HVzmT00RlHF5Po039hWNBHA/exec?q=https://blog.pulipuli.info

    my $modified = 0;

    # 跑迴圈，看每個資料
    if (length($domainHash)) {
      while (my ($domainNameValue, $backEndArray) = each ($domainHash)) {  	
        #system("echo '[!] " . $domainNameValue . "'");

        if ($self->checkSSLCertExists($domainNameValue) == 1) {
          ($domainHTTPSHash) = $self->cloneBackendHTTPtoHTTPS($domainHash, $domainHTTPSHash, $domainNameValue);
          next;
        }

        if ($self->checkSSLCertAvailable($domainNameValue) == 0) {
          next;
        }

        if ($modified == 0) {
          $modified = 1;
          if ($self->setupSSLCertSwitchToLighttpd($domainNameValue) == 0) {
            $self->getLibrary()->show_exceptions($_ . ' ( setupSSLCertSwitchToLighttpd failed )');
          }
        }
        #next;

        my $result = $self->setupSSLCert($domainNameValue);
        if ($result == 1) {
          ($domainHTTPSHash) = $self->cloneBackendHTTPtoHTTPS($domainHash, $domainHTTPSHash, $domainNameValue);
        }
      }
    }

    if ($modified == 1) {
      $self->setupSSLCertSwitchToPound();
    }
  } catch {
      $self->getLibrary()->show_exceptions($_ . ' ( checkSSLCert )');
  };
  return ($domainHTTPSHash);
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub checkSSLCertExists
{
  my ($self, $domainNameValue) = @_;
  
  # 測試有沒有已經存在的cert
  my $certfile = "/etc/pound/cert/" . $domainNameValue . ".pem";
  if (-e $certfile) {

    # 檢查看看有沒有過期 (必須是距離上次2個月內)
    my $epoch_timestamp = (stat($certfile))[9];
    my $epoc = time();
    my $intervalDays = ($epoc - $epoch_timestamp) / 60 / 60 / 24;
    #my $timestamp       = localtime($epoch_timestamp);
    if ($intervalDays > 60) {
      system("echo 'out date'");
      return 0;
    }
    else {
      system("echo 'existed'");
      return 1;
    }
  }
  system("echo 'not existed'");
  return 0;
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub checkSSLCertAvailable
{
  my ($self, $domainNameValue) = @_;
  
  #$domainNameValue = "blog.pulipuli.info";
  my $testURL = "https://script.google.com/macros/s/AKfycbzn1vBi_yGBZwxiNUMqZEwXjc3qmwaiRCAstfrRw26R2_3HVzmT00RlHF5Po039hWNBHA/exec";
  my $result = `wget -qO- ${testURL}?q=http://${domainNameValue}:888/certbot/`;
  #my $result = `wget -qO- ${testURL}?q=http://${domainNameValue}/`;
  #my $result = "pass. Could you only check on start?";

  system("echo '[!] " . $domainNameValue . " " . $result . "'");

  # /etc/ssl/test-zentyal-2.2021.pulipuli.info.pem
  #my $certfile = "/etc/ssl/test-zentyal-2.2021.pulipuli.info.pem";
  #my $certfile = "/home/dlll/git-init.sh";
  #my $epoch_timestamp = (stat($certfile))[9];
  #my $epoc = time();
  #my $intervalDays = ($epoc - $epoch_timestamp) / 60 / 60 / 24;
  #system("echo '[!] " . $domainNameValue . " " . $result . " " . $intervalDays . "'");

  if ($result eq 1) {
    system("echo 'OK go'");
    return 1;
  }
  else {
    return 0;
  }
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub setupSSLCert
{
  my ($self, $domainNameValue) = @_;

  system("echo 'setupSSLCert start'");

  # 則建立cert
  
  # certbot certonly --webroot -w /usr/share/zentyal/www/dlllciasrouter/certbot -d test-zentyal-3-2021.pulipuli.info
  my $certbotScript = "certbot certonly --webroot -w /usr/share/zentyal/www/dlllciasrouter/certbot -d " . $domainNameValue . " -n";
  system("echo '" . $certbotScript . "'");
  EBox::Sudo::root($certbotScript);

  my $folder = "/etc/letsencrypt/live/" . $domainNameValue;
  if (-d $folder) {
    # ok. moving on.
  }
  else {
    system("echo 'setupSSLCert no folder " . $folder . "'");
    return 0;
  }

  
  # -------------------
  # 組合檔案
  my $poundCertFolder = "/etc/pound/cert";
  my $targetPem = $poundCertFolder . "/" . $domainNameValue . ".pem";
  
  my $build = "cat /etc/letsencrypt/live/" . $domainNameValue . "/privkey.pem /etc/letsencrypt/live/" . $domainNameValue . "/fullchain.pem > " . $targetPem;
  system("echo '" . $build . "'");
  
  #EBox::Sudo::root($build);
  system("echo 'manual wait 30 sec'");
  sleep(30);

  system("echo 'setupSSLCert finish'");
  
  return 1;
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub cloneBackendHTTPtoHTTPS
{
  my ($self, $domainHash, $domainHTTPSHash, $domainNameValue) = @_;

  # -----------------------
  # 加入 $domainHTTPSHash
  my @backEndArray = @{$domainHash->{$domainNameValue}};
  $domainHTTPSHash->{$domainNameValue} = \@backEndArray;

  return ($domainHTTPSHash);
}

# 20210718 Pulipuli Chen
# 將設定改為適合certbot的伺服器
sub setupSSLCertSwitchToLighttpd
{
  my ($self, $domainName) = @_;

  my @params = ();

  system("echo 'setupSSLCertSwitchToLighttpd'");

  $self->parentModule()->writeConfFile(
      '/etc/pound/pound.cfg',
      "dlllciasrouter/pound.cfg.disable.mas",
      \@params,
      { uid => '0', gid => '0', mode => '744' }
  );

  EBox::Sudo::root("service pound restart");

  #system("echo '============================'");
  #system("cat /etc/pound/pound.cfg");
  #system("echo '============================'");
  
  #sleep(3);

  #system("echo '============================'");
  #system("sudo lsof -i -P -n | grep :80");
  #system("echo '============================'");
  
  #sleep(3);

  #if ($self->checkSSLCertAvailable($domainName) == 1) {
  #  system("echo 'setupSSLCertSwitchToLighttpd FAILED!!!'");
  #  return 0;
  #}

  system("echo 'setupSSLCertSwitchToLighttpd 0'");
  
  # 1. 停止pound
  #EBox::Sudo::root("service pound restart");
  
  #sleep(10);

  #EBox::Sudo::root("pkill pound");
  #EBox::Service::manage('dlllciasrouter.pound', 'stop');

  system("echo 'setupSSLCertSwitchToLighttpd 1'");

  $self->parentModule()->writeConfFile(
      '/etc/lighttpd/lighttpd.conf',
      "dlllciasrouter/lighttped.conf.certbot.mas",
      \@params,
      { uid => '0', gid => '0', mode => '744' }
  );

  #sleep(3);

  #system("echo '============================'");
  #system("cat /etc/lighttpd/lighttpd.conf");
  #system("echo '============================'");


  #system("echo 'setupSSLCertSwitchToLighttpd 2'");

  # 3. 重新啟動lighttpd
  #EBox::Sudo::root("/etc/init.d/lighttpd restart");
  EBox::Sudo::root("service lighttpd restart");
  #EBox::Service::manage('dlllciasrouter.pound', 'restart');

  #sleep(5);

  system("echo 'setupSSLCertSwitchToLighttpd finished'");

  return 1;
}

# 20210718 Pulipuli Chen
# 將設定從適合certbot的伺服器還原為pound
sub setupSSLCertSwitchToPound
{
  my ($self) = @_;

  system("echo 'setupSSLCertSwitchToPound'");

  # 1. 修改設定
  my @params = ();
  $self->parentModule()->writeConfFile(
      '/etc/lighttpd/lighttpd.conf',
      "dlllciasrouter/lighttped.conf.mas",
      \@params,
      { uid => '0', gid => '0', mode => '744' }
  );

  # 2. 重新啟動lighttpd
  EBox::Sudo::root("service lighttpd restart");
  #EBox::Service::manage('dlllciasrouter.lighttpd', 'restart');

  # 3. 啟動pound
  #EBox::Sudo::root("service pound start");
  #EBox::Service::manage('dlllciasrouter.pound', 'start');

  return;
}

1;
