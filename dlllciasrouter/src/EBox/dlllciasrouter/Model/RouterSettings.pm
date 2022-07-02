package EBox::dlllciasrouter::Model::RouterSettings;

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
use EBox::Types::URI;
use EBox::Types::Boolean;
use EBox::Types::IPAddr;
use EBox::Types::DomainName;
use EBox::Types::MailAddress;
use EBox::Types::Password;

use EBox::Network;

use Try::Tiny;

use EBox::Types::Text;

# Group: Public methods

# Constructor: new
#
#      Create a new Text model instance
#
# Returns:
#
#      <EBox::DNS::Model::RouterSettings> - the newly created model
#      instance
#
sub new
{
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless($self, $class);

    $self->{pound_port} = 80;

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

    my $tableName = 'RouterSettings';
    my $editErrorView = '/dlllciasrouter/View/ErrorMessage';
    my $manualDomainNameView = '/dlllciasrouter/View/ManualDomainName';
    my $manualNetworkIPRangeView = '/dlllciasrouter/View/ManualNetworkIPRange';

    my $address = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();
    #my $submask = $self->getLoadLibrary('LibraryNetwork')->getExternalMask();
    my $submask = 24;
    my $external_iface = $self->getLoadLibrary('LibraryNetwork')->getExternalIface();

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->getLoadLibrary('LibraryFields');

    

    my @fields = ();

    # ----------------------------------

    #push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ Zentyal_cloudBackup', __('Zentyal Cloud Backup ')));

    #push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName . "cloudBackupHelp", "Configuration will be backup to  <a href=\"https://remote.zentyal.com/\" target=\"zentyal_remote\">Zentyal Remote</a> weekly.  Only keep 3 backup online."));

    #push(@fields, new EBox::Types::MailAddress(
    #          fieldName     => 'adminMail',
    #          printableName => __('Account E-Mail Address '),
    #          editable      => 1,
    #          unique        => 1,
    #          optional => 0,
    #         ));

    #push(@fields, new EBox::Types::Password(
    #          fieldName     => 'adminPassword',
    #          printableName => __('Account Password '),
    #          editable      => 1,
    #          unique        => 1,
    #          optional => 0,
    #         ));

    #push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_cloudBackup", __('Configuration Backup'), "/SysInfo/Cloud/Backup", 1));

    # ----------------------------------

    push(@fields, $fieldsFactory->createFieldHeading('hr_ Zentyal_backup', __('Zentyal Backup ')));

    # @TODO 20170727 這邊應該改成按下去就立刻備份的HTML
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_cloudBackup", __('Configuration Backup'), "/SysInfo/Backup?selected=local#backup_description", 1));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'backupMailAddress',
        'printableName' => __('Backup mail addresses'),
        'help' => __('Split multiple addresses by SPACE. For example: admin1@dlll.cias.router.org admin2@dlll.cias.router.org'),
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue'  => 'pulipuli.chen+dlllciasrouter1@gmail.com pulipuli.chen+dlllciasrouter2@gmail.com',
        'optional'      => 0,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    ));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'backupMailSubject',
        'printableName' => __('Backup mail subject'),
        'help' => __('{IP} and {PORT} will be replaced as Zentyal\'s IP address and port.'),
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue'  => 'Zentyal backup (DLLL-CIAS Router) from {IP}',
        'optional'      => 0,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    ));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'backupMailBody',
        'printableName' => __('Backup mail body'),
        'help' => __('{IP} will be replaced as Zentyal\'s IP.'),
        'editable'      => 1,
        'unique'        => 1,
        #'defaultValue'  => 'Dear Zentyal Administrator,\\n\\nYou got this mail because you were set as Zentyal Administrator from DLLL-CIAS Router module.\\nAttachment is the back from Zentyal in {DATE}.\\n\\nYours faithfully,\\n\\n--\\n\\nFrom Zentyal server (DLLL-CIAS Router)\\nhttps://github.com/pulipulichen/zentyal-dlll',
        'defaultValue'  => 'Dear Zentyal Administrator,\n\n' 
            . 'You got this mail because you were set as Zentyal Administrator from DLLL-CIAS Router module.\n' 
            . 'Attachment is the back from Zentyal.\n' 
            . 'You can change the configuration from following URL:\n' 
            . 'https://{IP}:{PORT}/dlllciasrouter/Composite/SettingComposite#RouterSettings_backupMailAddress_row\n\n' 
            . 'Yours faithfully,\n\n' 
            . '--\n\n' 
            . 'From Zentyal server (DLLL-CIAS Router)\n' 
            . 'https://github.com/pulipulichen/zentyal-dlll',
        'optional'      => 0,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textareaSetter.mas',
    ));


    # ---------------------------------

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'backupLimit',
        'printableName' => __('Max backup file number'),
        'editable'      => 1,
        'unique'        => 0,
        'defaultValue' => 10,
        'optional' => 0,
    ));

    # ---------------------------------
    
    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ Zentyal_startup_mail', __('Zentyal Startup Mail')));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'startupMailSubject',
        'printableName' => __('Start mail subject'),
        'help' => __('{IP} will be replaced as Zentyal\'s IP.'),
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue'  => 'Zentyal startup (DLLL-CIAS Router) from {IP}',
        'optional'      => 0,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    ));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'startupMailBody',
        'printableName' => __('Startup message mail body'),
        'help' => __('{IP} and {PORT} will be replaced as Zentyal\'s IP address and port. {VEDomainName} will be replaced as Virtual Environment\'s main server domain name. ') 
            . '<a href="/dlllciasrouter/View/VEServerSetting#VEServerSetting_domainName_row" target="_blank">(Configuration)</a>',
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue'  => 'Dear Zentyal Administrator,\n\n' 
            . 'You got this mail because you were set as Zentyal Administrator from DLLL-CIAS Router module.\n\n' 
            . 'Zentyal server had been started recently. Please check following TODO list:\n\n' 
            . '- Check air conditioners work.\n' 
            . '- Check virtual environment work: https://{VEDomainName}:60000/\n\n' 
            . 'You can change the configuration from following URL:\n' 
            . 'https://{IP}:{PORT}/dlllciasrouter/Composite/SettingComposite#RouterSettings_backupMailAddress_row\n\n' 
            . 'Yours faithfully,\n\n' 
            . '--\n\n' 
            . 'From Zentyal server (DLLL-CIAS Router)\n' 
            . 'https://github.com/pulipulichen/zentyal-dlll',
        'optional'      => 0,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textareaSetter.mas',
    ));

    # ----------------------------------

    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ Zentyal_admin', __('Zentyal Administrator')));

    # 管理者清單的連結
    my $objectID = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Administrator-List')->id();
    my $editAdminNet = '/Objects/View/MemberTable?directory=ObjectTable/keys/'.$objectID.'/members&backview=/Objects/View/MemberTable';
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_adminNet", __('EDIT ADMINISTRATOR LIST'), $editAdminNet, 1));

    # 管理者清單的連結
    my $workplaceObjectID = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Workplace-List')->id();
    my $editWorkPlaceNet = '/Objects/View/MemberTable?directory=ObjectTable/keys/'.$workplaceObjectID.'/members&backview=/Objects/View/MemberTable';
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_workplaceNet", __('EDIT WORKPLACE LIST'), $editWorkPlaceNet, 1));

    # 黑名單的連結
    my $blObjectID = $self->getLoadLibrary('LibraryMAC')->getObjectRow('Blacklist')->id();
    my $editBL = '/Objects/View/MemberTable?directory=ObjectTable/keys/'.$blObjectID.'/members&backview=/Objects/View/MemberTable';
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_bl", __('EDIT BLACKLIST'), $editBL, 1));

    my $html = '<a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=audit_sessions">Administrator Sessions Logs</a>';
        #. ' <a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=audit_actions">Configuration Changes Logs</a>';
    $html = "<span>" . $html . "</span>";
    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName . "_zentyal_links", $html));

    # -----------------------------------------------------------

    #push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ZentyalAdmin', __('Zentyal Admin Configuration')));

    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ ZentyalPorts', __('Zentyal Network')));


    push(@fields, new EBox::Types::Port(
        'fieldName'     => 'webadminPort',
        'printableName' => __('Zentyal Webadmin Port. ') . "(" . __('Only For Administrator List') . ")",
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue'  => 64443,
        'optional'      => 0,
    ));

    push(@fields, new EBox::Types::Port(
            fieldName     => 'adminPort',
            printableName => __('Zentyal SSH Port. ') . "(" . __('Only For Administrator List') . ")",
            editable      => 1,
            unique        => 1,
            defaultValue => 64422,
            optional => 0,
        ));

    push(@fields, new EBox::Types::Port(
            fieldName     => 'xrdpPort',
            printableName => __('Zentyal XRDP Port. ') . "(" . __('Only For Administrator List') . ")",
            editable      => 1,
            unique        => 1,
            defaultValue => 64489,
            optional => 0,
        ));

    push(@fields, new EBox::Types::HostIP(
            fieldName     => 'anotherDNSIP',
            printableName => __('Another DNS IP'),
            help => __('If you want to use another IP which is different from the external network interface, you can custom the DNS IP in this field.'),
            editable      => 1,
            unique        => 1,
            #defaultValue => 64489,
            optional => 1,
        ));
    # ----------------------------------------------------------

    push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_PoundConfig', __('Pound Configuration')));
    push(@fields, new EBox::Types::Union(
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
        ));

    push(@fields, new EBox::Types::Port(
        'fieldName'     => 'port',
        'printableName' => __('External HTTP Port'),
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue' => 80,
        'optional' => 0,
    ));

    push(@fields, new EBox::Types::Port(
        'fieldName'     => 'portHTTPS',
        'printableName' => __('External HTTPS Port'),
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue' => 443,
        'optional' => 0,
    ));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'alive',
        'printableName' => __('Alive Time'),
        'editable'      => 1,
        'unique'        => 0,
        'defaultValue' => 30,
        'optional' => 0,
        'help' => __("Check backend every X secs. Default is 30 sec."),
    ));

    push(@fields, new EBox::Types::DomainName(
        "fieldName"     => 'testDomainName',
        "printableName" => __('Test Domain Name'),
        "editable"      => 1,
        "unique"        => 1,
        "defaultValue" => "test.dlll.nccu.edu.tw",
        "optional" => 0,
        "help" => __("Host by lightted."),
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    ));

    push(@fields, new EBox::Types::Text(
        "fieldName"     => 'timeout',
        "printableName" => __('Timeout'),
        "editable"      => 1,
        "unique"        => 0,
        "defaultValue" => 300,
        "optional" => 0,
        "help" => __("Wait for response X secs. Default is 300 sec."),
    ));
        
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName, __('EDIT ERROR MESSAGE'), $editErrorView, 1));
    #push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName, __('EDIT DOMAIN NAME MANUAL'), $manualDomainNameView, 1));
    #push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName, __('EDIT NETWORK IP RANGE MANUAL'), $manualNetworkIPRangeView, 1));

    my $poundCfg = '<a class="btn btn-icon btn-log" title="/etc/pound/pound.cfg" target="_blank" href="/dlllciasrouter/View/PoundSettings?backview=/dlllciasrouter/Composite/SettingComposite&backview_title=Settings&backview_hash=RouterSettings_hr_PoundConfig_hr_row">pound.cfg</a>';
    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName . "_pound_cfg", $poundCfg));

    #my $port = $self->value("port");
    my $port = $self->{pound_port};
    my $logPound = '<a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=firewall&filter-fw_dst='.$address.'&filter-fw_dpt='.$port.'">POUND LOGS</a>';
    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName . "_log_pound", $logPound));

    my $errPort = 888;
    my $logErr = '<a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=firewall&filter-fw_dst='.$address.'&filter-fw_dpt='.$errPort.'">POUND ERROR LOGS</a>';
    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName . "_log_err", $logErr));

        #$fieldsFactory->createFieldHrWithHeading('hr_ErrorMessage', __('Error Message Configuration')),
        #new EBox::Types::Boolean(
        #      fieldName     => 'enableError',
        #      printableName => __('Enable Custom Error Message'),
        #      defaultValue => 1,
        #      editable      => 1,
        #      optional => 0,
        #     ),
        #new EBox::Types::Text(
        #      fieldName     => 'error',
        #      printableName => __('Error Page Link'),
        #      editable      => 1,
        #      #defalutValue => 'http://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/error_page/error_example.html',
        #      optional => 1,
        #      help => __('HTML format. Example: ')
        #        .'<a href="https://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/error_page/error_example.html" target="error_example">https://github.com/pulipulichen/zentyal-dlll/raw/master/dlllciasrouter/error_page/error_example.html</a>'
        #        ,
        #     ),

        # 20150517 Pulipuli Chen
        # 由於Restarter的設計不穩定，在此關閉她的功能
        #$fieldsFactory->createFieldHrWithHeading('hr_EmergencyRestarter', __('Emergency Restarter Configuration')),
        #new EBox::Types::HostIP(
        #    fieldName => 'restarterIP',
        #    printableName => __('Restarter IP'),
        #    editable => 1,
        #    optional => 1,
        #),
        #new EBox::Types::Port(
        #    fieldName => 'restarterPort',
        #    printableName => __('Restarter Port'),
        #    editable => 1,
        #    defaultValue => 80,
        #),
        #new EBox::Types::Text(
        #    fieldName => 'notifyEmail',
        #    printableName => __('Notify E-MAIL Address'),
        #    editable => 1,
        #    optional => 1,
        #),
        #new EBox::Types::Text(
        #    fieldName => 'senderEmail',
        #    printableName => __('Sender E-MAIL Address'),
        #    editable => 1,
        #    optional => 1,
        #),

    #push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_PoundDesc', __('Zentyal Description')));
        
    #push(@fields, $fieldsFactory->createFieldDescription());
    #push(@fields, $fieldsFactory->createFieldAttachedFilesButton('/dlllciasrouter/Composite/SettingComposite', 0));
    #my $filePath = "/dlllciasrouter/View/AttachedFiles?directory=RouterSettings/keys/rs1/attachedFiles&backview=/dlllciasrouter/Composite/SettingComposite";
    #push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_attachedFiles", __('UPLOAD FILE'), $filePath, 1));

    my $pageTitle = __('Setting');
    
    my $logBtn = '  <a class="btn btn-icon btn-log" title="configure" target="_blank" href="/Logs/Index?search=Search&selected=audit_actions&filter-model='.$tableName.'">Logs</a>';
    my $dataTable = {
            'tableName' => $tableName,
            'pageTitle' => '',
            'printableTableName' => $pageTitle . $logBtn,
            'modelDomain'     => 'dlllciasrouter',
            'defaultActions' => [ 'editField' ],
            'tableDescription' => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/Composite/SettingComposite',
        };

    return $dataTable;
}

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}


