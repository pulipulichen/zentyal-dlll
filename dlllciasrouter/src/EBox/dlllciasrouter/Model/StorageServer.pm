package EBox::dlllciasrouter::Model::StorageServer;

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
    $options->{pageTitle} = __('Storage Server');
    $options->{printableTableName} = __('NAS Servers') . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-data-table-filter.js"></script>';
    $options->{printableRowName} = __('Server');
    $options->{tableName} = 'StorageServer';
    $options->{IPHelp} = __('The 1st part should be') . ' 10, <br />'
                . __('the 2nd part should be') . ' 6, <br />'
                . __('the 3rd part should be') . ' 1, and <br />'
                . __('the 4th part should be between') . ' 1~99. <br />'
                . __('Example:') . ' 10.6.1.4'
                . '<br /><a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/network-ip-range.md#storage-servers" target="_blank">' . __('More details') . '</a>';
    $options->{poundScheme} = 'http';
    $options->{poundSecure} = 1;
    $options->{enableOtherFunction} = 0;
    $options->{internalPortDefaultValue} = 80;
    $options->{expiryDate} = 'NEVER';
    $options->{enableHTTP} = 0;
    $options->{enableHTTPS} = 0;
    $options->{enableSSH} = 1;
    $options->{enableRDP} = 0;
    $options->{enableHardware} = 1;
    $options->{enableVMID} = 0;
    $options->{enableKVM} = 0;
    $options->{enableMount} = 1;
    $options->{defaultMountType} = 'nfs';

    return $options;
}

sub checkInternalIP
{
    my ($self, $row) = @_;

    my $options = $self->getOptions();

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
        my $message = __('Internal IP ' . $ipaddr  . ' format error.') .  '<br />' . $options->{IPHelp};
        $self->loadLibrary('LibraryToolkit')->show_exceptions($message);
    }
}

# -------------------------------------------

sub _table
{
    my ($self) = @_;

    my $options = $self->getOptions();

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
    $self->checkInternalIP($row);
    $ROW_NEED_UPDATE = 1;
    $self->loadLibrary("LibraryServers")->serverAddedRowNotify($row, $self->getOptions());
    $ROW_NEED_UPDATE = 0;
}

# -------------------------------------------

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->loadLibrary("LibraryServers")->serverDeletedRowNotify($row, $self->getOptions());
}

# -------------------------------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    $self->checkInternalIP($row);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        $self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow, $self->getOptions());
        $ROW_NEED_UPDATE = 0;
    }
}

1