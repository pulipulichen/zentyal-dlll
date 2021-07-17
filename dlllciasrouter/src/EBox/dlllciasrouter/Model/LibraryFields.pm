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
        defaultValue => 1,
        hiddenOnSetter => 0,
        hiddenOnViewer => 0,
    );

    return $field;
}

sub createFieldConfigEnableHidden
{
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'configEnable',
        'printableName' => __('Enabled'),
        'editable' => 0,
        'optional' => 0,
        'defaultValue' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
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
        'help' => '<a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-1-domain-name-rule.md" target="_blank">Domain name rule</a>: exp-example-2018.dlll.nccu.edu.tw',
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );

    return $field;
}

sub createFieldDomainNameUnique
{
    my $field = new EBox::Types::DomainName(
        'fieldName' => 'domainName',
        'printableName' => __('Domain Name'),
        'editable' => 1,
        'unique' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'help' => '<a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-1-domain-name-rule.md" target="_blank">Domain name rule</a>: exp-example-2018.dlll.nccu.edu.tw',
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );

    return $field;
}

# 20140208 Pulipuli
# 顯示時使用
sub createFieldDomainNameLink
{
    my $field = new EBox::Types::HTML(
        'fieldName' => 'domainNameLink',
        'printableName' => __('Domain Name'),
        'editable' => 0,
        'optional' =>1,
        'hiddenOnSetter' => 1,
        'hiddenOnViewer' => 0,
    );

    return $field;
}

##
# 20150514 Pulipuli Chen
# 輸入其他Domain Name的功能。如果一個伺服器有很多的名稱，可以用這個功能來設定。
##
sub createFieldOtherDomainNamesButton
{
    my ($self, $backView, $model) = @_;
    my $field = new EBox::Types::HasMany(
        'fieldName' => 'otherDomainName',
        'printableName' => __('Other') . '<br />' . __('Domain') . '<br />' . __('Names'),
        'foreignModel' => $model, #'OtherDomainNames',
        'view' => '/dlllciasrouter/View/' . $model,
        'backView' => $backView,
        'size' => '1',
        'hiddenOnSetter' => 1,
        'hiddenOnViewer' => 0,
   );
    return $field;
}

##
# 20150515 Pulipuli Chen
# 其他的Domain Name設定
# 如果一個伺服器有多個名字，可以用這個來設定
##
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
        'allowUnsafeChars' => 1,
   );
    return $field;
}

# 20150506 Pulipuli
# 顯示時使用
sub createFieldIpaddrLink
{
    my $field = new EBox::Types::HTML(
        'fieldName' => 'ipaddrLink',
        'printableName' => __('Link'),
        'editable' => 0,
        'optional' =>1,
        'hiddenOnSetter' => 1,
        'hiddenOnViewer' => 0,
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
        help => '
VMID: <span style="background-color: #ffCCEE;">2</span><span style="background-color: #00ff00;">43</span> 
= IP: 10.0.<span style="background-color: #ffCCEE;">2</span>.<span style="background-color: #00ff00;">43</span>
<br />
VMID: <span style="background-color: #00ffff;">1</span><span style="background-color: #ffCCEE;">0</span><span style="background-color: #00ff00;">01</span> 
= IP: 10.<span style="background-color: #00ffff;">1</span>.<span style="background-color: #ffCCEE;">0</span>.<span style="background-color: #00ff00;">1</span>
<br />
VMID:&nbsp;<span style="background-color: #00ffff;">3</span><span style="background-color: #ffCCEE;">1</span><span style="background-color: #00ff00;">24</span>&nbsp;
= IP: 10.<span style="background-color: #00ffff;">3</span>.<span style="background-color: #ffCCEE;">1</span>.<span style="background-color: #00ff00;">24</span>
<br />
<a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-2-network-ip-range.md#virtual-machine" target="_blank">' . __('More details') . '</a>',
    );

    return $field;
}

