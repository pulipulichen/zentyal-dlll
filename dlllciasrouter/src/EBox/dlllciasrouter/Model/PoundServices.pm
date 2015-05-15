package EBox::dlllciasrouter::Model::PoundServices;

use base 'EBox::Model::DataTable';
use strict;
use warnings;
use EBox::Gettext;

use EBox::Types::DomainName;
use EBox::Types::HostIP;
use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::HTML;
use EBox::Types::Boolean;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::Select;
use EBox::Types::HasMany;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use LWP::Simple;
use Try::Tiny;

sub _table
{
    my ($self) = @_;
    
    my $options = ();
    $options->{pageTitle} = __('Pound Back End');
    $options->{tableName} = 'PoundServices';
    $options->{IPHelp} = 'The 1st part should be 10, <br />'
                . 'the 2nd part should be 1~5, <br />'
                . 'the 3rd part should be 0~9, and <br />'
                . 'the 4th part should be between 1~99. <br />'
                . 'Example: 10.1.0.51';
    $options->{poundScheme} = 'http';
    $options->{internalPortDefaultValue } = 80;

    my $dataTable =
    {
        'tableName' => $self->getTableName(),
        'pageTitle' => $self->getPageTitle(),
        'printableTableName' => $self->getPageTitle(),
        'defaultActions' => [ 'add', 'del', 'editField', 'clone', 'changeView' ],
        'modelDomain' => 'dlllciasrouter',
        'tableDescription' => $self->loadLibrary("LibraryServers")->getFields($options),
        'printableRowName' => $self->getPageTitle(),
        'HTTPUrlView'=> 'dlllciasrouter/View/' . $self->getTableName(),
        'order' => 1,
    };

    return $dataTable;
}

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

# ---------------------------------------

##
# 設定新增時的動作
##
sub addedRowNotify
{
    my ($self, $row) = @_;

    $self->checkInternalIP($row);
    $self->loadLibrary("LibraryServers")->addedRowNotify($row);

}

# -------------------------------------------

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->loadLibrary("LibraryServers")->deletedRowNotify($row);
}

# -------------------------------------------

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    $self->checkInternalIP($row);
    $self->loadLibrary("LibraryServers")->updatedRowNotify($row, $oldRow);
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
        || !($partB > 0 && $partB < 5) 
        || !($partC > -1 && $partC < 10) 
        || !($partD > 0 && $partD < 100) ) {
        $self->loadLibrary("PoundLibrary")->show_exceptions('The 1st part should be 10, <br />'
                    . 'the 2nd part should be 1~5, <br />'
                    . 'the 3rd part should be 0~9, and <br />'
                    . 'the 4th part should be between 1~99. <br />'
                    . 'Example: 10.6.1.1');
    }
}

1;
