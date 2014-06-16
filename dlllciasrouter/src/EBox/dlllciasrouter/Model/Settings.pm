package EBox::dlllciasrouter::Model::Settings;

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

#    my $network = EBox::Global->modInstance('network');
#    my $address = "127.0.0.1";
#    my $external_iface = "eth0";
#    foreach my $if (@{$network->ExternalIfaces()}) {
#        if ($network->ifaceIsExternal($if)) {
#            $external_iface = $if;
#            $address = $network->ifaceAddress($if);
#            last;
#        }
#    }

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my $libNet = $self->loadLibrary('LibraryNetwork');
    my $external_iface = $libNet->getExternalIface();
    my $address = $libNet->getExternalIpaddr();

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
             ),
          new EBox::Types::Text(
              fieldName     => 'alive',
              printableName => __('Alive Time'),
              editable      => 1,
              unique        => 0,
              default => 30,
              help => __("Check backend every X secs"),
             ),
#          new EBox::Types::Text(
#                fieldName => 'helpURL',
#                printableName => __('Set Help Link'),
#                editable => 1,
#                defaultValue=> "https://github.com/pulipulichen/zentyal-dlll/wiki/domain-name-help",
#                optional => 0,
#            ),
#        new EBox::Types::HTML(
#            fieldName => 'helpLink',
#            printableName => __('Help Link'),
#            editable => 0,
#            defaultValue => '<a href="https://github.com/pulipulichen/zentyal-dlll/wiki/domain-name-help" target="_blank">https://github.com/pulipulichen/zentyal-dlll/wiki/domain-name-help</a>',
#        ),
        new EBox::Types::Boolean(
              fieldName     => 'enableError',
              printableName => __('Enable Custom Error Message'),
              defaultValue => 0,
              editable      => 1,
              optional => 0,
             ),
        new EBox::Types::Text(
              fieldName     => 'error',
              printableName => __('Error Page Link'),
              editable      => 1,
              optional => 1,
              help => __('HTML format. Don\'t use HTTPS. Example: ').'<a href="http://dl.dropboxusercontent.com/u/717137/20130914-error_page/error_example.html" target="error_example">http://dl.dropboxusercontent.com/u/717137/20130914-error_page/error_example.html</a>',
             ),

# ------------------------------
        new EBox::Types::HostIP(
            fieldName => 'restarterIP',
            printableName => __('Restarter IP'),
            editable => 1,
            optional => 0,
            # 20140616 Pulipuli Chen
            # 沒有辦法順利運作，此欄位暫時不使用
            hiddenOnSetter => 1,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Port(
            fieldName => 'restarterPort',
            printableName => __('Restarter Port'),
            editable => 1,
            defaultValue => 80,
            optional => 0,
            # 20140616 Pulipuli Chen
            # 沒有辦法順利運作，此欄位暫時不使用
            hiddenOnSetter => 1,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'notifyEmail',
            printableName => __('Notify E-MAIL Address'),
            editable => 1,
            optional => 0,
            # 20140616 Pulipuli Chen
            # 沒有辦法順利運作，此欄位暫時不使用
            hiddenOnSetter => 1,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'senderEmail',
            printableName => __('Sender E-MAIL Address'),
            help => __('<hr /><br />'
                . '<strong>Zentyal Configuration Link</strong>'),
            editable => 1,
            optional => 0,
            # 20140616 Pulipuli Chen
            # 沒有辦法順利運作，此欄位暫時不使用
            hiddenOnSetter => 1,
            hiddenOnViewer => 1,
        ),
        
        # --------------------------------
        # External Link
        
        $fieldsFactory->createFieldLink(
            'portForwarding',
            'Port Forwarding',
            "/Firewall/View/RedirectsTable",
            'LINK'
        ),

        $fieldsFactory->createFieldLink(
            'firewallLog',
            'Firewall Log',
            "/Logs/Index?selected=firewall&refresh=1",
            'LINK'
        ),
        
        $fieldsFactory->createFieldLink(
            'managementMember',
            'Administrator',
            "/Objects/View/MemberTable?directory=ObjectTable/keys/objc6/members&backview=/Objects/View/MemberTable",
            'LINK'
        ),

        $fieldsFactory->createFieldLink(
            'denyAnyConnectMember',
            'Deny Any Connect Member',
            "/Objects/View/MemberTable?directory=ObjectTable/keys/objc5/members&backview=/Objects/View/MemberTable",
            'LINK'
        ),

        $fieldsFactory->createFieldLink(
            'denyUDPMember',
            'Deny UDP Member',
            "/Objects/View/MemberTable?directory=ObjectTable/keys/objc4/members&backview=/Objects/View/MemberTable",
            'LINK'
        ),
      );

    my $dataTable =
        {
            tableName => 'Settings',
            'pageTitle' => __('Settings'),
            printableTableName => __('Settings'),
            modelDomain     => 'dlllciasrouter',
            defaultActions => [ 'editField',  'changeView' ],
            tableDescription => \@tableDesc,
            'HTTPUrlView'=> 'dlllciasrouter/Composite/Global',
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

    my $poundService = $self->getServicePortModel();
    if ($self->checkServicePort($oldRow) == 1)
    {
        $self->deleteServicePort($oldRow);
    }
    if ($self->checkServicePort($row) == 0)
    {
        $self->addServicePort($row);
    }

    if ($self->checkFilter() == 0) 
    {
        $self->addFilter();
    }

    #my $url  = $self->value('helpURL');
    #$url = '<a href="'.$url.'" target="_blank">'.$url.'</a>';
    #$self->setValue('helpLink', $url);
}

