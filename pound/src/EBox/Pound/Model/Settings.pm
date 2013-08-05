package EBox::Pound::Model::Settings;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Types::HostIP;
use EBox::Types::Port;

use EBox::Network;

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

    my $network = EBox::Global->modInstance('network');
    #my @ifaces = $network->allIfaces();
    #for(my $i=0; $i <= \@ifaces; $i++) {
    my $iface_help = "";
    foreach my $if (@{$network->allIfaces()}) {
        #$if = $ifaces[$i];
        my $address = $network->ifaceAddress($if);
        #$iface_help = $if . " " . $address;
        if ($iface_help ne "") {
            $iface_help = $iface_help . "<br />\n";
        }
        $iface_help = $iface_help . $if . ": " . $address;
    }

    my @tableDesc =
      (
          new EBox::Types::HostIP(
              fieldName     => 'address',
              printableName => __('Address'),
              editable      => 1,
              unique        => 1,
              help          => __($iface_help),
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
