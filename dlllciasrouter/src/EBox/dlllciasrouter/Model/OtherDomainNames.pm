package EBox::dlllciasrouter::Model::OtherDomainNames;

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
#use EBox::Types::Text;
use EBox::Types::Boolean;
use EBox::Types::Int;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;

use Try::Tiny;

# -----------------------------------

sub getOptions
{
    my $options = ();
    $options->{tableName} = 'OtherDomainNames';
    $options->{pageTitle} = __("Other Domain Names");
    $options->{printableTableName} = __('Other Domain Names')  . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-backview.js"></script>';
    $options->{printableRowName} = __("Other Domain Name");

    return $options;
}

# -----------------------------------

sub new
{
    my $class = shift;
    my %parms = @_;

    my $self = $class->SUPER::new(@_);
    bless ($self, $class);

    return $self;
}

sub pageTitle
{
    my ($self) = @_;
    try {
        my $lib = $self->getLibrary();
        my $row = $lib->getParentRow($self);

        my $domainName = $row->printableValueByName('domainName');
        my $ip = $row->printableValueByName('ipaddr');
        return $domainName . " (" . $ip . ")";
    }
    catch {
        my $options = $self->getOptions();
        return $options->{pageTitle};
    }
}

sub _table
{
    my ($self) = @_;  
    
    my $options = $self->getOptions();

    my $libFactory = $self->parentModule()->model('LibraryFields');

    my @fields = (
        #$libFactory->createFieldAddBtn('add'),

        $libFactory->createFieldConfigEnableHidden(),

        $libFactory->createFieldDomainName(),
        $libFactory->createFieldDomainNameLink(),
        $libFactory->createFieldBoundLocalDNSHidden(),
        $libFactory->createFieldProtocolScheme('POUND', 0, 'http'),
        $libFactory->createFieldInternalPortDefaultValue(80),
        $libFactory->createFieldPoundOnlyForLAN(0),
        $libFactory->createFieldEmergencyRestarter(),
    );

    my $dataTable =
    {
        'tableName' => $options->{tableName},
        'pageTitle' => $self->pageTitle(),
        'printableTableName' => $options->{printableTableName},
        'printableRowName' => $options->{printableRowName},
        'modelDomain' => 'dlllciasrouter',
        'automaticRemove' => 1,
        'defaultController' => '/dlllciasrouter/Controller/OtherDomainNames',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView'],
        'tableDescription' => \@fields,
        'sortedBy' => 'domainName',
        'class' => 'dataTable',
    };

    return $dataTable;
}

# --------------------------------

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

# --------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $subRow) = @_;

    $ROW_NEED_UPDATE = 1;

    try {

        my $libDN = $self->loadLibrary('LibraryDomainName');
        #$subRow = $self->row();
        #my $row = $self->parentRow();

        my $row = $self->getLibrary()->getParentRow($self);
        
        #my $isRowEnable = $self->getLibrary()->isEnable($row);
        #my $isSubRowEnable = $self->getLibrary()->isEnable($subRow);
        my $isRowEnable = $self->loadLibrary('LibraryServers')->isDomainNameEnable($row);
        #my $isSubRowEnable = $self->loadLibrary('LibraryServers')->isDomainNameEnable($subRow);

        # 1. 更新自己欄位的domain name連線資訊
        $libDN->updateDomainNameLink($subRow, 0);
        #if ($isRowEnable == 1 && $isSubRowEnable == 1) {
        if ($isRowEnable == 1) {
            $libDN->addDomainName($subRow->valueByName('domainName'));
        }

        # 2. 更新row欄位的domain name顯示資訊
        $libDN->updateDomainNameLink($row, 1);

        $row->store();
        $subRow->store();

    } catch {

        $self->getLibrary()->show_exceptions( $_ . '; Please add domain name again. ( OtherDomainNames->addedRowNotify() )');

    };

    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $subRow) = @_;
    
    try {

        # 刪除Domain Name
        my $libDN = $self->loadLibrary('LibraryDomainName');
        $libDN->deleteDomainName($subRow->valueByName('domainName'), 'dlllciasrouter-pound');

        # 更新row的資料

        #my $row = $self->parentRow();
        my $row = $self->getLibrary()->getParentRow($self);
        $libDN->updateDomainNameLink($row, 1);
        $row->store();

    } catch {
        $self->getLibrary()->show_exceptions($_ . ' ( OtherDomainNames->deletedRowNotify() )');
    };
}

sub updatedRowNotify
{
    my ($self, $subRow, $oldSubRow) = @_;

    try {

        #my $row = $self->parentRow();
        #my $row = $self->getLibrary()->getParentRow($self);

        if ($ROW_NEED_UPDATE == 0) {
            $ROW_NEED_UPDATE = 1;

            $self->deletedRowNotify($oldSubRow);
            $self->addedRowNotify($subRow);

            $ROW_NEED_UPDATE = 0;
        }   # if ($ROW_NEED_UPDATE == 0) {

    } catch {
        $self->getLibrary()->show_exceptions($_ . " (  OtherDomainNames->updatedRowNotify() ) ");
    };
}

# --------------------------------


1;