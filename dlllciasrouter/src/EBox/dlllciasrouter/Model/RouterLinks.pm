package EBox::dlllciasrouter::Model::RouterLinks;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use Try::Tiny;



sub getOptions
{
    my $options = ();
    $options->{moduleName} = 'RouterLinks';
    return $options;
}

# ------------------------------------------

sub new
{
    my ($class, %params) = @_;

    my $self = $class->SUPER::new(%params);
    bless($self, $class);

    return $self;
}

sub _table
{
    my ($self) = @_;

    my $options = $self->getOptions();

    my $lib = $self->parentModule()->model('PoundLibrary');
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();

    my $tableName = $options->{moduleName} . "Header";
    my $configView = '/dlllciasrouter/View/'.$options->{moduleName}.'Setting';

    my @links = (
        {
            'text' => __('Module Status'),
            'uri' => '/ServiceModule/StatusView',
            'icon' => 'icon-mstatus',
        }, 
        {
            'text' => __('Network Interface'),
            'uri' => '/Network/Ifaces',
            'icon' => 'icon-network',
        }, 
        {
            'text' => __('Port Forwarding'),
            'uri' => '/Firewall/View/RedirectsTable',
            'icon' => 'icon-firewall',
        }, 
        {
            'text' => __('Firewall Log'),
            'uri' => '/Logs/Index?selected=firewall&refresh=1',
            'icon' => 'icon-logs',
        }, 
        {
            'text' => __('Network Objects'),
            'uri' => '/Network/Objects',
            'icon' => 'icon-network',
        }, 
    );

    my $html = "";
    for (my $i = 0; $i <= $#links; $i++) {
        my $button = '<a href="'.$links[$i]{'uri'}.'" '
            . ' style="  height: 150%;line-height: 150%;padding-left: 50px !important;" '
            .' class="btn btn-icon  '.$links[$i]{'icon'}.'">'
            .$links[$i]{'text'}.'</a> ';
        $html = $html . $button;
    }

    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName, $html));

    my $pageTitle = __('Setting Quick Link');

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

# -------------------------------------------------------------

##
# 讀取指定的Model
sub loadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

1;
