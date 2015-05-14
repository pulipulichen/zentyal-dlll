package EBox::dlllciasrouter::Model::PoundServices;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
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

use LWP::Simple;
use Try::Tiny;

sub _table
{
    my ($self) = @_;
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = (
        $fieldsFactory->createFieldAddBtn('add'),

        $fieldsFactory->createFieldConfigEnable(),
        $fieldsFactory->createFieldDomainName(),
        $fieldsFactory->createFieldDomainNameLink(),
        $fieldsFactory->createFieldInternalIPAddressHideView(1, 'The 1st part should be 10, <br />'
                . 'the 2nd part should be 1~5, <br />'
                . 'the 3rd part should be 0~9, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.1.0.51'),

        $fieldsFactory->createFieldMACAddr(),
        $fieldsFactory->createFieldOtherDomainNamesButton('/dlllciasrouter/View/PoundServices'),
        $fieldsFactory->createFieldOtherDomainNamesSubModel(),

        # ----------------------------
        $fieldsFactory->createFieldHr('hr_contact'),

        $fieldsFactory->createFieldContactName(),
        $fieldsFactory->createFieldContactEmail(),
        $fieldsFactory->createFieldDescription(),
        $fieldsFactory->createFieldDescriptionHTML(),
        $fieldsFactory->createFieldExpiryDate(),

        # ----------------------------
        $fieldsFactory->createFieldHr('hr_pound'),

        $fieldsFactory->createFieldBoundLocalDNS(),

        $fieldsFactory->createFieldNetworkDisplay(),
        
        #$fieldsFactory->createFieldRedirectToHTTPS(),

        $fieldsFactory->createFieldProtocolScheme('POUND', 0, 'http'),
        $fieldsFactory->createFieldInternalPortDefaultValue(80),

        #$fieldsFactory->createFieldPoundProtocolScheme(),

        $fieldsFactory->createFieldPoundOnlyForLAN(),
        $fieldsFactory->createFieldEmergencyRestarter(),

        $fieldsFactory->createFieldHr('hr1'),
        
        # --------------------------
        # HTTP Redirect Fields 
        $fieldsFactory->createFieldHTTPRedirect(),
        $fieldsFactory->createFieldHTTPOnlyForLAN(),
        $fieldsFactory->createFieldHTTPLog(),
        $fieldsFactory->createFieldHTTPExternalPort(),
        $fieldsFactory->createFieldHTTPInternalPort(),
        $fieldsFactory->createFieldProtocolScheme("HTTP", 0, "http"),
        $fieldsFactory->createFieldHTTPNote(),
        $fieldsFactory->createFieldHr('hr_http'),
        

        # ----------------------
        # HTTPS Redirect Fields
        $fieldsFactory->createFieldHTTPSRedirect(),
        $fieldsFactory->createFieldHTTPSOnlyForLAN(),
        $fieldsFactory->createFieldHTTPSLog(),
        $fieldsFactory->createFieldHTTPSExternalPort(),
        $fieldsFactory->createFieldHTTPSInternalPort(),
        $fieldsFactory->createFieldProtocolScheme("HTTPS", 0, "https"),
        $fieldsFactory->createFieldHTTPSNote(),
        $fieldsFactory->createFieldHr('hr_https'),
        
        # --------------------------------
        # SSH Redirect Fields
        $fieldsFactory->createFieldSSHRedirect(),
        $fieldsFactory->createFieldSSHOnlyForLAN(),
        $fieldsFactory->createFieldSSHLog(),
        $fieldsFactory->createFieldSSHExternalPort(),
        $fieldsFactory->createFieldSSHInternalPort(),
        $fieldsFactory->createFieldProtocolScheme("SSH", 0, "none"),
        $fieldsFactory->createFieldSSHNote(),
        $fieldsFactory->createFieldHr('hr_ssh'),

        # --------------------------------
        # RDP Redirect Fields
        $fieldsFactory->createFieldRDPRedirect(),
        $fieldsFactory->createFieldRDPOnlyForLAN(),
        $fieldsFactory->createFieldRDPLog(),
        $fieldsFactory->createFieldRDPExternalPort(),
        $fieldsFactory->createFieldRDPInternalPort(),
        $fieldsFactory->createFieldProtocolScheme("RDP", 0, "none"),
        $fieldsFactory->createFieldRDPNote(),
        $fieldsFactory->createFieldHr('hr_rdp'),

        # --------------------------------

        $fieldsFactory->createFieldDisplayRedirectPorts(),

        # --------------------------------
        # Other Redirect Ports

        $fieldsFactory->createFieldOtherRedirectPortsButton('/dlllciasrouter/View/PoundServices'),
        $fieldsFactory->createFieldOtherRedirectPortsHint(),
        $fieldsFactory->createFieldOtherRedirectPortsSubModel(),

        # --------------------------------
        # Date Display

        $fieldsFactory->createFieldCreateDateDisplay(),
        $fieldsFactory->createFieldCreateDateData(),
        $fieldsFactory->createFieldDisplayLastUpdateDate(),
        $fieldsFactory->createFieldDisplayContactLink(),

        # ----------------------------------

    );

    my $dataTable =
    {
        tableName => 'PoundServices',

        'pageTitle' => __('Pound Back End'),
        'printableTableName' => __('Pound Back End'),
        'defaultActions' => [ 'add', 'del', 'editField', 'clone', 'changeView' ],
        'modelDomain' => 'dlllciasrouter',
        'tableDescription' => \@fields,
        'printableRowName' => __('Pound Back End'),
        'HTTPUrlView'=> 'dlllciasrouter/View/PoundServices',

        'order' => 1,
    };

    return $dataTable;
}

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

# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

##
# 設定新增時的動作
##
sub addedRowNotify
{
    my ($self, $row) = @_;

    try {

    $ROW_NEED_UPDATE = 1;
    
    my $lib = $self->getLibrary();
    my $libDN = $self->loadLibrary('LibraryDomainName');
    $libDN->updateDomainNameLink($row, 1);
    
    my $libCT = $self->loadLibrary('LibraryContact');
    $libCT->setCreateDate($row);
    $libCT->setUpdateDate($row);
    $libCT->setContactLink($row);
    $libCT->setDescriptionHTML($row);

    $libDN->addDomainName($row);

    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    $libREDIR->updateRedirectPorts($row);
    $libREDIR->addRedirects($row);

    my $libMAC = $self->loadLibrary('LibraryMAC');
    $libMAC->updateNetworkDisplay($row);
    $libMAC->addDHCPfixedIPMember($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

# -------------------------------------------

sub deletedRowNotify
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

# -------------------------------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
        
    my $lib = $self->getLibrary();

    try {

    if ($ROW_NEED_UPDATE == 0) {

        $ROW_NEED_UPDATE = 1;
        
        my $libDN = $self->loadLibrary('LibraryDomainName');
        $self->deletedRowNotify($oldRow);
        $libDN->updateDomainNameLink($row, 1);
    
        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->updateRedirectPorts($row);

        my $libCT = $self->loadLibrary('LibraryContact');
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);

        $libDN->addDomainName($row);
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
        $ROW_NEED_UPDATE = 0;
    }

    } catch {
        $lib->show_exceptions($_);
    };
}

1;
