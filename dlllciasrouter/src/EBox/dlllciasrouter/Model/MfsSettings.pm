package EBox::dlllciasrouter::Model::MfsSettings;

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
use EBox::Types::Text;

use EBox::Network;

use Try::Tiny;


sub getOptions
{
    my ($self) = @_;

    my $options = ();
    $options->{tableName} = "MfsSettings";
    $options->{printableName} = __("MooseFS (MFS) Settings");
    $options->{enableMooseFS} = 1;
    $options->{localhostSize} = "1GiB";
    $options->{chunkserverVMurl} = "https://app.box.com/s/cs3x2ocj90cacr3hzx66v832gvmqrfh1";

    return $options;
}

sub new
{
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless($self, $class);

    return $self;
}

sub _table
{
    my ($self) = @_;

    my $fieldsFactory = $self->loadLibrary('LibraryFields');
    my $options = $self->getOptions();
    my $tableName = $options->{tableName};

    my @fields = ();
    #push(@fields, $fieldsFactory->createFieldHrWithHeading('hr_ZentyalAdmi', __('Zentyal Admin Configuration')));

    my $address = $self->loadLibrary('LibraryNetwork')->getExternalIpaddr();
    my $cgiserv = "http://" . $address . ":9425/";
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_mfsInfo", __('MFS INFO'), $cgiserv, 1));

    $cgiserv = "https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/mfs-usage-instruction.md";
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_mfsUsageInstruction", __('MFS USAGE INSTRUCTION'), $cgiserv, 1));
    
    push(@fields, new EBox::Types::Boolean(
              fieldName     => 'mfsEnable',
              printableName => __('Enable MooseFS '),
              editable      => 1,
              unique        => 1,
              defaultValue => $options->{enableMooseFS},
              optional => 0,
             ));

    push(@fields, new EBox::Types::Text(
        'fieldName'     => 'localhostSize',
        'printableName' => __('Localhost Size '),
        'editable'      => 1,
        'unique'        => 1,
        'defaultValue' => $options->{localhostSize},
        'optional' => 0,
        'allowUnsafeChars' => 1,
    ));
    
    
    # Chunkserver OpenVZ Template
    my $downloadVM = '<a class="btn btn-icon btn-download" title="configure" target="_blank" href="' . $options->{chunkserverVMurl} . '">Download</a>';
    push(@fields, $fieldsFactory->createFieldTitledHTMLDisplay($options->{tableName} . "_download_chunkserver"
        , __('MooseFS Chunkserver & Metalogger OpenVZ Template')
        , $downloadVM));

    my $dataTable = {
            'tableName' => $options->{tableName},
            'pageTitle' => '',
            'printableTableName' => $options->{printableName},
            'modelDomain'     => 'dlllciasrouter',
            'defaultActions' => [ 'editField' ],
            'tableDescription' => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/Composite/StorageServerComposite',
        };

    return $dataTable;
}

# -------------------------------------

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}


# -----------------------

# 20150529 Pulipuli Chen
# 只有第一次執行會用到
sub initServicePort
{
    my ($self) = @_;

    try
    {

        my $libServ = $self->loadLibrary("LibraryService");

        # MooseFS
        $libServ->addServicePort("dlllciasrouter-admin", 9425, 1);

        $libServ->addServicePort("MFS", 9420, 0);
        $libServ->addServicePort("MFS", 9421, 0);

        #nfs
        $libServ->addServicePort("NFS", 111, 0);
        $libServ->addServicePort("NFS", 2049, 0);
        $libServ->addServicePort("NFS", 4000, 0);
        $libServ->addServicePort("NFS", 4001, 0);
        $libServ->addServicePort("NFS", 4002, 0);

    } catch {
        $self->getLibrary()->show_exceptions($_ . '(RouterSettings->initServicePort())');
    }
}

1;
