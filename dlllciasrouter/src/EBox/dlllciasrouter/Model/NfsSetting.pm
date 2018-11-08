package EBox::dlllciasrouter::Model::NfsSetting;

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
    $options->{tableName} = "NfsSetting";
    $options->{printableName} = __("Zentyal NFS Setting");
    #$options->{enableMooseFS} = 1;
    #$options->{localhostSize} = "1GiB";
    #$options->{chunkserverVMurl} = "https://app.box.com/s/cs3x2ocj90cacr3hzx66v832gvmqrfh1";

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
    
    my $usageInstruction = "https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/nfs-usage-instruction.md";
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_nfsUsageInstruction", __('NFS USAGE INSTRUCTION'), $usageInstruction, 1));

    my $dataTable = {
            'tableName' => $options->{tableName},
            'pageTitle' => '',
            'printableTableName' => $options->{printableName},
            'modelDomain'     => 'dlllciasrouter',
            #'defaultActions' => [ 'editField' ],
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
