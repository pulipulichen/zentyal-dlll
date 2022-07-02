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
use File::Slurp;
#use HTML::Entities;

#use Data::Dumper;

sub getOptions
{
    my ($self) = @_;

    my $options = ();
    $options->{tableName} = "PoundSettings";
    $options->{printableName} = __("Pound Settings");
    $options->{pageTitle} = __("Pound Settings");
    
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

    #my $pound_cfg = 'File content: /etc/pound/pound.cfg';
    #my $file = '/etc/pound/pound.cfg';
    #my $pound_cfg = '<pre>' . read_file( $file ) . '</pre>';
    my $pound_cfg_title = __('/etc/pound/pound.cfg (Save changes to check modefied pound.cfg) ');
    my $pound_cfg_fieldName = $tableName . "_pound_cfg";

    #push(@fields, $fieldsFactory->createFieldTitledHTMLDisplay($pound_cfg_fieldName
    #    , $pound_cfg_title
    #    , $pound_cfg));

    push(@fields, new EBox::Types::HTML(
        'fieldName' => $pound_cfg_fieldName,
        'printableName' => $pound_cfg_title,
        'editable' => 0,
        'optional' => 0,
        'defaultValue' => '<span></span>',
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 0,
    ));

    my $dataTable = {
        'tableName' => $tableName,
        'pageTitle' => $options->{pageTitle},
        'printableTableName' => $options->{printableName} . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-backview.js"></script>',
        'modelDomain' => 'dlllciasrouter',
        'defaultActions' => [ ],
        'tableDescription' => \@fields,
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

##
# 20170731 Pulipuli Chen
# 重新從檔案讀取
##
sub setUpdateCfg
{
    my ($self) = @_;

    my $options = $self->getOptions();
    my $tableName = $options->{tableName};
    my $pound_cfg_fieldName = $tableName . "_pound_cfg";
    
    my $file = '/etc/pound/pound.cfg';
    my $pound_cfg = read_file( $file );
    my $libEnc = $self->loadLibrary("LibraryEncoding");
    my $pound_cfg_contents = $libEnc->encodeEntities($pound_cfg);

    $pound_cfg = '<pre>' . $pound_cfg_contents . '</pre>';
    $self->setValue($pound_cfg_fieldName, $pound_cfg);
}

# -----------------------

1;
