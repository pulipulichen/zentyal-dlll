package EBox::dlllciasrouter::Model::DNS;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
#use EBox::Types::Text;
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

# Method: _table
#
# Overrides:
#
#       <EBox::Model::DataTable::_table>
#
sub _table
{
    my ($self) = @_;
    my $fieldsFactory = $self->getLoadLibrary('LibraryFields');

    my @fields = (
        $fieldsFactory->createFieldConfigEnable(),
        $fieldsFactory->createFieldDomainNameUnique(),
        # $fieldsFactory->createFieldWildcardDomainNameUnique(),
        $fieldsFactory->createFieldBoundLocalDNS(),
        $fieldsFactory->createFieldEnableWildcardDNS(),
        $fieldsFactory->createFieldDomainNameLink(),
        new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('IP Address'),
            editable => 1,
        ),
        
        $fieldsFactory->createFieldContactName(),
        $fieldsFactory->createFieldContactEmail(),
        $fieldsFactory->createFieldDescription(),
        $fieldsFactory->createFieldDescriptionHTML(),
        $fieldsFactory->createFieldExpiryDate('NEVER'),

        $fieldsFactory->createFieldCreateDateDisplay(),
        $fieldsFactory->createFieldCreateDateData(),
        $fieldsFactory->createFieldDisplayLastUpdateDate(),

        $fieldsFactory->createFieldDisplayContactLink(),

        # ----------------------------------
    );

    my $dataTable =
    {
        tableName => 'DNS',
        printableTableName => __('DNS'),
        defaultActions => [ 'add', 'del', 'editField', 'clone', 'changeView' ],
        modelDomain => 'dlllciasrouter',
        tableDescription => \@fields,

        'pageTitle' => __('DNS'),
        printableRowName => __('DNS'),
        #sortedBy => 'domainName',
        'HTTPUrlView'=> 'dlllciasrouter/View/DNS',
        
        # 20140219 Pulipuli Chen
        # 關閉enable選項，改成自製的
        #'enableProperty' => 0,
        #defaultEnabledValue => 1,
        'order' => 1,
    };

    return $dataTable;
}

##
# 讀取LibraryToolkit
# @author Pulipuli Chen
##
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
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}


# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

sub getWildcardDomainName 
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName('domainName');
    if ($row->elementExists('enableWildcardDNS')) {
    my $enableWildcardDNS = $row->valueByName("enableWildcardDNS");
    if ($enableWildcardDNS == 1) {
        $domainName = "*." .$domainName
    }
    return $domainName
}

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();
    my $libDN = $self->getLoadLibrary('LibraryDomainName');
    my $libCT = $self->getLoadLibrary('LibraryContact');
    
    $libDN->updateDomainNameLink($row, 1);

    $libCT->setCreateDate($row);
    $libCT->setUpdateDate($row);

    $libCT->setContactLink($row);
    $libCT->setDescriptionHTML($row);

    if ($self->getLoadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
        #$libDN->addDomainName($row->valueByName('domainName'));
        my $domainName = $self->getWildcardDomainName($row);
        $libDN->addDomainNameWithIP($domainName, $row->valueByName('ipaddr'));
    }

    $row->store();
    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $libDN = $self->getLoadLibrary('LibraryDomainName');

    # my $domainName = $self->getWildcardDomainName($row);
    # $libDN->deleteDomainName($domainName, 'DNS');
    
    $libDN->deleteDomainName($row->valueByName('domainName'), 'DNS');
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        my $lib = $self->getLibrary();
        my $libDN = $self->getLoadLibrary('LibraryDomainName');
        my $libCT = $self->getLoadLibrary('LibraryContact');

        $self->deletedRowNotify($oldRow);
        
        $libDN->updateDomainNameLink($row, 1);
    
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);

        $libCT->setContactLink($row);
        
        try 
        {
            # my $domainName = $self->getWildcardDomainName($row);
            # if ($row->valueByName("configEnable")) {
            #     if ($self->getLoadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
            #         $libDN->addDomainNameWithIP($domainName, $row->valueByName('ipaddr'));
            #     }
            # }
            # else {
            #     $libDN->deleteDomainName($domainName, 'DNS');
            # }

            # my $domainName = $self->getWildcardDomainName($row);
            if ($row->valueByName("configEnable")) {
                if ($self->getLoadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
                    $libDN->addDomainNameWithIP($row->valueByName('domainName'), $row->valueByName('ipaddr'));
                }
            }
            else {
                $libDN->deleteDomainName($row->valueByName('domainName'), 'DNS');
            }
        } catch {
            my $lib = $self->getLibrary();
            $lib->show_exceptions($_ . " ( DNS->updatedRowNotify() )");
        };

        $row->store();
        $ROW_NEED_UPDATE = 0;
    }
}

1;
