package EBox::dlllciasrouter::Model::LibraryFields;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::MACAddr;
use EBox::Types::Text;
use EBox::Types::HTML;
use EBox::Types::Boolean;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Select;
use EBox::Types::HasMany;
use EBox::Types::File;
use EBox::Types::IPAddr;
use EBox::Types::MailAddress;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;

sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

sub createFieldConfigEnable
{
    my $field = new EBox::Types::Boolean(
        fieldName => 'configEnable',
        printableName => __('Enabled'),
        editable => 1,
        optional => 0,

        # 20140207 Pulipuli Chen
        # 預設改成false，這是因為一開始建置時都是在測試中，連線失誤是很正常的。當設定穩定之後再手動調整成true
        defaultValue => 1,

        hiddenOnSetter => 0,
        hiddenOnViewer => 0,
        #help => __('If you want to use emergency restarter, you have to enable HTTP redirect first.'),
    );

    return $field;
}

sub createFieldDomainName
{
    my $field = new EBox::Types::DomainName(
        'fieldName' => 'domainName',
        'printableName' => __('Domain Name'),
        'editable' => 1,
        # 因為要允許同一個Domain Name指向多個Back End，所以這部份要做些調整
        #'unique' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );

    return $field;
}

sub createFieldDomainNameUnique
{
    my $field = new EBox::Types::DomainName(
        fieldName => 'domainName',
        printableName => __('Domain Name'),
        editable => 1,
        'unique' => 1,
        hiddenOnSetter => 0,
        hiddenOnViewer => 1,
    );

    return $field;
}

# 20140208 Pulipuli
# 顯示時使用
sub createFieldDomainNameLink
{
    my $field = new EBox::Types::HTML(
            fieldName => 'domainNameLink',
            printableName => __('Domain Name'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );

    return $field;
}


# 20150514 Pulipuli Chen
# 輸入其他連接埠
sub createFieldOtherDomainNamesButton
{
    my ($self, $backView) = @_;
    my $field = new EBox::Types::HasMany(
            'fieldName' => 'otherDomainName',
            'printableName' => __('Other <br />Domain <br />Names'),
            'foreignModel' => 'OtherDomainNames',
            'view' => '/dlllciasrouter/View/OtherDomainNames',
            'backView' => $backView,
            'size' => '1',
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 0,
       );
    return $field;
}

# 20150515 Pulipuli Chen
sub createFieldOtherDomainNamesSubModel
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
            'fieldName' => 'otherDomainName_subMod',
            'printableName' => __(''),
            #'defaultValue' => '',
            'editable' => 0,
            'optional' => 1,
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 1,
       );
    return $field;
}

# 20150506 Pulipuli
# 顯示時使用
sub createFieldIpaddrLink
{
    my $field = new EBox::Types::HTML(
            fieldName => 'ipaddrLink',
            printableName => __('Link'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );

    return $field;
}

sub createFieldInternalIPAddress
{
    my $field = new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
            #'unique' => 1,
            help => __('The 1st part should be 10, <br />'
                . 'the 2nd part should be 1~5, <br />'
                . 'the 3rd part should be 0~9, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.1.0.51'),
        );

    return $field;
}

sub createFieldInternalIPAddressHideView
{
    my ($self, $unique, $help) = @_;

    my $field = new EBox::Types::HostIP(
            'fieldName' => 'ipaddr',
            'printableName' => __('Internal IP Address'),
            'editable' => 1,
            'unique' => $unique,
            'help' => __($help),
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );

    return $field;
}

# 20150516 Pulipuli Chen
# 外部的IP
sub createFieldExternalIPAddressHideView
{
    my ($self, $unique, $help) = @_;

    my $field = new EBox::Types::HostIP(
            'fieldName' => 'extIpaddr',
            'printableName' => __('External IP Address'),
            'editable' => 1,
            'unique' => $unique,
            'help' => __($help),
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );

    return $field;
}

# 20150517 Pulipuli Chen
# 外部的IP，包含submask
sub createFieldExternalIPAddressWithSubmask
{
    my ($self, $unique, $help) = @_;

    my $field = new EBox::Types::IPAddr(
            'fieldName' => 'extIpaddr',
            'printableName' => __('External IP Address'),
            'editable' => 1,
            'unique' => $unique,
            'help' => __($help),
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );

    return $field;
}

