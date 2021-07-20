package EBox::dlllciasrouter::Model::LibraryServiceSSH;

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

# -----------------------------------------------

1;
