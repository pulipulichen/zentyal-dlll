package EBox::dlllciasrouter::Model::LibraryServers;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use Try::Tiny;


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

sub getDataTable
{
    my ($self, $options) = @_;

    my $fieldsFactory = $self->loadLibrary('LibraryFields');
    my $backView = '/dlllciasrouter/Composite/' . $options->{tableName} . "Composite";

    my @fields = ();
    #push(@fields, $fieldsFactory->createFieldAddBtn('add'));
    #push(@fields, $fieldsFactory->createFieldDescription());

    push(@fields, $fieldsFactory->createFieldConfigEnable());
    push(@fields, $fieldsFactory->createFieldDomainName());
    push(@fields, $fieldsFactory->createFieldBoundLocalDNS());

    if ($options->{enableVMID} == 0) {
        push(@fields, $fieldsFactory->createFieldInternalIPAddressHideView(1, $options->{IPHelp}));
    }
    else {
        push(@fields, $fieldsFactory->createFieldInternalVirtualMachineIdentify(1, $options->{IPHelp}));
        push(@fields, $fieldsFactory->createFieldInternalIPAddressHide(1, $options->{IPHelp}));
    }
    

    push(@fields, $fieldsFactory->createFieldNetworkDisplay());
    
    push(@fields, $fieldsFactory->createFieldDomainNameLink());

    push(@fields, $fieldsFactory->createFieldMACAddr());

    if ($options->{enableOtherFunction} == 1) {
        push(@fields, $fieldsFactory->createFieldOtherDomainNamesButton($backView, "OtherDomainNames"));
    }

    if ($options->{enableRedirectPorts} == 1) {
        push(@fields, $fieldsFactory->createFieldOtherRedirectPortsButton($backView));
    }

    if ($options->{enableOtherFunction} == 1) {
        push(@fields, $fieldsFactory->createFieldOtherRedirectPortsButton($backView));
    }

    # ----------------------------
    #push(@fields, $fieldsFactory->createFieldHr('hr_contact'));
    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_contact', __('Management Information')));

    push(@fields, $fieldsFactory->createFieldContactName());
    push(@fields, $fieldsFactory->createFieldContactEmail());
    push(@fields, $fieldsFactory->createFieldDescription());
    push(@fields, $fieldsFactory->createFieldDescriptionHTML());

    push(@fields, $fieldsFactory->createFieldAttachedFilesButton($backView));

    push(@fields, $fieldsFactory->createFieldExpiryDate($options->{expiryDate}));
    push(@fields, $fieldsFactory->createFieldCreateDateData());
    push(@fields, $fieldsFactory->createFieldDisplayLastUpdateDate());
    
    

    # -------------------------------------
    # hardware

    if ($options->{enableHardware} == 1) {
        #push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_hardware', __('Management Information')));

        push(@fields, $fieldsFactory->createFieldPhysicalLocation());
        push(@fields, $fieldsFactory->createFieldOS());
        if ($options->{enableKVM} == 1) {
            push(@fields, $fieldsFactory->createFieldHardwareKVM());
        }
        push(@fields, $fieldsFactory->createFieldHardwareCPU());
        push(@fields, $fieldsFactory->createFieldHardwareRAM());
        push(@fields, $fieldsFactory->createFieldHardwareDisk());
        push(@fields, $fieldsFactory->createFieldHardwareDisplay());

        #push(@fields, $fieldsFactory->createFieldHr('hr_hardd'));
    }

    # ----------------------------
    if ($options->{enableMount} == 1) {
        push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_mount', __('Mount Settings')));

        push(@fields, $fieldsFactory->createFieldMountEnable());
        push(@fields, $fieldsFactory->createFieldMountType($options->{defaultMountType}));
        push(@fields, $fieldsFactory->createFieldMountPath());
        push(@fields, $fieldsFactory->createFieldMountUsername());
        push(@fields, $fieldsFactory->createFieldMountPassword());
    }

    # ----------------------------
    #push(@fields, $fieldsFactory->createFieldHr('hr_pound'));
    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_pound', __('Pound Network Settings')));

        
    #push(@fields, $fieldsFactory->createFieldRedirectToHTTPS());

    push(@fields, $fieldsFactory->createFieldProtocolScheme('POUND', 0, $options->{poundScheme}));
    push(@fields, $fieldsFactory->createFieldInternalPortDefaultValue($options->{internalPortDefaultValue}));

    #push(@fields, $fieldsFactory->createFieldPoundProtocolScheme());

    push(@fields, $fieldsFactory->createFieldPoundOnlyForLAN($options->{poundSecure}));
    push(@fields, $fieldsFactory->createFieldEmergencyRestarter());

    #push(@fields, $fieldsFactory->createFieldHr('hr1'));

        
    # --------------------------
    # HTTP Redirect Fields 
    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_http', __('HTTP Network Settings')));

    push(@fields, $fieldsFactory->createFieldHTTPRedirect($options->{enableHTTP}));
    push(@fields, $fieldsFactory->createFieldHTTPOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldHTTPLog());
    push(@fields, $fieldsFactory->createFieldHTTPExternalPort());
    push(@fields, $fieldsFactory->createFieldHTTPInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("HTTP", 0, "http"));
    push(@fields, $fieldsFactory->createFieldHTTPNote());
    #push(@fields, $fieldsFactory->createFieldHr('hr_http'));


    # ----------------------
    # HTTPS Redirect Fields
    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_https', __('HTTPS Network Settings')));

    push(@fields, $fieldsFactory->createFieldHTTPSRedirect($options->{enableHTTPS}));
    push(@fields, $fieldsFactory->createFieldHTTPSOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldHTTPSLog());
    push(@fields, $fieldsFactory->createFieldHTTPSExternalPort());
    push(@fields, $fieldsFactory->createFieldHTTPSInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("HTTPS", 0, "https"));
    push(@fields, $fieldsFactory->createFieldHTTPSNote());
    #push(@fields, $fieldsFactory->createFieldHr('hr_https'));

    # --------------------------------
    # SSH Redirect Fields
    push(@fields, $fieldsFactory->createFieldHrWithHeading('ht_ssh', __('SSH Network Settings')));

    push(@fields, $fieldsFactory->createFieldSSHRedirect($options->{enableSSH}));
    push(@fields, $fieldsFactory->createFieldSSHOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldSSHLog());
    push(@fields, $fieldsFactory->createFieldSSHExternalPort());
    push(@fields, $fieldsFactory->createFieldSSHInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("SSH", 0, "none"));
    push(@fields, $fieldsFactory->createFieldSSHNote());
    #push(@fields, $fieldsFactory->createFieldHr('hr_ssh'));

    # --------------------------------
    # RDP Redirect Fields
    push(@fields, $fieldsFactory->createFieldHrWithHeading('ht_rdp', __('RDP Network Settings')));

    push(@fields, $fieldsFactory->createFieldRDPRedirect($options->{enableRDP}));
    push(@fields, $fieldsFactory->createFieldRDPOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldRDPLog());
    push(@fields, $fieldsFactory->createFieldRDPExternalPort());
    push(@fields, $fieldsFactory->createFieldRDPInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("RDP", 0, "none"));
    push(@fields, $fieldsFactory->createFieldRDPNote());
    #push(@fields, $fieldsFactory->createFieldHr('hr_rdp'));

    # --------------------------------

    push(@fields, $fieldsFactory->createFieldDisplayRedirectPorts());

    # --------------------------------
    # Other Redirect Ports

    if ($options->{enableOtherFunction} == 1) {
        #push(@fields, $fieldsFactory->createFieldOtherRedirectPortsButton($backView));
        push(@fields, $fieldsFactory->createFieldOtherRedirectPortsHint());
        push(@fields, $fieldsFactory->createFieldOtherRedirectPortsSubModel());
    }

    # --------------------------------
    # Date Display

    push(@fields, $fieldsFactory->createFieldCreateDateDisplay());
    #push(@fields, $fieldsFactory->createFieldCreateDateData());
    #push(@fields, $fieldsFactory->createFieldDisplayLastUpdateDate());
    push(@fields, $fieldsFactory->createFieldDisplayContactLink());

    #push(@fields, $fieldsFactory->createFieldAttachedFilesButton($backView, 1));
    push(@fields, $fieldsFactory->createFieldLogsLink());

    # ----------------------------------

    #new EBox::Types::HasMany(
    #    fieldName => 'configuration',
    #    printableName => __('Configuration'),
    #    foreignModel => 'BackEndConfiguration',
    #    foreignModelIsComposite => 1,
    #    view => '/dlllciasrouter/Composite/BackEndConfiguration',
    #    backView => 'dlllciasrouter/View/PoundServices',
    #),

    my $logBtn = '  <a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=audit_actions&filter-model='.$options->{tableName}.'">Logs</a>';
    my $dataTable =
    {
        'tableName' => $options->{tableName},
        'pageTitle' => $options->{pageTitle},
        'printableTableName' => $options->{printableTableName} . $logBtn,
        'defaultActions' => [ 'add', 'del', 'editField', 'clone', 'changeView' ],
        'modelDomain' => 'dlllciasrouter',
        'tableDescription' => \@fields,
        'printableRowName' => $options->{printableRowName},
        'HTTPUrlView'=> 'dlllciasrouter/View/' . $options->{tableName},
        'order' => 1,
    };

    return $dataTable;
}