##
# 20150513 Pulipuli Chen
# 調整內部port的設定
##
sub createFieldInternalPort
{
    my $field = new EBox::Types::Port(
            'fieldName' => 'port',
            'printableName' => __('Internal Port'),
            'defaultValue' => 80,
            'editable' => 1,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
            'help' => __('If HTTP to HTTPS enabled, Internal Port will be not worked.'),
        );

    return $field;
}

##
# 20150513 Pulipuli Chen
# 調整內部port的設定
##
sub createFieldInternalPortDefaultValue
{
    my ($self, $defaultValue) = @_;

    my $field = new EBox::Types::Port(
            'fieldName' => 'port',
            'printableName' => __('Internal Port'),
            'defaultValue' => $defaultValue,
            'editable' => 1,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
            #'help' => __('If HTTP to HTTPS enabled, Internal Port will be not worked.'),
        );

    return $field;
}

sub createFieldMACAddr
{
    my $field = new EBox::Types::MACAddr(
            fieldName => 'macaddr',
            printableName => __('Network Card MAC Address'),
            editable => 1,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => __('Set MAC to assign Internal IP by DHCP.'),
        );

    return $field;
}

sub createFieldNetworkDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'network_display',
            printableName => __('Network'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

sub createFieldContactName
{
    my $field = new EBox::Types::Text(
            fieldName => 'contactName',
            printableName => __('Contact Name'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

# 20150515 Pulipuli Chen
# 讓聯絡人可以在欄位上顯示
sub createFieldContactNameDisplayOnViewer
{
    my $field = new EBox::Types::Text(
            fieldName => 'contactName',
            printableName => __('Contact Name'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 0,
        );

    return $field;
}

sub createFieldContactEmail
{
    my $field = new EBox::Types::MailAddress(
            fieldName => 'contactEmail',
            printableName => __('Contact Email'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldEmailKMDescription
{
    my $field = new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => 
                '<button onclick="window.open(\'http://email-km.dlll.nccu.edu.tw/wp-admin/post-new.php?post_title=[CLOUD-SERVICE]\', \'_blank\');return false;">'
                . __('Create New Post') 
                . '</button><br />'
                . __('Please using EMAIL-KM to create a host post and input URL in this field. '),
        );

    return $field;
}

sub createFieldDescription
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 0,
            optional => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => $self->createFieldDescriptionEditor(),
        );

    return $field;
}

sub createFieldDescriptionEditor
{
    # https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/zentyal-field-html-editor.js
    #my $script = "https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/zentyal-field-html-editor.js";
    my $script = "/data/dlllciasrouter/js/zentyal-field-html-editor.js";
    #my $script = "http://pc-pudding.dlll.nccu.edu.tw/zentyal-dlll/dlllciasrouter/javascript/zentyal-field-html-editor.js";      # 不能用HTTP!!
    
    return '<div class="html-editor"></div>'
    .'<span class="init-span">'
        .'<button type="button" class="init-button"  '
    .'onclick="this.className=\'init-button trigger\';this.innerHTML=\'LOADING\';this.disabled=true;if (typeof(_ZENTYAL_UTIL) === \'undefined\') {var _script=document.createElement(\'script\');_script.type=\'text/javascript\';_script.src=\''.$script.'\';document.getElementsByTagName(\'body\')[0].appendChild(_script);} else {_ZENTYAL_UTIL.init()}"'
    .'>LOAD</button> </span>'
    .'<script type="text/javascript">'
        .'document.getElementsByClassName("init-button")[0].click();'
    .'</script>';
}

sub createFieldDescriptionHTML
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'descriptionHTML',
            printableName => __('Description HTML'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 1,
        );
    return $field;
}


sub createFieldExpiryDate
{
    my ($self, $defaultValue) = @_;

    my $field = new EBox::Types::Text(
            fieldName => 'expiry',
            printableName => __('Expiry Date'),
            editable => 1,
            optional=>0,
            defaultValue => $defaultValue,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,

            # 20140207 Pulipuli Chen
            # 加上說明
            help => __('Example: NEVER or 2015/1/1'),
        );

    return $field;
}

sub createFieldExpiryDateWithHR
{
    my $field = new EBox::Types::Text(
            fieldName => 'expiry',
            printableName => __('Expiry Date'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,

            # 20140207 Pulipuli Chen
            # 加上說明
            help => __('Example: NEVER or 2015/1/1 <br /> <hr />'),
        );

    return $field;
}

sub createFieldEmergencyRestarter
{
    my $field = new EBox::Types::Boolean(
            fieldName => 'emergencyEnable',
            printableName => __('Enable Emergency Restarter'),
            editable => 1,
            optional => 0,

            # 20140207 Pulipuli Chen
            # 預設改成false，這是因為一開始建置時都是在測試中，連線失誤是很正常的。當設定穩定之後再手動調整成true
            defaultValue => 0,

            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => __('If you want to use emergency restarter, you have to enable HTTP redirect first.'),
        );

    return $field;
}

sub createFieldRedirectToHTTPS
{
    my $field = new EBox::Types::Boolean(
            fieldName => 'httpToHttps',
            printableName => __('Redirect HTTP to HTTPS port forwarding'),
            editable => 1,
            optional => 0,
            defaultValue => 0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,

            # 20140207 Pulipuli Chen
            # 加上說明
            #help => __('If you want to enable redirect to HTTPS, be sure setting Internal Port to HTTPS port, like 443. <br />' 
            #    . 'Example: http://demo.url/ will be redirected to https://demo.url:13743/'),
            help => __('If this option enabled, link to HTTP will be redirect to HTTPS\'s port forwarding. <br />' 
                . 'For example, test.dlll.nccu.edu.tw had enabled HTTPS, port forwarding is 10543. <br />'
                . 'So link to test.dlll.nccu.edu.tw will be redirect to test.dlll.nccu.edu.tw:10543.'),
        );

    return $field;
}

sub createFieldIsHTTPS
{
    my $field = new EBox::Types::Boolean(
            fieldName => 'isHttps',
            printableName => __('Is HTTPS'),
            editable => 1,
            optional => 0,
            help => ( '<hr />'),
            defaultValue => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,

        );

    return $field;
}

sub createFieldBoundLocalDNSwithHR
{
    my $field = new EBox::Types::Boolean(
            fieldName => 'boundLocalDns',
            printableName => __('Setup In Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'
                . "<br /> <hr />"),
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldBoundLocalDNS
{
    my $field = new EBox::Types::Boolean(
            fieldName => 'boundLocalDns',
            printableName => __('Bound Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'),
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

# --------------------------------
# Protocal Redirect Fields

sub createFieldProtocolRedirect
{
    my ($self, $protocol, $enable) = @_;
    my $field = new EBox::Types::Boolean(
            fieldName => 'redir'.$protocol.'_enable',
            printableName => __('Enable '.$protocol.' Redirect'),
            editable => 1,
            optional => 0,
            defaultValue => $enable,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldProtocolOnlyForLAN
{
    my ($self, $protocol, $enable) = @_;
    my $field = new EBox::Types::Boolean(
            fieldName => 'redir'.$protocol.'_secure',
            printableName => __('Only For Administrator Network'),
            help => '<a href="/dlllciasrouter/Composite/SettingComposite" target="_blank">' . __('Administrator Network Setting') . '</a>',
            editable => 1,
            optional => 0,
            defaultValue => $enable,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldProtocolLog
{
    my ($self, $protocol, $enable) = @_;
    my $field = new EBox::Types::Boolean(
            fieldName => 'redir'.$protocol.'_log',
            printableName => __('Enable Zentyal Log'),
            #help => __('Only for local lan, like 140.119.61.0/24.'),
            editable => 1,
            optional => 0,
            defaultValue => $enable,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldProtocolExternalPort
{
    my ($self, $protocol, $unique, $extPort) = @_;
    my $field = new EBox::Types::Union(
            'fieldName' => 'redir'.$protocol.'_extPort',
            'printableName' => __($protocol.' External Port'),
            'unique' => $unique,
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'redir'.$protocol.'_extPort_default',
                'printableName' => __('Default: Based on IP address. (****'. $extPort  . ')')),
            new EBox::Types::Port(
                'fieldName' => 'redir'.$protocol.'_extPort_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        );

    return $field;
}


# 20150516 Pulipuli Chen
# 固定欄位的連接埠
sub createFieldProtocolExternalPortFixed
{
    my ($self, $protocol, $extPort) = @_;

    my $field = new EBox::Types::Port(
            'fieldName' => 'redir'.$protocol.'_extPort',
            'printableName' => __($protocol.' External Port'),
            'unique' => 1,
            'defaultValue' => $extPort,
            'editable' => 0,
        );

    return $field;
}

sub createFieldProtocolInternalPort
{
    my ($self, $protocol, $port) = @_;
    my $field = new EBox::Types::Union(
            'fieldName' => 'redir'.$protocol.'_intPort',
            'printableName' => __($protocol.' Internal Port'),
            'subtypes' =>
            [
            new EBox::Types::Port(
                'fieldName' => 'redir'.$protocol.'_default',
                'printableName' => __('Default '.$protocol.' port ('.$port.')'),
                'defaultValue' => $port,
                'hidden' => 1,
                'editable' => 0,),
            new EBox::Types::Port(
                'fieldName' => 'redir'.$protocol.'_other',
                'printableName' => __('Other'),
                'editable' => 1,),
            ],
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldProtocolScheme
{
    my ($self, $protocol, $unique, $defaultValue) = @_;

    my $field = new EBox::Types::Select(
            'fieldName' => 'redir'.$protocol.'_scheme',
            'printableName' => __($protocol.' Protocol Scheme'),
            'unique' => $unique,
            'populate' => \&_populateFieldProtocolScheme,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
            'defaultValue' => $defaultValue,
            'editable' => 1
        );

    return $field;
}

sub createFieldPoundProtocolScheme
{
    my ($self) = @_;
    my $field = new EBox::Types::Union(
            'fieldName' => 'poundProtocolScheme',
            'printableName' => __('Pound Protocol'),
            'unique' => 0,
            'subtypes' =>
            [
            new EBox::Types::Port(
                'fieldName' => 'poundProtocolScheme_http',
                'printableName' => __('HTTP (http://)'),
                'defaultValue' => 80,
                'editable' => 1,),
            new EBox::Types::Port(
                'fieldName' => 'poundProtocolScheme_https',
                'printableName' => __('HTTPS (https://)'),
                'defaultValue' => 443,
                'editable' => 1,),
            new EBox::Types::Union::Text(
                'fieldName' => 'poundProtocolScheme_none',
                'printableName' => __('Not a link'),
                'defaultValue' => '',
                'hidden' => 1,
                'editable' => 0,),
            ],
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldPoundOnlyForLAN
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolOnlyForLAN("POUND", 1);
    return $field;
}

sub _populateFieldProtocolScheme
{
    # life time values must be in hours
    return  [
                {
                    value => 'http',
                    printableValue => __('HTTP (http://)'),
                },
                {
                    value => 'https',
                    printableValue => __('HTTPS (https://)'),
                },
                {
                    value => 'none',
                    printableValue => __('Not a link'),
                },
            ];
}

sub createFieldProtocolNote
{
    my ($self, $protocol) = @_;
    my $field = new EBox::Types::Text(
            fieldName => 'redir'.$protocol.'_note',
            printableName => __($protocol.' Note'),
            editable => 1,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => ( 'Login account / password, or using this port for other usage'),
        );

    return $field;
}

sub createFieldProtocolNoteWithHr
{
    my ($self, $protocol) = @_;
    my $field = new EBox::Types::Text(
            fieldName => 'redir'.$protocol.'_note',
            printableName => __($protocol.' Note'),
            editable => 1,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => ( 'Login account / password, or using this port for other usage <br /> <hr />'),
        );

    return $field;
}

# --------------------------------
# HTTP Redirect Fields

sub createFieldHTTPRedirect
{
    my ($self, $enable) = @_;
    my $field = $self->createFieldProtocolRedirect("HTTP", $enable);
    return $field;
}

sub createFieldHTTPOnlyForLAN
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolOnlyForLAN("HTTP", 0);
    return $field;
}

sub createFieldHTTPLog
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolLog("HTTP", 0);
    return $field;
}

sub createFieldHTTPExternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolExternalPort("HTTP", 0, 8);
    return $field;
}

sub createFieldHTTPInternalPort
{
    #my $field = new EBox::Types::Text(
    #        'fieldName' => 'redirHTTP_intPort',
    #        'printableName' => __('HTTP Internal Port'),
    #        'editable' => 0,
    #        'defaultValue' => "Use reverse proxy internal port",
    #        hiddenOnSetter => 0,
    #        hiddenOnViewer => 1,
    #    );
    my ($self) = @_;
    my $field = $self->createFieldProtocolInternalPort("HTTP", 80);
    return $field;
}

sub createFieldHTTPNote
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolNote("HTTP");
    return $field;
}

# --------------------------------
# HTTPS Redirect Fields

sub createFieldHTTPSRedirect
{
    my ($self, $enable) = @_;
    my $field = $self->createFieldProtocolRedirect("HTTPS", $enable);
    return $field;
}

sub createFieldHTTPSOnlyForLAN
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolOnlyForLAN("HTTPS", 1);
    return $field;
}

sub createFieldHTTPSLog
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolLog("HTTPS", 1);
    return $field;
}

sub createFieldHTTPSExternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolExternalPort("HTTPS", 1, 3);
    return $field;
}

sub createFieldHTTPSInternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolInternalPort("HTTPS", 443);
    return $field;
}

sub createFieldHTTPSNote
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolNote("HTTPS");
    return $field;
}


# --------------------------------
# SSH Redirect Fields

sub createFieldSSHRedirect
{
    my ($self, $enable) = @_;
    my $field = $self->createFieldProtocolRedirect("SSH", $enable);
    return $field;
}

sub createFieldSSHOnlyForLAN
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolOnlyForLAN("SSH", 1);
    return $field;
}

sub createFieldSSHLog
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolLog("SSH", 1);
    return $field;
}

sub createFieldSSHExternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolExternalPort("SSH", 1, 2);
    return $field;
}

sub createFieldSSHInternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolInternalPort("SSH", 22);
    return $field;
}

sub createFieldSSHNote
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolNote("SSH");
    return $field;
}

# --------------------------------
# RDP Redirect Fields

sub createFieldRDPRedirect
{
    my ($self, $enable) = @_;
    my $field = $self->createFieldProtocolRedirect("RDP", $enable);
    return $field;
}

sub createFieldRDPOnlyForLAN
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolOnlyForLAN("RDP", 1);
    return $field;
}

sub createFieldRDPLog
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolLog("RDP", 1);
    return $field;
}

sub createFieldRDPExternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolExternalPort("RDP", 1, 9);
    return $field;
}

sub createFieldRDPInternalPort
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolInternalPort("RDP", 3389);
    return $field;
}

sub createFieldRDPNote
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolNote("RDP");
    return $field;
}

