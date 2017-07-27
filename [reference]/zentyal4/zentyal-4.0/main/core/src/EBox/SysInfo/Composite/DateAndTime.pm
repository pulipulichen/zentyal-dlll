# Copyright (C) 2014 Zentyal S.L.
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

package EBox::SysInfo::Composite::DateAndTime;

use base 'EBox::Model::Composite';

use EBox::Global;
use EBox::Gettext;

# Group: Protected methods

# Method: _description
#
# Overrides:
#
#       <EBox::Model::Composite::_description>
#
sub _description
{
    my $description =
    {
        layout          => 'top-bottom',
        name            => __PACKAGE__->nameFromClass,
        printableName   => __('Date and Time'),
        pageTitle       => __('Date and Time'),
        compositeDomain => 'SysInfo',
    };

    return $description;
}

# Method: componentNames
#
# Overrides:
#
#     <EBox::Model::Composite::componentNames>
#
sub componentNames
{
    my ($self) = @_;

    my @components = ( 'sysinfo/TimeZone', 'sysinfo/DateTime' );

    if ($self->global()->modExists('ntp')) {
        push (@components, 'ntp/Settings', 'ntp/Servers');
    }

    return \@components;
}

1;
