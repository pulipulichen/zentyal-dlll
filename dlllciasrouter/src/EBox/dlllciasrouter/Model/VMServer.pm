package EBox::dlllciasrouter::Model::VMServer;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;
use EBox::Global;

# ---------------------------------------------

sub getOptions
{
    my $options = ();
    #$options->{pageTitle} = __('Virtual Machine');
    $options->{pageTitle} = __('Virtual Machine');
    $options->{printableTableName} = __('Servers') . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-data-table-filter.js"></script>';
    # https://cloud-router.dlll.nccu.edu.tw:64443/data/dlllciasrouter/js/zentyal-data-table-filter.js
    $options->{printableRowName} = __('Server');
    $options->{tableName} = 'VMServer';
    $options->{IPHelp} = '
VMID: <span style="background-color: #ffCCEE;">2</span><span style="background-color: #00ff00;">43</span> 
= IP: 10.0.<span style="background-color: #ffCCEE;">2</span>.<span style="background-color: #00ff00;">43</span>
<br />
VMID: <span style="background-color: #00ffff;">1</span><span style="background-color: #ffCCEE;">0</span><span style="background-color: #00ff00;">01</span> 
= IP: 10.<span style="background-color: #00ffff;">1</span>.<span style="background-color: #ffCCEE;">0</span>.<span style="background-color: #00ff00;">1</span>
<br />
VMID:&nbsp;<span style="background-color: #00ffff;">3</span><span style="background-color: #ffCCEE;">1</span><span style="background-color: #00ff00;">24</span>&nbsp;
= IP: 10.<span style="background-color: #00ffff;">3</span>.<span style="background-color: #ffCCEE;">1</span>.<span style="background-color: #00ff00;">24</span>
<br />
<a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/guide/5-2-network-ip-range.md#virtual-machine" target="_blank">' . __('More details') . '</a>';
    $options->{poundScheme} = 'http';
    $options->{poundSecure} = 0;
    $options->{enableOtherFunction} = 1;
    #$options->{enableRedirectPorts} = 1;
    $options->{internalPortDefaultValue} = 80;
    $options->{expiryDate} = '';
    $options->{enableHTTP} = 1;
    $options->{enableHTTPS} = 1;
    $options->{enableSSH} = 1;
    $options->{enableRDP} = 0;
    $options->{enableHardware} = 0;
    $options->{enableVMID} = 1;
    $options->{enableKVM} = 0;
    $options->{enableMount} = 0;

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
        #|| !($partB > 0 && $partB < 6) 
        || !($partB > -1 && $partB < 6) 
        || !($partC > -1 && $partC < 10) 
        || !($partD > 0 && $partD < 100) ) {
        my $message = __('Internal IP ' . $ipaddr . '  format error.') . '<br />' . $options->{IPHelp};
        $self->loadLibrary('LibraryToolkit')->show_exceptions($message);
    }
}

# -------------------------------------------

sub _table
{
    my ($self) = @_;

    my $options = $self->getOptions();

    #$self->param('id');
    my $table = $self->loadLibrary("LibraryServers")->getDataTable($options);

    return $table;
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
    $self->loadLibrary("LibraryServers")->updateVMIDIPAddr($row);
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

    $self->loadLibrary("AttachedFiles")->deleteAllAttachedFiles($row);
}

# -------------------------------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    $self->loadLibrary("LibraryServers")->updateVMIDIPAddr($row);
    $self->checkInternalIP($row);

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        $self->loadLibrary("LibraryServers")->serverUpdatedRowNotify($row, $oldRow, $self->getOptions());
        $ROW_NEED_UPDATE = 0;
    }
}

1