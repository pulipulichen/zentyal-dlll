package EBox::dlllciasrouter::Model::AttachedFiles;

use base 'EBox::Model::DataTable';

use EBox::Global;
use EBox::Gettext;
use EBox::Validate qw(:all);
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use strict;
use warnings;

use EBox::Gettext;

use EBox::Types::Port;
use EBox::Types::Text;
use EBox::Types::Boolean;
use EBox::Types::Int;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;
use EBox::Sudo;

use Try::Tiny;


sub new
{
    my $class = shift;
    my %parms = @_;

    my $self = $class->SUPER::new(@_);
    bless ($self, $class);

    return $self;
}

sub pageTitle
{
    my ($self) = @_;
    my $row = $self->parentRow();
    
    if (defined($row))
    {
        my $domainName = $row->printableValueByName('domainName');
        my $ip = $row->printableValueByName('ipaddr');
        return $domainName . " (" . $ip . ")";
    }
    else {
        return __("Attached Files");
    } 
}

sub _table
{

    my ($self) = @_;  
    
    my $libFactory = $self->parentModule()->model('LibraryFields');

    my @fields = (
        $libFactory->createFieldAddBtn('add'),
        
        # Description
        $libFactory->createFieldContactNameDisplayOnViewer(),

        $libFactory->createFieldDescription(),
        $libFactory->createFieldDescriptionHTML(),

        $libFactory->createFieldFile('file', __('File')),
        $libFactory->createFieldDisplayLastUpdateDate(),

        $libFactory->createFieldFileDescriptionDisplay(),
    );

    my $dataTable =
    {
        'tableName' => 'AttachedFiles',
        'printableTableName' => __('Attached File'),
        'printableRowName' => __('Attached File'),
        'pageTitle' => $self->pageTitle(),
        'modelDomain' => 'dlllciasrouter',
        'automaticRemove' => 1,
        'defaultController' => '/dlllciasrouter/Controller/AttachedFiles',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView'],
        'tableDescription' => \@fields,
        'sortedBy' => 'updateDate',
        'class' => 'dataTable',
    };

    # 變更權限...
    my $chmod = "chmod 777 /usr/share/zentyal/www/dlllciasrouter/files";
    EBox::Sudo::root($chmod);

    return $dataTable;
}

# --------------------------------

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

# --------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $subRow) = @_;

    $ROW_NEED_UPDATE = 1;

    #my $msg = $subRow->elementByName('file')->linkToDownload();
    #$self->getLibrary()->show_exceptions( '[' . $msg . ']; Please add domain name again. (AttachedFiles->addedRowNotify)');

    try {

    # 更新Description HTML + File Link
    my $libCT = $self->loadLibrary('LibraryContact');
    $libCT->setDescriptionHTML($subRow);

    #  更新ContactLink
    $self->setFileDescription($subRow);

    # 更新LastUpdated
    $libCT->setUpdateDate($subRow);

    $subRow->store();

    } catch {
        $self->getLibrary()->show_exceptions( $_ . '; Please add domain name again. (AttachedFiles->addedRowNotify)');
    };

    $ROW_NEED_UPDATE = 0;
}

sub updatedRowNotify
{
    my ($self, $subRow, $oldSubRow) = @_;

    try {

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;
    
        $self->addedRowNotify($subRow);
    }   # if ($ROW_NEED_UPDATE == 0) {

    } catch {
        $self->getLibrary()->show_exceptions($_ . '; Please add domain name again. (AttachedFiles->updatedRowNotify)');
    };
}

sub deletedRowNotify
{
    my ($self, $subRow) = @_;

    my $path = $subRow->elementByName('file')->path();
    if (unlink($path) == 0) {
        system('echo "" > ' . $path);
    }
    #$self->getLibrary()->show_exceptions(system('rm -f ' . $path) . 'rm -f ' . $path . '; Please add domain name again. (AttachedFiles->updatedRowNotify)');
}

# --------------------------------

sub setFileDescription
{
    my ($self, $subRow) = @_;

    my $fileDesc = '';

    my $desc = $subRow->valueByName('descriptionHTML');
    #my $file = $subRow->valueByName('file')->linkToDownload();
    my $file = $subRow->elementByName('file')->linkToDownload();

    if (defined($file) && $file ne '') {
        $file = '<a href="'.$file.'">' . $file . "</a>";
        $fileDesc = $file . "<br />";
    }
    $fileDesc = $fileDesc . $desc;

    $fileDesc = '<span>' . $fileDesc . "</span>";

    $subRow->elementByName('fileDescription')->setValue($fileDesc);
}

1;