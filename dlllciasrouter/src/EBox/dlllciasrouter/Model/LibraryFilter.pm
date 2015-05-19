package EBox::dlllciasrouter::Model::LibraryFilter;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use EBox::NetWrappers qw(:all);

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

##
# 讀取PoundLibrary
# @author Pulipuli Chen
# 20150514
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
}

# ------------------------------------------

# 20150518 Pulipuli Chen
sub initZentyalAdminFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_object',
        'source_object' => $self->loadLibrary('LibraryMAC')->getObjectRow('Administrator-Network')->id(),
        'service' => $self->loadLibrary("LibraryService")->getServiceId('dlllciastouer-admin'),
        'description' => __("Zentyal Webadmin & SSH"),
    );

    $self->addExternalToEBoxRule(%param);
}

# 20150519 Pulipuli Chen
sub initBlackListFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'deny',
        'source_selected' => 'source_object',
        'source_object' => $self->loadLibrary('LibraryMAC')->getObjectRow('Black-List')->id(),
        'service' => $self->loadLibrary("LibraryService")->getServiceId('any'),
        'description' => __("Black List"),
    );

    $self->addExternalToEBoxRule(%param);
}

# 20150518 Pulipuli Chen
sub initPoundFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->loadLibrary("LibraryService")->getServiceId('dlllciasrouter-pound'),
        'description' => __("Reverse Proxy & Lighttpd."),
    );

    $self->addExternalToEBoxRule(%param);
}

# 20150519 Pulipuli Chen
sub initPoundLogFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'log',
        'source_selected' => 'source_any',
        'service' => $self->loadLibrary("LibraryService")->getServiceId('dlllciasrouter-pound'),
        'description' => __("Reverse Proxy & Lighttpd Log."),
    );

    $self->addExternalToEBoxRule(%param);
}

# 20150518 Pulipuli Chen
sub addExternalToEBoxRule
{
    my ($self, %param) = @_;

    my $network = EBox::Global->modInstance('firewall');
    my $ruleTable = $network->model('ExternalToEBoxRuleTable');
    my $id = $ruleTable->findId('description'=>$param{description});
    if (!defined($id)) {
        $ruleTable->addRow(%param)
    }
}

1;