# --------------------------

sub getServiceModel
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('services');
    return $network->model('ServiceTable');
}

sub getFilterModel
{
    my ($self) = @_;

    my $network = EBox::Global->modInstance('firewall');
    return $network->model('ExternalToEBoxRuleTable');
}

# --------------------------

sub getServiceParam
{
    my ($self) = @_;

    return (
        # 寫入參數
        'internal' => 'pound',
        'name' => 'pound',
        'printableName' => 'pound',
        'description' => 'For Reverse Proxy use.',
    );
}

sub checkService
{
    my ($self) = @_;

    # 確認服務是否存在
    my %param = $self->getServiceParam();

    my $serviceMod = $self->getServiceModel();

    # 確認
    my $id = $serviceMod->findId('name' => $param{name});

    my $existed = 0;
    if (defined($id) == 1)
    {
        $existed = 1;
    }
    return $existed;
}

sub addService
{
    my ($self) = @_;
    
    my %param = $self->getServiceParam();

    # 新增服務
    my $serviceMod = $self->getServiceModel();

    my $id = $serviceMod->findId(name=> $param{name});

    if (defined($id) == 0) {
        $serviceMod->addRow(%param);
    }
}

sub getServiceRowId
{
     my ($self) = @_;
    
    my %param = $self->getServiceParam();
    my $serviceMod = $self->getServiceModel();
    my $id = $serviceMod->findId('name'=>$param{name});
    
    return $id;
}

sub getServiceRow
{
     my ($self) = @_;
     
    if ($self->checkService() == 0) {
        $self->addService();
    }

     my $serviceMod = $self->getServiceModel();
     my $id = $self->getServiceRowId();

     if (defined($id) == 1) {
        return $serviceMod->row($id);
     }
     else {
        return undef;
     }
}

# ------------------

sub getServicePortModel
{
    my ($self) = @_;
    
    my $serviceRow = $self->getServiceRow();
    if (defined($serviceRow) == 1) {
        return $serviceRow->subModel('configuration');
    }
    else {
        return undef;
    }
}

sub getServicePortParam
{
    my ($self, $port) = @_;

    # 不確定，有可能錯誤
    return (
        # 設定連接埠參數
        'protocol' => 'tcp/udp',
        'source_range_type' => 'any',
        'destination_range_type' => 'single',
        'destination_single_port' => $port,
    );
}


sub checkServicePort
{
    my ($self, $row) = @_;

    my $portMod = $self->getServicePortModel();
    my $port = $row->valueByName("port");
    my %param = $self->getServicePortParam($port);

    my $id = $portMod->findId('destination'=> $port );
    
    my $existed = 0;
    if (defined($id) == 1)
    {
        $existed = 1;
    }
    return $existed;
}

sub addServicePort
{
    my ($self, $row) = @_;

    my $portMod = $self->getServicePortModel();
    my $port = $row->valueByName("port");
    my %param = $self->getServicePortParam($port);

    my $id = $portMod->findId('destination'=>$port);
    if (defined($id) == 0) {
        $portMod->addRow(%param);
    }
}

sub deleteServicePort
{
    my ($self, $row) = @_;

    my $portMod = $self->getServicePortModel();
    my $port = $row->valueByName("port");
    my %param = $self->getServicePortParam($port);

    my $id = $portMod->findId('destination'=>$port);

    if (defined($id) == 1) {
        $portMod->removeRow($id);
    }
}

# ----------------------

sub checkFilter
{
    my ($self) = @_;

    my $filterMod = $self->getFilterModel();
    my %param = $self->getFilterParam();

    my $existed = 0;
    my $id = $filterMod->findId(description => $param{description});
    if (defined($id) == 1) {
        $existed = 1;
    }
    return $existed;
}

sub addFilter
{
    my ($self) = @_;

    my $filterMod = $self->getFilterModel();
    my %param = $self->getFilterParam();

    my $id = $filterMod->findId('description'=>$param{description});
    if (defined($id) == 0) {
        $filterMod->addRow(%param);
    }
}

sub getFilterRow
{
    my ($self) = @_;    

    my $filterMod = $self->getFilterModel();
    my %param = $self->getFilterParam();

    my $id = $filterMod->findId('description'=>$param{description});

    if (defined($id) == 1) {
        return $filterMod->row($id);
    }
    else {
        return undef;
    }
}

sub getFilterParam
{
    my ($self) = @_;

    return (
        # 設定連接埠參數
        'decision' => 'accept',
        'source_selected' => 'source_any',
        'service' => $self->getServiceRowId(),
        'description' => 'For Reverse Proxy use.',
    );
}

1;
