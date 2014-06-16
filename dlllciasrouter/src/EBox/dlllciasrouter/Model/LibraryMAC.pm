package EBox::dlllciasrouter::Model::LibraryMAC;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

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
    if (defined $macaddr && $macaddr ne '') {
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

    my $objectsModule = EBox::Global->modInstance('objects');
    my $objectTable = $objectsModule->model('ObjectTable');

    my $name = 'DHCP-fixed-IP';
    my $id = $objectTable->findId('name' => $name);

    if (defined($id) == 0) {
        $id = $objectTable->addRow('name' => $name);

        unless (defined($id)) {
            throw EBox::Exceptions::Internal("Couldn't add object's name: $name");
        }
    }

    my $objectRow = $objectTable->row($id);
    
    # 設定DHCP FixedAddresses
    $self->setupDHCPfixedIP($id);

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

    my $domainName = $row->valueByName('domainName');
    my $ipaddr = $row->valueByName('ipaddr');
    my $macaddr = $row->valueByName('macaddr');

    if (!defined $macaddr || $macaddr eq '') {
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
sub setupDHCPfixedIP
{
    my ($self, $objectRowID) = @_;

    my $dhcpModule = EBox::Global->modInstance('dhcp');
    my $interfacesModel = $dhcpModule->model('Interfaces');

    # 先找尋有啟用的裝置，取得第一個
    my $id = $interfacesModel->findId('enabled'=>1);
    if (defined($id) == 0) {
        # 沒有裝置啟動，不使用
        return;
    }

    my $enabledInterface = $interfacesModel->row($id);
    my $configuration = $enabledInterface->subModel('configuration');
    my $fixedAddresses = $configuration->componentByName('FixedAddressTable');
    
    # 先找找有沒有已經設定的群組
    my $desc = 'Reverse Proxy Fixed Address Object (DHCP-fixed-IP)';
    $id = $fixedAddresses->findId('description' => $desc);

    if (defined($id)) {
        # 已經設定
        return;
    }

    $fixedAddresses->addRow(
        'object' => $objectRowID,
        'description' => $desc,
    );
}

1;
