package EBox::dlllciasrouter::Model::ErrorMessage;

use base 'EBox::Model::DataForm';

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;

use EBox::Types::Text;
use EBox::Types::MailAddress;


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
            'fieldName' => 'websiteTitle',
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
            'optional'=>0,
            'defaultValue' => "https://github.com/pulipulichen/zentyal-dlll",
        ));
    
    # menu contact
    push(@fields, new EBox::Types::Text(
            'fieldName' => 'contactText',
            'printableName' => __('Contact Us Label'),
            'editable' => 1,
            'optional'=>0,
            'defaultValue' => __('CONTACT US'),
        ));
    push(@fields, new EBox::Types::MailAddress(
            'fieldName' => 'contactEMAIL',
            'printableName' => __('Contact Us Email'),
            'editable' => 1,
            'optional' => 0,
            'defaultValue' => 'pulipuli.chen@gmail.com',
        ));

    #  error message
#    my $desc = '<h2>Oops! It looks something went completely wrong.</h2>'
#.'<p>'
#.'    Sorry. Evidently the document you were looking for has either been moved or no longer exists. '
#.'    Please use the navigational links to the night to locate additional resources and information.'
#.'</p>'
#.'<h4 class="regular">Lost? We suggest...</h4>'
#.'<ol>'
#.'    <li><span>The load average on the server is too high at the moment. Please wait a few minutes and <a href="javascript:location.reload();">trying again</a>.</span></li>'
#.'    <li><span>Checking the web address for types.</span></li>'
#.'    <li><span>Contacting our <a href="mailto:pudding@nccu.edu.tw">WEB ADMINISTRATOR</a>.</span></li>'
#.'    <li><span>Visiting the <a href="http://dlll.nccu.edu.tw/">HOMEPAGE</a> (link to the left).</span></li>'
#.'    <li><span><a href="javascript:window.history.back();">Go back</a>.</span></li>'
#.'</ol>';
    my $desc = '+003C+0068+0032+003E+004F+006F+0070+0073+0021+0020+0049+0074+0020+006C+006F+006F+006B+0073+0020+0073+006F+006D+0065+0074+0068+0069+006E+0067+0020+0077+0065+006E+0074+0020+0063+006F+006D+0070+006C+0065+0074+0065+006C+0079+0020+0077+0072+006F+006E+0067+002E+003C+002F+0068+0032+003E+000A+003C+0070+003E+0053+006F+0072+0072+0079+002E+0020+0045+0076+0069+0064+0065+006E+0074+006C+0079+0020+0074+0068+0065+0020+0064+006F+0063+0075+006D+0065+006E+0074+0020+0079+006F+0075+0020+0077+0065+0072+0065+0020+006C+006F+006F+006B+0069+006E+0067+0020+0066+006F+0072+0020+0068+0061+0073+0020+0065+0069+0074+0068+0065+0072+0020+0062+0065+0065+006E+0020+006D+006F+0076+0065+0064+0020+006F+0072+0020+006E+006F+0020+006C+006F+006E+0067+0065+0072+0020+0065+0078+0069+0073+0074+0073+002E+0020+0050+006C+0065+0061+0073+0065+0020+0075+0073+0065+0020+0074+0068+0065+0020+006E+0061+0076+0069+0067+0061+0074+0069+006F+006E+0061+006C+0020+006C+0069+006E+006B+0073+0020+0074+006F+0020+0074+0068+0065+0020+006E+0069+0067+0068+0074+0020+0074+006F+0020+006C+006F+0063+0061+0074+0065+0020+0061+0064+0064+0069+0074+0069+006F+006E+0061+006C+0020+0072+0065+0073+006F+0075+0072+0063+0065+0073+0020+0061+006E+0064+0020+0069+006E+0066+006F+0072+006D+0061+0074+0069+006F+006E+002E+003C+002F+0070+003E+000A+003C+0068+0034+0020+0063+006C+0061+0073+0073+003D+0022+0072+0065+0067+0075+006C+0061+0072+0022+003E+004C+006F+0073+0074+003F+0020+0057+0065+0020+0073+0075+0067+0067+0065+0073+0074+002E+002E+002E+003C+002F+0068+0034+003E+000A+003C+006F+006C+003E+000A+003C+006C+0069+003E+0054+0068+0065+0020+006C+006F+0061+0064+0020+0061+0076+0065+0072+0061+0067+0065+0020+006F+006E+0020+0074+0068+0065+0020+0073+0065+0072+0076+0065+0072+0020+0069+0073+0020+0074+006F+006F+0020+0068+0069+0067+0068+0020+0061+0074+0020+0074+0068+0065+0020+006D+006F+006D+0065+006E+0074+002E+0020+0050+006C+0065+0061+0073+0065+0020+0077+0061+0069+0074+0020+0061+0020+0066+0065+0077+0020+006D+0069+006E+0075+0074+0065+0073+0020+0061+006E+0064+0020+003C+0061+003E+0074+0072+0079+0069+006E+0067+0020+0061+0067+0061+0069+006E+003C+002F+0061+003E+002E+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0043+0068+0065+0063+006B+0069+006E+0067+0020+0074+0068+0065+0020+0077+0065+0062+0020+0061+0064+0064+0072+0065+0073+0073+0020+0066+006F+0072+0020+0074+0079+0070+0065+0073+002E+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0043+006F+006E+0074+0061+0063+0074+0069+006E+0067+0020+006F+0075+0072+0020+003C+0061+0020+0068+0072+0065+0066+003D+0022+006D+0061+0069+006C+0074+006F+003A+0070+0075+0064+0064+0069+006E+0067+0040+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0022+003E+0057+0045+0042+0020+0041+0044+004D+0049+004E+0049+0053+0054+0052+0041+0054+004F+0052+003C+002F+0061+003E+002E+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0056+0069+0073+0069+0074+0069+006E+0067+0020+0074+0068+0065+0020+003C+0061+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+003A+002F+002F+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+002F+0022+003E+0048+004F+004D+0045+0050+0041+0047+0045+003C+002F+0061+003E+0020+0028+006C+0069+006E+006B+0020+0074+006F+0020+0074+0068+0065+0020+006C+0065+0066+0074+0029+002E+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+003C+0061+003E+0047+006F+0020+0062+0061+0063+006B+003C+002F+0061+003E+002E+003C+002F+006C+0069+003E+000A+003C+002F+006F+006C+003E';

    my $address = $self->loadLibrary('LibraryNetwork')->getExternalIpaddr();

    push(@fields, new EBox::Types::Text(
            'fieldName'  => 'errorMessage',
            'printableName' => __('Right Column Error Message'),
            'editable' => 0,
            'optional' => 0,
            'hiddenOnSetter' => 0,
            'hiddenOnViewer' => 1,
            'help' => $self->loadLibrary('LibraryFields')->createFieldDescriptionEditor(),
            'defaultValue' => $desc,
        ));

    # 預覽畫面
    my $errorMessagePreview = 'http://' . $address;
    my $html = '<a href="'.$errorMessagePreview.'" '
            . ' style="  height: 150%;line-height: 150%;background-image: url(\'/data/images/view.gif\');" '
            .' class="btn btn-icon  " target="_blank">'
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
            'defaultActions' => [ 'editField' ],
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
