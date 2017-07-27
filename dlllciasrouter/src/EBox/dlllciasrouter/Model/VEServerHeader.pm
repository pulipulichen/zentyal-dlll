package EBox::dlllciasrouter::Model::VEServerHeader;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use Try::Tiny;

sub getOptions
{
    my $options = ();
    $options->{moduleName} = 'VEServer';
    $options->{help} = '<div class="tip">
<p>IP: 10.<span style="background-color: #00ffff;">6</span>.<span style="background-color: ##ffCCEE;">0</span>.<span style="background-color: #00ff00;">12</span></p>
<p><a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/network-ip-range.md#virtual-environment-server-proxmox" target="_blank">' . __('More details') . '</a></p>
</div>';
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
