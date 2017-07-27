# Copyright (C) 2012-2014 Zentyal S.L.
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

# Class: EBox::RemoteServices::Subscription::Check
#
#  This class performs the required checks to register/unregister
#  your server from the cloud
#

use strict;
use warnings;

package EBox::RemoteServices::Subscription::Check;

use EBox::Gettext;
use EBox::Global;
use EBox::RemoteServices::Exceptions::NotCapable;
use TryCatch::Lite;

# Group: Public methods

# Constructor: new
#
#     Create the subscription checker
#
sub new
{
    my ($class) = @_;

    my $self = {};

    bless($self, $class);
    return $self;
}

# Method: unsubscribeIsAllowed
#
#    Check whether the installed modules let the host be unsubscribed
#    from the cloud
#
#    Static method
#
# Returns:
#
#    True - if there is no problem in unsubscribing
#
# Exceptions:
#
#    <EBox::RemoteServices::Exceptions::NotCapable> - thrown if any module don't let the
#    host be unsubscribed from the cloud
#
sub unsubscribeIsAllowed
{
    my $modList = EBox::Global->modInstances();
    foreach my $mod (@{  $modList }) {
        my $method = 'canUnsubscribeFromCloud';
        if ($mod->can($method)) {
            $mod->$method();
        }
    }
    return 1;
}

# Method: check
#
#    Check if a server is suitable for the given edition codename.
#
#    Call <lastError> if you want to know why the server is not
#    suitable for the given edition.
#
# Parameters:
#
#    subscriptionDetails - Hash ref subscription information to check
#                          data from
#
# Returns:
#
#    True - if it is suitable
#
sub check
{
    my ($self, $subscriptionDetails) = @_;

    my $capable = 1;
    try {
        $self->_performUsersCheck($subscriptionDetails);
        delete $self->{lastError};
    } catch (EBox::RemoteServices::Exceptions::NotCapable $e) {
        $self->{lastError} = $e->text();
        $capable = 0;
    } catch ($exc) {
        EBox::error("Error checking if suitable for this edition: $exc");
        $self->{lastError} = "$exc";
    }

    return $capable;
}

# Method: lastError
#
#    Get the last error from last <check> method call
#
# Returns:
#
#    String - i18ned string with the error
#
sub lastError
{
    my ($self) = @_;

    if ( exists($self->{lastError}) ) {
        return $self->{lastError};
    }
    return undef;
}

# Group: Private methods

# Perform the required checks for SB edition
sub _performUsersCheck
{
    my ($self, $details) = @_;

    my $gl = EBox::Global->getInstance();
    $self->_usersCheck($gl, $details);
}

# Check number of users
sub _usersCheck
{
    my ($self, $gl, $details) = @_;

    if ( $gl->modExists('samba') ) {
        my $usersMod = $gl->modInstance('samba');
        my $rsMod = $gl->modInstance('remoteservices');
        if ($usersMod->isEnabled()) {
            # This check must be done if the server is master or Zentyal Cloud is
            my $users = $usersMod->realUsers('without_admin');
            my $maxUsers = $details->{features}->{serverusers}->{max};
            if (defined($maxUsers) and scalar(@{$users}) > $maxUsers ) {
                # throw Ebox::RemoteServices::Exceptions::NotCapable
                $rsMod->pushAdMessage(
                    'max_users',
                    __sx('Please note that the maximum number of users for {edition} is {max} '
                         . 'and you currently have {nUsers}.',
                         edition => $rsMod->i18nServerEdition(),
                         max => $maxUsers, nUsers => scalar(@{$users})));
            } else {
                $rsMod->popAdMessage('max_users');
            }
        }
    }
}

1;
