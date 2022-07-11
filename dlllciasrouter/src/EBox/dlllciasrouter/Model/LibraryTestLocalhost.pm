package EBox::dlllciasrouter::Model::LibraryTestLocalhost;

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


# 20210718 Pulipuli Chen
# 將設定從適合certbot的伺服器還原為pound
sub startupTestServer
{
  my ($self) = @_;

  #system("echo 'setupSSLCertSwitchToPound'");

  # 1. 修改設定
  my @params = ();
  $self->parentModule()->writeConfFile(
      '/etc/lighttpd/lighttpd.conf',
      "dlllciasrouter/lighttpd.conf.mas",
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
