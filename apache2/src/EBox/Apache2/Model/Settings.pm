package EBox::Apache2::Model::Settings;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::Port;

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
        new EBox::Types::Port(
            'fieldName' => 'listeningPort',
            'printableName' => __('Listening port'),
	        'defaultValue' => 80,
            'editable' => 1
        )
    );

    my $dataTable =
    {
        tableName => 'Settings',
        printableTableName => __('Settings'),
        pageTitle => $self->parentModule()->printableName(),
        defaultActions => [ 'editField' ],
        modelDomain => 'Apache2',
        tableDescription => \@fields,
        help => __('This is the help of the model')
    };

    return $dataTable;
}

1;
