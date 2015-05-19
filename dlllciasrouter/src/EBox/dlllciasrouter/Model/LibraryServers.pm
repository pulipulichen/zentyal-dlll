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
    return $self->parentModule()->model("PoundLibrary");
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
    push(@fields, $fieldsFactory->createFieldDomainNameLink());
    push(@fields, $fieldsFactory->createFieldInternalIPAddressHideView(1,$options->{IPHelp}));

    push(@fields, $fieldsFactory->createFieldMACAddr());
    push(@fields, $fieldsFactory->createFieldOtherDomainNamesButton($backView));
    push(@fields, $fieldsFactory->createFieldOtherDomainNamesSubModel());

    # ----------------------------
    push(@fields, $fieldsFactory->createFieldHr('hr_contact'));

    push(@fields, $fieldsFactory->createFieldContactName());
    push(@fields, $fieldsFactory->createFieldContactEmail());
    push(@fields, $fieldsFactory->createFieldDescription());
    push(@fields, $fieldsFactory->createFieldDescriptionHTML());
    push(@fields, $fieldsFactory->createFieldExpiryDate($options->{expiryDate}));

    # ----------------------------
    push(@fields, $fieldsFactory->createFieldHr('hr_pound'));

    push(@fields, $fieldsFactory->createFieldBoundLocalDNS());

    push(@fields, $fieldsFactory->createFieldNetworkDisplay());
        
    #push(@fields, $fieldsFactory->createFieldRedirectToHTTPS());

    push(@fields, $fieldsFactory->createFieldProtocolScheme('POUND', 0, $options->{poundScheme}));
    push(@fields, $fieldsFactory->createFieldInternalPortDefaultValue($options->{internalPortDefaultValue}));

    #push(@fields, $fieldsFactory->createFieldPoundProtocolScheme());

    push(@fields, $fieldsFactory->createFieldPoundOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldEmergencyRestarter());

    push(@fields, $fieldsFactory->createFieldHr('hr1'));

    # -------------------------------------
    # hardware

    if ($options->{enableHardware} == 1) {
        push(@fields, $fieldsFactory->createFieldHardwareCPU());
        push(@fields, $fieldsFactory->createFieldHardwareRAM());
        push(@fields, $fieldsFactory->createFieldHardwareDisk());
        push(@fields, $fieldsFactory->createFieldHardwareDisplay());

        push(@fields, $fieldsFactory->createFieldHr('hr_hardd'));
    }
        
    # --------------------------
    # HTTP Redirect Fields 
    push(@fields, $fieldsFactory->createFieldHTTPRedirect($options->{enableHTTP}));
    push(@fields, $fieldsFactory->createFieldHTTPOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldHTTPLog());
    push(@fields, $fieldsFactory->createFieldHTTPExternalPort());
    push(@fields, $fieldsFactory->createFieldHTTPInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("HTTP", 0, "http"));
    push(@fields, $fieldsFactory->createFieldHTTPNote());
    push(@fields, $fieldsFactory->createFieldHr('hr_http'));


    # ----------------------
    # HTTPS Redirect Fields
    push(@fields, $fieldsFactory->createFieldHTTPSRedirect($options->{enableHTTPS}));
    push(@fields, $fieldsFactory->createFieldHTTPSOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldHTTPSLog());
    push(@fields, $fieldsFactory->createFieldHTTPSExternalPort());
    push(@fields, $fieldsFactory->createFieldHTTPSInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("HTTPS", 0, "https"));
    push(@fields, $fieldsFactory->createFieldHTTPSNote());
    push(@fields, $fieldsFactory->createFieldHr('hr_https'));

    # --------------------------------
    # SSH Redirect Fields
    push(@fields, $fieldsFactory->createFieldSSHRedirect($options->{enableSSH}));
    push(@fields, $fieldsFactory->createFieldSSHOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldSSHLog());
    push(@fields, $fieldsFactory->createFieldSSHExternalPort());
    push(@fields, $fieldsFactory->createFieldSSHInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("SSH", 0, "none"));
    push(@fields, $fieldsFactory->createFieldSSHNote());
    push(@fields, $fieldsFactory->createFieldHr('hr_ssh'));

    # --------------------------------
    # RDP Redirect Fields
    push(@fields, $fieldsFactory->createFieldRDPRedirect($options->{enableRDP}));
    push(@fields, $fieldsFactory->createFieldRDPOnlyForLAN());
    push(@fields, $fieldsFactory->createFieldRDPLog());
    push(@fields, $fieldsFactory->createFieldRDPExternalPort());
    push(@fields, $fieldsFactory->createFieldRDPInternalPort());
    push(@fields, $fieldsFactory->createFieldProtocolScheme("RDP", 0, "none"));
    push(@fields, $fieldsFactory->createFieldRDPNote());
    push(@fields, $fieldsFactory->createFieldHr('hr_rdp'));

    # --------------------------------

    push(@fields, $fieldsFactory->createFieldDisplayRedirectPorts());

    # --------------------------------
    # Other Redirect Ports

    push(@fields, $fieldsFactory->createFieldOtherRedirectPortsButton($backView));
    push(@fields, $fieldsFactory->createFieldOtherRedirectPortsHint());
    push(@fields, $fieldsFactory->createFieldOtherRedirectPortsSubModel());

    # --------------------------------
    # Date Display

    push(@fields, $fieldsFactory->createFieldCreateDateDisplay());
    push(@fields, $fieldsFactory->createFieldCreateDateData());
    push(@fields, $fieldsFactory->createFieldDisplayLastUpdateDate());
    push(@fields, $fieldsFactory->createFieldDisplayContactLink());
    push(@fields, $fieldsFactory->createFieldAttachedFilesButton($backView, 1));

    # ----------------------------------

    #new EBox::Types::HasMany(
    #    fieldName => 'configuration',
    #    printableName => __('Configuration'),
    #    foreignModel => 'BackEndConfiguration',
    #    foreignModelIsComposite => 1,
    #    view => '/dlllciasrouter/Composite/BackEndConfiguration',
    #    backView => 'dlllciasrouter/View/PoundServices',
    #),


    my $dataTable =
    {
        'tableName' => $options->{tableName},
        'pageTitle' => $options->{pageTitle},
        'printableTableName' => $options->{printableTableName},
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
    my ($self, $mod, $row) = @_;

    try {

    #$ROW_NEED_UPDATE = 1;
    
    my $lib = $self->getLibrary();
    my $libDN = $self->loadLibrary('LibraryDomainName');
    $libDN->updateDomainNameLink($row, 1);
    
    my $libCT = $self->loadLibrary('LibraryContact');
    $libCT->setCreateDate($row);
    $libCT->setUpdateDate($row);
    $libCT->setContactLink($row);
    $libCT->setDescriptionHTML($row);
    $libCT->setHardwareDisplay($row);

    if ($self->isDomainNameEnable($row) == 1) {
        $libDN->addDomainName($row->valueByName('domainName'));
    }

    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    $libREDIR->updateRedirectPorts($row);
    $libREDIR->addRedirects($row);

    my $libMAC = $self->loadLibrary('LibraryMAC');
    $libMAC->updateNetworkDisplay($row);
    $libMAC->addDHCPfixedIPMember($row);

    $row->store();
    #$ROW_NEED_UPDATE = 0;

    } catch {
        #$self->getLibrary()->show_exceptions($_ . "( LibraryServers->serverAddedRowNotify() )");
        $mod->setMessage($_ . '( LibraryServers->updatedRowNotify() )', 'error');
    };
}


