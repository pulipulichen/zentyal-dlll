# Copyright (C) 2008-2012 eBox Technologies S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
use strict;
use warnings;
# Class: EBox::DHCP::Composite::BackEndConfiguration
#
#   This class is used to manage dhcp server configuration on a given
#   interface. It stores four models indexed by interface this
#   composite does
#
package EBox::dlllciasrouter::Composite::BackEndConfiguration;
use base 'EBox::Model::Composite';

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
    my ($self) = @_;

    my $parentRow = $self->parentRow();
    if (not $parentRow) {
        # workaround: sometimes with a logout + apache restart the directory
        # parameter is lost. (the apache restart removes the last directory used
        # from the models)
        EBox::Exceptions::ComponentNotExists->throw('Directory parameter and attribute lost');
    }

    my $pageTitle = __('Back End Configuration');

    my $description = {
       layout          => 'top-bottom',
       name            => 'BackEndConfiguration',
       printableName   => $pageTitle,
       pageTitle       => $self->parentRow()->valueByName('domainName'),
       compositeDomain => 'dlllciasrouter',
      };

    return $description;
}

1;
