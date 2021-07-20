package EBox::dlllciasrouter::Model::NameServer;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;
use EBox::Global;

# ---------------------------------------------

sub getOptions
{
    my $options = ();
    #$options->{pageTitle} = __('Storage Servers');
    $options->{pageTitle} = __('Name Server');
    $options->{printableTableName} = __('Name Servers') . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-data-table-filter.js"></script>';
    $options->{printableRowName} = __('Server');
    $options->{tableName} = 'NameServer';
    
    return $options;
}

# -------------------------------------------

sub _table
{
    my ($self) = @_;

    my $options = $self->getOptions();

    # @TODO

    return $self->loadLibrary("LibraryServers")->getDataTable($options);
}

##
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

##
# 設定新增時的動作
##
sub addedRowNotify
{
    my ($self, $row) = @_;
    
    # @TODO
}

# -------------------------------------------

sub deletedRowNotify
{
    my ($self, $row) = @_;
    
    # @TODO
}

# -------------------------------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    
    # @TODO
}

1