sub serverDeletedRowNotify
{
    my ($self, $row) = @_;

    try {

    my $libDN = $self->loadLibrary('LibraryDomainName');
    $libDN->deleteDomainName($row->valueByName('domainName'), 'PoundServices');
    $libDN->deleteOtherDomainNames($row->valueByName('otherDomainName_subMod'), 'PoundServices');
    
    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    $libREDIR->deleteRedirects($row);

    my $libMAC = $self->loadLibrary('LibraryMAC');
    $libMAC->removeDHCPfixedIPMember($row);

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( PoundServices->deletedRowNotify() )');
    };
}


sub serverUpdatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    my $lib = $self->getLibrary();

    try {

        my $libDN = $self->loadLibrary('LibraryDomainName');
        $self->deletedRowNotify($oldRow);
        $libDN->updateDomainNameLink($row, 1);
    
        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->updateRedirectPorts($row);

        my $libCT = $self->loadLibrary('LibraryContact');
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);
        $libCT->setHardwareDisplay($row);

        if ($self->isDomainNameEnable($row) == 1) {
            $libDN->addDomainName($row->valueByName('domainName'));
        }

        $libREDIR->addRedirects($row);

        my $libMAC = $self->loadLibrary('LibraryMAC');
        $libMAC->updateNetworkDisplay($row);
        $libMAC->removeDHCPfixedIPMember($oldRow);
        $libMAC->addDHCPfixedIPMember($row);

        my $redirOther = $row->subModel('redirOther');

        for my $subId (@{$redirOther->ids()}) {
            my $redirRow = $redirOther->row($subId);
            $redirOther->deleteRedirect($oldRow, $redirRow);
            $redirOther->updateExtPortHTML($row, $redirRow);
            $redirOther->addRedirect($row, $redirRow);
        }

        $row->store();
    } catch {
        $lib->show_exceptions($_);
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

    return ($isEnable && $isBound);
}

1;
