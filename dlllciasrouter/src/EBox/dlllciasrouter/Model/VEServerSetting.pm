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
    $options->{IPHelp} = 'The 1st part should be 10, <br />'
                . 'the 2nd part should be 6, <br />'
                . 'the 3rd part should be 0, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.6.0.55';
    $options->{poundScheme} = 'https';
    $options->{internalPortDefaultValue} = 8006;
    $options->{externalPortDefaultValue} = 60000;
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
        
        $self->loadLibrary('LibrarySetting')->updatedRowNotify($row, $oldRow, $options);

        $ROW_NEED_UPDATE = 0;
    }
}

1;