# -----------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    try {

      $self->setWebadminPort($row->valueByName("webadminPort"));

      my $libServ = $self->getLoadLibrary("LibraryService");

      $libServ->updateServicePort("dlllciasrouter-admin"
          , $oldRow->valueByName("webadminPort")
          , $row->valueByName("webadminPort")
          , 1);
      $libServ->updateServicePort("dlllciasrouter-admin"
          , $oldRow->valueByName("adminPort")
          , $row->valueByName("adminPort")
          , 1);
      $libServ->updateServicePort('dlllciasrouter-pound'
          , $oldRow->valueByName("port")
          , $row->valueByName("port")
          , 1);
      $self->{pound_port} = $row->valueByName("port");

      if ($row->valueByName('testDomainName') ne $oldRow->valueByName('testDomainName')) {
        my $libDN = $self->getLoadLibrary('LibraryDomainName');
        $libDN->deleteDomainName($oldRow->valueByName('testDomainName'));
        $libDN->addDomainName($row->valueByName('testDomainName'));
      }

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( RouterSettings->updatedRowNotify() )');
    };

    #$self->setCloudConfigBackup($row);
}

sub setWebadminPort
{
    # 要在設定防火牆之前修改
    my ($self, $port) = @_;

    try {
        my $mod = EBox::Global->modInstance('webadmin');
        #$mod->updateAdminPortService($port);
        my $portMod = $mod->model('AdminPort');
        $portMod->setValue('port', $port);
        #$portMod->store();
    } catch {
        #$self->getLibrary()->show_exceptions($_ . $port . ' ( RouterSettings->setWebadminPort() )');
    };
}

