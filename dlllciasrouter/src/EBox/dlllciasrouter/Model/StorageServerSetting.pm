package EBox::dlllciasrouter::Model::StorageServerSetting;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Link;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;
use EBox::Types::Link;
use EBox::Types::Boolean;

use EBox::Network;

# Group: Public methods

# Constructor: new
#
#      Create a new Text model instance
#
# Returns:
#
#      <EBox::DNS::Model::StorageServerSetting> - the newly created model
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
    my $external_iface = "eth0";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $external_iface = $if;
            last;
        }
    }

    my $options = ();
    $options->{pageTitle} = __('Storage Main Server Setting');
    $options->{tableName} = 'StorageServerSetting';
    $options->{IPHelp} = 'The 1st part should be 10, '
                . 'the 2nd part should be 6, '
                . 'the 3rd part should be 1, and '
                . 'the 4th part should be between 1~99. '
                . 'Example: 10.6.1.4';

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();
    push(@fields, $fieldsFactory->createFieldDomainName());
    push(@fields, $fieldsFactory->createFieldBoundLocalDNS());
    push(@fields, $fieldsFactory->createFieldExternalIPAddressHideView(1, ""));
    push(@fields, $fieldsFactory->createFieldInternalIPAddressHideView(1,$options->{IPHelp}));

    my $dataTable =
        {
            tableName => $options->{tableName},
            'pageTitle' => $options->{pageTitle},
            'printableTableName' => $options->{pageTitle},
            modelDomain     => 'dlllciasrouter',
            defaultActions => [ 'editField' ],
            tableDescription => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/View/' . $options->{tableName},
        };

    return $dataTable;
}

# -------------------------------------------------------------

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


# -----------------------

my $ROW_NEED_UPDATE = 0;

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    $self->loadLibrary("StorageServers")->checkInternalIP($row);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        
        #$self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow);
        
        # 新增 Domain Name
        my $libDN = $self->loadLibrary('LibraryDomainName');
        $libDN->deleteDomainName($oldRow->valueByName('domainName'), 'PoundServices');

        if ($self->loadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
            $libDN->addDomainNameWithIP($row->valueByName('domainName'), $row->valueByName('extIpaddr'));
        }

        # 新增 Redirect
        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParam($oldRow));
        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParam($row));

        $ROW_NEED_UPDATE = 0;
    }
}

1;