# --------------------------------------

sub createFieldDisplayRedirectPorts
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'redirPorts',
            printableName => __('Redirect Ports'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

# --------------------------------------
# Other Redirect Ports

sub createFieldOtherRedirectPortsButton
{
    my ($self, $backView) = @_;
    my $field = new EBox::Types::HasMany(
            'fieldName' => 'redirOther',
            'printableName' => __('Other <br />Redirect<br />Ports'),
            'foreignModel' => 'PortRedirect',
            'view' => '/dlllciasrouter/View/PortRedirect',
            'backView' => $backView,
            'size' => '1',
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 0,
       );
    return $field;
}

sub createFieldOtherRedirectPortsHint
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
            fieldName => 'redirOtherHelp',
            printableName => __('Other Redirect Ports'),
            defaultValue => __('You can configure other redirection at following table. You have to add this row first.'),
            editable => 0,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

# 20150515 Pulipuli Chen
sub createFieldOtherRedirectPortsSubModel
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
            'fieldName' => 'redirOther_subMod',
            'printableName' => __(''),
            #'defaultValue' => '',
            'editable' => 0,
            'optional' => 1,
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 1,
       );
    return $field;
}

# --------------------------------------
# Date Display

sub createFieldCreateDateDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'createDate',
            printableName => __('Create Date'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

sub createFieldCreateDateData
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
            fieldName => 'createDateField',
            printableName => __('Create Date'),
            editable => 1,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 1,
        );
    return $field;
}

