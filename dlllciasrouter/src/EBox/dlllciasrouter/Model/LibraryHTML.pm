package EBox::dlllciasrouter::Model::LibraryHTML;

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
    $self->parentModule()->writeConfFile(
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

# -----------------------------------------------

1;