# 20150518 Pulipuli Chen
# 只有第一次執行會用到
sub initServicePort
{
    my ($self) = @_;

    try
    {
        $self->setWebadminPort($self->value("webadminPort"));

        my $libServ = $self->getLoadLibrary("LibraryService");
        $libServ->addServicePort("dlllciasrouter-pound", $self->value('port'), 0);
        $libServ->addServicePort("dlllciasrouter-pound", $self->value('portHTTPS'), 0);
        $libServ->addServicePort("dlllciasrouter-pound", 888, 0); # lighttpd

        $libServ->addServicePort("dlllciasrouter-admin", $self->value('webadminPort'), 1);
        $libServ->addServicePort("dlllciasrouter-admin", $self->value('adminPort'), 1);
        $libServ->addServicePort("dlllciasrouter-admin", $self->value('xrdpPort'), 1);

        #dns server
        $libServ->addServicePort("dlllciasrouter-dns", 53, 0);

    } catch {
        $self->getLibrary()->show_exceptions($_ . ' (RouterSettings->initServicePort())');
    }
}

# 20150519 Pulipuli Chen
sub getExtIPAddress
{
    my ($self) = @_;

    my $address = "127.0.0.1";
    if ($self->value("address") eq "address_extIface") {
        $address = $self->getLoadLibrary("LibraryNetwork")->getExternalIpaddr();
    }
    else {
        $address = $self->value("address");
    }

    return $address;
}

##
# 本功能因為Zentyal不運作CloudBackup了，所以現在不使用
# @Departed 20170816
# 20150605 Pulipuli Chen
##
#sub setCloudConfigBackup
#{
#    my ($self, $row) = @_;
#
#    my $email = $row->valueByName("adminMail");
#    my $password = $row->valueByName("adminPassword");
#
#    my $hostname = EBox::Global->modInstance('sysinfo')->hostName();
#
#    
#    # 清除未註冊的帳號
#    my $remoteservices = EBox::Global->getInstance()->modInstance('remoteservices');
#    #$remoteservices->_removeSubscriptionData();
#    my $username = $remoteservices->username();
#    if ($username ne $email) {
#        # 登入
#        try {
#            $remoteservices->registerAdditionalCommunityServer($email, $password, $hostname);
#        }
#        catch {
#            try {
#                $remoteservices->registerFirstCommunityServer($email, $password, $hostname);
#
#            }
#            catch {
#                $self->getLibrary()->show_exceptions("Your password is wrong. Please reset your password from <a href=\"https://remote.zentyal.com/reset/\" target=\"zentyal_remote\">Zentyal Remote</a>.");
#            };
#        };
#    }
#}

1;
