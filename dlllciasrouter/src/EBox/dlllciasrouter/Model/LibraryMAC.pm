package EBox::dlllciasrouter::Model::LibraryMAC;

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
# 更新NetworkDisplay欄位
# 顯示IP跟MAC
# @param $row 欄
##
sub updateNetworkDisplay
{
    my ($self, $row) = @_;

    my $ipaddr = $row->valueByName('ipaddr');
    my $macaddr = $row->valueByName('macaddr');
    if (defined($macaddr) && $macaddr ne '') {
        $ipaddr = $ipaddr . ' <br /> (' . $macaddr . ')';
    }
    
    $ipaddr = '<span>' . $ipaddr . '</span>';

    $row->elementByName('network_display')->setValue($ipaddr);
}

##
# 從Objects當中找出DHCP-fixed-IP的成員名單
# 如果沒有的話，則建立一個
##
sub getDHCPfixedIPMemberModel
{
    my ($self) = @_;

    my $name = 'DHCP-fixed-IP';
    my $objectRow = $self->getObjectRow($name);
    #$self->setupDHCPfixedIP($objectRow->id());
    my $memberModel = $objectRow->subModel('members');

    return $memberModel;
}

# 20150517 Pulipuli Chen
sub getObjectRow
{
    my ($self, $name) = @_;

    my $objectsModule = EBox::Global->modInstance('objects');
    my $objectTable = $objectsModule->model('ObjectTable');

    my $id = $objectTable->findId('name' => $name);

    if (!defined($id)) {
        $id = $objectTable->addRow('name' => $name);

        unless (defined($id)) {
            throw EBox::Exceptions::Internal("Couldn't add object's name: " . $name);
        }
    }

    my $objectRow = $objectTable->row($id);
    
    return $objectRow;
}

# 20150517 Pulipuli Chen
sub getMemberModel
{
    my ($self, $objectRow) = @_;

    my $memberModel = $objectRow->subModel('members');

    return $memberModel;
}

##
# 增加DHCP-fixed-IP的成員
# @param $row 來自BackEnd的row
##
sub addDHCPfixedIPMember
{
    my ($self, $row) = @_;

    if (! ($self->getLibrary()->isEnable($row))) {
        return;
    }

    my $domainName = $row->valueByName('domainName');
    my $ipaddr = $row->valueByName('ipaddr');
    my $macaddr = $row->valueByName('macaddr');

    if (!defined($macaddr) || $macaddr eq '') {
        return;
    }

    my $memberModel = $self->getDHCPfixedIPMemberModel();

    # 先移除既有的
    my $id = $memberModel->findId('macaddr' => $macaddr);
    if (defined($id)) {
        $memberModel->removeRow($id);
    }
    
    # 加入新的 
    $memberModel->addRow(
        name => $domainName,
        address_selected => 'ipaddr',
        ipaddr_ip => $ipaddr,
        ipaddr_mask => '32',
        macaddr => $macaddr
    );
}

##
# 20150517 Pulipuli Chen
##
sub initAdministorNetworkMember
{
    my ($self) = @_;

    my $libNET = $self->loadLibrary('LibraryNetwork');

    my $address = $self->loadLibrary('LibraryNetwork')->getExternalIpaddr();
    my $sourceMask = $self->loadLibrary('LibraryNetwork')->getExternalMask();

    my $ip_network = EBox::NetWrappers::ip_network($address, $sourceMask);
    my $ip_broadcast = EBox::NetWrappers::ip_broadcast($address, $sourceMask);

    my $objectRow = $self->getObjectRow('Administrator-Network');
    my $memberModel = $objectRow->subModel('members');
    # 先移除既有的
    my $id = $memberModel->findId('name' => 'default');
    if (!defined($id)) {
        #my $macaddr;
        # 加入新的 
        $id = $memberModel->addRow(
            name => 'default',
            address_selected => 'iprange',
            iprange_begin => $ip_network,
            iprange_end => $ip_broadcast,
            #macaddr => $macaddr,
        );
    }
    return $memberModel->row($id);
}

##
# 20150517 Pulipuli Chen
##
sub initBlackListMember
{
    my ($self) = @_;

    my $objectRow = $self->getObjectRow('Black-List');
}

##
# 移除DHCP-fixed-IP的成員
# @param $row 來自BackEnd的row
##
sub removeDHCPfixedIPMember
{
    my ($self, $row) = @_;

    my $macaddr = $row->valueByName('macaddr');

    my $memberModel = $self->getDHCPfixedIPMemberModel();

    # 移除既有的
    my $id = $memberModel->findId('macaddr' => $macaddr);
    if (defined($id)) {
        $memberModel->removeRow($id);
    }
}

##
# 設定DHCP中的FixedAddresses
# @param $objectRowID 要設定的ObjectID
## 
sub initDHCPfixedIP
{
    my ($self) = @_;

    my $name = 'DHCP-fixed-IP';
    my $objectRowID = $self->getObjectRow($name)->id();

    my $iface = $self->loadLibrary('LibraryNetwork')->getInternalIface();
    if (!defined($iface)) {
        return;
    }
    my $dhcpModule = EBox::Global->modInstance('dhcp');
    my $interfacesModel = $dhcpModule->model('Interfaces');

    # 先找尋有啟用的裝置，取得第一個
    my $id = $interfacesModel->findId('iface'=>$iface);
    if (defined($id) == 0) {
        # 沒有裝置啟動，不使用
        return;
    }

    my $enabledInterface = $interfacesModel->row($id);
    my $configuration = $enabledInterface->subModel('configuration');

    my $RangeTable = $configuration->componentByName('RangeTable');
    $name = 'Reverse Proxy Ranges (DHCP)';
    $id = $RangeTable->findId('name' => $name);
    if (!defined($id)) {
        $RangeTable->addRow(
            'name' => $name,
            'from' => "10.6.2.1",
            'to' => "10.6.2.254",
        );
    }

    my $fixedAddresses = $configuration->componentByName('FixedAddressTable');
    # 先找找有沒有已經設定的群組
    my $desc = 'Reverse Proxy Fixed Address Object (DHCP-fixed-IP)';
    $id = $fixedAddresses->findId('description' => $desc);

    if (!defined($id)) {
        $fixedAddresses->addRow(
            'object' => $objectRowID,
            'description' => $desc,
        );
    }
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

1;