#20150526 Pulipuli Chen
sub createFieldInternalVirtualMachineIdentify
{
    my ($self, $unique, $help) = @_;
    my $field = new EBox::Types::Union(
            'fieldName' => 'vmIdentify',
            'printableName' => __('Virtual Machine Identify'),
            'unique' => 1,
            'help' => $help,
            'subtypes' =>
            [
                new EBox::Types::Port(
                    #'fieldName' => 'vmid',
                    'fieldName' => 'vmIdentify_vmid',
                    'printableName' => __('VMID'),
                    'editable' => 1,
                ),
                new EBox::Types::HostIP(
                    #'fieldName' => 'ipaddr',
                    'fieldName' => 'vmIdentify_ipaddr',
                    'printableName' => __('Internal IP Address'),
                    'editable' => 1,
                    'unique' => $unique,
                    
                ),
            ],
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

#20150526 Pulipuli Chen
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

#20150526 Pulipuli Chen
sub createFieldInternalIPAddressHide
{
    my ($self, $unique, $help) = @_;

    my $field = new EBox::Types::HostIP(
            'fieldName' => 'ipaddr',
            'printableName' => __('Internal IP Address'),
            'editable' => 1,
            'optional'=>1,
            'unique' => $unique,
            'help' => __($help),
            'hiddenOnSetter' => 1,
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

    my $field = new EBox::Types::HostIP(
            'fieldName' => 'extIpaddr',
            'printableName' => __('External IP Address'),
            'editable' => 1,
            'mask' => 24,
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
        help => __('Set MAC to assign Internal IP by DHCP. For example: 00:A0:C9:14:C8:29. '  )
            . '<a href="https://lh3.googleusercontent.com/-KrrvguQ6wSg/WXmZXy9IXfI/AAAAAAADO90/qH3Je2-ekg8NCYQ_rko8xjLKzmsZnNyzACHMYCw/s0/2017-07-27_15-40-42.png" target="_blank">' 
                . __('How to find out MAC address?') 
            . '</a>',
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
        optional => 1,
        hiddenOnSetter => 1,
        hiddenOnViewer => 0,
    );
    return $field;
}

sub createFieldContactName
{
    my $field = new EBox::Types::Text(
        'fieldName' => 'contactName',
        'printableName' => __('Contact Name'),
        'editable' => 1,
        'optional' => 0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );

    return $field;
}

# 20150515 Pulipuli Chen
# 讓聯絡人可以在欄位上顯示
sub createFieldContactNameDisplayOnViewer
{
    my $field = new EBox::Types::Text(
        'fieldName' => 'contactName',
        'printableName' => __('Contact Name'),
        'editable' => 1,
        'optional' =>0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 0,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );

    return $field;
}

sub createFieldContactEmail
{
    my $field = new EBox::Types::MailAddress(
        'fieldName' => 'contactEmail',
        'printableName' => __('Contact Email'),
        'editable' => 1,
        'optional' => 0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );

    return $field;
}

##
# @departed 20170816
# 現在不跟EMAIL-KM結合了，不需要這個欄位了
##
#sub createFieldEmailKMDescription
#{
#    my $field = new EBox::Types::Text(
#        'fieldName' => 'description',
#        'printableName' => __('Description'),
#        'editable' => 1,
#        'optional' =>0,
#        'hiddenOnSetter' => 0,
#        'hiddenOnViewer' => 1,
#        'help' => 
#            '<button onclick="window.open(\'http://email-km.dlll.nccu.edu.tw/wp-admin/post-new.php?post_title=[CLOUD-SERVICE]\', \'_blank\');return false;">'
#            . __('Create New Post') 
#            . '</button><br />'
#            . __('Please using EMAIL-KM to create a host post and input URL in this field. '),
#        'allowUnsafeChars' => 1,
#    );
#
#    return $field;
#}

sub createFieldDescription
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
        'fieldName' => 'description',
        'printableName' => __('Description'),
        'editable' => 0,
        'optional' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'help' => $self->createFieldDescriptionEditor('Description'),
        'allowUnsafeChars' => 1,
    );

    return $field;
}

sub createFieldDescriptionEditor
{
    my ($self, $id) = @_;

    $id ||= "";

    # https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/zentyal-field-html-editor.js
    #my $script = "https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/zentyal-field-html-editor.js";
    my $script = "/data/dlllciasrouter/js/zentyal-field-html-editor.js";
    #my $script = "http://pc-pudding.dlll.nccu.edu.tw/zentyal-dlll/dlllciasrouter/javascript/zentyal-field-html-editor.js";      # 不能用HTTP!!
    
    return '<div class="html-editor" id="FieldDescriptionEditor' . $id . '_HTMLEditor"></div>'
    .'<span class="init-span" id="FieldDescriptionEditor' . $id . '_InitSpan">'
        .'<button type="button" class="init-button" id="FieldDescriptionEditor' . $id . '_InitButton" '
    .'onclick="this.className=\'init-button trigger\';this.innerHTML=\'LOADING\';this.disabled=true;if (typeof(_ZENTYAL_UTIL) === \'undefined\') {var _script=document.createElement(\'script\');_script.type=\'text/javascript\';_script.src=\''.$script.'\';document.getElementsByTagName(\'body\')[0].appendChild(_script);setTimeout(()=>{_ZENTYAL_UTIL_init(\'FieldDescriptionEditor' . $id . '\')},3000)} else {_ZENTYAL_UTIL_init(\'FieldDescriptionEditor' . $id . '\')}"'
    .'>LOAD</button> </span>'
    .'<script type="text/javascript">'
        .'document.getElementById("FieldDescriptionEditor' . $id . '_InitButton").click();'
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

sub createFieldDescriptionDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'description_display',
            printableName => __(''),
            editable => 0,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 0,
        );
    return $field;
}


