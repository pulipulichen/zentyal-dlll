package EBox::dlllciasrouter::Model::PoundSettings;

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


sub getOptions
{
    my ($self) = @_;

    my $options = ();
    $options->{tableName} = "PoundSettings";
    $options->{printableName} = __("Pound Settings");
    
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

    my $pound_cfg = 'File content: /etc/pound/pound.cfg';
    push(@fields, $fieldsFactory->createFieldTitledHTMLDisplay($tableName . "_pound_cfg"
        , __('/etc/pound/pound.cfg')
        , $pound_cfg));

    my $dataTable = {
            'tableName' => $tableName,
            'pageTitle' => '',
            'printableTableName' => $options->{printableName},
            'modelDomain'     => 'dlllciasrouter',
            'defaultActions' => [ 'editField' ],
            'tableDescription' => \@fields,
            #'HTTPUrlView'=> 'dlllciasrouter/Composite/StorageServerComposite',
        };

    return $dataTable;
}

# -------------------------------------

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# -----------------------

1;
