# Copyright 2010-2013 Zentyal S.L.
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
use strict;
use warnings;

package EBox::Zarafa::Model::ZarafaUser;

use base 'EBox::Model::DataForm';

use EBox::Gettext;
use EBox::Types::Boolean;

sub new
{
        my $class = shift;
        my %parms = @_;

        my $self = $class->SUPER::new(@_);
        bless($self, $class);

        return $self;
}

sub _table
{

    my @tableHead =
    (
        new EBox::Types::Boolean(
            'fieldName' => 'enabled',
            'printableName' => __('Groupware Account'),
            'editable' => 1,
            'defaultValue' => 1
        ),
        new EBox::Types::Boolean(
            'fieldName' => 'contact',
            'printableName' => __('Groupware Contact'),
            'help' => __('Enable contact in the addressbook even if it has not Zarafa account.'),
            'editable' => 1,
            'defaultValue' => 1
        ),
        new EBox::Types::Boolean(
            'fieldName' => 'pop3',
            'printableName' => __('Enable POP3 Access'),
            'editable' => 1,
            'defaultValue' => 1
        ),
        new EBox::Types::Boolean(
            'fieldName' => 'imap',
            'printableName' => __('Enable IMAP Access'),
            'editable' => 1,
            'defaultValue' => 1
        ),
    );
    my $dataTable =
    {
        'tableName' => 'ZarafaUser',
        'printableTableName' => __('Zarafa'),
        'pageTitle' => undef,
        'modelDomain' => 'Zarafa',
        'defaultActions' => ['add', 'del', 'editField', 'changeView' ],
        'tableDescription' => \@tableHead,
    };

    return $dataTable;
}

1;
