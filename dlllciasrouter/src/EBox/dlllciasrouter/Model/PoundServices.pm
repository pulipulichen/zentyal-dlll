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
        $fieldsFactory->createFieldConfigEnable(),
        $fieldsFactory->createFieldDomainName(),
        $fieldsFactory->createFieldDomainNameLink(),
        $fieldsFactory->createFieldBoundLocalDNS(),
        $fieldsFactory->createFieldInternalIPAddressHideView(),

        $fieldsFactory->createFieldMACAddr(),
        $fieldsFactory->createFieldNetworkDisplay(),

        $fieldsFactory->createFieldInternalPort(),
        $fieldsFactory->createFieldRedirectToHTTPS(),
        $fieldsFactory->createFieldEmergencyRestarter(),

        $fieldsFactory->createFieldContactName(),
        $fieldsFactory->createFieldContactEmail(),
        $fieldsFactory->createFieldDescription(),
        $fieldsFactory->createFieldDescriptionHTML(),
        #$fieldsFactory->createFieldExpiryDateWithHR(),
        $fieldsFactory->createFieldExpiryDate(),
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

        $fieldsFactory->createFieldOtherRedirectPortsDisplay(),
        $fieldsFactory->createFieldOtherRedirectPortsHint(),

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
    my $libCT = $self->loadLibrary('LibraryContact');
    my $libREDIR = $self->loadLibrary('LibraryRedirect');

    $libDN->updateDomainNameLink($row);
    
    $libREDIR->updateRedirectPorts($row);

    $libCT->setCreateDate($row);
    $libCT->setUpdateDate($row);

    $libCT->setContactLink($row);
    $libCT->setDescriptionHTML($row);

    $libDN->addDomainName($row);
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

sub deletedRowNotify
{
    my ($self, $row) = @_;

    try {

    my $libDN = $self->loadLibrary('LibraryDomainName');
    $libDN->deleteDomainName($row, 'PoundServices');
    
    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    $libREDIR->deleteRedirects($row);

    my $libMAC = $self->loadLibrary('LibraryMAC');
    $libMAC->removeDHCPfixedIPMember($row);

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( PoundServices->deletedRowNotify() )');
    };
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    try {

    if ($ROW_NEED_UPDATE == 0) {

        $ROW_NEED_UPDATE = 1;
        
        my $lib = $self->getLibrary();
        my $libDN = $self->loadLibrary('LibraryDomainName');
        my $libCT = $self->loadLibrary('LibraryContact');
        my $libREDIR = $self->loadLibrary('LibraryRedirect');

        $self->deletedRowNotify($oldRow);
        $libDN->updateDomainNameLink($row);
    
        $libREDIR->updateRedirectPorts($row);
        
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
        my $lib = $self->getLibrary();
        $lib->show_exceptions($_);
    };
}

1;
