package EBox::dlllciasrouter::Model::LibraryServiceLighttpd;

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

sub initLighttpd
{
    my ($self, $packageName) = @_;

    my @params = ();
    $self->parentModule()->writeConfFile(
        '/etc/lighttpd/lighttpd.conf',
        "dlllciasrouter/lighttped.conf.mas",
        \@params,
        { uid => '0', gid => '0', mode => '744' }
    );

    # 變更 /usr/share/zentyal/www/dlllciasrouter 權限 
    system('chmod 744  /usr/share/zentyal/www/dlllciasrouter');
    system('chmod 755  /usr/share/zentyal/www/dlllciasrouter/certbot');
    

}

# -----------------------------------------------

1;
