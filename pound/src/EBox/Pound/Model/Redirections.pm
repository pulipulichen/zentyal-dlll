package EBox::Pound::Model::Redirections;

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

# Group: Public methods

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
    return $self->parentRow()->printableValueByName('domainName');
}

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