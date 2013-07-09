package EBox::Pound::Model::Settings;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Types::HostIP;
use EBox::Types::Port;

# Group: Public methods

# Constructor: new
#
#      Create a new Text model instance
#
# Returns:
#
#      <EBox::DNS::Model::Settings> - the newly created model
#      instance
#
sub new
{
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless($self, $class);

    return $self;
}

# Group: Protected methods

# Method: _table
#
# Overrides:
#
#     <EBox::Model::DataForm::_table>
#
sub _table
{
    my ($self) = @_;

    my @tableDesc =
      (
          new EBox::Types::HostIP(
              fieldName     => 'address',
              printableName => __('Address'),
              editable      => 1,
              unique        => 1,
             ),
          new EBox::Types::Port(
              fieldName     => 'port',
              printableName => __('port'),
              editable      => 1,
              unique        => 1,
             ),
      );

    my $dataTable =
        {
            tableName => 'Settings',
            printableTableName => __('Settings'),
            modelDomain     => 'Pound',
            defaultActions => [ 'editField',  'changeView' ],
            tableDescription => \@tableDesc,
            'HTTPUrlView'=> 'Pound/Composite/Global',
        };

    return $dataTable;
}

1;
