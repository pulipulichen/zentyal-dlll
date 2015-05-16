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

use Try::Tiny;

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

    my $options = $self->getOptions();

    my $network = EBox::Global->modInstance('network');
    my $external_iface = "eth0";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $external_iface = $if;
            last;
        }
    }

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();

    push(@fields, $fieldsFactory->createFieldServerLinkButton($options->{tableName}, 'SERVERS', $options->{configView}));

    #push(@fields, $fieldsFactory->createFieldWebLinkButton($options->{tableName}));

    push(@fields, $fieldsFactory->createFieldDomainName());
    push(@fields, $fieldsFactory->createFieldBoundLocalDNS());
    push(@fields, $fieldsFactory->createFieldExternalIPAddressHideView(1, ""));
    push(@fields, $fieldsFactory->createFieldProtocolExternalPortFixed('Main', $options->{externalPortDefaultValue}));
    push(@fields, $fieldsFactory->createFieldInternalIPAddressHideView(1,$options->{IPHelp}));

    push(@fields, $fieldsFactory->createFieldInternalPortDefaultValue($options->{internalPortDefaultValue}));
    push(@fields, $fieldsFactory->createFieldProtocolScheme('Main', 0, $options->{poundScheme}));

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

sub getOptions
{
    my $options = ();
    $options->{pageTitle} = __('Storage Main Server Setting');
    $options->{tableName} = 'StorageServerSetting';
    $options->{IPHelp} = 'The 1st part should be 10, '
                . 'the 2nd part should be 6, '
                . 'the 3rd part should be 1, and '
                . 'the 4th part should be between 1~99. '
                . 'Example: 10.6.1.4';
    $options->{poundScheme} = 'https';
    $options->{internalPortDefaultValue} = 443;
    $options->{externalPortDefaultValue} = 61000;
    $options->{configView} = '/dlllciasrouter/Composite/StorageServerComposite';
    $options->{headerModule} = 'StorageServerHeader';
    $options->{headerFieldName} = 'StorageServerHeader_web_button';
    return $options;
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
    my $options = $self->getOptions();

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        
        try {

        #$self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow);
        
        # 新增 Domain Name
        my $libDN = $self->loadLibrary('LibraryDomainName');
        $libDN->deleteDomainName($oldRow->valueByName('domainName'), 'PoundServices');

        if ($self->loadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
            $libDN->addDomainNameWithIP($row->valueByName('domainName'), $row->valueByName('extIpaddr'));
        }

        # 新增 Redirect
        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        my $tableName = $options->{tableName};
        my $extPort = $row->valueByName('redirMain_extPort');
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamDMZ($oldRow, $tableName, $extPort));
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamOrigin($oldRow, $tableName, $extPort));
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamZentyal($oldRow, $tableName, $extPort));

        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamDMZ($row, $tableName, $extPort));
        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamOrigin($row, $tableName, $extPort));
        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamZentyal($row, $tableName, $extPort));

        # 設定按鈕

        my $domainName = $row->valueByName('domainName');
        my $scheme = $row->valueByName('redirMain_scheme');
        my $button = '<span></span>';
        if ($scheme ne "none") {
            my $port = ":" . $extPort;
            if ($port eq ":80") {
                $port = "";
            }
            my $link = $scheme . "://" . $domainName . $port . "/";
            $button = '<a target="_blank" href="'.$link.'" class="btn btn-icon icon-webserver" style="padding-left: 40px !important;">Open Main Server</a>';
        }   # if ($shceme ne "none") {}

        my $fieldName = $options->{tableName} . '_web_button';
        if ($row->elementExists($fieldName)) {
            $row->elementByName($fieldName)->setValue($button);
        }
        $row->store();

        # 更新另外一個模組的資料
        my $header = $self->parentModule->model($options->{headerModule});
        $header->setValue($options->{headerFieldName}, $button);

        } catch {
            $self->getLibrary()->show_exceptions($_ . '( StorageServerSetting->updatedRowNotify() )');
        };

        $ROW_NEED_UPDATE = 0;
    }
}

1;