# ---------------------------------------------------------



##
# 設定新增時的動作
##
sub serverAddedRowNotify
{
    my ($self, $row, $options) = @_;

    try {

        #$ROW_NEED_UPDATE = 1;

        my $lib = $self->getLibrary();
        my $libDN = $self->loadLibrary('LibraryDomainName');
        $libDN->updateDomainNameLink($row, 1);
        $self->updateNetworkDisplay($row, $options->{enableVMID});

        my $libCT = $self->loadLibrary('LibraryContact');
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);
        $libCT->updateLogsLink($row);
        $libCT->setDescriptionHTML($row);
        $libCT->setHardwareDisplay($row);

        if ($self->isDomainNameEnable($row) == 1) {
            $libDN->addDomainName($row->valueByName('domainName'));
            if ($row->elementExists("otherDomainName_subMod")) {
                $libDN->addOtherDomainNames($row->valueByName('otherDomainName_subMod'));
            }
        }

        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->updateRedirectPorts($row);
        $libREDIR->addRedirects($row);

        my $libMAC = $self->loadLibrary('LibraryMAC');
        $libMAC->addDHCPfixedIPMember($row);

        $row->store();
        #$ROW_NEED_UPDATE = 0;

    } catch {

        $self->getLibrary()->show_exceptions($_ . "( LibraryServers->serverAddedRowNotify() )");
        #$mod->setMessage($_ . ' ( LibraryServers->updatedRowNotify() )', 'error');
    };
}