sub createFieldDisplayLastUpdateDate
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'updateDate',
            printableName => __('Last Update Date'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

sub createFieldDisplayContactLink
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'contactLink',
            printableName => __('Contact <br />& Details'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

# -----------------------------------

sub createFieldLink
{
    my ($self, $fieldName, $printableName, $url, $text) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => $fieldName,
            printableName => __($printableName),
            editable => 0,
            defaultValue => '<a href="'.$url.'" target="'.$fieldName.'">'.__($text).'</a>',
            #optional=>1,
        );
    return $field;
}

# ------------------------------------

##
# 20150506 Pulipuli Chen
# 記錄伺服器CPU
##
sub createFieldHardwareCPU
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
            fieldName => 'hardwareCPU',
            printableName => __('CPU'),
            editable => 1,
            defaultValue => '',
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

##
# 20150506 Pulipuli Chen
# 記錄伺服器RAM
##
sub createFieldHardwareRAM
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
            fieldName => 'hardwareRAM',
            printableName => __('RAM'),
            editable => 1,
            defaultValue => '',
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# 水平線
##
sub createFieldHr
{
    my ($self, $fieldName) = @_;

    my $field = new EBox::Types::HTML(
            'fieldName' => $fieldName . '_hr',
            'printableName' => __(''),
            'editable' => 0,
            'defaultValue' => '<hr />',
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );
    return $field;
}

##
# 20150517 Pulipuli Chen
# 水平線
##
sub createFieldHrWithHeading
{
    my ($self, $fieldName, $heading) = @_;

    my $field = new EBox::Types::HTML(
            'fieldName' => $fieldName . '_hr',
            'printableName' => __(''),
            'editable' => 0,
            'defaultValue' => '<span></span>',
            'help' => "<hr /><h4>".$heading."</h4>",
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );
    return $field;
}

##
# 20150515 Pulipuli Chen
# 新增按鈕
##
sub createFieldAddBtn
{
    my ($self, $fieldName) = @_;

    my $field = new EBox::Types::HTML(
            'fieldName' => $fieldName . '_addBtn',
            'printableName' => __(''),
            'editable' => 0,
            'defaultValue' => '<button type="button" onclick="document.getElementsByName (\'add\')[0].click();" class="btn btn-icon btn-add">ADD</button>',
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );
    return $field;
}


##
# 20150506 Pulipuli Chen
# 記錄伺服器Disk
##
sub createFieldHardwareDisk
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
            fieldName => 'hardwareDisk',
            printableName => __('Disk'),
            editable => 1,
            defaultValue => '',
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

##
# 20150506 Pulipuli Chen
# 顯示硬體資訊
##
sub createFieldHardwareDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'hardwareDisplay',
            printableName => __('Hardware'),
            editable => 0,
            defaultValue => '<span></span>',
            #optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# 連接埠輸入欄位
##
sub createFieldPortDescription
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
            'fieldName' => 'description',
            'printableName' => __('Port Description'),
            'editable' => 1,
            'optional' => 0,
            'unique' => 1,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# 連接埠顯示欄位
##
sub createFieldPortDescriptionDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'descriptionDisplay',
            printableName => __('Port Description'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# 外接連接埠輸入欄位
##
sub createFieldPortExtPort
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::Port(
            'fieldName' => 'extPort',
            'printableName' => __('External Port Last 1 Numbers'),
            'unique' => 1,
            'editable' => 1,
            optional=>0,
            help => $help,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# 外接連接埠顯示欄位
##
sub createFieldPortExtPortDisplay
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'extPortHTML',
            printableName => __('External Port'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# 內部連接埠欄位
##
sub createFieldPortIntPort
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::Port(
            'fieldName' => 'intPort',
            'printableName' => __('Internal Port'),
            'unique' => 1,
            'editable' => 1,
            optional=>0,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# Only For LAN 顯示
##
sub createFieldPortOnlyForLan
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::Boolean(
            'fieldName' => 'secure',
            'printableName' => __('Only For Administrator Network'),
            'help' => '<a href="/dlllciasrouter/Composite/SettingComposite" target="_blank">' . __('Administrator Network Setting') . '</a>',
            'editable' => 1,
            optional=>0,
        );
    return $field;
}

##
# 20150512 Pulipuli Chen
# Only For LAN 顯示
##
sub createFieldPortEnableLog
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::Boolean(
            fieldName => 'log',
            printableName => __('Enable Zentyal Log'),
            #help => __('Only for local lan, like 140.119.61.0/24.'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
        );
    return $field;
}

# ---------------------------------------

# 20150515 Pulipuli Chen
# 開啟記錄按鈕
sub createFieldAttachedFilesButton
{
    my ($self, $backView) = @_;
    my $field = new EBox::Types::HasMany(
            'fieldName' => 'OtherDomainNames2',
            'printableName' => __('other domain Nmae '),
            'foreignModel' => 'OtherDomainNames2',
            'view' => '/dlllciasrouter/View/OtherDomainNames2',
            'backView' => $backView,
            'size' => '1',
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 0,
       );
    return $field;
}

##
# 20150515 Pulipuli Chen
# 檔案上傳標示
##
sub createFieldFile
{
    my ($self, $fieldName, $label) = @_;
    my $libEnc = $self->loadLibrary("LibraryEncoding");
    my $field = new EBox::Types::File(
            'fieldName' => $fieldName,
            'printableName' => $label,
            'editable' => 1,
            'optional' => 1,
            'dynamicPath'   => sub {
                my ($self) = @_;
                my $name = $self->row()->elementByName($fieldName)->userPath();
                if (!defined($name) || $name eq '') {
                    return $self->row()->elementByName($fieldName)->{filePath};
                }
                my $id = $self->row()->id();
                
                my $dir = "/usr/share/zentyal/www/dlllciasrouter/files/" . $id;
                mkdir($dir);

                my $path = $dir. "/" . $name;
                $self->row()->elementByName($fieldName)->{filePath} = $path;
                
                return $path;
            },
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
            "allowDownload"  => 1,
        );
    return $field;
}

##
# 20150515 Pulipuli Chen
# 檔案資訊顯示
##
sub createFieldFileDescriptionDisplay
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'fileDescription',
            printableName => __('Fille Description '),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        );
    return $field;
}

# --------------------------------------------------------

# 20150516 Pulipuli Chen
# 建立網頁連線的工具
sub createFieldWebLinkButton
{
    my ($self, $fieldName) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => $fieldName . "_web_button",
            printableName => '',
            editable => 0,
            optional=>0,
            defaultValue => "<span></span>",
        );

    return $field;
}

