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
        $fieldsFactory->createFieldExpiryDateWithHR(),
        
        # --------------------------
        # HTTP Redirect Fields 
        $fieldsFactory->createFieldHTTPRedirect(),
        $fieldsFactory->createFieldHTTPOnlyForLAN(),
        $fieldsFactory->createFieldHTTPLog(),
        $fieldsFactory->createFieldHTTPExternalPort(),
        $fieldsFactory->createFieldHTTPInternalPort(),
        $fieldsFactory->createFieldHTTPNote(),

        # ----------------------
        # HTTPS Redirect Fields
        $fieldsFactory->createFieldHTTPSRedirect(),
        $fieldsFactory->createFieldHTTPSOnlyForLAN(),
        $fieldsFactory->createFieldHTTPSLog(),
        $fieldsFactory->createFieldHTTPSExternalPort(),
        $fieldsFactory->createFieldHTTPSInternalPort(),
        $fieldsFactory->createFieldHTTPSNote(),
        
        # --------------------------------
        # SSH Redirect Fields
        $fieldsFactory->createFieldSSHRedirect(),
        $fieldsFactory->createFieldSSHOnlyForLAN(),
        $fieldsFactory->createFieldSSHLog(),
        $fieldsFactory->createFieldSSHExternalPort(),
        $fieldsFactory->createFieldSSHInternalPort(),
        $fieldsFactory->createFieldSSHNote(),

        # --------------------------------
        # RDP Redirect Fields
        $fieldsFactory->createFieldRDPRedirect(),
        $fieldsFactory->createFieldRDPOnlyForLAN(),
        $fieldsFactory->createFieldRDPLog(),
        $fieldsFactory->createFieldRDPExternalPort(),
        $fieldsFactory->createFieldRDPInternalPort(),
        $fieldsFactory->createFieldRDPNote(),

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

        'pageTitle' => __('Back End'),
        printableTableName => __('Back End'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        modelDomain => 'dlllciasrouter',
        tableDescription => \@fields,
        printableRowName => __('Back End'),
        #sortedBy => 'updateDate',
        'HTTPUrlView'=> 'dlllciasrouter/View/PoundServices',

        # 20140219 Pulipuli Chen
        # 關閉enable選項，改成自製的
        #'enableProperty' => 0,
        #defaultEnabledValue => 1,
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
}

sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    my $libDN = $self->loadLibrary('LibraryDomainName');
    $libDN->deleteDomainName($row, 'PoundServices');
    $libREDIR->deleteRedirects($row);

    my $libMAC = $self->loadLibrary('LibraryMAC');
    $libMAC->removeDHCPfixedIPMember($row);
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
        $libCT->setDescriptionHTML($row);

        $libDN->addDomainName($row);
        $libREDIR->addRedirects($row);

        my $libMAC = $self->loadLibrary('LibraryMAC');
        $libMAC->updateNetworkDisplay($row);
        $libMAC->removeDHCPfixedIPMember($oldRow);
        $libMAC->addDHCPfixedIPMember($row);

        for my $subId (@{$row->subModel('redirOther')->ids()}) {
            my $redirRow = $row->subModel('redirOther')->row($subId);
            my $redirModel = $row->subModel('redirOther');
            $redirModel->deleteRedirect($oldRow, $redirRow);
            $redirModel->updateExtPortHTML($row, $redirRow);
            $redirModel->addRedirect($row, $redirRow);
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
