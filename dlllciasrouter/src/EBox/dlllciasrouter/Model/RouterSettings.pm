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

use EBox::Network;

use Try::Tiny;

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

    my $address = $self->loadLibrary('LibraryNetwork')->getExternalIpaddr();
    #my $submask = $self->loadLibrary('LibraryNetwork')->getExternalMask();
    my $submask = 24;
    my $external_iface = $self->loadLibrary('LibraryNetwork')->getExternalIface();

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    

    my @fields = ();
    #push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ZentyalAdmi', __('Zentyal Admin Configuration')));

    #my $editAdminPort = '/SysInfo/Composite/General#AdminPort';
    #push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName . 'zentyal_webadmin', __('EDIT Zentyal Webadmin Port'), $editAdminPort, 1));
    
    push(@fields, new EBox::Types::Port(
              fieldName     => 'webadminPort',
              printableName => __('Zentyal Webadmin Port. ') . __('Only For Administrator Network'),
              editable      => 1,
              unique        => 1,
              defaultValue => 64443,
              optional => 0,
             ));

    push(@fields, new EBox::Types::Port(
            fieldName     => 'adminPort',
            printableName => __('Zentyal SSH Port. '). __('Only For Administrator Network'),
            help => '<a href="/dlllciasrouter/Composite/SettingComposite" target="_blank">' . __('Administrator Network Setting') . '</a>',
            editable      => 1,
            unique        => 1,
            defaultValue => 64422,
            optional => 0,
        ));

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
              fieldName     => 'port',
              printableName => __('External Port'),
              editable      => 1,
              unique        => 1,
              defaultValue => 80,
              optional => 0,
             ));
    push(@fields, new EBox::Types::Text(
              fieldName     => 'alive',
              printableName => __('Alive Time'),
              editable      => 1,
              unique        => 0,
              defaultValue => 30,
              optional => 0,
              help => __("Check backend every X secs. Default is 30 sec."),
             ));
    push(@fields, new EBox::Types::Text(
              fieldName     => 'timeout',
              printableName => __('TimeOut'),
              editable      => 1,
              unique        => 0,
              defaultValue => 300,
              optional => 0,
              help => __("Wait for response X secs. Default is 30 sec."),
        ));
        
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName, __('EDIT ERROR MESSAGE'), $editErrorView, 1));

    
    #  Administrator Network