sub serverDeletedRowNotify
{
    my ($self, $row, $options) = @_;

    try {

        my $libDN = $self->loadLibrary('LibraryDomainName');
        #$libDN->deleteDomainName($row->valueByName('domainName'), 'PoundServices');
        #$libDN->deleteOtherDomainNames($row->valueByName('otherDomainName_subMod'), 'PoundServices');
        $libDN->deleteDomainName($row->valueByName('domainName'), 'dlllciasrouter-pound');
        if ($row->elementExists("otherDomainName_subMod")) {
            $libDN->deleteOtherDomainNames($row->valueByName('otherDomainName_subMod'), 'dlllciasrouter-pound');
        }

        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->deleteRedirects($row);

        my $libMAC = $self->loadLibrary('LibraryMAC');
        $libMAC->removeDHCPfixedIPMember($row);

    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( LibraryServers->deletedRowNotify() )');
    };
}

##
# 20170731 Pulipuli Chen
# 更新，好像會有Domain Name無法正常儲存的問題
##
sub serverUpdatedRowNotify
{
    my ($self, $row, $oldRow, $options) = @_;

    my $lib = $self->getLibrary();
    
    my $libDN = $self->loadLibrary('LibraryDomainName');
    try {
        $self->serverDeletedRowNotify($oldRow);
      
        $libDN->updateDomainNameLink($row, 1);
        $self->updateNetworkDisplay($row, $options->{enableVMID});
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() libDN )');
    };
    
    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    try {
        $libREDIR->updateRedirectPorts($row);
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() libREDIR )');
    };

    try {
        my $libCT = $self->loadLibrary('LibraryContact');
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);
        $libCT->updateLogsLink($row);
        $libCT->setHardwareDisplay($row);
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() libCT )');
    };

    try {
        if ($self->isDomainNameEnable($row) == 1) {
            $libDN->addDomainName($row->valueByName('domainName'));
            if ($row->elementExists("otherDomainName_subMod")) {
                $libDN->addOtherDomainNames($row->valueByName('otherDomainName_subMod'));
            }
        }

        $libREDIR->deleteRedirects($row);
        $libREDIR->addRedirects($row);
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() libDN libREDIR )');
    };

    try {
        my $libMAC = $self->loadLibrary('LibraryMAC');
        $libMAC->removeDHCPfixedIPMember($oldRow);
        $libMAC->addDHCPfixedIPMember($row);
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() libMAC )');
    };

    try {
        if ($row->elementExists("redirOther_subMod")) {
            my $redirOther = $row->subModel('redirOther');

            for my $subId (@{$redirOther->ids()}) {
                my $redirRow = $redirOther->row($subId);
                $redirOther->deleteRedirect($oldRow, $redirRow);
                $redirOther->updateExtPortHTML($row, $redirRow);
                $redirOther->addRedirect($row, $redirRow);
            }
        }
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() redirOther )');
    };
        
    try {
        $row->store();
    } catch {
        $lib->show_exceptions($_  . ' ( LibraryServers->serverUpdatedRowNotify() row )');
    };
}

