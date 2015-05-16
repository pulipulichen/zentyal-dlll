package EBox::dlllciasrouter::Model::StorageServerHeader;

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

use Try::Tiny;

# Group: Public methods

# Constructor: new
#
#      Create a new Text model instance
#
# Returns:
#
#      <EBox::DNS::Model::StorageServerHeader> - the newly created model
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

    my $options = $self->getOptions();

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();

    push(@fields, $fieldsFactory->createFieldWebLinkButton($options->{tableName}));
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($options->{tableName}, 'CONFIGURATION', $options->{configView}));

    my $dataTable =
        {
            'tableName' => $options->{tableName},
            'pageTitle' => $options->{pageTitle},
            'printableTableName' => $options->{pageTitle},
            'modelDomain'     => 'dlllciasrouter',
            #defaultActions => [ 'editField' ],
            'tableDescription' => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/View/' . $options->{tableName},
        };

    return $dataTable;
}

sub getOptions
{
    my $options = ();
    $options->{pageTitle} = __('Setting');
    $options->{tableName} = 'StorageServerHeader';
    $options->{configView} = '/dlllciasrouter/View/StorageServerSetting';
    return $options;
}

# -------------------------------------------------------------

sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
}

##
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

1;
