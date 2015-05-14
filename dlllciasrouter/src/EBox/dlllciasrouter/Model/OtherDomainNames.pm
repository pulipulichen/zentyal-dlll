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
use EBox::Types::Text;
use EBox::Types::Boolean;
use EBox::Types::Int;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;

use Try::Tiny;


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
    my $row = $self->parentRow();
    
    if (defined($row))
    {
        my $domainName = $row->printableValueByName('domainName');
        my $ip = $row->printableValueByName('ipaddr');
        return $domainName . " (" . $ip . ")";
    }
    else {
        return __("Other Domain Names");
    } 
}

sub _table
{

    my ($self) = @_;  
    
    my $libFactory = $self->parentModule()->model('LibraryFields');

    my @fields = (
        $libFactory->createFieldConfigEnable(),

        $libFactory->createFieldDomainName(),
        $libFactory->createFieldDomainNameLink(),
        $libFactory->createFieldBoundLocalDNS(),
        $libFactory->createFieldProtocolScheme('POUND', 0, 'http'),
        $libFactory->createFieldInternalPortDefaultValue(80),
        $libFactory->createFieldPoundOnlyForLAN(),
        $libFactory->createFieldEmergencyRestarter(),
    );

    my $dataTable =
    {
        'tableName' => 'OtherDomainNames',
        'printableTableName' => __('Other Domain Names'),
        'printableRowName' => __('Other Domain Names'),
        'pageTitle' => $self->pageTitle(),
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

# --------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $dnRow) = @_;

    $ROW_NEED_UPDATE = 1;

    try {

    my $row = $self->parentRow();
    my $libDN = $self->loadLibrary('LibraryDomainName');
    
    # 1. 更新自己欄位的domain name連線資訊
    $libDN->updateDomainNameLink($dnRow, 0);
    $libDN->addDomainName($dnRow);

    # 2. 更新row欄位的domain name顯示資訊
    $libDN->updateDomainNameLink($row, 1);
    $row->store();

    # 3. 看是否要設定*****0欄位 (由row去觸發)
    #my $libREDIR = $self->loadLibrary('LibraryRedirect');
    #$libREDIR->addPoundRedirect($row);
    
    $dnRow->store();

    } catch {
        $self->getLibrary()->show_exceptions( $_ . '; Please add domain name again. (OtherDomainNames->addedRowNotify)');
    };

    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $redirRow) = @_;
    
    try {

    #my $row = $self->parentRow();
    #my $libRe = $self->parentModule()->model("LibraryRedirect");
    #$libRe->deleteOtherOtherDomainNames($row, $redirRow);
    #$libRe->updateRedirectPorts($row);

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

sub updatedRowNotify
{
    my ($self, $redirRow, $oldRedirRow) = @_;

    try {

    #$self->checkExternalPort($redirRow);
    #my $row = $self->parentRow();

    #if (!defined($row)) {
    #    $self->getLibrary()->show_exceptions("row is not defined");
    #}

    #my $libRe = $self->parentModule()->model("LibraryRedirect");
    #$libRe->updateOtherOtherDomainNamesPorts($row, $redirRow, $oldRedirRow);

    #if ($ROW_NEED_UPDATE == 0) {
    #    $ROW_NEED_UPDATE = 1;
    #
    #    my $libDomainName = $self->loadLibrary('LibraryDomainName');
    #    $libDomainName->updatePortDescription($row, $redirRow);
    #
    #    $self->updateExtPortHTML($row, $redirRow);
    #    $ROW_NEED_UPDATE = 0;
    #}

    } catch {
        $self->getLibrary()->show_exceptions($_);
    };
}

# --------------------------------


1;