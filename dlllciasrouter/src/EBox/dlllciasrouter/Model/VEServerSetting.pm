package EBox::dlllciasrouter::Model::VEServerSetting;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Network;

use Try::Tiny;

# Group: Public methods

sub new
{
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless($self, $class);

    return $self;
}

# Group: Protected methods
sub _table
{
    my ($self) = @_;

    my $options = $self->getOptions();

    return $self->loadLibrary('LibrarySetting')->getDataTable($options);
}

sub getOptions
{
    my $options = ();
    $options->{pageTitle} = __('VE Main Server Setting');
    $options->{moduleName} = 'VEServer';
    $options->{IPHelp} = __('The 1st part should be') . ' 10, <br />'
                . __('the 2nd part should be') . ' 6, <br />'
                . __('the 3rd part should be') . ' 0, and <br />'
                . __('the 4th part should be between') . ' 1~99. <br />'
                . __('Example:') . ' 10.6.0.55'
                . '<br /><a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/network-ip-range.md#virtual-environment-server-proxmox" target="_blank">' . __('More details') . '</a>';
    $options->{poundScheme} = 'https';
    $options->{poundSecure} = 1;
    $options->{internalPortDefaultValue} = 8006;
    $options->{externalPortDefaultValue} = 60000;
    $options->{enableSSH} = 1;
    $options->{externalSSHPortDefaultValue} = 60002;

    return $options;
}

# -------------------------------------------------------------

##
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}


# -----------------------

my $ROW_NEED_UPDATE = 0;

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    
    my $options = $self->getOptions();

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        
        $self->loadLibrary('LibrarySetting')->updatedRowNotify($self, $row, $oldRow, $options);

        $ROW_NEED_UPDATE = 0;
    }
}

1;
