package EBox::dlllciasrouter::Composite::Global;

use base 'EBox::Model::Composite';

use strict;
use warnings;

use EBox::Gettext;
use EBox::Global;

# Group: Protected methods

# Method: _description
#
# Overrides:
#
#     <EBox::Model::Composite::_description>
#
sub _description
{
    my $pageTitle = 'DLLL-CIAS Router';

    my $description =
      {
       layout          => 'top-bottom',
       name            => 'Global',
       pageTitle       => $pageTitle,
       printableName   => $pageTitle,
       compositeDomain => 'dlllciasrouter',
      };

    return $description;
}

1;
