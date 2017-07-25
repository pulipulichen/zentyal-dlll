package EBox::dlllciasrouter::Model::LibraryService;

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
sub getZentyalAdminService
{
    my ($self) = @_;

    my $name = "dlllciasrouter-admin";
    my $desc = __("Zentyal Webadmin, SSH & MooseFS");
    return $self->initService($name, $desc);
}

# 20170726 Pulipuli Chen
sub getDNSServerService
{
    my ($self) = @_;

    my $name = "dlllciasrouter-dns";
    my $desc = __("DNS Server");
    return $self->initService($name, $desc);
}

# 20150518 Pulipuli Chen
sub getPoundService
{
    my ($self) = @_;

    my $name = "dlllciasrouter-pound";
    my $desc = __("Reverse Proxy & Lighttpd.");
    return $self->initService($name, $desc);
}

# 20150528 Pulipuli Chen
sub getNFSService
{
    my ($self) = @_;

    my $name = "NFS";
    my $desc = __("Network File System");
    return $self->initService($name, $desc);
}

# 20150528 Pulipuli Chen
sub getMFSService
{
    my ($self) = @_;

    my $name = "MFS";
    my $desc = __("MooseFS ");
    return $self->initService($name, $desc);
}

# 20150518 Pulipuli Chen
sub initService
{
    my ($self, $name, $desc) = @_;

    # 已經有Zentyal Admin Member了

    # 建立 Service
    my $serviceMod =  $self->getServiceModel();
    my %param = $self->getServiceParam($name, $desc);

    my $id = $serviceMod->findId(name=> $name);
    if (defined($id) == 0) {
        $id = $serviceMod->addRow(%param);
    }
    return $serviceMod->row($id);
}

# 20150518 Pulipuli Chen
sub getService
{
    my ($self, $name) = @_;

    # 建立 Service
    my $serviceMod =  $self->getServiceModel();

    my $id = $serviceMod->findId(name=> $name);
    if (defined($id)) {
        return $serviceMod->row($id);
    }
    else {
        return undef;
    }
}

# 20150518 Pulipuli Chen
sub getServiceId
{
    my ($self, $name) = @_;

    # 建立 Service
    my $row = $self->getService($name);
    if (!defined($row)) {
        return undef;
    }
    my $id = $row->id();
    return $id;
}

# 20150518 Pulipuli Chen
sub getServiceModel
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('services');
    return $network->model('ServiceTable');
}

# 20150518 Pulipuli Chen
sub getServiceParam
{
    my ($self, $name, $desc) = @_;

    return (
        # 寫入參數
        'internal' => $name,
        'name' => $name,
        'printableName' => $name,
        'description' => $desc,
    );
}

# -------------------------------------------------------------------------

# 20150518 Pulipuli Chen
sub getConfig
{
    my ($self, $name) = @_;
    my $service = $self->getService($name);
    if (defined($service)) {
        return $service->subModel('configuration');
    }
    else {
        return undef;
    }
}

# --------------------------------------------------------------------------

# 20150518 Pulipuli Chen
sub getServicePortParam
{
    my ($self, $onlyTcp, $port) = @_;

    my $tcp = "tcp/udp";
    if ($onlyTcp == 1) {
        $tcp = "tcp";
    }

    # 不確定，有可能錯誤
    return (
        # 設定連接埠參數
        'protocol' => $tcp,
        'source_range_type' => 'any',
        'destination_range_type' => 'single',
        'destination_single_port' => $port,
    );
}

# 20150518 Pulipuli Chen
sub addServicePort
{
    my ($self, $name, $port, $onlyTcp) = @_;

    my $config = $self->getConfig($name);
    my $id = $config->findId("destination" => $port);
    if (!defined($id)) {
        my $tcp = "tcp/udp";
        if ($onlyTcp == 1) {
            $tcp = "tcp";
        }
        $config->addRow(
            'protocol' => $tcp,
            'source_range_type' => 'any',
            'destination_range_type' => 'single',
            'destination_single_port' => $port,
        );
    }
}

# 20150518 Pulipuli Chen
sub deleteServicePort
{
    my ($self, $name, $port) = @_;

    my $config = $self->getConfig($name);
    my $id = $config->findId("destination" => $port);
    if (defined($id)) {
        $config->removeRow($id);
    }
}

# 20150518 Pulipuli Chen
sub updateServicePort
{
    my ($self, $name, $oldPort, $port, $onlyTcp) = @_;

    if ($oldPort == $port) {
        return;
    }
    $self->deleteServicePort($name, $oldPort);
    $self->addServicePort($name, $port, $onlyTcp);
}

1;