sub createFieldExpiryDate
{
    my ($self, $defaultValue) = @_;

    my $field = new EBox::Types::Text(
        'fieldName' => 'expiry',
        'printableName' => __('Expiry Date'),
        'editable' => 1,
        'optional' => 0,
        'defaultValue' => $defaultValue,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,

        # 20140207 Pulipuli Chen
        # 加上說明
        'help' => __('Example: 2015/1/1 or NEVER. <a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-1-domain-name-rule.md">(How to determine the expiration date?)</a>  <br /> <hr />') 
          . $self->setExpiryDateDefaultValue('expiry'),
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );

    return $field;
}


sub setExpiryDateDefaultValue
{
    my ($self, $id) = @_;

    $id ||= "";

    my $script = "/data/dlllciasrouter/js/zentyal-field-expiry-date.js";
    
    my $initScript = 'ZENTYAL_FIELD_EXPIRY_DATE(document.currentScript)' 

    return '<script>if (typeof(ZENTYAL_FIELD_EXPIRY_DATE) === \'undefined\') {'
      . 'var _script=document.createElement(\'script\');'
      . '_script.type=\'text/javascript\';'
      . '_script.src=\''.$script.'\';'
      . 'document.getElementsByTagName(\'body\')[0].appendChild(_script);'
      . 'setTimeout(()=>{' . $initScript . '}, 1000)'
    .'}else{' . $initScript . '}</script>';
}


sub createFieldExpiryDateWithHR
{
    my $field = new EBox::Types::Text(
        'fieldName' => 'expiry',
        'printableName' => __('Expiry Date'),
        'editable' => 1,
        'optional' => 0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,

        # 20140207 Pulipuli Chen
        # 加上說明
        'help' => __('Example: 2015/1/1 or NEVER. <a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-1-domain-name-rule.md">(How to determine the expiration date?)</a>  <br /> <hr />'),
        'allowUnsafeChars' => 1,
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

            hiddenOnSetter => 1,
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


sub createFieldBoundLocalDNS
{
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'boundLocalDns',
        'printableName' => __('Bound Local DNS'),
        'editable' => 1,
        'optional' => 0,
        'defaultValue' => 1,
        'help' => __('If you want to bound this service with local DNS, this domain name will be created when service creates. Otherwise, this domain name will be removed when service deletes.'),
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );

    return $field;
}


sub createFieldBoundLocalDNSHidden
{
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'boundLocalDns',
        'printableName' => __('Bound Local DNS'),
        'editable' => 0,
        'optional' => 0,
        'defaultValue' => 1,
        #'help' => __('If you want to bound this service with local DNS, this domain name will be created when service creates. Otherwise, this domain name will be removed when service deletes.'),
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );

    return $field;
}


sub createFieldBoundLocalDNSwithHR
{
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'boundLocalDns',
        'printableName' => __('Setup In Local DNS'),
        'editable' => 1,
        'optional' => 0,
        'defaultValue' => 1,
        'help' => __('If you want to bound this service with local DNS, this domain name will be created when service creates. Otherwise, this domain name will be removed when service deletes.'
            . "<br /> <hr />"),
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );

    return $field;
}

# --------------------------------
# Protocal Redirect Fields

sub createFieldProtocolRedirect
{
    my ($self, $protocol, $enable) = @_;
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'redir'.$protocol.'_enable',
        'printableName' => __('Enable '.$protocol.' Redirect'),
        'editable' => 1,
        'optional' => 0,
        'defaultValue' => $enable,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );

    return $field;
}

