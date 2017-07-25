package EBox::dlllciasrouter::Model::LibraryLogs;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use EBox::NetWrappers qw(:all);

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

##
# 讀取PoundLibrary
# @author Pulipuli Chen
# 20150514
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
}

# ------------------------------------------

# 20150518 Pulipuli Chen
sub enableLogs
{
    my ($self) = @_;

    my $configLogs = EBox::Global->modInstance('logs')->model('ConfigureLogs');
    for my $id (@{$configLogs->ids()}) {
        my $row = $configLogs->row($id);
        $row->elementByName("enabled")->setValue(1);
        #$self->getLibrary()->show_exceptions($row->valueByName('domain'));
        $row->store();
    }
    
    #my $modules = $logs->getLogsModules();
    #my $status = 1;
    #foreach my $module (@{ $modules }) {
    #        $module->enableLog($status);
    #}
}


1;
