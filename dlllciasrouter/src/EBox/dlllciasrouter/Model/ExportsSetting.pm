package EBox::dlllciasrouter::Model::ExportsSetting;

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

sub getOptions
{
    my ($self) = @_;

    my $options = ();
    $options->{tableName} = "ExportsSetting";
    $options->{printableName} = __("Exports");
    $options->{printableRowName} = __("Export");

    return $options;
}

sub _table
{
    my ($self) = @_;
    
    my $options = $self->getOptions();
    my $tableName = $options->{tableName};

    my $fieldsFactory = $self->loadLibrary('LibraryFields');
    my @fields = ();


    my $dataTable =
    {
        'tableName' => $tableName,
        'printableTableName' => $options->{printableName},
        'defaultActions' => [ 'add', 'del', 'editField', 'clone', 'changeView' ],
        'modelDomain' => 'dlllciasrouter',
        'tableDescription' => \@fields,
        'pageTitle' => $options->{printableName},
        'printableRowName' => $options->{printableRowName},
        'HTTPUrlView'=> 'dlllciasrouter/View/ExportsSetting',
        'order' => 1,
    };

    return $dataTable;
}

# -----------------------------------------

##
# 讀取PoundLibrary
# @author Pulipuli Chen
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("PoundLibrary");
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

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();
    try 
    {

    } catch {
        $lib->show_exceptions($_ . "(ExportsSetting->updateRowNotify())");
    };
    
    $ROW_NEED_UPDATE = 0;
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    my $lib = $self->getLibrary();
    try 
    {

    } catch {
        $lib->show_exceptions($_ . "(ExportsSetting->updateRowNotify())");
    };
}

sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    my $lib = $self->getLibrary();

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
        
        try 
        {
            
        } catch {
            $lib->show_exceptions($_ . "(ExportsSetting->updateRowNotify())");
        };
        $ROW_NEED_UPDATE = 0;
    }
}

1;
