package EBox::Pound::Model::DNS;

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
    my $fieldsFactory = $self->getLibrary();

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
        modelDomain => 'Pound',
        tableDescription => \@fields,

        'pageTitle' => __('DNS'),
        printableRowName => __('DNS'),
        #sortedBy => 'domainName',
        'HTTPUrlView'=> 'Pound/View/DNS',
        
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


# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();
    
    $lib->updateDomainNameLink($row);

    $lib->setCreateDate($row);
    $lib->setUpdateDate($row);

    $lib->setContactLink($row);

    $lib->addDomainName($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();
    $lib->deleteDomainName($row, 'DNS');
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        my $lib = $self->getLibrary();

        $self->deletedRowNotify($oldRow);
        
        $lib->updateDomainNameLink($row);
    
        $lib->setCreateDate($row);
        $lib->setUpdateDate($row);

        $lib->setContactLink($row);
        
        try 
        {
            if ($row->valueByName("configEnable")) {
                $lib->addDomainName($row);
            }
            else {
                $lib->deleteDomainName($row, 'DNS');
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