#    push(@fields, new EBox::Types::HTML(
#              fieldName     => 'adminNet',
#              printableName => __('Administrator Network'),
#              #editable      => 1,
#              ip => $address,
#              mask => $submask,
#              optional => 1,
#              #help => __(""),
#        );
    my $objectID = $self->loadLibrary('LibraryMAC')->getObjectRow('Administrator-Network')->id();
    my $editAdminNet = '/Objects/View/MemberTable?directory=ObjectTable/keys/'.$objectID.'/members&backview=/Objects/View/MemberTable';
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_adminNet", __('EDIT ADMINISTRATOR NETWORK'), $editAdminNet, 1));

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
        
    push(@fields, $fieldsFactory->createFieldDescription());
    #push(@fields, $fieldsFactory->createFieldAttachedFilesButton('/dlllciasrouter/Composite/SettingComposite', 0));
    my $filePath = "/dlllciasrouter/View/AttachedFiles?directory=RouterSettings/keys/rs1/attachedFiles&backview=/dlllciasrouter/Composite/SettingComposite";
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_attachedFiles", __('UPLOAD FILE'), $filePath, 1));

    my $pageTitle = __('Setting');
    
    my $dataTable = {
            'tableName' => $tableName,
            'pageTitle' => '',
            'printableTableName' => $pageTitle,
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

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    #my $msg = $self->loadLibrary('LibraryMAC')->getObjectRow('DHCP-fixed-IP')->id();
    #$self->getLibrary()->show_exceptions("[" . $msg . ']'. ' ( RouterSettings->updatedRowNotify() )');
    #$self->getLibrary()->show_exceptions("[" . $row->elementByName('adminNet')->ip() . ']'. ref($row->valueByName('adminNet')).' ( RouterSettings->updatedRowNotify() )');

    try {

    #my $sshPort = $row->valueByName('sshPort');
    #my $poundService = $self->getServicePortModel();

    #if (defined($oldRow) && $self->checkServicePort($oldRow) == 1) {
    #    $self->deleteServicePort($oldRow);
    #}
    my $libServ = $self->loadLibrary("LibraryService");
    $libServ->updateServicePort('pound'
        , $oldRow->valueByName("port")
        , $row->valueByName("port")
        , 1);
    $libServ->updateServicePort("dlllciastouer-admin"
        , $oldRow->valueByName("webadminPort")
        , $row->valueByName("webadminPort")
        , 1);
    $libServ->updateServicePort("dlllciastouer-admin"
        , $oldRow->valueByName("adminPort")
        , $row->valueByName("adminPort")
        , 1);

    #if ($self->checkServicePort($row) == 0)
    #{
    #    $self->addServicePort($row);
    #}

    #if ($self->checkFilter() == 0) 
    #{
    #        $self->addFilter();
    #}

    $self->setWebadminPort($row->valueByName("webadminPort"));

    #my $url  = $self->value('helpURL');
    #$url = '<a href="'.$url.'" target="_blank">'.$url.'</a>';
    #$self->setValue('helpLink', $url);
    #my $adminIp = $row->elementByName('adminNet')->ip();
    #my $adminNetmask = $row->elementByName('adminNet')->mask();

    } catch {
        $self->getLibrary()->show_exceptions($_ . '( RouterSettings->updatedRowNotify() )');
    };
}
sub setWebadminPort
{
    my ($self, $port) = @_;

    my $mod = EBox::Global->modInstance('webadmin');
    my $portMod = $mod->model('AdminPort');
    
    ##$portMod->set(
    #    'port' => $port
    #);
    #$portMod->store();
    $portMod->setValue('port', $port);

    #$self->getLibrary()->show_exceptions($portMod->value('port') . '( RouterSettings->updatedRowNotify() )'. $port);
    #$row->elementByName('port')->setValue($port);
    #$row->store();
}
# --------------------------



#sub getFilterModel
#{
#    my ($self) = @_;
#
#    my $network = EBox::Global->modInstance('firewall');
#    return $network->model('ExternalToEBoxRuleTable');
#}

# --------------------------

# 20150518 Pulipuli Chen
#sub getServiceParam
#{
#    my ($self) = @_;
#    return $self->loadLibrary("LibraryService")->getPoundService();
#}

#sub addService
#{
#    my ($self) = @_;
#    
#    my %param = $self->getServiceParam();
#
#    # 新增服務
#    my $serviceMod = $self->loadLibrary("LibraryService")->getServiceModel();
#
#    my $id = $serviceMod->findId(name=> $param{name});
#
#    if (defined($id) == 0) {
#        $serviceMod->addRow(%param);
#    }
#}

#sub getServiceRowId
#{
#    my ($self) = @_;
#    
#    return $self->loadLibrary("LibraryService")->getServiceId("pound");
#
#    #my %param = $self->getServiceParam();
#    #my $serviceMod = $self->loadLibrary("LibraryService")->getServiceModel();
#    #my $id = $serviceMod->findId('name'=>$param{name});
#    
#    #return $id;
#}
#
#sub getServiceRow
#{
#     my ($self) = @_;
     
    #if ($self->checkService() == 0) {
    #    $self->addService();
    #}

    #my $serviceMod = $self->loadLibrary("LibraryService")->getServiceModel();
    #my $id = $self->getServiceRowId();

    #if (defined($id) == 1) {
    #      return $serviceMod->row($id);
    #}
    #else {
    #   return undef;
    #}
#}

# ------------------

#sub getServicePortModel
#{
#    my ($self) = @_;
#    return $self->loadLibrary("LibraryService")->getConfig("pound");
    #
    #my $serviceRow = $self->loadLibrary("")getServiceRow();
    #if (defined($serviceRow) == 1) {
    #    return $serviceRow->subModel('configuration');
    #}
    #else {
    #    return undef;
    #}
