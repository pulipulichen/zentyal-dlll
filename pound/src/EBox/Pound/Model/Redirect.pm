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

use POSIX qw(strftime);

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
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
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
            fieldName => 'contactName',
            printableName => __('Contact Name'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'contactEmail',
            printableName => __('Contact Email'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::HTML(
            fieldName => 'contactLink',
            printableName => __('Contact & Last Update Date'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 1,
            hiddenOnViewer => 0,
        ),
        new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::Text(
            fieldName => 'expiry',
            printableName => __('Expiry Date'),
            editable => 1,
            optional=>0,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
        ),
        new EBox::Types::HTML(
            fieldName => 'createDate',
            printableName => __('Create Date'),
            editable => 0,
            optional=>1,
                hiddenOnSetter => 0,
                hiddenOnViewer => 1,
        ),
        new EBox::Types::HTML(
            fieldName => 'updateDate',
            printableName => __('Last Update Date'),
            editable => 0,
            optional=>1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
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

my $ROW_NEED_UPDATE = 0;

sub addedRowNotify
{
    my ($self, $row) = @_;

    $ROW_NEED_UPDATE = 1;

    $self->setLink($row);

    $self->setCreateDate($row);
    $self->setUpdateDate($row);
    $self->setContactLink($row);
    $self->addDomainName($row);

    $row->store();
    $ROW_NEED_UPDATE = 0;
}
sub updatedRowNotify
{
    my ($self, $row, $oldRow) = @_;

    if ($ROW_NEED_UPDATE == 0) {
        $ROW_NEED_UPDATE = 1;

        $self->deletedDomainName($oldRow);

        $self->setLink($row);
        $self->setUpdateDate($row);
        $self->setContactLink($row);
        $self->addDomainName($row);

        $row->store();
        $ROW_NEED_UPDATE = 0;
    }
}

sub deletedRowNotify
{
    my ($self, $row) = @_;
    $self->deletedDomainName($row);
}

# ----------------------------------------

sub setLink
{
    my ($self, $row) = @_;

    my $domainName = $row->valueByName('domainName');
    my $url = $row->valueByName('url');

    my $domainNameLink = $self->domainNameToLink($domainName);
    my $urlLink = $self->urlToLink($url);

    $row->elementByName('domainNameLink')->setValue($domainNameLink);
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

sub domainNameToLink
{
    my ($self, $url) = @_;

    my $link = $url;
    if ( (substr($link, 0, 7) ne 'http://') &&  (substr($link, 0, 8) ne 'https://')) {
        $link = "http://" . $link . "/";
    }

    $url = $self->parentModule()->model("PoundServices")->breakUrl($url);

    $link = '<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="'.$link.'" target="_blank">'.$url.'</a>';

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

sub setUpdateDate
{
    my ($self, $row) = @_;

    my $date = strftime "%Y/%m/%d", localtime;

    $row->elementByName('updateDate')->setValue('<span>'.$date."</span>");
    #$row->store();
}

sub setCreateDate
{
    my ($self, $row) = @_;

    my $date = strftime "%Y/%m/%d", localtime;

    $row->elementByName('createDate')->setValue('<span>'.$date."</span>");
    #$row->store();
}

sub setContactLink
{
    my ($self, $row) = @_;

    my $name = $row->valueByName('contactName');
    my $email = $row->valueByName('contactEmail');
    my $expiry = $row->valueByName('expiry');

    my $link = '<a style="background: none;text-decoration: underline;color: #A3BD5B;"  href="mailto:'.$email.'">'.$name.'</a>';

    my $date = strftime "%Y/%m/%d", localtime;
    $link = $link."<br />[Update] ".$date;
    $link = $link."<br />[Expiry] ".$expiry;
    $link = "<span>".$link."</span>";

    $row->elementByName('contactLink')->setValue($link);
    #$row->store();
}

# -----------------------------

1