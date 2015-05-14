package EBox::dlllciasrouter::Model::StorageServers;

use base 'EBox::Model::DataTable';

use EBox::Global;
use EBox::Gettext;
use EBox::Validate qw(:all);
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::Port;
use EBox::Types::HTML;
use EBox::Types::Date;
use EBox::Types::Boolean;
use EBox::Types::Text;

use POSIX qw(strftime);
use Try::Tiny;

# Group: Public methods

#sub new
#{
#    my $class = shift;
#    my %parms = @_;
#
#    my $self = $class->SUPER::new(@_);
#    bless ($self, $class);
#
#    return $self;
#}

sub _table
{

    my ($self) = @_;
    my $fieldsFactory = $self->loadLibrary('LibraryFields');
    
    my @fields = (
        $fieldsFactory->createFieldConfigEnable(),
        
        $fieldsFactory->createFieldDomainNameUnique(),
        $fieldsFactory->createFieldDomainNameLink(),
        $fieldsFactory->createFieldBoundLocalDNS(),

        $fieldsFactory->createFieldIpaddrLink(),
        $self->createFieldInternalIPAddressHideView(),

        $fieldsFactory->createFieldMACAddr(),
        $fieldsFactory->createFieldNetworkDisplay(),

        $fieldsFactory->createFieldInternalPortDefaultValue(443),
        $fieldsFactory->createFieldProtocolOnlyForLAN('Main', 1),

        $fieldsFactory->createFieldIsHTTPS(),

        $self->createFieldOtherRedirectPortsDisplay(),
        
        $fieldsFactory->createFieldHardwareCPU(),
        $fieldsFactory->createFieldHardwareRAM(),
        $fieldsFactory->createFieldHardwareDisk(),
        $fieldsFactory->createFieldHardwareDisplay(),

        $fieldsFactory->createFieldHr('hr1'),

        $fieldsFactory->createFieldContactName(),
        $fieldsFactory->createFieldContactEmail(),
        $fieldsFactory->createFieldDisplayContactLink(),
        $fieldsFactory->createFieldDescription(),
        $fieldsFactory->createFieldDescriptionHTML(),
        
        $fieldsFactory->createFieldCreateDateDisplay(),
        $fieldsFactory->createFieldCreateDateData(),
        $fieldsFactory->createFieldDisplayLastUpdateDate(),
    );

    my $dataTable =
    {
        'tableName' => 'StorageServers',
        'printableTableName' => __('Storage Servers'),
        'printableRowName' => __('Storage Servers'),
        'pageTitle' => __('Storage Servers'),
        'modelDomain' => 'dlllciasrouter',
        'defaultController' => '/dlllciasrouter/Controller/StorageServers',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView' ],
        'tableDescription' => \@fields,
        'class' => 'dataTable',
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

my $ROW_NEED_UPDATE = 0;

# -----------------------------

##
# 20150513 Pulipuli Chen
# 增加
##
sub addedRowNotify
{
    my ($self, $row) = @_;

    $self->checkInternalIP($row);

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
    $libCT->setHardwareDisplay($row);

    $libDN->setServerMainLink($row);
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

# -----------------------------

##
# 20150513 Pulipuli Chen
# 刪除
##
sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $libDN = $self->loadLibrary('LibraryDomainName');

    try {
        
        $libDN->deleteDomainName($row, 'StorageServers');

        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->deleteRedirects($row);

        my $libMAC = $self->loadLibrary('LibraryMAC');
        $libMAC->removeDHCPfixedIPMember($row);

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( StorageServers->deletedRowNotify() )');
    };
}

# -----------------------------

##
# 20150513 Pulipuli Chen
##
sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    my $lib = $self->getLibrary();
    $self->checkInternalIP($row);

    try {

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        
        my $libDN = $self->loadLibrary('LibraryDomainName');
        $self->deletedRowNotify($oldRow);
        $libDN->updateDomainNameLink($row, 1);

        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->updateRedirectPorts($row);

        $libDN->setServerMainLink($row);

        # 設定Netword的那一個
        my $libCT = $self->loadLibrary('LibraryContact');
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);
        $libCT->setDescriptionHTML($row);
        $libCT->setHardwareDisplay($row);
        
        #$libDN->addDomainName($row);
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

# -----------------------------

sub createFieldInternalIPAddressHideView
{
    my $field = new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
            #'unique' => 1,
            help => __('The 1st part should be 10, <br />'
                . 'the 2nd part should be 6, <br />'
                . 'the 3rd part should be 1, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.6.1.1'),
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
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
        || !($partB == 6) 
        || !($partC == 1) 
        || !($partD > 0 && $partD < 100) ) {
        $self->getLibrary()->show_exceptions('The 1st part should be 10, <br />'
                    . 'the 2nd part should be 6, <br />'
                    . 'the 3rd part should be 1, and <br />'
                    . 'the 4th part should be between 1~99. <br />'
                    . 'Example: 10.6.1.1');
    }
}

# --------------------------------------
# Other Redirect Ports

sub createFieldOtherRedirectPortsDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HasMany(
            'fieldName' => 'redirOther',
            'printableName' => __('Other <br />Redirect <br />Ports'),
            'foreignModel' => 'ServerPortRedirect',
            'view' => '/dlllciasrouter/View/StorageServers/PortRedirect',
            'backView' => '/dlllciasrouter/View/StorageServers',
            'size' => '1',
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 0,
       );
    return $field;
}


1