package EBox::dlllciasrouter::Model::RouterDocumentation;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use Try::Tiny;



sub getOptions
{
    my $options = ();
    $options->{moduleName} = 'RouterDocumentation';
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

    my $lib = $self->parentModule()->model('LibraryToolkit');
    my $fieldsFactory = $self->loadLibrary('LibraryFields');

    my @fields = ();

    my $tableName = $options->{moduleName} . "Header";
    my $configView = '/dlllciasrouter/View/'.$options->{moduleName}.'Setting';

    my @links = (
        {
            'text' => __('Domain Name Rule'),
            'uri' => '/dlllciasrouter/View/ManualDomainName',
            'icon' => 'icon-dns',
        }, 
        {
            'text' => __('Network IP Range'),
            'uri' => '/dlllciasrouter/View/ManualNetworkIPRange',
            'icon' => 'icon-network',
        }
    );

    my $html = "";
    for (my $i = 0; $i <= $#links; $i++) {
        my $target = "_self";
        if (substr($links[$i]{'uri'}, 0, 1) ne ('/')) {
            $target = "_blank";
        }

        my $button = '<a href="' . $links[$i]{'uri'} . '" '
            . ' style="  height: 150%;line-height: 150%;padding-left: 50px !important;" '
            . ' class="btn btn-icon  '.$links[$i]{'icon'}.'" '
            . ' target="' . $target . '" >'
            . $links[$i]{'text'}.'</a> ';
        $html = $html . $button;
    }

    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName, $html));

    push(@fields, $fieldsFactory->createFieldDescription());
    #push(@fields, $fieldsFactory->createFieldAttachedFilesButton('/dlllciasrouter/Composite/SettingComposite', 0));
    my $filePath = "/dlllciasrouter/View/AttachedFiles?directory=RouterSettings/keys/rs1/attachedFiles&backview=/dlllciasrouter/Composite/SettingComposite";
    push(@fields, $fieldsFactory->createFieldConfigLinkButton($tableName."_attachedFiles", __('UPLOAD FILE'), $filePath, 1));


    my $pageTitle = __('Documentation');

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
