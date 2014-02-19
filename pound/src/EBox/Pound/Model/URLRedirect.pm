package EBox::Pound::Model::URLRedirect;

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
use EBox::Types::Text;

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
    my $fieldsFactory = $self->getLibrary();
    
    my @fields = (
        $fieldsFactory->createFieldConfigEnable(),
        $fieldsFactory->createFieldDomainNameUnique(),
        new EBox::Types::Text(
            'fieldName' => 'url',
            'printableName' => __('Redirect URL'),
            'editable' => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        $fieldsFactory->createFieldDomainNameLink(),
        $fieldsFactory->createFieldBoundLocalDNS(),
        new EBox::Types::HTML(
            fieldName => 'urlLink',
            printableName => __('Redirect URL'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 1,
                hiddenOnViewer => 0,
        ),
        $fieldsFactory->createFieldContactName(),
        $fieldsFactory->createFieldContactEmail(),
        $fieldsFactory->createFieldDisplayContactLink(),
        $fieldsFactory->createFieldDescription(),
        $fieldsFactory->createFieldExpiryDate(),
        
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
        'modelDomain' => 'Pound',
        defaultController => '/Pound/Controller/URLRedirect',
        'defaultActions' => ['add', 'del', 'editField', 'changeView' ],
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
    return $self->parentModule()->model("PoundLibrary");
}

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    my $lib = $self->getLibrary();

    $lib->setLink($row);

    $lib->setCreateDate($row);
    $lib->setUpdateDate($row);
    $lib->setContactLink($row);
    $lib->addDomainName($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;
}
sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        my $lib = $self->getLibrary();

        $lib->setLink($row);

        $lib->deleteDomainName($oldRow, 'URLRedirect');

        $lib->setLink($row);
        $self->setLink($row);
        
        $lib->setCreateDate($row);
        $lib->setUpdateDate($row);
        $lib->setContactLink($row);
        $lib->addDomainName($row);

        $row->store();
        $ROW_NEED_UPDATE = 0;
    }
}

sub deletedRowNotify
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();
    $lib->deleteDomainName($row, 'URLRedirect');
}

sub setLink
{
    my ($self, $row) = @_;

    my $lib = $self->getLibrary();

    my $domainName = $row->valueByName('domainName');
    my $url = $row->valueByName('url');
    my $enable = $lib->isEnable($row);

    my $urlLink = $self->urlToLink($url);

    $row->elementByName('urlLink')->setValue($urlLink);

    #$row->store();
}


sub urlToLink
{
    my ($self, $url) = @_;

    my $link = $url;
    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
        $link = "http://" . $link . "/";
    }

    if (length($url) > 20) 
    {
        $url = substr($url, 0, 20) . "...";
    }

    $link = '<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$url.'</a>';

    return $link;
}

1