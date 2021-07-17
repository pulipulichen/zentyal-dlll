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
    return $self->parentModule()->model("LibraryToolkit");
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

    my $external_iface = $self->loadLibrary('LibraryNetwork')->getExternalIface();

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();

    my $tableName = $options->{moduleName} . "Setting";
    my $configView = '/dlllciasrouter/Composite/'. $options->{moduleName} . 'Composite';
    push(@fields, $fieldsFactory->createFieldServerLinkButton($tableName, $options->{moduleName} . ' Management', $configView));

    push(@fields, $fieldsFactory->createFieldHr('hr_setting'));

    #push(@fields, $fieldsFactory->createFieldWebLinkButton($options->{tableName}));

    push(@fields, $fieldsFactory->createFieldDomainName());
    push(@fields, $fieldsFactory->createFieldBoundLocalDNS());
    push(@fields, $fieldsFactory->createFieldExternalIPAddressWithSubmask(1, ""));
    push(@fields, $fieldsFactory->createFieldInternalIPAddressHideView(1, $options->{IPHelp}, $options->{IPTemplate}));

    push(@fields, $fieldsFactory->createFieldHrWithHeading('ht_main', __('Main Network Settings')));

    push(@fields, $fieldsFactory->createFieldProtocolExternalPortFixed('Main', $options->{externalPortDefaultValue}));    
    push(@fields, $fieldsFactory->createFieldServerLinkButtonNewWindow($tableName, 'Change Zentyal Webadmin Port', "/dlllciasrouter/Composite/SettingComposite#RouterSettings_webadminPort_row"));

    push(@fields, $fieldsFactory->createFieldInternalPortDefaultValue($options->{internalPortDefaultValue}));
    push(@fields, $fieldsFactory->createFieldProtocolScheme('Main', 0, $options->{poundScheme}));
    
    push(@fields, $fieldsFactory->createFieldHrWithHeading('ht_ssh', __('SSH Network Settings')));

    push(@fields, $fieldsFactory->createFieldSSHRedirect($options->{enableSSH}));
    push(@fields, $fieldsFactory->createFieldProtocolExternalPortFixed('SSH', $options->{externalSSHPortDefaultValue}));
    push(@fields, $fieldsFactory->createFieldServerLinkButtonNewWindow($tableName, 'Change Zentyal SSH Port', "/dlllciasrouter/Composite/SettingComposite#RouterSettings_adminPort_row"));
    push(@fields, $fieldsFactory->createFieldSSHInternalPort());

    push(@fields, $fieldsFactory->createFieldHrWithHeading('ht_desc', __('Description')));
    push(@fields, $fieldsFactory->createFieldDescription());

    my $filePath = "/dlllciasrouter/View/AttachedFiles?directory=".$tableName."/keys/rs1/attachedFiles&backview=/dlllciasrouter/View/". $tableName;
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_attachedFiles", __('UPLOAD FILE'), $filePath, 1));

    my $logBtn = '  <a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=audit_actions&filter-model='.$tableName.'">Logs</a>';

    my $dataTable = {
            'tableName' => $tableName,
            'pageTitle' => $options->{pageTitle},
            'printableTableName' => $options->{pageTitle} . $logBtn,
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

##
# 20150516 Pulipuli Chen
# 更新表單的動作
##
sub updatedRowNotify
{
    my ($self, $mod, $row, $oldRow, $options) = @_;

    my $lib = $self->getLibrary();

    try {

        #my $extIp = $row->elementByName('extIpaddr')->ip();
        #my $extMask = $row->elementByName('extIpaddr')->mask();
        my $extIp = $row->valueByName('extIpaddr');
        my $extMask = $self->loadLibrary('LibraryNetwork')->getExternalMask();

        $self->loadLibrary($options->{moduleName})->checkInternalIP($row);

        #$self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow);

        # 新增 Domain Name
        my $libDN = $self->loadLibrary('LibraryDomainName');
        #$libDN->deleteDomainName($oldRow->valueByName('domainName'), 'PoundServices');
        $libDN->deleteDomainName($oldRow->valueByName('domainName'), 'dlllciasrouter-pound');

        if ($self->loadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
            $libDN->addDomainNameWithIP($row->valueByName('domainName'), $extIp);
        }

        # 新增 Redirect
        my $libREDIR = $self->loadLibrary('LibraryRedirect');
        my $tableName = $options->{moduleName} . "Setting";
        my $extPort = $row->valueByName('redirMain_extPort');
        my $intPort = $row->valueByName("port");
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamDMZ($oldRow, $tableName, $extPort, $intPort, 'Main'));
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamOrigin($oldRow, $tableName, $extPort, $intPort, 'Main'));
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamZentyal($oldRow, $tableName, $extPort, $intPort, 'Main'));

        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamDMZ($row, $tableName, $extPort, $intPort, 'Main'));
        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamOrigin($row, $tableName, $extPort, $intPort, 'Main'));
        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamZentyal($row, $tableName, $extPort, $intPort, 'Main'));

        my $SSHextPort = $row->valueByName('redirSSH_extPort');
        my $SSHintPort = $row->valueByName("redirSSH_intPort");
        if ($intPort eq 'redirSSH_default') {
            $intPort = 22;
        }
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamOrigin($oldRow, $tableName, $SSHextPort, $SSHintPort, 'SSH'));
        $libREDIR->deleteRedirectRow($libREDIR->getServerRedirectParamZentyal($oldRow, $tableName, $SSHextPort, $SSHintPort, 'SSH'));

        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamOrigin($row, $tableName, $SSHextPort, $SSHintPort, 'SSH'));
        $libREDIR->addRedirectRow($libREDIR->getServerRedirectParamZentyal($row, $tableName, $SSHextPort, $SSHintPort, 'SSH'));

        # 設定按鈕
        my $domainName = $row->valueByName('domainName');
        my $scheme = $row->valueByName('redirMain_scheme');

        my $intIpaddr = $row->valueByName('ipaddr');
        my $logButton = '<a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=firewall&filter-fw_dst='.$intIpaddr.'">LOGS</a>';

        my $sshLink = "";
        if ($row->valueByName('redirSSH_enable') == 1) {
            $sshLink =  '<br /><a href="ssh://' . $domainName . ":" . $options->{externalSSHPortDefaultValue} . '" target="_blank">' . "ssh://" . $domainName . ":" . $options->{externalSSHPortDefaultValue} . "</a>";
        }

        my $libEnc = $self->loadLibrary("LibraryEncoding");

        my $button = '<span></span>';
        if ($scheme ne "none") {
            my $port = ":" . $extPort;
            if ($port eq ":80") {
                $port = "";
            }

            my $link = $scheme . "://" . $domainName . $port . "/";
            my $lanLink = $scheme . "://" . $intIpaddr . ':' . $intPort . "/";

            my $buttonBtn = '<a target="_blank" href="'.$link.'" class="btn btn-icon icon-webserver" style="padding-left: 40px !important;">Open Main Server</a>';

            my $configView = '/dlllciasrouter/View/'.$options->{moduleName}.'Setting';
            my $buttonConfigBtn = '<a href="' . $configView . '" class="btn btn-icon btn-config" style="padding-left: 40px !important;">Main Server Setting</a>';
            my $buttonLink = '<a target="_blank" href="'.$link.'" >'.$link.'</a>'
                . '<br /><a target="_blank" href="'.$lanLink.'" >'.$lanLink.'</a>';

            $button = "<span>" . $buttonBtn . " " . $buttonConfigBtn . " " . $logButton . "<br/>"  . $buttonLink . $sshLink . "</span>";
            $button = $button . "<div>" . $libEnc->unescapeFromUtf16($row->valueByName('description')) . "</div>";
        }   # if ($shceme ne "none") {}
        else {
            $button = $logButton . $sshLink;
        }

        my $fieldName = $tableName . '_web_button';
        if ($row->elementExists($fieldName)) {
            $row->elementByName($fieldName)->setValue($button);
        }

        # 儲存他
        $row->store();

        # 更新另外一個模組的資料
        my $headerModule = $options->{moduleName} . 'Header';
        my $headerFieldName = $headerModule . "_web_button";
        my $header = $self->parentModule->model($headerModule);
        $header->setValue($headerFieldName, $button);

        # 設定敘述
        my $desc = $row->valueByName('description');
        $desc = $libEnc->unescapeFromUtf16($desc);
        #$desc = $libEnc->stripsHtmlTags($desc);
        $desc = "<span>" . $desc . "</span>";
        #$header->setValue("description_display", $desc);

        # 設定Virtual Interface
        #$extMask = $self->loadLibrary('LibraryNetwork')->bitwiseShiftMask($extMask);
        $self->loadLibrary('LibraryNetwork')->setVirtualInterface(
            $options->{moduleName}, $extIp, $extMask
        );

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( LibrarySetting->updatedRowNotify() )');
        #$mod->setMessage($_ . '( LibrarySetting->updatedRowNotify() )', 'warning');
    };
}

1;
