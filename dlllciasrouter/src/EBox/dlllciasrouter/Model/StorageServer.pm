package EBox::dlllciasrouter::Model::StorageServer;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;
use EBox::Global;

sub _table
{
    my ($self) = @_;

    my $options = ();
    $options->{pageTitle} = __('Storage Servers');
    $options->{tableName} = 'StorageServer';
    $options->{IPHelp} = 'The 1st part should be 10, <br />'
                . 'the 2nd part should be 6, <br />'
                . 'the 3rd part should be 1, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.6.1.4';
    $options->{poundScheme} = 'https';
    $options->{internalPortDefaultValue} = 443;
    $options->{expiryDate} = 'NEVER';
    $options->{enableHTTP} = 0;
    $options->{enableHTTPS} = 0;
    $options->{enableSSH} = 0;
    $options->{enableRDP} = 0;
    $options->{enableHardware} = 1;

    return $self->loadLibrary("LibraryServers")->getDataTable($options);
}

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

# ---------------------------------------

my $ROW_NEED_UPDATE = 0;

##
# 設定新增時的動作
##
sub addedRowNotify
{
    my ($self, $row) = @_;
    $self->checkInternalIP($row);
    $ROW_NEED_UPDATE = 1;
    $self->loadLibrary("LibraryServers")->serverAddedRowNotify($row);
    $ROW_NEED_UPDATE = 0;
}

# -------------------------------------------

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->loadLibrary("LibraryServers")->serverDeletedRowNotify($row);
}

# -------------------------------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    $self->checkInternalIP($row);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        $self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow);
        $ROW_NEED_UPDATE = 0;
    }
}

sub checkInternalIP
{
    my ($self, $row) = @_;

    my $ipaddr = $row->valueByName('ipaddr');
    my @parts = split('\.', $ipaddr);
    my $partA = $parts[0];
    my $partB = $parts[1];
    my $partC = $parts[2];
    my $partD = $parts[3];

    if (!($partA == 10) 
        || !($partB == 6) 
        || !($partC == 1) 
        || !($partD > 0 && $partD < 100) ) {
        $self->getLibrary()->show_exceptions('The 1st part should be 10, <br />'
                    . 'the 2nd part should be 6, <br />'
                    . 'the 3rd part should be 1, and <br />'
                    . 'the 4th part should be between 1~99. <br />'
                    . 'Example: 10.6.1.1');
    }
}

1