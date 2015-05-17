package EBox::dlllciasrouter::Model::LibrarySetting;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use Try::Tiny;


# -----------------------------

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

# ----------------------------

sub getDataTable
{
    my ($self, $options) = @_;

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

    my $tableName = $options->{moduleName} . "Setting";
    my $configView = '/dlllciasrouter/Composite/'. $options->{moduleName} . 'Composite';
    push(@fields, $fieldsFactory->createFieldServerLinkButton($tableName, 'SERVERS', $configView));
    push(@fields, $fieldsFactory->createFieldHr('hr_setting'));


    #push(@fields, $fieldsFactory->createFieldWebLinkButton($options->{tableName}));

    push(@fields, $fieldsFactory->createFieldDomainName());
    push(@fields, $fieldsFactory->createFieldBoundLocalDNS());
    push(@fields, $fieldsFactory->createFieldExternalIPAddressHideView(1, ""));
    push(@fields, $fieldsFactory->createFieldProtocolExternalPortFixed('Main', $options->{externalPortDefaultValue}));
    push(@fields, $fieldsFactory->createFieldInternalIPAddressHideView(1,$options->{IPHelp}));

    push(@fields, $fieldsFactory->createFieldInternalPortDefaultValue($options->{internalPortDefaultValue}));
    push(@fields, $fieldsFactory->createFieldProtocolScheme('Main', 0, $options->{poundScheme}));

    my $dataTable = {
            'tableName' => $tableName,
            'pageTitle' => $options->{pageTitle},
            'printableTableName' => $options->{pageTitle},
            'modelDomain'     => 'dlllciasrouter',
            'defaultActions' => [ 'editField' ],
            'tableDescription' => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/View/' . $tableName,
            'messages' => {
                'update' => 'DONE <script type="text/javascript">location.href="'.$configView.'";</script>',
            }
        };

    return $dataTable;
}

# ---------------------------------------------------------

# 20150516 更新表單的動作
sub updatedRowNotify
{
    my ($self, $row, $oldRow, $options) = @_;

    my $lib = $self->getLibrary();

    try {

    $self->loadLibrary($options->{moduleName})->checkInternalIP($row);

    #$self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow);

    # 新增 Domain Name
    my $libDN = $self->loadLibrary('LibraryDomainName');
    $libDN->deleteDomainName($oldRow->valueByName('domainName'), 'PoundServices');

    if ($self->loadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
        $libDN->addDomainNameWithIP($row->valueByName('domainName'), $row->valueByName('extIpaddr'));
    }

    # 新增 Redirect
    my $libREDIR = $self->loadLibrary('LibraryRedirect');
    my $tableName = $options->{moduleName} . "Setting";
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
        my $buttonBtn = '<a target="_blank" href="'.$link.'" class="btn btn-icon icon-webserver" style="padding-left: 40px !important;">Open Main Server</a>';
        my $buttonLink = '<a target="_blank" href="'.$link.'" >'.$link.'</a>';
        $button = "<span>" . $buttonBtn . "<br/>" . $buttonLink . "</span>";
    }   # if ($shceme ne "none") {}

    my $fieldName = $tableName . '_web_button';
    if ($row->elementExists($fieldName)) {
        $row->elementByName($fieldName)->setValue($button);
    }
    $row->store();

    # 更新另外一個模組的資料
    my $headerModule = $options->{moduleName} . 'Header';
    my $headerFieldName = $headerModule . "_web_button";
    my $header = $self->parentModule->model($headerModule);
    $header->setValue($headerFieldName, $button);

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( LibrarySetting->updatedRowNotify() )');
    };
}

1;