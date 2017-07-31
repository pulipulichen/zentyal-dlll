package EBox::dlllciasrouter::Model::LibraryToolkit;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::MACAddr;
use EBox::Types::Text;
use EBox::Types::HTML;
use EBox::Types::Boolean;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Select;
use EBox::Types::HasMany;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;
use EBox::Exceptions::Error;

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

# ----------------------------

sub show_exceptions
{
    my ($self, $message) = @_;
    throw EBox::Exceptions::External($message);
    #throw EBox::Exceptions::InvalidData("ERROR", $message);

    #throw EBox::Exceptions::Error($message);
    #$self->setMessage(
    #       $message,
    #        'warning');
}

sub isEnable
{
    my ($self, $row) = @_;
    return $row->valueByName('configEnable');
}

##
# 20170731 Pulipuli Chen
# 改進原本Zentyal問題的取得上一層row的作法
##
sub getParentRow
{
    my ($self, $obj) = @_;
    
    my $row = $obj->parentRow();

    if (defined($row)) {
        return $row;
    }

    #return $self->parentModule()->model($library);
    my $directory = $obj->{'directory'};
    my @parts = split('/', $directory);
    my $modelName = $parts[0];
    my $id = $parts[2];

    #return $modelName;

    my $mod = $self->loadLibrary($modelName);
    $row = $mod->row($id);

    return $row;
}

# ----------------------------

1;
