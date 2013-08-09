package EBox::Pound::Model::Settings;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Union;
use EBox::Types::Union::Text;

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
    my $address = "127.0.0.1";
    my $external_iface = "eth0";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $external_iface = $if;
            $address = $network->ifaceAddress($if);
            last;
        }
    }

    my @tableDesc =
      (
#          new EBox::Types::HostIP(
#              fieldName     => 'address',
#              printableName => __('External IP Address'),
#              editable      => 0,
#              unique        => 1,
#              defaultValue  => $address,
#              help          => '<a href="/Network/Ifaces?iface='.$external_iface.'">'.__('Modify External Network').'</a>',
#              allowUnsafeChars => 1,
#             ),
          new EBox::Types::Union(
            'fieldName' => 'address',
            'printableName' => __('External IP Address'),
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'address_extIface',
                'printableName' => $external_iface." (".$address.")"),
            new EBox::Types::HostIP(
                'fieldName' => 'address_custom',
                'printableName' => __('Custom'),
                'editable' => 1,),
            ]
          ),
          new EBox::Types::Port(
              fieldName     => 'port',
              printableName => __('External Port'),
              editable      => 1,
              unique        => 1,
              help          => "<ul>"
                                . '<li><a href="/Firewall/View/ExternalToEBoxRuleTable">' . __("Please add rule to allow this port from external networks link to Zentyal") . "</a></li>"
                                #. '<li><a href="/Firewall/View/ExternalToInternalRuleTable">' . __("Please add rule to allow port 10000~60000 from external networks link to internal networks") . "</a></li>"
                                . '</ul>'
                                . '<a href="/Firewall/View/RedirectsTable" target="_blank">Custom Port Forwarding</a>'
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
