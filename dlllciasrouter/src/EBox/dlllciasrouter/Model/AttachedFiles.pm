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

#use CGI;


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
    
    #if (defined($row))
    #{
        #my $domainName = $row->printableValueByName('domainName');
        #my $ip = $row->printableValueByName('ipaddr');
        #return $domainName . " (" . $ip . ")";
#        return $row->id() . __("Attached Files");
#    }
#    else {
        return __("Attached Files");
#    } 
}

sub _table
{

    my ($self) = @_;  
    
    my $libFactory = $self->parentModule()->model('LibraryFields');

    my @fields = (
        #$libFactory->createFieldAddBtn('add'),
        
        # Description
        $libFactory->createFieldFileDescriptionDisplay(),

        $libFactory->createFieldFile('file', __('File')),
        $libFactory->createFieldDescription(),
        $libFactory->createFieldDescriptionHTML(),

        $libFactory->createFieldContactNameDisplayOnViewer(),
        $libFactory->createFieldDisplayLastUpdateDate(0),

        
    );
    
    my $dataTable =
    {
        'tableName' => 'attachedFiles',
        'printableTableName' => __('Attached File') .  '+' . $self->{parent}. '+' . $self->{backview}. '-'  . $self->{directory},
        'printableRowName' => __('Attached File') . $self->{backView},
        'pageTitle' => $self->pageTitle(),
        'modelDomain' => 'dlllciasrouter',
        'automaticRemove' => 1,
        'defaultController' => '/dlllciasrouter/Controller/AttachedFiles',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView'],
        'tableDescription' => \@fields,
        'sortedBy' => 'updateDate',
        'class' => 'dataTable',
        #'confmodule' => $self->loadLibrary('RouterSettings'),
        #'directory' => 'RouterSettings/keys/rs1/attachedFiles',
    };

    #$self->{parent} = $self->loadLibrary('RouterSettings');
    #$self->{confmodule} = $self->loadLibrary('RouterSettings');
    #$self->{directory} = 'RouterSettings/keys/rs1/attachedFiles';

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

    #my $msg = $subRow->elementByName('file')->userPath();
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

    my $file = $subRow->elementByName('file');
    if ($file->toRemove() == 0) {
        my $path = $file->path();
        unlink($path);

        my $pos = rindex($path, "/");
        my $dir = substr($path, 0, $pos);
        rmdir($dir);
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
    $subRow->store();
    my $file = $subRow->elementByName('file');
    #my $chmod = "chmod 777 /usr/share/zentyal/www/dlllciasrouter/files";
    #EBox::Sudo::root($chmod);

    if (defined($file->exist())) {
        my $link = $file->linkToDownload();
        #my $filename = "DOWNLOAD";
        my $path = $file->path();
        my $pos = rindex($path, "/") + 1;
        my $filename = substr($path, $pos);
        $file = '<a href="'.$link.'" class="btn btn-icon btn-download" style="text-transform: none;">'.$filename.'</a>';
        $fileDesc = $file . "<br />";
    }
    $fileDesc = $fileDesc . $desc;

    $fileDesc = '<span>' . $fileDesc . "</span>";

    $subRow->elementByName('fileDescription')->setValue($fileDesc);
}

1;