##
# 20170731 Pulipuli Chen
# 這是給主要管理伺服器用的
# @departed 20170731
##
#sub createFieldProtocolOnlyForLAN
#{
#    my ($self, $protocol, $enable) = @_;
#    my $field = new EBox::Types::Boolean(
#            fieldName => 'redir'.$protocol.'_secure',
#            printableName => __('Only For Administrator List'),
#            help => '<a href="/dlllciasrouter/Composite/SettingComposite#RouterSettings_RouterSettings_adminNet_config_button_row" target="_blank">' . __('Administrator List Setting') . '</a>',
#            editable => 1,
#            optional => 0,
#            defaultValue => $enable,
#            hiddenOnSetter => 0,
#            hiddenOnViewer => 1,
#        );
#
#    return $field;
#}

##
# 20170731 Pulipuli Chen
# 這是給主要管理伺服器用的，可以選擇多種Port
##
sub createFieldProtocolSecureSelection
{
    my ($self, $protocol, $secureLevel) = @_;

    my $field = new EBox::Types::Select(
        'fieldName' => 'redir'.$protocol.'_secure',
        'printableName' => __('Secure level'),
        'populate' => \&_populateProtocolSecureSelection,
        'editable' => 1,
        'defaultValue' => $secureLevel,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'help' => '<a href="/dlllciasrouter/Composite/SettingComposite#RouterSettings_hr_ Zentyal_admin_hr_row" target="_blank">' . __('Set up Administrator List & Workplace List') . '</a>',
    );

    return $field;
}

##
# 20170731 Pulipuli Chen
# 這是給主要管理伺服器用的，可以選擇多種Port 選項
##
sub _populateProtocolSecureSelection
{
    return [
        {
            'value' => 0,
            'printableValue' => __('Public'),
        },
        {
            'value' => 1,
            'printableValue' => __('Only for Administrator List'),
        },
        {
            'value' => 2,
            'printableValue' => __('Only for Workplace List'),
        },
    ];
}

