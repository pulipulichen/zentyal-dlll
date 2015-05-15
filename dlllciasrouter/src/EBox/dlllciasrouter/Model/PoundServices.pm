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
        #$fieldsFactory->createFieldDescription(),

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
        #$fieldsFactory->createFieldAttachedFilesButton('/dlllciasrouter/View/PoundServices'),

        # ----------------------------------

        #new EBox::Types::HasMany(
        #    fieldName => 'configuration',
        #    printableName => __('Configuration'),
        #    foreignModel => 'BackEndConfiguration',
        #    foreignModelIsComposite => 1,
        #    view => '/dlllciasrouter/Composite/BackEndConfiguration',
        #    backView => 'dlllciasrouter/View/PoundServices',
        #),

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
    $self->checkInternalIP($row);
    $ROW_NEED_UPDATE = 1;
    $self->loadLibrary("LibraryServers")->serverAddedRowNotify($row);
    $ROW_NEED_UPDATE = 0;
}

# -------------------------------------------

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->loadLibrary("LibraryServers")->serverDeletedRowNotify($row);
}

# -------------------------------------------

my $ROW_NEED_UPDATE = 0;

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    $self->checkInternalIP($row);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        $self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow);
        $ROW_NEED_UPDATE = 0;
    }
}

sub checkInternalIP
{
    my ($self, $row) = @_;

    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    my $partC = $parts[2];
    my $partD = $parts[3];

    if (!($partA == 10) 
        || !($partB > 0 && $partB < 5) 
        || !($partC > -1 && $partC < 10) 
        || !($partD > 0 && $partD < 100) ) {
        $self->loadLibrary("PoundLibrary")->show_exceptions('The 1st part should be 10, <br />'
                    . 'the 2nd part should be 1~5, <br />'
                    . 'the 3rd part should be 0~9, and <br />'
                    . 'the 4th part should be between 1~99. <br />'
                    . 'Example: 10.6.1.1');
    }
}

1;
