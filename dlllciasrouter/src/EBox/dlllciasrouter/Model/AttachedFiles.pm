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
#use EBox::Types::Text;
use EBox::Types::Boolean;
use EBox::Types::Int;
use EBox::Types::Union;
use EBox::Types::Union::Text;
use EBox::Types::HTML;
use EBox::Sudo;

use Try::Tiny;

#use CGI;
#use Data::Dumper;

sub new
{
    my $class = shift;
    my %parms = @_;

    my $self = $class->SUPER::new(@_);
    bless ($self, $class);

    #my $query = CGI->new;
    #$self->{'directory'} = $query->param('directory');
    #$self->{'directory'} = $self->findRowByModel();
    #$self->{'backview'} = '/dlllciasrouter/Composite/VMServerComposite';
    
    #my $lib = $self->getLibrary();
    #my $row = $lib->getParentRow($self);

    return $self;
}

##
# 20170731 Pulipuli Chen
# @departed
##
#sub findRowByModel
#{
#    my ($self) = @_;
#
#    my $query = new CGI;
#    my $directory = $query->param('directory');
#    # VMServer/keys/vms5/attachedFiles
#    
#    my @parts = split('/', $directory);
#    my $modelName = $parts[0];
#    #my $id = $parts[2];
#
#    #my $lib = $self->getLibrary();
#    #my $mod = $lib->getLoadLibrary($modelName);
#
#    return $modelName;
#    #my $row = $mod->findId(id => $id);
#
#    #return $row;
#}

sub pageTitle
{
    my ($self) = @_;
    try {
        my $lib = $self->getLibrary();
        my $row = $lib->getParentRow($self);
        #my $backview = $lib->getBackview($self);

        my $domainName = $row->printableValueByName('domainName');
        my $ip = $row->printableValueByName('ipaddr');
        #return $domainName . " (" . $ip . ") : " . $backview . " | " . Dumper($self);
        return $domainName . " (" . $ip . ")";
    }
    catch {
        #return __('Attached Files: ' . $_);
        return __('Attached Files');
    }
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
        'tableName' => 'AttachedFiles',
        'pageTitle' => 'bbb' . $self->pageTitle(),
        'printableTableName' => __('Attached Files') . '<script type="text/javascript" src="/data/dlllciasrouter/js/zentyal-backview.js"></script>',
        'printableRowName' => __('Attached File'),
        'modelDomain' => 'dlllciasrouter',
        'automaticRemove' => 1,
        'defaultController' => '/dlllciasrouter/Controller/AttachedFiles',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView'],
        'tableDescription' => \@fields,
        'sortedBy' => 'updateDate',
        'class' => 'dataTable',
        #'backview' => '/dlllciasrouter/Composite/VMServerComposite',
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
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub getLoadLibrary
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
        my $libCT = $self->getLoadLibrary('LibraryContact');
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

# ------------------------------------------

##
# 20170801 Pulipuli Chen
# 移除檔案
##
sub deleteAllAttachedFiles
{
    my ($self, $row) = @_;

    my $subMod = $row->subModel('attachedFiles');

    for my $subId (@{$subMod->ids()}) {
        $subMod->removeRow($subId);
    }
}
 
1;