# 20150518 Pulipuli Chen
sub isDomainNameEnable
{
    my ($self, $row) = @_;

    my $isEnable = 1;
    if ($row->elementExists('configEnable')) {
        $isEnable = $row->valueByName('configEnable');
    }
    my $isBound = 1;
    if ($row->elementExists('boundLocalDns')) {
        $isBound = $row->valueByName('boundLocalDns');
    }

    return ($isEnable == 1 && $isBound == 1);
}

# 20150526 Pulipuli Chen
sub getVMID
{
    my ($self, $ipaddr) = @_;
    
    my $vmid;

    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    if ($partB eq '0') {
        $partB = "";
    }

    my $partC = $parts[2];
    my $partD = $parts[3];
    if ($partD < 10) {
        $partD = "0" . $partD;
    }
    $vmid = $partB . $partC . $partD;

    return $vmid;
}

# 20170727 Pulipuli Chen
# IP對應表說明：https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-2-network-ip-range.md#virtual-machine
sub convertVMIDtoIPAddr
{
    my ($self, $vmid) = @_;
    
    my $ipaddr;
        
    $vmid = "" + $vmid;
    my $partA = 10;
    my $partB = '0';
    my $partC = '1';
    my $partD = '63';

    if (length($vmid) == 4) {
        $partB = substr($vmid, 0, 1);
        $partC = substr($vmid, 1, 1);
        $partD = substr($vmid, 2, 2);
    }
    elsif (length($vmid) == 3) {
        $partB = '0';
        $partC = substr($vmid, 0, 1);
        $partD = substr($vmid, 1, 2);
    }

    if (substr($partD, 0, 1) == "0") {
        $partD = substr($partD, 1, 1);
    }

    $ipaddr = $partA . "." . $partB . "." . $partC . "." . $partD;

    return $ipaddr;
}

# 20150526 Pulipuli Chen
sub updateVMIDIPAddr
{
    my ($self, $row) = @_;
    
    my $ipaddr = $row->valueByName("vmIdentify");

    if (length($ipaddr) < 5) {
        #是VMID
        $ipaddr = $self->convertVMIDtoIPAddr($ipaddr);
    }
    $row->elementByName("ipaddr")->setValue($ipaddr);

#    if (defined($row->valueByName("ipaddr"))) {
#        return;
#    }
#    else {
#        my $ipaddr;
#        if (defined($row->valueByName("vmIdentify_ipaddr"))) {
#            $ipaddr = $row->valueByName("vmIdentify_ipaddr");
#        }
#        else {
#            $ipaddr = $self->getIPAddr($row);
#        }
#        $row->elementByName("ipaddr")->setValue($ipaddr);
#    }
}

##
# 20170801 Pulipuli Chen
# 更新NetworkDisplay欄位
# 顯示IP跟MAC
# @param $row 欄
##
sub updateNetworkDisplay
{
    my ($self, $row, $enableVMID) = @_;

    my $ipaddr = $row->valueByName('ipaddr');
    my $display = '';

    # 20170801 Pulipuli Chen
    # 加上連結

    my $ipSchema = "http";
    #$ipSchema = $row->valueByName('poundProtocolScheme');
    $ipSchema = $row->valueByName('redirPOUND_scheme');
    my $ipPort = 80;
    $ipPort = $row->valueByName('port');
    
    $display = '<a href="' . $ipSchema . '://' . $ipaddr . ':' . $ipPort . '/"' 
        . ' style="background: none;text-decoration: underline;color: #A3BD5B;" '
        . ' target="_blank">' . $ipaddr .'</a>';

    # ------------------------------------

    if ($enableVMID == 1) {
        my $vmid = $self->getVMID($ipaddr);
        $display = $display . ' <br /><strong>VMID:</strong> ' . $vmid;
    }

    my $macaddr = $row->valueByName('macaddr');
    if (defined($macaddr) && $macaddr ne '') {
        $display = $display . ' <br /><strong>MAC:</strong> ' . $macaddr;
    }

    if ($row->elementExists("mountEnable") 
        && $row->valueByName("mountEnable") == 1
        && defined($row->valueByName("mountPath")) ) {
        my $type = $row->valueByName("mountType");
        $type = uc($type);
        $display = $display . "<br />[".$type."]";
    }
    
    $display = '<span>' . $display . '</span>';

    $row->elementByName('network_display')->setValue($display);
}

1;