# 20150516 Pulipuli Chen
# 建立網頁連線的工具
sub createFieldConfigLinkButton
{
    my ($self, $fieldName, $text, $link) = @_;
    my $field = new EBox::Types::HTML(
            "fieldName" => $fieldName . "_config_button",
            "printableName" => '',
            "editable" => 0,
            "optional"=> 0,
            "defaultValue" => "<span></span>",
            "help" => '<a href="'.$link.'" class="btn btn-icon btn-config">'.$text.'</a>',
        );

    return $field;
}

# 20150516 Pulipuli Chen
# 建立標題空白的HTML文字網頁
sub createFieldHTMLDisplay
{
    my ($self, $fieldName, $html) = @_;
    my $field = new EBox::Types::HTML(
            "fieldName" => $fieldName . "_config_button",
            "printableName" => '',
            "editable" => 0,
            "optional"=> 0,
            "defaultValue" => "<span></span>",
            "help" => $html,
        );

    return $field;
}

# 20150516 Pulipuli Chen
# 建立網頁連線的工具
sub createFieldServerLinkButton
{
    my ($self, $fieldName, $text, $link) = @_;
    my $field = new EBox::Types::HTML(
            'fieldName' => $fieldName . "_server_button",
            'printableName' => '',
            'editable' => 0,
            'optional'=>0,
            "defaultValue" => "<span></span>",
            'help' => '<a href="'.$link.'" class="btn btn-icon btn-log">'.$text.'</a>',
        );

    return $field;
}

1;