sub createFieldProtocolLog
{
    my ($self, $protocol, $enable) = @_;
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'redir'.$protocol.'_log',
        'printableName' => __('Enable Zentyal Log'),
        #'help' => __('Only for local lan, like 140.119.61.0/24.'),
        'editable' => 1,
        'optional' => 0,
        'defaultValue' => $enable,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
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

##
# 20170731 Pulipuli Chen
# 通訊協定
##
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

##
# 20170731 Pulipuli Chen
# 通訊協定 選項
##
sub _populateFieldProtocolScheme
{
    # life time values must be in hours
    return  [
        {
            'value' => 'http',
            'printableValue' => __('HTTP (http://)'),
        },
        {
            'value' => 'https',
            'printableValue' => __('HTTPS (https://)'),
        },
        {
            'value' => 'none',
            'printableValue' => __('Not a link'),
        },
    ];
}

##
# 20170801 Pulipuli Chen
# 好像是不用的樣子
##
sub createFieldPoundProtocolScheme
{
    my ($self) = @_;
    my $field = new EBox::Types::Union(
        'fieldName' => 'poundProtocolScheme',
        'printableName' => __('Pound Protocol'),
        'unique' => 0,
        'subtypes' => [
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
    my ($self, $enable) = @_;

    #my $field = $self->createFieldProtocolOnlyForLAN("POUND", $enable);
    my $field = $self->createFieldProtocolSecureSelection("POUND", $enable);
    return $field;
}


##
# 20210717 Pulipuli Chen
# 現在要想辦法處理這一格
## 
sub createFieldProtocolNote
{
    my ($self, $protocol) = @_;
    my $field = new EBox::Types::Text(
        'fieldName' => 'redir'.$protocol.'_note',
        'printableName' => __($protocol.' Note'),
        'editable' => 0,
        'optional' =>1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        #'help' => __( 'Login account / password, or using this port for other usage'),
        'help' => $self->createFieldDescriptionEditor($protocol.'_Note'),
        'allowUnsafeChars' => 1,
        #'HTMLSetter' => '/ajax/setter/textareaSetter.mas',
    );

    return $field;
}

sub createFieldProtocolNoteWithHr
{
    my ($self, $protocol) = @_;
    my $field = new EBox::Types::Text(
        'fieldName' => 'redir'.$protocol.'_note',
        'printableName' => __($protocol.' Note'),
        'editable' => 1,
        'optional' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'help' => ( 'Login account / password, or using this port for other usage <br /> <hr />'),
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textareaSetter.mas',
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
    #my $field = $self->createFieldProtocolOnlyForLAN("HTTP", 0);
    my $field = $self->createFieldProtocolSecureSelection("HTTP", 0);
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
    #my $field = $self->createFieldProtocolOnlyForLAN("HTTPS", 1);
    my $field = $self->createFieldProtocolSecureSelection("HTTPS", 1);
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
    #my $field = $self->createFieldProtocolOnlyForLAN("SSH", 1);
    my $field = $self->createFieldProtocolSecureSelection("SSH", 1);
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
    #my $field = $self->createFieldProtocolOnlyForLAN("RDP", 1);
    my $field = $self->createFieldProtocolSecureSelection("RDP", 1);
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
            'foreignModel' => 'ServerPortRedirect',
            'view' => '/dlllciasrouter/View/ServerPortRedirect',
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
        'fieldName' => 'redirOtherHelp',
        'printableName' => __('Other Redirect Ports'),
        'defaultValue' => __('You have to add this row before setting up other redirection at following table.'),
        'editable' => 0,
        'optional' => 0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
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
        'allowUnsafeChars' => 1,
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
        'fieldName' => 'createDateField',
        'printableName' => __('Create Date'),
        'editable' => 1,
        'optional' => 1,
        'hiddenOnSetter' => 1,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
    );
    return $field;
}

sub createFieldDisplayLastUpdateDate
{
    my ($self, $hiddenOnViewer) = @_;
    if (!defined($hiddenOnViewer)) {
        $hiddenOnViewer = 1;
    }

    my $field = new EBox::Types::HTML(
            fieldName => 'updateDate',
            printableName => __('Last Update Date'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => $hiddenOnViewer,
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

# 20150519 Pulipuli Chen
sub createFieldLogsLink
{
    my ($self) = @_;
    my $field = new EBox::Types::HTML(
            fieldName => 'logsLink',
            printableName => __('Logs'),
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
# 20150526 Pulipuli Chen
# 記錄伺服器位置
##
sub createFieldPhysicalLocation
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
        'fieldName' => 'physicalLocation',
        'printableName' => __('Physical Location'),
        'editable' => 1,
        #'defaultValue' => '',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );
    return $field;
}

##
# 20170801 Pulipuli Chen
# 記錄伺服器作業系統
##
sub createFieldOS
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
        'fieldName' => 'hardwareOS',
        'printableName' => __('Operating System or Machine Model'),
        'editable' => 1,
        #'defaultValue' => '',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );
    return $field;
}

##
# 20150506 Pulipuli Chen
# 記錄伺服器CPU
##
sub createFieldHardwareCPU
{
    my ($self) = @_;

    my $field = new EBox::Types::Text(
        'fieldName' => 'hardwareCPU',
        'printableName' => __('CPU'),
        'editable' => 1,
        'defaultValue' => '',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
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
        'fieldName' => 'hardwareRAM',
        'printableName' => __('RAM'),
        'editable' => 1,
        'defaultValue' => '',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );
    return $field;
}

##
# 20150528 Pulipuli Chen
# 記錄伺服器是否啟用KVM
##
sub createFieldHardwareKVM
{
    my ($self) = @_;

    my $field = new EBox::Types::Boolean(
            fieldName => 'hardwareKVM',
            printableName => __('Enable KVM'),
            editable => 1,
            defaultValue => 1,
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
# 20150727 Pulipuli Chen
# 只有標題
##
sub createFieldHeading
{
    my ($self, $fieldName, $heading) = @_;

    my $field = new EBox::Types::HTML(
            'fieldName' => $fieldName . '_hr',
            'printableName' => __(''),
            'editable' => 0,
            'defaultValue' => '<span></span>',
            'help' => "<h4>".$heading."</h4>",
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
        'fieldName' => 'hardwareDisk',
        'printableName' => __('Disk'),
        'editable' => 1,
        'defaultValue' => '',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
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
        'allowUnsafeChars' => 1,
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
        'optional' =>0,
        'help' => $help,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );
    return $field;
}

##
# 20170731 Pulipuli Chen
# 外接連接埠輸入欄位，選擇版本
##
sub createFieldPortExtPortSelection
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::Select(
        'fieldName' => 'extPort',
        'printableName' => __('External Port Last 1 Numbers'),
        'populate' => \&_populatePortExtPortSelection,
        'editable' => 1,
        'optional' =>0,
        'help' => $help,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
    );
    return $field;
}


##
# 20170731 Pulipuli Chen
# 外接連接埠輸入欄位，選擇版本 選項
##
sub _populatePortExtPortSelection
{
    return [
        {
            value => 1,
            printableValue => 1,
        },
        {
            value => 4,
            printableValue => 4,
        },
        {
            value => 5,
            printableValue => 5,
        },
        {
            value => 6,
            printableValue => 6,
        },
        {
            value => 7,
            printableValue => 7,
        },
    ];
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
# 這是給虛擬機器用的
##
sub createFieldPortOnlyForLan
{
    my ($self, $help) = @_;
    my $field = new EBox::Types::Boolean(
        'fieldName' => 'secure',
        'printableName' => __('Only For Administrator List'),
        'help' => '<a href="/dlllciasrouter/Composite/SettingComposite#RouterSettings_RouterSettings_adminNet_config_button_row" target="_blank">' . __('Administrator List Setting') . '</a>',
        'editable' => 1,
        'optional' => 0,
    );
    return $field;
}

##
# 20170731 Pulipuli Chen
# 這是給虛擬機器 Other Redirection用的
# 權限選擇
##
sub createFieldPortSecureSelection
{
    my ($self, $secureLevel) = @_;
    my $field = new EBox::Types::Select(
        'fieldName' => 'secure',
        'printableName' => __('Secure level'),
        'help' => '<a href="/dlllciasrouter/Composite/SettingComposite#RouterSettings_hr_ Zentyal_admin_hr_row" target="_blank">' . __('Set up Administrator List & Workplace List') . '</a>',
        'populate' => \&_populateProtocolSecureSelection,
        'editable' => 1,
        'defaultValue' => $secureLevel,
        'optional' => 0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
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
        'fieldName' => 'attachedFiles',
        'printableName' => __('Files'),
        'foreignModel' => 'AttachedFiles',
        'view' => '/dlllciasrouter/View/AttachedFiles',
        'backView' => $backView,
        'size' => '1',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 0,
        'help' => __('You have to add this row before setting up other redirection at following table.'),
        #'parent' =>  $self->loadLibrary('RouterSettings'),
   );
    return $field;
}

##
# 20150515 Pulipuli Chen
# 開啟上傳檔案的按鈕
##
sub createFieldAttachedFilesButtonShow
{
    my ($self, $backView) = @_;
    my $field = new EBox::Types::HasMany(
        'fieldName' => 'attachedFiles',
        'printableName' => __('Files'),
        'foreignModel' => 'AttachedFiles',
        'view' => '/dlllciasrouter/View/AttachedFiles',
        #'backView' => $backView,
        'backView' => '/dlllciasrouter/Composite/VMServerComposite',
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
            'fieldName' => 'fileDescription',
            'printableName' => __('Fille Description '),
            'editable' => 0,
            'optional' => 1,
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 0,
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
    my ($self, $fieldName, $text, $link, $isBlank) = @_;

    my $target = "";
    if ($isBlank == 1) {
        $target = ' target="_blank"';
    }
    my $field = new EBox::Types::HTML(
            "fieldName" => $fieldName . "_config_button",
            "printableName" => '',
            "editable" => 0,
            "optional"=> 0,
            "defaultValue" => "<span></span>",
            "help" => '<a href="'.$link.'" class="btn btn-icon btn-config" '.$target.'>'.$text.'</a>',
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

    my $fullFieldName = $fieldName . "_" . $text . "_server_button";
    $fullFieldName =~ s/\s/_/g;

    my $field = new EBox::Types::HTML(
            'fieldName' => $fullFieldName,
            'printableName' => '',
            'editable' => 0,
            'optional'=>0,
            "defaultValue" => "<span></span>",
            'help' => '<a href="'.$link.'" class="btn btn-icon btn-log">'.$text.'</a>',
        );

    return $field;
}

# 20170727 Pulipuli Chen
# 建立另開網頁連線的工具
sub createFieldServerLinkButtonNewWindow
{
    my ($self, $fieldName, $text, $link) = @_;

    my $fullFieldName = $fieldName . "_" . $text . "_server_button";
    $fullFieldName =~ s/\s/_/g;

    my $field = new EBox::Types::HTML(
            'fieldName' => $fullFieldName,
            'printableName' => '',
            'editable' => 0,
            'optional'=>0,
            "defaultValue" => "<span></span>",
            'help' => '<a href="'.$link.'" class="btn btn-icon btn-log" target="_blank">'.$text.'</a>',
        );

    return $field;
}

# 20170727 Pulipuli Chen
# 建立可以儲存網址的欄位
sub createFieldURL
{
    my ($self, $title) = @_;

    my $field = new EBox::Types::URI(
        'fieldName' => 'url',
        'printableName' => __($title),
        'editable' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
        'help' => __('For example: http://www.dlll.nccu.edu.tw/'),
    );

    return $field;
}

# 20150528 Pulipuli Chen
# 建立標題有文字的HTML文字網頁
sub createFieldTitledHTMLDisplay
{
    my ($self, $fieldName, $title, $html) = @_;

    my $fullFieldName = $fieldName . "_" . $title . "_config_button";
    $fullFieldName =~ s/\s/_/g;

    my $field = new EBox::Types::HTML(
        "fieldName" => $fullFieldName,
        "printableName" => $title,
        "editable" => 0,
        "optional" => 0,
        "defaultValue" => "<span></span>",
        "help" => $html,
    );

    return $field;
}

# --------------------------------------------

##
# 20150528 Pulipuli Chen
# 記錄NAS是否啟用Mount
##
sub createFieldMountEnable
{
    my ($self) = @_;

    my $field = new EBox::Types::Boolean(
            fieldName => 'mountEnable',
            printableName => __('Mount Enable'),
            editable => 1,
            defaultValue => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

##
# 20150528 Pulipuli Chen
# mount類型
##
sub createFieldMountType
{
    my ($self, $defaultValue) = @_;

    my $field = new EBox::Types::Select(
            fieldName => 'mountType',
            printableName => __('Mount Type'),
            'populate' => \&_populateFieldMountType,
            editable => 1,
            defaultValue => $defaultValue,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );
    return $field;
}

##
# 20150528 Pulipuli Chen
# mount類型
##
sub _populateFieldMountType
{
    # life time values must be in hours
    return  [
                {
                    value => 'nfs',
                    printableValue => __('NFS'),
                },
                {
                    value => 'cifs',
                    printableValue => __('Samba (CIFS))'),
                },
            ];
}


##
# 20150529 Pulipuli Chen
# 連接埠輸入欄位
##
sub createFieldMountPath
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
        'fieldName' => 'mountPath',
        'printableName' => __('Path'),
        'help' => "Option is the <u>underline</u> part. For example: <br />" 
            . " NFS: mount -t nfs 10.6.1.1:<u>/mnt/nfs</u> /opt/mfschunkservers/10.6.1.1 <br />"
            . " Samba (CIFS)): mount -t cifs -o username=&quot;user&quot;,password=&quot;password&quot; //10.6.1.1<u>/cifs</u> /opt/mfschunkservers/10.6.1.1",
        'editable' => 1,
        'optional' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );
    return $field;
}

##
# 20150529 Pulipuli Chen
# 連接埠輸入欄位
##
sub createFieldMountUsername
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
        'fieldName' => 'mountUsername',
        'printableName' => __('Username'),
        'help' => "Username is the <u>underline</u> part. For example: <br />" 
            . " Samba (CIFS)): mount -t cifs -o username=&quot;<u>user</u>&quot;,password=&quot;password&quot; //10.6.1.1/cifs /opt/mfschunkservers/10.6.1.1",
        'editable' => 1,
        'optional' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );
    return $field;
}

##
# 20150529 Pulipuli Chen
# 連接埠輸入欄位
##
sub createFieldMountPassword
{
    my ($self) = @_;
    my $field = new EBox::Types::Text(
        'fieldName' => 'mountPassword',
        'printableName' => __('Password'),
        'help' => "Password is the <u>underline</u> part. For example: <br />" 
            . " Samba (CIFS)): mount -t cifs -o username=&quot;user&quot;,password=&quot;<u>password</u>&quot; //10.6.1.1/cifs /opt/mfschunkservers/10.6.1.1",
        'editable' => 1,
        'optional' => 1,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'allowUnsafeChars' => 1,
        'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
    );
    return $field;
}

1;
