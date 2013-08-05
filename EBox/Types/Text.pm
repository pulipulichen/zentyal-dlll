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

package EBox::Types::Text;

use strict;
use warnings;

use base 'EBox::Types::Basic';

use EBox;
use EBox::Gettext;
use EBox::Exceptions::InvalidData;

# Group: Public methods

sub new
{
    my $class = shift;
    my %opts = @_;

    unless (exists $opts{'HTMLSetter'}) {
        $opts{'HTMLSetter'} ='/ajax/setter/textSetter.mas';
    }
    unless (exists $opts{'HTMLViewer'}) {
        $opts{'HTMLViewer'} ='/ajax/viewer/textViewer.mas';
    }

    $opts{'type'} = 'text' unless defined ($opts{'type'});
    my $self = $class->SUPER::new(%opts);

    bless($self, $class);
    return $self;
}

sub size
{
    my ($self) = @_;

    return $self->{'size'};
}

# Method: printableValue
#
#   This functions overrides <EBox::Types::Abstract::printableValue>
#   to i18nize the string in case the type is set as localizable
#
sub printableValue
{
    my ($self) = @_;

    if ($self->{'localizable'}) {
        return __($self->{value});
    } else {
        return $self->SUPER::printableValue();
    }
}

# Method: cmp
#
# Overrides:
#
#      <EBox::Types::Abstract::cmp>
#
sub cmp
{
    my ($self, $compareType) = @_;

    unless ( (ref $self) eq (ref $compareType) ) {
        return undef;
    }

    return $self->value() cmp $compareType->value();
}

# Group: Protected methods

# Method: _paramIsValid
#
# Overrides:
#
#       <EBox::Types::Abstract::_paramIsValid>
#
sub _paramIsValid
{
    return 1;
}

# Method: _paramIsSet
#
# Overrides:
#
#       <EBox::Types::Abstract::_paramIsSet>
#
sub _paramIsSet
{
    my ($self, $params) = @_;

    # Check if the parameter exist
    my $param =  $params->{$self->fieldName()};

    return defined ( $param ) and ($param ne '');
}

1;
