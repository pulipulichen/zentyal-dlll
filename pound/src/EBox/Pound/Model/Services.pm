package EBox::Pound::Model::Services;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::Boolean;

# Method: _table
#
# Overrides:
#
#       <EBox::Model::DataTable::_table>
#
sub _table
{
    my ($self) = @_;

    my @fields = (
        new EBox::Types::DomainName(
            fieldName => 'domainName',
            printableName => __('Domain Name'),
            editable => 1,
        ),
        new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('IP Address'),
            editable => 1,
        ),
        new EBox::Types::Port(
            fieldName => 'port',
            printableName => __('port'),
            defaultValue => 80,
            editable => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('description'),
            editable => 1,
        ),
        new EBox::Types::Boolean(
            fieldName => 'enabled',
            printableName => __('enabled'),
            editable => 1,
            optional => 0,
            defaultValue => 0
        ),
    );

    my $dataTable =
    {
        tableName => 'Services',
        printableTableName => __('Services'),
        defaultActions => [ 'add', 'del', 'editField', 'changeView' ],
        pageTitle => 'Services',
        modelDomain => 'Pound',
        tableDescription => \@fields,
        printableRowName => __('Pound Service'),
        sortedBy => 'domainName',
        'HTTPUrlView'=> 'DNS/Composite/Global',
        help => __('This is the help of the model'),
    };

    return $dataTable;
}

1;
