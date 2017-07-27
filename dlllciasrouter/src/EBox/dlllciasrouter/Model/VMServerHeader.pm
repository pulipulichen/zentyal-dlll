package EBox::dlllciasrouter::Model::VMServerHeader;

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
<p><strong>VMID and IP address mapping:</strong></p>
<p>VMID: <span style="background-color: #00ffff;">1</span><span style="background-color: ##ffCCEE;">0</span><span style="background-color: #00ff00;">01</span> 
= IP: 10.<span style="background-color: #00ffff;">1</span>.<span style="background-color: ##ffCCEE;">0</span>.<span style="background-color: #00ff00;">1</span></p>
<p>VMID:&nbsp;<span style="background-color: #00ffff;">3</span><span style="background-color: ##ffCCEE;">1</span><span style="background-color: #00ff00;">24</span>&nbsp;
= IP: 10.<span style="background-color: #00ffff;">3</span>.<span style="background-color: ##ffCCEE;">1</span>.<span style="background-color: #00ff00;">24</span></p>
<p><a href="https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/network-ip-range.md#virtual-machine" target="_blank">' . __('More details') . '</a></p>
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
