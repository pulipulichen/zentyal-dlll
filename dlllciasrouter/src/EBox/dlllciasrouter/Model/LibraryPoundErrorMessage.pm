package EBox::dlllciasrouter::Model::LibraryPoundErrorMessage;

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

##
# 20150519 Pulipuli Chen
##
sub updatePoundErrorMessage
{
    my ($self) = @_;

    my $mod = $self->getLoadLibrary('ErrorMessage');

    my @params = ();

    my $address = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();
    push(@params, 'baseURL' => "http://" . $address . ":888");

    push(@params, 'websiteTitle' => $mod->value('websiteTitle'));
    push(@params, 'homeText' => $mod->value('homeText'));
    push(@params, 'homeURL' => $mod->value('homeURL'));
    push(@params, 'aboutText' => $mod->value('aboutText'));
    push(@params, 'aboutURL' => $mod->value('aboutURL'));    
    push(@params, 'contactText' => $mod->value('contactText'));
    push(@params, 'contactEMAIL' => $mod->value('contactEMAIL'));

    my $errorMessage = $mod->value('errorMessage');
    my $libEnc = $self->getLoadLibrary("LibraryEncoding");
    $errorMessage = $libEnc->unescapeFromUtf16($errorMessage);
    push(@params, 'errorMessage' => $errorMessage);

    $self->parentModule()->writeConfFile(
        '/etc/pound/error.html',
        "dlllciasrouter/error.html.mas",
        \@params,
        { uid => '0', gid => '0', mode => '777' }
    );

    $self->parentModule()->writeConfFile(
        '/usr/share/zentyal/www/dlllciasrouter/css/styles.css',
        "dlllciasrouter/styles.css.mas",
        \@params,
        { uid => '0', gid => '0', mode => '777' }
    );
}


# -----------------------------------------------

1;
