package EBox::dlllciasrouter::Model::ErrorMessage;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use Try::Tiny;



sub getOptions
{
    my $options = ();
    $options->{moduleName} = 'ErrorMessage';
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

    my $tableName = $options->{moduleName};

    push(@fields, new EBox::Types::Text(
            'fieldName' => 'websiteTile',
            'printableName' => __('Website Title'),
            'editable' => 1,
            'optional'=>0,
            'defaultValue' => __('Website Title'),
        ));

    # menu homepage
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'homeText',
            'printableName' => __('Honepage Label'),
            'editable' => 1,
            'optional'=>0,
            'defaultValue' => __('HOMEPAGE'),
        ));
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'homeURL',
            'printableName' => __('Honepage URL'),
            'editable' => 1,
            'optional'=>0,
            'defaultValue' => "https://github.com/pulipulichen/zentyal-dlll",
        ));

    # menu about
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'aboutText',
            'printableName' => __('About Label'),
            'editable' => 1,
            'optional' => 0,
            'defaultValue' => __('ABOUT'),
        ));
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'aboutURL',
            'printableName' => __('About URL'),
            'editable' => 1,
            'optional'=>1,
        ));
    
    # menu contact
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'contactText',
            'printableName' => __('Contact Us Label'),
            'editable' => 1,
            'optional'=>0,
            'defaultValue' => __('CONTACT US'),
        ));
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'contactEMAIL',
            'printableName' => __('Contact Us Email'),
            'editable' => 1,
            'optional' => 1,
        ));

    #  error message
    push(@fields, new EBox::Types::Text(
            fieldName => 'description',
            printableName => __('Description'),
            editable => 0,
            optional => 1,
            hiddenOnSetter => 0,
            hiddenOnViewer => 1,
            help => $self->loadLibrary('LibraryFields')->createFieldDescriptionEditor(),
        ));

    # 預覽畫面
    my $errorMessagePreview = 'http://192.168.11.75';
    my $html = '<a href="'.$errorMessagePreview.'" '
            . ' style="  height: 150%;line-height: 150%;padding-left: 50px !important;background-image: url( \'/data/images/package-icons/view.gif\');" '
            .' class="btn btn-icon  ">'
            .__('ERROR MESSAGE PREVIEW').'</a> ';
    push(@fields, $fieldsFactory->createFieldHTMLDisplay($tableName, $html));

    my $pageTitle = __('Error Message');
 
    my $configView = '/dlllciasrouter/Composite/SettingComposite';
    my $dataTable =
        {
            'tableName' => $tableName,
            'pageTitle' => $pageTitle,
            'printableTableName' => $pageTitle,
            'modelDomain'     => 'dlllciasrouter',
            #defaultActions => [ 'editField' ],
            'tableDescription' => \@fields,
            'HTTPUrlView'=> 'dlllciasrouter/View/' . $tableName,
            'messages' => {
                'update' => 'DONE <script type="text/javascript">location.href="'.$configView.'";</script>',
            }
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
