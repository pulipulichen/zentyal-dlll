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
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

##
# 讀取LibraryToolkit
# @author Pulipuli Chen
# 20150514
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

# ------------------------------------------

# 20150518 Pulipuli Chen
# 允許管理者通行的防火牆規則
sub initZentyalAdminFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_object',
        'source_object' => $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id(),
        #'source_inverseMatch' => 1, 
        #'service' => $self->getLoadLibrary("LibraryService")->getServiceId('dlllciasrouter-admin'),
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('dlllciasrouter-admin'),
        'description' => __("Zentyal Administrator"),
    );

    $self->addExternalToEBoxRule(%param);
}

# 20170727 Pulipuli Chen
# 允許辦公室通行的防火牆規則
# sub initWorkplaceFilter
# {
#     my ($self) = @_;

#     my %param = (
#         'decision' => 'accept',
#         'source_selected' => 'source_object',
#         'source_object' => $self->getLoadLibrary('LibraryMAC')->getObjectRow('Workplace-List')->id(),
#         'service' => $self->getLoadLibrary("LibraryService")->getServiceId('dlllciasrouter-workplace'),
#         'description' => __("Zentyal Administrator"),
#     );

#     $self->addExternalToEBoxRule(%param);
# }

# 20170726 Pulipuli Chen
# 設定DNS伺服器的防火牆
sub initDNSServerFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('dlllciasrouter-dns'),
        'description' => __("DNS Server"),
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
        'source_object' => $self->getLoadLibrary('LibraryMAC')->getObjectRow('Blacklist')->id(),
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('any'),
        'description' => __("Blacklist"),
    );

    my $id = $self->addExternalToEBoxRule(%param);
    $self->moveRuleToTop(%param);
}

# 20150518 Pulipuli Chen
sub initPoundFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('dlllciasrouter-pound'),
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
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('dlllciasrouter-pound'),
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
        $id = $ruleTable->addRow(%param)
    }
    return $id;
}

# 20150528 Pulipuli Chen
sub initNFSFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('NFS'),
        'description' => __("Network File System"),
    );

    $self->addInternalToEBoxRule(%param);
}

# 20150528 Pulipuli Chen
sub initMFSFilter
{
    my ($self) = @_;

    my %param = (
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->getLoadLibrary("LibraryService")->getServiceId('MFS'),
        'description' => __("MooseFS"),
    );

    $self->addInternalToEBoxRule(%param);
}

# 20150518 Pulipuli Chen
sub addInternalToEBoxRule
{
    my ($self, %param) = @_;

    my $network = EBox::Global->modInstance('firewall');
    my $ruleTable = $network->model('InternalToEBoxRuleTable');
    my $id = $ruleTable->findId('description'=>$param{description});
    if (!defined($id)) {
        $id = $ruleTable->addRow(%param)
    }
    return $id;
}

sub moveRuleToTop
{
    my ($self, %param) = @_;

    
    my $id = $self->addExternalToEBoxRule(%param);

    my $network = EBox::Global->modInstance('firewall');
    my $ruleTable = $network->model('ExternalToEBoxRuleTable');
    my $row = $ruleTable->row($id);
    my $order = $ruleTable->_rowOrder($id);

    while ($ruleTable->_rowOrder($id) > 0) {
        my %order = $ruleTable->_orderHash();

        my $pos = $order{$id};
        if ($order{$id} == 0) {
            last;
        }
        #$ruleTable->_swapPos($pos, $pos - 1);
        my $posA = $pos;
        my $posB = $pos - 1;

        my $confmod = $ruleTable->{'confmodule'};
        my @order = @{$confmod->get_list($ruleTable->{'order'})};

        my $temp = $order[$posA];
        $order[$posA] =  $order[$posB];
        $order[$posB] = $temp;

        $confmod->set_list($ruleTable->{'order'}, 'string', \@order);
    }
    

    #$self->getLoadLibrary('LibraryToolkit')->show_exceptions("[] " . $param{description} . "-----" . $ruleTable->_rowOrder($id) . "[]");
}

1;