#}

#sub checkServicePort
#{
#    my ($self, $row) = @_;
#
#    my $portMod = $self->getServicePortModel();
#    my $port = $row->valueByName("port");
#    my %param = $self->loadLibrary("LibraryService")->getServicePortParam(0, $port);
#
#    my $id = $portMod->findId('destination'=> $port );
#    
#    my $existed = 0;
#    if (defined($id) == 1)
#    {
#        $existed = 1;
#    }
#    return $existed;
#}

# 20150518 Pulipuli Chen
sub initServicePort
{
    my ($self) = @_;

    try
    {
    my $libServ = $self->loadLibrary("LibraryService");
    $libServ->addServicePort("pound", 80, 0);
    $libServ->addServicePort("pound", 88, 0); # lighttpd

    $libServ->addServicePort("dlllciastouer-admin", 64443, 1);
    $libServ->addServicePort("dlllciastouer-admin", 6, 1);
    } catch {
        $self->getLibrary()->show_exceptions($_ . '(RouterSettings->initServicePort())');
    }
    

    #my $portMod = $self->getServicePortModel();
    #my $port = 80;
    #if (defined($row)) {
    #    $port = $row->valueByName("port");
    #}
    #my %param = $self->loadLibrary("LibraryService")->getServicePortParam(0, $port);

    #my $id = $portMod->findId('destination'=>$port);
    #if (defined($id) == 0) {
    #    $portMod->addRow(%param);
    #}

    # 20150517 Pulipuli Chen 同時新增Lighttpd的Port
    #$port = 88;
    #%param = $self->loadLibrary("LibraryService")->getServicePortParam(0, $port);

    #$id = $portMod->findId('destination'=>$port);
    #if (defined($id) == 0) {
    #    $portMod->addRow(%param);
    #}

#    # 20150517 Pulipuli Chen 同時新增Lighttpd的Port
#    $port = 64443;
#    %param = $self->getServicePortParam($port);
#
#    $id = $portMod->findId('destination'=>$port);
#    if (defined($id) == 0) {
#        $portMod->addRow(%param);
#    }

#    $port = 64422;
#    %param = $self->getServicePortParam($port);
#
#    $id = $portMod->findId('destination'=>$port);
#    if (defined($id) == 0) {
#        $portMod->addRow(%param);
#    }
}

#sub deleteServicePort
#{
#    my ($self, $row) = @_;
#
#    #my $portMod = $self->getServicePortModel();
#    
#    my $name = "pound";
#    $self->loadLibrary("LibraryService")->deleteServicePort($name, $row->valueByName("port"));
#    #my %param = $self->loadLibrary("LibraryService")->getServicePortParam(0, $port);
#
#    #my $id = $portMod->findId('destination'=>$port);
#
#    #if (defined($id) == 1) {
#    #    $portMod->removeRow($id);
#    #}
#}

# ----------------------

#sub checkFilter
#{
#    my ($self) = @_;
#
#    my $filterMod = $self->getFilterModel();
#    my %param = $self->getFilterParam();
#
#    my $existed = 0;
#    my $id = $filterMod->findId(description => $param{description});
#    if (defined($id) == 1) {
#        $existed = 1;
#    }
#    return $existed;
#}

#sub addFilter
#{
#    my ($self) = @_;
#
#    my $filterMod = $self->getFilterModel();
#    my %param = $self->getFilterParam();
#
#    my $id = $filterMod->findId('description'=>$param{description});
#    if (defined($id) == 0) {
#        $filterMod->addRow(%param);
#    }
#}

#sub getFilterRow
#{
#    my ($self) = @_;    
#
#    my $filterMod = $self->getFilterModel();
#    my %param = $self->getFilterParam();
#
#    my $id = $filterMod->findId('description'=>$param{description});
#
#    if (defined($id) == 1) {
#        return $filterMod->row($id);
#    }
#    else {
#        return undef;
#    }
#}



1;
