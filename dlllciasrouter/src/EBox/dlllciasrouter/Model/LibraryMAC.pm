package EBox::dlllciasrouter::Model::LibraryMAC;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use EBox::NetWrappers qw(:all);
use Try::Tiny;

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
# 能觸碰Zentyal核心服務的相關成員
##
sub initAdministorNetworkMember
{
    my ($self) = @_;

    try {
        my $libNET = $self->getLoadLibrary('LibraryNetwork');

        my $address = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();
        my $sourceMask = $self->getLoadLibrary('LibraryNetwork')->getExternalMask();

        #$self->getLibrary()->show_exceptions("sourceMask: " . $sourceMask .  '( LibraryMAC->initAdministorNetworkMember() )');

        my $ip_network = EBox::NetWrappers::ip_network($address, $sourceMask);
        my $ip_broadcast = EBox::NetWrappers::ip_broadcast($address, $sourceMask);

        my $objectRow = $self->getObjectRow('Administrator-List');
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
    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryMAC->initAdministorNetworkMember() )');
    };
}

##
# 20150517 Pulipuli Chen
# 能觸碰Zentyal核心服務的相關成員
##
sub initWorkplaceNetworkMember
{
    my ($self) = @_;

    try {
        my $libNET = $self->getLoadLibrary('LibraryNetwork');

        my $address = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();
        my $sourceMask = '255.255.0.0';

        my $ip_network = EBox::NetWrappers::ip_network($address, $sourceMask);

        if ($ip_network eq "0.0.0.0") {
            $self->getLibrary()->show_exceptions("iprange_begin should not be 0.0.0.0. address = " . $address . ' ( LibraryMAC->initWorkplaceNetworkMember() )');
        }

        my $ip_broadcast = EBox::NetWrappers::ip_broadcast($address, $sourceMask);

        if ($ip_broadcast eq "0.0.0.0") {
            $self->getLibrary()->show_exceptions("iprange_end should not be 0.0.0.0. address = " . $address . ' ( LibraryMAC->initWorkplaceNetworkMember() )');
        }

        #$self->getLibrary()->show_exceptions("break point: " . $ip_network .  '( LibraryMAC->initWorkplaceNetworkMember() )');

        # ----------------------------

        my $objectRow = $self->getObjectRow('Workplace-List');
        my $memberModel = $objectRow->subModel('members');
        my $id = $memberModel->findId('name' => 'default');
        if (!defined($id)) {
            $id = $memberModel->addRow(
                name => 'default',
                address_selected => 'iprange',
                iprange_begin => $ip_network,
                iprange_end => $ip_broadcast,
            );
        }
        return $memberModel->row($id);
    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryMAC->initWorkplaceNetworkMember() )');
    };
}

##
# 20150517 Pulipuli Chen
# 阻止以下IP進入
##
sub initBlackListMember
{
    my ($self) = @_;

    try {
        # my $objectRow = $self->getObjectRow('Blacklist');
        # 實際上並沒有設定黑名單，只是建立名為「Blacklist」黑名單的Object而已

        # 20181028
        my $name = 'Blacklist';
        my $objectRow = $self->getObjectRow($name);
        my $memberModel = $objectRow->subModel('members');
        my $id = $memberModel->findId('name' => "default");
        if (!defined($id)) {
          $memberModel->addRow(
              name => "default",
              address_selected => 'ipaddr',
              ipaddr_ip => '1.1.1.1',
              ipaddr_mask => '32'
          );
        }
        
    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryMAC->initBlackListMember() )');
    };
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

    try {
        my $name = 'DHCP-fixed-IP';
        my $objectRowID = $self->getObjectRow($name)->id();

        my $iface = $self->getLoadLibrary('LibraryNetwork')->getInternalIface();
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
            try {
                $fixedAddresses->addRow(
                    'object' => $objectRowID,
                    'description' => $desc,
                );
            }
            catch {
                # 增加失敗則略過，通常是已經新增了
            }
        }
    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryMAC->initDHCPfixedIP() )');
    };
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

1;
