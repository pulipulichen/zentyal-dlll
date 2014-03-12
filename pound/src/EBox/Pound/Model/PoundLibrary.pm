package EBox::Pound::Model::PoundLibrary;

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
        fieldName => 'domainName',
        printableName => __('Domain Name'),
        editable => 1,
        # 因為要允許同一個Domain Name指向多個Back End，所以這部份要做些調整
        #'unique' => 1,
        hiddenOnSetter => 0,
        hiddenOnViewer => 1,
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

sub createFieldInternalIPAddress
{
    my $field = new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
            #'unique' => 1,
            help => __('The third part should be between 1~5, and the forth part should be between 1~99. <br />'
                . 'Example: 10.9.1.51'),
        );

    return $field;
}

sub createFieldInternalIPAddressHideView
{
    my $field = new EBox::Types::HostIP(
            fieldName => 'ipaddr',
            printableName => __('Internal IP Address'),
            editable => 1,
            #'unique' => 1,
            help => __('The third part should be between 1~5, and the forth part should be between 1~99. <br />'
                . 'Example: 10.9.1.51'),
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldInternalPort
{
    my $field = new EBox::Types::Port(
            fieldName => 'port',
            printableName => __('Internal Port'),
            defaultValue => 80,
            editable => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => __('If HTTP to HTTPS enabled, Internal Port will be not worked.'),
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

sub createFieldContactEmail
{
    my $field = new EBox::Types::Text(
            fieldName => 'contactEmail',
            printableName => __('Contact Email'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

    return $field;
}

sub createFieldDescription
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

sub createFieldExpiryDate
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

sub createFieldBoundLocalDNSwithHR
{
    my $field = new EBox::Types::Boolean(
            fieldName => 'boundLocalDns',
            printableName => __('Bound Local DNS'),
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
            printableName => __('Only For LAN'),
            help => __('Only for local LAN, like 140.119.61.0/24.'),
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
    my ($self, $protocol, $unique) = @_;
    my $field = new EBox::Types::Union(
            'fieldName' => 'redir'.$protocol.'_extPort',
            'printableName' => __($protocol.' External Port'),
            'unique' => $unique,
            'subtypes' =>
            [
            new EBox::Types::Union::Text(
                'fieldName' => 'redir'.$protocol.'_extPort_default',
                'printableName' => __('Default: Based on IP address.')),
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

sub createFieldProtocolInternalPort
{
    my ($self, $protocol, $port) = @_;
    my $field = new EBox::Types::Union(
            'fieldName' => 'redir'.$protocol.'_intPort',
            'printableName' => __($protocol.' Redirect'),
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
            help => ( 'Login account / password, or using this port for other usage <br /> <hr />'),
        );

    return $field;
}

# --------------------------------
# HTTP Redirect Fields

sub createFieldHTTPRedirect
{
    my ($self) = @_;
    my $field = $self->createFieldProtocolRedirect("HTTP", 1);
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
    my $field = $self->createFieldProtocolExternalPort("HTTP", 0);
    return $field;
}

sub createFieldHTTPInternalPort
{
    my $field = new EBox::Types::Text(
            'fieldName' => 'redirHTTP_intPort',
            'printableName' => __('HTTP Internal Port'),
            'editable' => 0,
            'defaultValue' => "Use reverse proxy internal port",
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        );

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
    my ($self) = @_;
    my $field = $self->createFieldProtocolRedirect("HTTPS", 1);
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
    my $field = $self->createFieldProtocolExternalPort("HTTPS", 1);
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
    my ($self) = @_;
    my $field = $self->createFieldProtocolRedirect("SSH", 1);
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
    my $field = $self->createFieldProtocolExternalPort("SSH", 1);
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
    my ($self) = @_;
    my $field = $self->createFieldProtocolRedirect("RDP", 1);
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
    my $field = $self->createFieldProtocolExternalPort("RDP", 1);
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

sub createFieldOtherRedirectPortsDisplay
{
    my ($self) = @_;
    my $field = new EBox::Types::HasMany(
            'fieldName' => 'redirOther',
            'printableName' => __('Other <br />Redirect <br />Ports'),
            'foreignModel' => 'PortRedirect',
            'view' => '/Pound/View/PortRedirect',
            'backView' => '/Pound/View/PoundServices',
            'size' => '1',
            #optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
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
            printableName => __('Contact & Last Update Date'),
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

# -----------------------------------
# Domain Name

# 20140208 Pulipuli Chen
# 這是舊式的寫法，應禁止使用
#sub addDomainName
#{
#    my ($self, $row) = @_;
#
#    if ($row->valueByName('boundLocalDns')) {
#        my $domainName = $row->valueByName('domainName');
#        my $gl = EBox::Global->getInstance();
#        my $dns = $gl->modInstance('dns');
#        my $domModel = $dns->model('DomainTable');
#        my $id = $domModel->findId(domain => $domainName);
#        if (defined($id) == 0) 
#        {
#            $dns->addDomain({
#                domain_name => $domainName,
#            });
#        }
#    }
#}

sub addDomainName
{
    my ($self, $row) = @_;

    if ($row->valueByName('boundLocalDns')) {
        my $domainName = $row->valueByName('domainName');
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        my $domModel = $dns->model('DomainTable');
        my $id = $domModel->findId(domain => $domainName);
        if (defined($id)) {
            $domModel->removeRow($id);
        }
        $domModel->addDomain({
            'domain_name' => $domainName,
        });

        $id = $domModel->findId(domain => $domainName);
        my $domainRow = $domModel->row($id);

        # 刪掉多餘的IP
        my $ipTable = $domainRow->subModel("ipAddresses");
        $ipTable->removeAll();

        # 刪掉多餘的Hostname
        my $hostnameTable = $domainRow->subModel("hostnames");
        my $zentyalHostnameID = $hostnameTable->findId("hostname"=> 'zentyal');
        my $zentyalRow = $hostnameTable->row($zentyalHostnameID);
        my $zentyalIpTable = $zentyalRow->subModel("ipAddresses");
        $zentyalIpTable->removeAll();

        my $ipaddr = $self->getExternalIpaddr();

        # 幫ipTable加上指定的IP
        $ipTable->addRow(
            ip => , $ipaddr
        );

        # 幫zentyalIpTalbe加上指定的IP
        $zentyalIpTable->addRow(
            ip => , $ipaddr
        );
    }
}

sub deleteDomainName
{
    my ($self, $row, $excludeModel) = @_;
    my $domainName = $row->valueByName('domainName');

    try {

    # 先找找看有沒有
    my $hasDomainName = 0;

    if ($hasDomainName == 0 && $excludeModel ne 'PoundServices') 
    {
        $hasDomainName = $self->modelHasDomainName('PoundServices', $domainName);
    }

    if ($hasDomainName == 0 && $excludeModel ne 'URLRedirect') 
    {
        $hasDomainName = $self->modelHasDomainName('URLRedirect', $domainName);
    }
    
    if ($hasDomainName == 0 && $excludeModel ne 'DNS') 
    {
        $hasDomainName = $self->modelHasDomainName('DNS', $domainName);
    }

    if ($hasDomainName == 0) 
    {
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        my $domModel = $dns->model('DomainTable');
        my $id = $domModel->findId(domain => $domainName);
        if (defined($id)) 
        {
            $domModel->removeRow($id);
        }
    }

    } catch {
        $self->show_exceptions($_);
    };
}

sub modelHasDomainName
{
    my ($self, $modelName, $domainName) = @_;

    my $model = $self->parentModule()->model($modelName);
    my $domainNameId = $model->findId(
        'domainName' => $domainName
    );
    return defined($domainNameId);
}

# -----------------------------------
# Field Setter

sub setLink
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName('domainName');
    my $url = $row->valueByName('url');
    my $enable = $self->isEnable($row);

    my $domainNameLink = $self->domainNameToLink($domainName, $enable);
    my $urlLink = $self->urlToLink($url);

    $row->elementByName('domainNameLink')->setValue($domainNameLink);
    $row->elementByName('urlLink')->setValue($urlLink);

    #$row->store();
}

sub domainNameToLink
{
    my ($self, $url, $enable) = @_;

    my $link = $url;
    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
        $link = "http://" . $link . "/";
    }

    $url = $self->breakUrl($url);

    my $textDecoration = "underline";
    if ($enable == 0) {
        $textDecoration = "line-through";
    }

    $link = '<a style="background: none;text-decoration: '.$textDecoration.';color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$url.'</a>';

    return $link;
}


sub updateDomainNameLink
{
    my ($self, $row) = @_;
    
    my $domainName = $row->valueByName("domainName");
    my $port = $self->parentModule()->model("Settings")->value("port");

    if ($port == 80) {
        $port = "";
    }
    else {
        $port = ":" . $port;
    }
    my $link = "http\://" . $domainName . $port . "/";

    $domainName = $self->breakUrl($domainName);

    my $enable = $self->isEnable($row);
    my $textDecoration = "underline";
    if ($enable == 0) {
        $textDecoration = "line-through";
    }

    $link = '<a href="'.$link.'" ' 
        . 'target="_blank" ' 
        . 'style="background: none;text-decoration: '.$textDecoration.';color: #A3BD5B;">' 
        . $domainName 
        . '</a>';
    $row->elementByName("domainNameLink")->setValue($link);

    #$row->store();
}

sub breakUrl
{
    my ($self, $url) = @_;

     my $result = index($url, ".");
    $url = substr($url, 0, $result) . "<br />" . substr($url, $result);
    return $url;
}


# ------------------------------------------------
# Date Setter

sub setUpdateDate
{
    my ($self, $row) = @_;

    my $date = strftime "%Y/%m/%d %H:%M:%S", localtime;

    $row->elementByName('updateDate')->setValue('<span>'.$date."</span>");
    #$row->store();
}

sub setCreateDate
{
    my ($self, $row) = @_;

    my $date = $row->valueByName("createDateField");
    if (defined($date) == 0) {
        $date = strftime "%Y/%m/%d %H:%M:%S", localtime;
        $row->elementByName('createDate')->setValue('<span>'.$date."</span>");
        $row->elementByName('createDateField')->setValue($date);
    }
    else {
        $row->elementByName('createDate')->setValue('<span>'.$date."</span>");
    }
    
    #$row->store();
}

# ------------------------------------------------
# Contact Setter

sub setContactLink
{
    my ($self, $row) = @_;

    my $link = '';

    my $desc = $row->valueByName('description');
    if ($desc =~ m/^(http)/i) {
        $link = $link.'[<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$desc.'" target="_blank">EMAIL-KM</a>]'.'<br />';
    }
    else {
        # 20140207 Pulipuli Chen
        # 如果不是網址，則顯示額外訊息
        my $short_desc = $desc;
        if (length($short_desc) > 10) {
            $short_desc = substr($short_desc, 0, 10) . "...";
            $short_desc = "<span title=\"".$desc."\">".$short_desc."</span>"
        }

        $link = $link.$short_desc.'<br />';
    }

    my $name = $row->valueByName('contactName');
    my $email = $row->valueByName('contactEmail');
    my $expiry = $row->valueByName('expiry');

    if ($email eq "") {
        $link = $link.$name;
    }
    elsif ($email =~ m/(@)/i) {
        $link = $link.'<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="mailto:'.$email.'">'.$name.'</a>';
    }
    else {
        $link = $link.$name.'<br />('.$email.')';
    }

    my $date = strftime "%Y/%m/%d", localtime;
    $link = $link."<br />[Update] ".$date;
    $link = $link."<br />[Expiry] ".$expiry;
    $link = "<span>".$link."</span>";

    $row->elementByName('contactLink')->setValue($link);

    #$row->store();
}

# ---------------------------------------
# External Network

# 20140208 Pulipuli Chen
# 好像沒有用到，作廢吧？
#sub getExternalIpaddrs
#{
#    my $network = EBox::Global->modInstance('network');
#    my $address = "127.0.0.1";
#    foreach my $if (@{$network->ExternalIfaces()}) {
#        if ($network->ifaceIsExternal($if)) {
#            $address = $network->ifaceAddress($if);
#            last;
#        }
#    }
#    my @ipaddr=($address);
#    return \@ipaddr;
#}

sub getExternalIpaddr
{
    my $network = EBox::Global->modInstance('network');
    my $address = "127.0.0.1";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $address = $network->ifaceAddress($if);
            last;
        }
    }
    return $address;
}

sub getExternalIface
{
    my $network = EBox::Global->modInstance('network');
    my $iface = "eth0";
    foreach my $if (@{$network->ExternalIfaces()}) {
        if ($network->ifaceIsExternal($if)) {
            $iface = $if;
            last;
        }
    }
    return $iface;
}

# ----------------------------

sub show_exceptions
{
    my ($self, $message) = @_;
    throw EBox::Exceptions::External($message);
}

sub isEnable
{
    my ($self, $row) = @_;
    return $row->valueByName('configEnable');
}

# ----------------------------

##
# 更新NetworkDisplay欄位
# 顯示IP跟MAC
# @param $row 欄
##
sub updateNetworkDisplay
{
    my ($self, $row) = @_;

    my $ipaddr = $row->valueByName('ipaddr');
    my $macaddr = $row->valueByName('macaddr');
    if ($macaddr ne '') {
        $ipaddr = $ipaddr . ' <br /> (' . $macaddr . ')';
    }
    
    $ipaddr = '<span>' . $ipaddr . '</span>';

    $row->elementByName('network_display')->setValue($ipaddr);
}

##
# 從Objects當中找出DHCP-fixed-IP的成員名單
# 如果沒有的話，則建立一個
##
sub getDHCPfixedIPMemberModel
{
    my ($self) = @_;

    my $objectsModule = EBox::Global->modInstance('objects');
    my $objectTable = $objectsModule->model('ObjectTable');

    my $name = 'DHCP-fixed-IP';
    my $id = $objectTable->findId('name' => $name);

    if (defined($id) == 0) {
        $id = $objectTable->addRow('name' => $name);

        unless (defined($id)) {
            throw EBox::Exceptions::Internal("Couldn't add object's name: $name");
        }
    }

    my $objectRow = $objectTable->row($id);
    
    # 設定DHCP FixedAddresses
    $self->setupDHCPfixedIP($id);

    my $memberModel = $objectRow->subModel('members');

    return $memberModel;
}

##
# 增加DHCP-fixed-IP的成員
# @param $row 來自BackEnd的row
##
sub addDHCPfixedIPMember
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName('domainName');
    my $ipaddr = $row->valueByName('ipaddr');
    my $macaddr = $row->valueByName('macaddr');

    if ($macaddr eq '') {
        return;
    }

    my $memberModel = $self->getDHCPfixedIPMemberModel();

    # 先移除既有的
    my $id = $memberModel->findId('macaddr' => $macaddr);
    if (defined($id)) {
        $memberModel->removeRow($id);
    }
    
    # 加入新的 
    $memberModel->addRow(
        name => $domainName,
        address_selected => 'ipaddr',
        ipaddr_ip => $ipaddr,
        ipaddr_mask => '32',
        macaddr => $macaddr
    );
}

##
# 移除DHCP-fixed-IP的成員
# @param $row 來自BackEnd的row
##
sub removeDHCPfixedIPMember
{
    my ($self, $row) = @_;

    my $macaddr = $row->valueByName('macaddr');

    my $memberModel = $self->getDHCPfixedIPMemberModel();

    # 移除既有的
    my $id = $memberModel->findId('macaddr' => $macaddr);
    if (defined($id)) {
        $memberModel->removeRow($id);
    }
}

##
# 設定DHCP中的FixedAddresses
# @param $objectRowID 要設定的ObjectID
## 
sub setupDHCPfixedIP
{
    my ($self, $objectRowID) = @_;

    my $dhcpModule = EBox::Global->modInstance('dhcp');
    my $interfacesModel = $dhcpModule->model('Interfaces');

    # 先找尋有啟用的裝置，取得第一個
    my $id = $interfacesModel->findId('enabled'=>1);
    if (defined($id) == 0) {
        # 沒有裝置啟動，不使用
        return;
    }

    my $enabledInterface = $interfacesModel->row($id);
    my $configuration = $enabledInterface->subModel('configuration');
    my $fixedAddresses = $configuration->componentByName('FixedAddressTable');
    
    # 先找找有沒有已經設定的群組
    my $desc = 'Reverse Proxy Fixed Address Object (DHCP-fixed-IP)';
    $id = $fixedAddresses->findId('description' => $desc);

    if (defined($id)) {
        # 已經設定
        return;
    }

    $fixedAddresses->addRow(
        'object' => $objectRowID,
        'description' => $desc,
    );
}

1;
