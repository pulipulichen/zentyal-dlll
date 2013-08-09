package EBox::Pound::Model::Redirections;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::Port;

sub _table
{

    my ($self) = @_;  

    my @fields = (
        new EBox::Types::Port(
            'fieldName' => 'extPort',
            'printableName' => __('External Port'),
            'unique' => 1,
            'editable' => 1
        ),
        new EBox::Types::Port(
            'fieldName' => 'intPort',
            'printableName' => __('Internal Port'),
            'unique' => 1,
            'editable' => 1
        ),
    );

    my $dataTable =
    {
        'tableName' => 'Redirections',
        'printableTableName' => __('Port Redirect'),
        'printableRowName' => __('Port Redirect'),
        'modelDomain' => 'Pound',
        'defaultActions' => ['add', 'del', 'editField', 'changeView' ],
        'tableDescription' => \@fields,
        'sortedBy' => 'extPort',
        'enableProperty' => 1,
    };

    return $dataTable;
}

1;