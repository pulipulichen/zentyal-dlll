package EBox::dlllciasrouter::Model::LibraryHeader;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

use Try::Tiny;

# -----------------------------

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

# ----------------------------

sub getDataTable
{
    my ($self, $options) = @_;

    my $lib = $self->getLibrary();
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();

    my $tableName = $options->{moduleName} . "Header";
    my $configView = '/dlllciasrouter/View/'.$options->{moduleName}.'Setting';

    push(@fields, $fieldsFactory->createFieldWebLinkButton($tableName));
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName, __('CONFIGURATION'), $configView, 0));

    my $pageTitle = __('Main Server');

    my $dataTable =
        {
            'tableName' => $tableName,
            'pageTitle' => $pageTitle,
            'printableTableName' => $pageTitle,
            'modelDomain'     => 'dlllciasrouter',
            #defaultActions => [ 'editField' ],
            'tableDescription' => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/View/' . $tableName,
        };

    return $dataTable;
}

1;
