package EBox::dlllciasrouter::Model::ManualDomainName;

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
    $options->{moduleName} = 'ManualDomainName';
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

    my $tableName = $options->{moduleName};

    my $desc = "+003C+0068+0031+003E+0044+006F+006D+0061+0069+006E+0020+004E+0061+006D+0065+0020+0052+0075+006C+0065+003C+002F+0068+0031+003E+000A+003C+0068+0032+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0066+006F+0072+006D+0061+0074+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0066+006F+0072+006D+0061+0074+0022+003E+003C+002F+0061+003E+0046+006F+0072+006D+0061+0074+003C+002F+0068+0032+003E+000A+003C+0070+003E+0044+006F+006D+0061+0069+006E+0020+004E+0061+006D+0065+0020+0053+0065+0063+0074+0069+006F+006E+0020+0046+006F+0072+006D+0061+0074+003A+003C+002F+0070+003E+000A+003C+0070+003E+0022+005B+0074+0079+0070+0065+005D+002D+005B+006E+0061+006D+0065+005D+002D+005B+0079+0065+0061+0072+005D+002E+005B+0075+0070+0070+0065+0072+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+005D+0022+003C+002F+0070+003E+000A+003C+0070+003E+0046+006F+0072+0020+0065+0078+0061+006D+0070+006C+0065+003A+003C+002F+0070+003E+000A+003C+0070+003E+0022+0074+0065+0073+0074+002D+007A+0065+006E+0074+0079+0061+006C+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0022+003C+002F+0070+003E+000A+003C+0068+0032+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0073+0065+0063+0074+0069+006F+006E+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0073+0065+0063+0074+0069+006F+006E+0022+003E+003C+002F+0061+003E+0053+0065+0063+0074+0069+006F+006E+003C+002F+0068+0032+003E+000A+003C+0068+0033+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0074+0079+0070+0065+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0074+0079+0070+0065+0022+003E+003C+002F+0061+003E+005B+0074+0079+0070+0065+005D+003C+002F+0068+0033+003E+000A+003C+0070+003E+0055+0073+0061+0067+0065+002E+003C+002F+0070+003E+000A+003C+0075+006C+003E+000A+003C+006C+0069+003E+0065+0078+0070+0026+006E+0062+0073+0070+003B+0028+0065+0078+0070+0065+0072+0069+006D+0065+006E+0074+0029+003A+0020+0066+006F+0072+0020+0031+0020+0073+0065+006D+0065+0073+0074+0065+0072+002E+0026+006E+0062+0073+0070+003B+003C+0062+0072+0020+002F+003E+0065+0078+0070+002D+006B+0061+006C+0073+002D+0032+0030+0031+0032+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0074+0065+0073+0074+003A+0020+0064+0069+0073+0063+0061+0072+0064+0020+0069+006E+0020+0061+006E+0079+0074+0069+006D+0065+002E+003C+0062+0072+0020+002F+003E+0074+0065+0073+0074+002D+0070+0075+0064+0064+0069+006E+0067+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0070+0063+0026+006E+0062+0073+0070+003B+0028+0070+0065+0072+0073+006F+006E+0061+006C+0020+0063+006F+006D+0070+0075+0074+0065+0072+0029+003A+0020+0066+006F+0072+0020+0033+0020+0079+0065+0061+0072+0073+002E+003C+0062+0072+0020+002F+003E+0070+0063+002D+0070+0075+0064+0064+0069+006E+0067+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0074+0065+0061+0063+0068+003A+0020+0066+006F+0072+0020+0031+0020+0073+0065+006D+0065+0073+0074+0065+0072+002E+003C+0062+0072+0020+002F+003E+0074+0065+0061+0063+0068+002D+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0064+0065+006D+006F+003A+0020+0066+006F+0072+0020+0061+0020+006C+006F+006E+0067+0020+0074+0069+006D+0065+003C+0062+0072+0020+002F+003E+0064+0065+006D+006F+002D+006B+0061+006C+0073+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0070+0075+0062+006C+0069+0063+003A+0020+0066+006F+0072+0020+0061+0020+006C+006F+006E+0067+0020+0074+0069+006D+0065+002E+003C+0062+0072+0020+002F+003E+0070+0075+0062+006C+0069+0063+002D+006B+0061+006C+0073+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0028+006E+006F+006E+002D+0074+0079+0070+0065+0029+003A+0020+0065+0071+0075+0061+006C+0020+0074+006F+0020+0074+0079+0070+0065+0020+0070+0075+0062+006C+0069+0063+002C+0020+0066+006F+0072+0020+0061+0020+006C+006F+006E+0067+0020+0074+0069+006D+0065+002E+003C+0062+0072+0020+002F+003E+0072+0065+0061+0064+0069+006E+0067+002D+0063+006C+0075+0062+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+002F+0075+006C+003E+000A+003C+0068+0033+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+006E+0061+006D+0065+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+006E+0061+006D+0065+0022+003E+003C+002F+0061+003E+005B+006E+0061+006D+0065+005D+003C+002F+0068+0033+003E+000A+003C+0070+003E+0050+0072+006F+006A+0065+0063+0074+0020+006E+0061+006D+0065+0020+006F+0072+0020+0075+0073+0065+0072+0026+0072+0073+0071+0075+006F+003B+0073+0020+006E+0061+006D+0065+002E+003C+002F+0070+003E+000A+003C+0075+006C+003E+000A+003C+006C+0069+003E+000A+003C+0070+003E+006B+0061+006C+0073+003A+0020+0061+0020+0070+0072+006F+006A+0065+0063+0074+0020+006E+0061+006D+0065+002E+003C+0062+0072+0020+002F+003E+0064+0065+006D+006F+002D+006B+0061+006C+0073+002D+0032+0030+0030+0039+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0070+003E+000A+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+000A+003C+0070+003E+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+003A+0020+0061+0020+0070+0072+006F+006A+0065+0063+0074+0020+006E+0061+006D+0065+002E+003C+0062+0072+0020+002F+003E+0064+0065+006D+006F+002D+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+002D+0032+0030+0031+0033+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0070+003E+000A+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+000A+003C+0070+003E+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+002D+0030+0031+003A+0020+0061+0020+0070+0072+006F+006A+0065+0063+0074+0020+006E+0061+006D+0065+0020+0066+006F+0072+0020+0067+0072+006F+0075+0070+0020+0030+0031+002E+003C+0062+0072+0020+002F+003E+0074+0065+0061+0063+0068+002D+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+002D+0030+0031+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0070+003E+000A+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+000A+003C+0070+003E+0070+0075+0064+0064+0069+006E+0067+003A+0020+0061+0020+0075+0073+0065+0072+0020+006E+0061+006D+0065+002E+003C+0062+0072+0020+002F+003E+0070+0063+002D+0070+0075+0064+0064+0069+006E+0067+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0070+003E+000A+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+000A+003C+0070+003E+0072+0065+0064+003A+0020+0061+0020+0075+0073+0065+0072+0020+006E+0061+006D+0065+002E+003C+0062+0072+0020+002F+003E+0070+0063+002D+0072+0065+0064+002D+0032+0030+0031+0032+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0070+003E+000A+003C+002F+006C+0069+003E+000A+003C+002F+0075+006C+003E+000A+003C+0068+0033+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0079+0065+0061+0072+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0079+0065+0061+0072+0022+003E+003C+002F+0061+003E+005B+0079+0065+0061+0072+005D+003C+002F+0068+0033+003E+000A+003C+0070+003E+0043+0072+0065+0061+0074+0065+0064+0020+0079+0065+0061+0072+002E+003C+002F+0070+003E+000A+003C+0075+006C+003E+000A+003C+006C+0069+003E+0032+0030+0031+0032+003A+0020+0043+0072+0065+0061+0074+0065+0064+0020+0066+0072+006F+006D+0020+0032+0030+0031+0032+002E+003C+0062+0072+0020+002F+003E+0070+0063+002D+0072+0065+0064+002D+0032+0030+0031+0032+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+0032+0030+0031+0033+003A+0020+0043+0072+0065+0061+0074+0065+0064+0020+0066+0072+006F+006D+0020+0032+0030+0031+0033+002E+003C+0062+0072+0020+002F+003E+0064+0065+006D+006F+002D+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+002D+0032+0030+0031+0033+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+002F+0075+006C+003E+000A+003C+0068+0033+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0075+0070+0070+0065+0072+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0075+0070+0070+0065+0072+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+0022+003E+003C+002F+0061+003E+005B+0075+0070+0070+0065+0072+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+005D+003C+002F+0068+0033+003E+000A+003C+0070+003E+0044+006F+006D+0061+0069+006E+0020+006E+0061+006D+0065+0020+0077+0068+0069+0063+0068+0020+0044+004E+0053+0020+0063+006F+0075+006C+0064+0020+0063+006F+006E+0074+0072+006F+006C+002E+003C+002F+0070+003E+000A+003C+0075+006C+003E+000A+003C+006C+0069+003E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003A+0020+0066+006F+0072+0020+0044+004C+004C+004C+0020+004C+0041+0042+0020+0075+0073+0065+002E+003C+0062+0072+0020+002F+003E+0074+0065+0061+0063+0068+002D+0064+0073+0070+0061+0063+0065+002D+0064+006C+006C+006C+002D+0030+0031+002D+0032+0030+0031+0033+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+006C+0069+003E+006C+0069+0061+0073+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003A+0020+0066+006F+0072+0020+004C+0049+0041+0053+0020+0075+0073+0065+002E+003C+0062+0072+0020+002F+003E+0074+0065+0061+0063+0068+002D+006B+006F+0068+0061+002D+0032+0030+0031+0033+002E+006C+0069+0061+0073+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+006C+0069+003E+000A+003C+002F+0075+006C+003E+000A+003C+0068+0072+0020+002F+003E+000A+003C+0068+0032+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+7DB2+5740+7533+8ACB+539F+5247+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+0025+0045+0037+0025+0042+0036+0025+0042+0032+0025+0045+0035+0025+0039+0044+0025+0038+0030+0025+0045+0037+0025+0039+0034+0025+0042+0033+0025+0045+0038+0025+0041+0042+0025+0038+0042+0025+0045+0035+0025+0038+0045+0025+0039+0046+0025+0045+0035+0025+0038+0039+0025+0038+0037+0022+003E+003C+002F+0061+003E+0044+006F+006D+0061+0069+006E+0020+004E+0061+006D+0065+0028+7DB2+5740+0029+7533+8ACB+539F+5247+003C+002F+0068+0032+003E+000A+003C+0068+0034+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+006C+0069+0061+0073+006E+0063+0063+0075+0065+0064+0075+0074+0077+002D+7DB2+57DF+5E95+4E0B+7684+7DB2+5740+683C+5F0F+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+006C+0069+0061+0073+006E+0063+0063+0075+0065+0064+0075+0074+0077+002D+0025+0045+0037+0025+0042+0036+0025+0042+0032+0025+0045+0035+0025+0039+0046+0025+0039+0046+0025+0045+0035+0025+0042+0041+0025+0039+0035+0025+0045+0034+0025+0042+0038+0025+0038+0042+0025+0045+0037+0025+0039+0041+0025+0038+0034+0025+0045+0037+0025+0042+0036+0025+0042+0032+0025+0045+0035+0025+0039+0044+0025+0038+0030+0025+0045+0036+0025+0041+0030+0025+0042+0043+0025+0045+0035+0025+0042+0043+0025+0038+0046+0022+003E+003C+002F+0061+003E+006C+0069+0061+0073+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0020+7DB2+57DF+5E95+4E0B+7684+7DB2+5740+683C+5F0F+003C+002F+0068+0034+003E+000A+003C+0070+003E+9019+90E8+4EFD+6B78+5C6C+5716+6A94+6240+FF0C+7531+52A9+6559+7BA1+7406+0028+6211+5E0C+671B+5982+6B64+0029+3002+8ACB+4F9D+7167+8001+5E2B+3001+52A9+6559+7684+8981+6C42+4F86+8A2D+5B9A+3002+4F9B+5716+6A94+6240+3001+7814+8A0E+6703+3001+6559+5B78+3001+5716+6A94+6240+5B78+751F+4F7F+7528+3002+003C+002F+0070+003E+000A+003C+0070+003E+4E00+822C+5BE6+9A57+5BA4+6210+54E1+5728+505A+5BE6+9A57+3001+6E2C+8A66+6642+FF0C+8ACB+52FF+4F7F+7528+006C+0069+0061+0073+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+7DB2+5740+3002+003C+002F+0070+003E+000A+003C+0068+0034+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+0064+006C+006C+006C+006E+0063+0063+0075+0065+0064+0075+0074+0077+002D+7DB2+57DF+5E95+4E0B+7684+7DB2+5740+683C+5F0F+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0064+006C+006C+006C+006E+0063+0063+0075+0065+0064+0075+0074+0077+002D+0025+0045+0037+0025+0042+0036+0025+0042+0032+0025+0045+0035+0025+0039+0046+0025+0039+0046+0025+0045+0035+0025+0042+0041+0025+0039+0035+0025+0045+0034+0025+0042+0038+0025+0038+0042+0025+0045+0037+0025+0039+0041+0025+0038+0034+0025+0045+0037+0025+0042+0036+0025+0042+0032+0025+0045+0035+0025+0039+0044+0025+0038+0030+0025+0045+0036+0025+0041+0030+0025+0042+0043+0025+0045+0035+0025+0042+0043+0025+0038+0046+0022+003E+003C+002F+0061+003E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0020+7DB2+57DF+5E95+4E0B+7684+7DB2+5740+683C+5F0F+003C+002F+0068+0034+003E+000A+003C+0070+003E+7DB2+5740+8207+865B+64EC+4E3B+6A5F+7684+0068+006F+0073+0074+006E+0061+006D+0065+7684+683C+5F0F+76E1+91CF+4EE5+4EE5+4E0B+7684+5F62+5F0F+4F86+8A2D+5B9A+FF1A+003C+002F+0070+003E+000A+003C+0070+003E+005B+670D+52D9+985E+578B+4EE3+865F+005D+002D+005B+670D+52D9+540D+7A31+005D+002D+005B+526F+672C+7DE8+865F+005D+002D+005B+5EFA+7ACB+5E74+4EFD+005D+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0070+003E+000A+003C+0070+003E+8209+4F8B+4F86+8AAA+FF0C+004B+0041+004C+0053+6A19+8A3B+7CFB+7D71+7684+670D+52D9+985E+578B+70BA+300C+516C+958B+670D+52D9+300D+0028+8A2D+70BA+0070+0075+0062+006C+0069+0063+0029+FF0C+670D+52D9+540D+7A31+70BA+300C+006B+0061+006C+0073+300D+FF0C+5EFA+7ACB+5E74+4EFD+70BA+300C+0032+0030+0031+0031+300D+5E74+7684+670D+52D9+FF0C+5247+7DB2+5740+70BA+300C+0070+0075+0062+006C+0069+0063+002D+006B+0061+006C+0073+002D+0032+0030+0031+0031+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+300D+3002+003C+002F+0070+003E+000A+003C+0070+003E+5982+679C+670D+52D9+540D+7A31+96E3+4EE5+6C7A+5B9A+FF0C+90A3+9EBC+5C31+4EE5+7533+8ACB+8005+7684+0065+002D+006D+0061+0069+006C+540D+7A31+70BA+4E3B+3002+4F8B+5982+300C+0064+0065+006D+006F+002D+0079+0065+006E+0063+0068+0061+006E+0067+002D+0032+0030+0031+0031+300D+3002+003C+002F+0070+003E+000A+003C+0070+003E+5982+679C+662F+505A+6210+96C6+53E2+0028+0063+006C+0075+0073+0074+0065+0072+0029+FF0C+5247+4EE5+0056+004D+0049+0044+7DE8+865F+FF0C+4F8B+5982+0065+0078+0070+002D+006B+0061+006C+0073+002D+006D+006F+006F+0064+006C+0065+002D+0031+0033+0034+002D+0032+0030+0031+0034+003C+002F+0070+003E+000A+003C+0068+0034+003E+003C+0061+0020+0069+0064+003D+0022+0075+0073+0065+0072+002D+0063+006F+006E+0074+0065+006E+0074+002D+4F9D+7167+670D+52D9+985E+578B+5206+6210+4EE5+4E0B+985E+5225+0022+0020+0063+006C+0061+0073+0073+003D+0022+0061+006E+0063+0068+006F+0072+0022+0020+0068+0072+0065+0066+003D+0022+0068+0074+0074+0070+0073+003A+002F+002F+0067+0069+0074+0068+0075+0062+002E+0063+006F+006D+002F+0070+0075+006C+0069+0070+0075+006C+0069+0063+0068+0065+006E+002F+007A+0065+006E+0074+0079+0061+006C+002D+0064+006C+006C+006C+002F+0062+006C+006F+0062+002F+006D+0061+0073+0074+0065+0072+002F+0067+0075+0069+0064+0065+002F+0035+002D+0031+002D+0064+006F+006D+0061+0069+006E+002D+006E+0061+006D+0065+002D+0072+0075+006C+0065+002E+006D+0064+0023+0025+0045+0034+0025+0042+0045+0025+0039+0044+0025+0045+0037+0025+0038+0035+0025+0041+0037+0025+0045+0036+0025+0039+0043+0025+0038+0044+0025+0045+0035+0025+0038+0042+0025+0039+0039+0025+0045+0039+0025+0041+0031+0025+0039+0045+0025+0045+0035+0025+0039+0045+0025+0038+0042+0025+0045+0035+0025+0038+0038+0025+0038+0036+0025+0045+0036+0025+0038+0038+0025+0039+0030+0025+0045+0034+0025+0042+0042+0025+0041+0035+0025+0045+0034+0025+0042+0038+0025+0038+0042+0025+0045+0039+0025+0041+0031+0025+0039+0045+0025+0045+0035+0025+0038+0038+0025+0041+0035+0022+003E+003C+002F+0061+003E+4F9D+7167+670D+52D9+985E+578B+FF0C+5206+6210+4EE5+4E0B+985E+5225+FF1A+003C+002F+0068+0034+003E+000A+003C+0074+0061+0062+006C+0065+0020+0066+0072+0061+006D+0065+003D+0022+0062+006F+0072+0064+0065+0072+0022+0020+0072+0075+006C+0065+0073+003D+0022+0061+006C+006C+0022+0020+0061+006C+0069+0067+006E+003D+0022+006C+0065+0066+0074+0022+003E+000A+003C+0074+0062+006F+0064+0079+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+670D+52D9+985E+578B+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+985E+578B+4EE3+865F+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+4F7F+7528+6642+9593+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+5099+4EFD+6578+91CF+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+7528+9014+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+6B63+5F0F+7DB2+5740+0020+FF08+90E8+5206+5C6C+65BC+516C+958B+670D+52D9+3001+90E8+5206+5C6C+65BC+96F2+7AEF+5E73+53F0+FF09+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0028+4E0D+52A0+985E+578B+4EE3+865F+8207+5E74+4EFD+0029+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+6C38+4E45+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0031+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+0020+5BE6+9A57+5BA4+7DB2+7AD9+FF1A+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0020+FF08+516C+958B+670D+52D9+FF09+0020+25C7+0020+0044+004E+0053+FF1A+0064+006E+0073+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0020+FF08+516C+958B+670D+52D9+FF09+0020+25C7+0020+5BE6+9A57+5BA4+0046+0054+0050+FF1A+0066+0074+0070+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0020+FF08+96F2+7AEF+5E73+53F0+FF09+0020+25C7+0020+004B+004D+FF1A+006B+006D+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+0020+FF08+96F2+7AEF+5E73+53F0+FF09+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+516C+958B+670D+52D9+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0070+0075+0062+006C+0069+0063+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+9577+671F+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0035+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+0020+5C0D+5BE6+9A57+5BA4+4EE5+5916+7684+4EBA+63D0+4F9B+7684+670D+52D9+0020+25C7+76E1+53EF+80FD+662F+5B8C+6574+7684+670D+52D9+0020+25C7+53EF+80FD+6703+6709+591A+500B+7248+672C+FF0C+6240+4EE5+8981+52A0+4E0A+5E74+4EFD+0020+25C7+8981+7559+4E0B+806F+7D61+65B9+5F0F+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+5BE6+9A57+670D+52D9+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0065+0078+0070+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+77ED+671F+0028+4E00+5E74+4E4B+5167+0029+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0031+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+5BA3+50B3+5BE6+9A57+7DB2+5740+6642+53EF+4EE5+4F7F+7528+0020+25C7+53EF+80FD+6703+5FEB+901F+6539+8B8A+3001+6D88+5931+3001+4E0D+4F7F+7528+0020+25C7+52D9+5FC5+52A0+5165+5E74+4EFD+FF0C+5340+5225+7248+672C+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+5C55+793A+670D+52D9+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0064+0065+006D+006F+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+9577+671F+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0035+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+8AD6+6587+5B8C+6210+4E4B+5F8C+7684+7CFB+7D71+5C55+793A+0020+25C7+8CC7+6599+76E1+91CF+4E0D+8981+6539+8B8A+FF0C+4FDD+6301+5BE6+9A57+5B8C+6210+7684+539F+8C8C+0020+25C7+4F5C+70BA+5F80+5F8C+5B78+5F1F+59B9+7814+7A76+7684+7CFB+7D71+57FA+790E+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+6559+5B78+670D+52D9+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0074+0065+0061+0063+0068+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+77ED+671F+0028+4E00+5B78+671F+0029+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0031+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+4F9B+6559+5B78+6642+65B9+4FBF+8B93+4EBA+8A18+5F97+7DB2+5740+4F7F+7528+0020+25C7+8A18+5F97+8981+52A0+4E0A+5E74+4EFD+FF0C+56E0+70BA+540C+4E00+7A2E+6559+5B78+65B9+5F0F+53EF+80FD+6703+7528+5728+4E0D+540C+5B78+671F+3002+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+6E2C+8A66+670D+52D9+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0074+0065+0073+0074+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+975E+5E38+77ED+0028+6578+6708+5167+0029+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+79C1+4EBA+4E0B+6E2C+8A66+7528+0020+25C7+4E0D+4F7F+7528+7684+8A71+8A18+5F97+4E00+5B9A+8981+79FB+9664+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+500B+4EBA+4F7F+7528+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0070+0063+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+77ED+671F+0028+4E00+5230+5169+5E74+0029+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+25C7+0026+006E+0062+0073+0070+003B+0070+0063+002D+0072+0065+0064+002D+0032+0030+0031+002E+0064+006C+006C+006C+002E+006E+0063+0063+0075+002E+0065+0064+0075+002E+0074+0077+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+96F2+7AEF+5E73+53F0+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0063+006C+006F+0075+0064+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+9577+671F+670D+52D9+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0031+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+96F2+7AEF+5E73+53F0+4F7F+7528+7684+5DE5+5177+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+0074+0072+003E+000A+003C+0074+0064+003E+7BC4+672C+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0074+0065+006D+0070+006C+0061+0074+0065+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+9577+671F+0028+5E73+6642+95DC+6A5F+0029+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+0030+003C+002F+0074+0064+003E+000A+003C+0074+0064+003E+88FD+4F5C+5176+4ED6+7DB2+7AD9+6A23+677F+4F7F+7528+7684+985E+578B+003C+002F+0074+0064+003E+000A+003C+002F+0074+0072+003E+000A+003C+002F+0074+0062+006F+0064+0079+003E+000A+003C+002F+0074+0061+0062+006C+0065+003E";

    push(@fields, new EBox::Types::Text(
        'fieldName'  => 'content',
        'printableName' => __('Content'),
        'editable' => 0,
        'optional' => 0,
        'hiddenOnSetter' => 0,
        'hiddenOnViewer' => 1,
        'help' => $self->loadLibrary('LibraryFields')->createFieldDescriptionEditor(),
        'defaultValue' => $desc,
        'allowUnsafeChars' => 1,
    ));

    my $pageTitle = __('Domain Name Manual');
 
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
