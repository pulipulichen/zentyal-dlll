package EBox::dlllciasrouter::Model::URLRedirect;

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
use EBox::Types::HTML;
use EBox::Types::Date;
use EBox::Types::Boolean;
#use EBox::Types::Text;
use EBox::Types::URI;

use POSIX qw(strftime);
use Try::Tiny;

# Group: Public methods

#sub new
#{
#    my $class = shift;
#    my %parms = @_;
#
#    my $self = $class->SUPER::new(@_);
#    bless ($self, $class);
#
#    return $self;
#}

sub _table
{

    my ($self) = @_;
    my $fieldsFactory = $self->getLoadLibrary('LibraryFields');
    
    my @fields = (
        $fieldsFactory->createFieldConfigEnable(),
        $fieldsFactory->createFieldDomainNameUnique(),
        $fieldsFactory->createFieldBoundLocalDNS(),
        $fieldsFactory->createFieldURL('Redirect URL'),
        $fieldsFactory->createFieldDomainNameLink(),
        new EBox::Types::HTML(
            'fieldName' => 'urlLink',
            'printableName' => __('Redirect URL'),
            'editable' => 0,
            'optional' => 1,
            'hiddenOnSetter' => 1,
            'hiddenOnViewer' => 0,
            'HTMLSetter' => '/ajax/setter/textFullWidthSetter.mas',
            'help' => __('For example: http://www.dlll.nccu.edu.tw/'),
        ),
        $fieldsFactory->createFieldContactName(),
        $fieldsFactory->createFieldContactEmail(),
        $fieldsFactory->createFieldDisplayContactLink(),
        $fieldsFactory->createFieldDescription(),
        $fieldsFactory->createFieldDescriptionHTML(),
        $fieldsFactory->createFieldExpiryDate('NEVER'),
        
        $fieldsFactory->createFieldCreateDateDisplay(),
        $fieldsFactory->createFieldCreateDateData(),
        $fieldsFactory->createFieldDisplayLastUpdateDate(),
    );

    my $dataTable =
    {
        'tableName' => 'URLRedirect',
        'printableTableName' => __('URL Redirect'),
        'printableRowName' => __('URL Redirect'),
        'pageTitle' => __('URL Redirect'),
        'modelDomain' => 'dlllciasrouter',
        defaultController => '/dlllciasrouter/Controller/URLRedirect',
        'defaultActions' => ['add', 'del', 'editField', 'clone', 'changeView' ],
        'tableDescription' => \@fields,
        #'sortedBy' => 'domainName',
        class => 'dataTable',

        # 20140219 Pulipuli Chen
        # 關閉enable選項，改成自製的
        #'enableProperty' => 0,
        #defaultEnabledValue => 1,
        'order' => 1,
    };

    return $dataTable;
}

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

# --------------------------------------------------------

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();
    my $libDN = $self->getLoadLibrary('LibraryDomainName');
    my $libCT = $self->getLoadLibrary('LibraryContact');

    $libDN->updateDomainNameLink($row, 1);

    $libDN->setLink($row);

    $libCT->setCreateDate($row);
    $libCT->setUpdateDate($row);

    $libCT->setContactLink($row);
    $libCT->setDescriptionHTML($row);

    if ($self->getLoadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
        $libDN->addDomainName($row->valueByName('domainName'));
    }

    $row->store();
    $ROW_NEED_UPDATE = 0;
}
sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        my $lib = $self->getLibrary();
        my $libDN = $self->getLoadLibrary('LibraryDomainName');
        my $libCT = $self->getLoadLibrary('LibraryContact');

        $libDN->updateDomainNameLink($row, 1);

        $libDN->setLink($row);

        $libDN->deleteDomainName($oldRow->valueByName('domainName'), 'URLRedirect');

        $libDN->setLink($row);
        #$self->setLink($row);
        
        $libCT->setCreateDate($row);
        $libCT->setUpdateDate($row);
        $libCT->setContactLink($row);

        if ($self->getLoadLibrary('LibraryServers')->isDomainNameEnable($row) == 1) {
            $libDN->addDomainName($row->valueByName('domainName'));
        }

        $row->store();
        $ROW_NEED_UPDATE = 0;
    }
}

sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $libDN = $self->getLoadLibrary('LibraryDomainName');
    $libDN->deleteDomainName($row->valueByName('domainName'), 'URLRedirect');
}

1