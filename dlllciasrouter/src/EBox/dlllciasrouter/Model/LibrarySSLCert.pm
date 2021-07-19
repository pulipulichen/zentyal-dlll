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

  # https://script.google.com/macros/s/AKfycbzn1vBi_yGBZwxiNUMqZEwXjc3qmwaiRCAstfrRw26R2_3HVzmT00RlHF5Po039hWNBHA/exec?q=https://blog.pulipuli.info

  my $modified = 0;
  
  # 跑迴圈，看每個資料
  if (length($domainHash)) {
    while (my ($domainNameValue, $backEndArray) = each ($domainHash)) {  	
      #system("echo '[!] " . $domainNameValue . "'");
      
      if ($self->checkSSLCertExists($domainNameValue) == 1) {
        #next;
      }
      
      if ($self->checkSSLCertAvailable($domainNameValue) == 0) {
        next;
      }
      
      if ($modified == 0) {
        $modified = 1;
        $self->setupSSLCertSwitchToLighttpd();
      }
      
      ($domainHTTPSHash) = $self->setupSSLCert($domainHTTPSHash, $domainNameValue);
    }
  }
  
  if ($modified == 1) {
    $self->setupSSLCertSwitchToPound();
  }

  return ($domainHTTPSHash);
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub checkSSLCertAvailable
{
  my ($self, $domainNameValue) = @_;
  
  # https://script.google.com/macros/s/AKfycbzn1vBi_yGBZwxiNUMqZEwXjc3qmwaiRCAstfrRw26R2_3HVzmT00RlHF5Po039hWNBHA/exec?q=https://blog.pulipuli.info
  my $testURL = "https://script.google.com/macros/s/AKfycbw1gAhCzBvcQ08K-B8r7Ed4SyW0iUBltws8tmC0qrNWG71ARClI0hthNoaEuV6VRmyZUg/exec";
  my $result = `wget -qO- ${testURL}?q=http://${domainNameValue}:888/certbot/`
  system("echo '[!] " . $domainNameValue . " " . $result . "'");

  if ($result eq "1") {
    return 1;
  }
  else {
    return 0;
  }
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub checkSSLCertExists
{
  my ($self, $domainNameValue) = @_;
  
  # 測試有沒有已經存在的cert

    # 測試能不能連線

      # 如果可以連線，則建立cert

      #($domainHTTPSHash) = $self->setupSSLCert($domainHTTPSHash, $domainNameValue)
      
  # 檢查看看有沒有過期 (必須是距離上次2個月內)
  return 1;
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

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub setupSSLCertSwitchToLighttpd
{
  my ($self) = @_;

  # 則建立cert

  # 記錄上次更新的時間
  
  # 加入 $domainHTTPSHash

  return;
}

# 20210718 Pulipuli Chen
# 取得測試伺服器的資料
sub setupSSLCertSwitchToPound
{
  my ($self) = @_;

  # 則建立cert

  # 記錄上次更新的時間
  
  # 加入 $domainHTTPSHash

  return;
}

1;