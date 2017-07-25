package EBox::dlllciasrouter::Model::StorageServerHeader;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use Try::Tiny;



sub getOptions
{
    my $options = ();
    $options->{moduleName} = 'StorageServer';
    return $options;
}

# ------------------------------------------

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

    my $options = $self->getOptions();

    return $self->loadLibrary('LibraryHeader')->getDataTable($options);
}

# -------------------------------------------------------------

##
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

1;
