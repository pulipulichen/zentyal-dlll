package EBox::dlllciasrouter::Model::DNS;

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

# Method: _table
#
# Overrides:
#
#       <EBox::Model::DataTable::_table>
#
sub _table
{
    my ($self) = @_;
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = (
        $fieldsFactory->createFieldConfigEnable(),
        $fieldsFactory->createFieldDomainNameUnique(),
        $fieldsFactory->createFieldBoundLocalDNS(),
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
        $fieldsFactory->createFieldExpiryDate(),

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
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
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
# 讀取PoundLibrary
# @author Pulipuli Chen
##
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

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();
    my $libDN = $self->loadLibrary('LibraryDomainName');
    my $libCT = $self->loadLibrary('LibraryContact');
    
    $libDN->updateDomainNameLink($row);

    $libCT->setCreateDate($row);
    $libCT->setUpdateDate($row);

    $libCT->setContactLink($row);
    $libCT->setDescriptionHTML($row);

    $libDN->addDomainName($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $libDN = $self->loadLibrary('LibraryDomainName');

    $libDN->deleteDomainName($row, 'DNS');
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        my $lib = $self->getLibrary();
        my $libDN = $self->loadLibrary('LibraryDomainName');
        my $libCT = $self->loadLibrary('LibraryContact');

        $self->deletedRowNotify($oldRow);
        
        $libDN->updateDomainNameLink($row);
    
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);

        $libCT->setContactLink($row);
        $libCT->setDescriptionHTML($row);
        
        try 
        {
            if ($row->valueByName("configEnable")) {
                $libDN->addDomainName($row);
            }
            else {
                $libDN->deleteDomainName($row, 'DNS');
            }
        } catch {
            my $lib = $self->getLibrary();
            $lib->show_exceptions($_);
        };
        

        $row->store();
        $ROW_NEED_UPDATE = 0;
    }
}

1;
