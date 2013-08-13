package EBox::Pound::Model::Redirect;

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

    my @fields = (
        new EBox::Types::DomainName(
            'fieldName' => 'domainName',
            'printableName' => __('Domain Name'),
            'unique' => 1,
            'editable' => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            'fieldName' => 'url',
            'printableName' => __('Redirect URL'),
            'editable' => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::HTML(
            fieldName => 'domainNameLink',
            printableName => __('Domain Name'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 1,
                hiddenOnViewer => 0,
        ),
        new EBox::Types::Boolean(
            fieldName => 'boundLocalDns',
            printableName => __('Bound Local DNS'),
            editable => 1,
            optional => 0,
            defaultValue => 1,
            help => __('If you want to bound this service with local DNS, this domain name will be created when service creates. The other hand, this doamin name will be removed when service deletes.'),
        ),
        new EBox::Types::HTML(
            fieldName => 'urlLink',
            printableName => __('Redirect URL'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 1,
                hiddenOnViewer => 0,
        ),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
            optional=>1,
        ),
        new EBox::Types::Date(
            fieldName => 'updateDate',
            printableName => __('Update Date'),
            editable => 0,
            optional=>1,
        ),
    );

    my $dataTable =
    {
        'tableName' => 'Redirect',
        'printableTableName' => __('URL Redirect'),
        'printableRowName' => __('URL Redirect'),
        'modelDomain' => 'Pound',
        defaultController => '/Pound/Controller/Redirect',
        'defaultActions' => ['add', 'del', 'editField', 'changeView' ],
        'tableDescription' => \@fields,
        'sortedBy' => 'domainName',
        class => 'dataTable',
        'enableProperty' => 1,
        defaultEnabledValue => 1,
    };

    return $dataTable;
}

sub addedRowNotify
{
    my ($self, $row) = @_;
    $self->setLink($row);

    $self->addDomainName($row);
}
sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;
    $self->setLink($row);

    $self->deletedDomainName($oldRow);
    $self->addDomainName($row);
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->deletedDomainName($row);
}

sub setLink
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName('domainName');
    my $url = $row->valueByName('url');

    my $domainNameLink = $self->urlToLink($domainName);
    my $urlLink = $self->urlToLink($url);

    $row->elementByName('domainNameLink')->setValue($domainNameLink);
    $row->elementByName('urlLink')->setValue($urlLink);

    $row->store();
}

sub urlToLink
{
    my ($self, $url) = @_;

    my $link = $url;
    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
        $link = "http://" . $link . "/";
    }

    $link = '<a href="'.$link.'" target="_blank">'.$url.'</a>';

    return $link;
}
# ---------------------------------------

sub addDomainName
{
    my ($self, $row) = @_;

    if ($row->valueByName('boundLocalDns')) {
        my $domainName = $row->valueByName('domainName');
        my $gl = EBox::Global->getInstance();
        my $dns = $gl->modInstance('dns');
        my $domModel = $dns->model('DomainTable');
        my $id = $domModel->findId(domain => $domainName);
        if (defined($id) == 0) 
        {
            $dns->addDomain({
                domain_name => $domainName,
            });
        }
    }
}

sub deletedDomainName
{
    my ($self, $row) = @_;
    my $domainName = $row->valueByName('domainName');

    my $gl = EBox::Global->getInstance();
    my $dns = $gl->modInstance('dns');
    my $domModel = $dns->model('DomainTable');
    my $id = $domModel->findId(domain => $domainName);
    if (defined($id)) 
    {
        $domModel->removeRow($id);
    }
}

# -----------------------------

1;