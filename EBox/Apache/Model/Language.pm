# Copyright (C) 2012 eBox Technologies S.L.
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
# Class: EBox::Apache::Model::Language
#
#   This model is used to configure the interface languaje
#

package EBox::Apache::Model::Language;
use base 'EBox::Model::DataForm';

use Error qw(:try);

use EBox;
use EBox::Gettext;
use EBox::Types::Select;
use EBox::Global;

# Method: validateTypedRow
#
#   Override <EBox::Model::DataTable::validateTypedRow> method
#
sub validateTypedRow
{
    my ($self, $action, $oldParams, $newParams) = @_;

    my $langs = EBox::Gettext::langs();
    my $lang = $newParams->{'language'}->value();

    my $showPkgWarn = not EBox::Config::configkey('custom_prefix');
    my $pkgInstalled = 1;
    my $package = '';
    if ($showPkgWarn) {
        my ($pkglang) = split (/_/, $lang);
        if (($pkglang eq 'pt') or ($pkglang eq 'zh')) {
            ($pkglang) = split (/\./, $lang);
            $pkglang =~ tr/_/-/;
            $pkglang =~ tr/[A-Z]/[a-z]/;
            $pkglang = 'pt' if ($pkglang eq 'pt-pt');
        }
        $package = "language-pack-zentyal-$pkglang";
        $pkgInstalled = $lang eq 'C' ? 1 : EBox::GlobalImpl::_packageInstalled($package);
    }

    if ($showPkgWarn and not $pkgInstalled) {
        throw EBox::Exceptions::External(
            __x('The language pack for {l} is missing, you can install it by running the following command: {c}',
                              l => $lang, c => "<b>sudo apt-get install $package</b>"));
    }
}

sub _table
{
    my ($self) = @_;

    my @tableHead = (new EBox::Types::Select(fieldName => 'language',
                                             populate  => \&_populateLanguages,
                                             editable  => 1));
    my $dataTable =
    {
        'tableName' => 'Language',
        'printableTableName' => __('Language selection'),
        'modelDomain' => 'Apache',
        'defaultActions' => [ 'editField' ],
        'messages' => {
            'update' => __('New language selected, save changes to commit'),
           },
        'tableDescription' => \@tableHead,
    };

    return $dataTable;
}

sub _populateLanguages
{
    my $langs = EBox::Gettext::langs();

    my $default = EBox::locale();

    my @array;
    push (@array, { value => $default, printableValue => $langs->{$default} });

    foreach my $l (sort keys %{$langs}) {
        unless ($l eq $default) {
            push (@array, { value => $l, printableValue => $langs->{$l} });
        }
    }

    return \@array;
}

sub updatedRowNotify
{
    my ($self) = @_;
    my $global = $self->global();
    my $sysinfo = $global->modInstance('sysinfo');
    $sysinfo->setReloadPageAfterSavingChanges(1);
    my $apache = $global->modInstance('apache');
    $apache->setHardRestart(1);
}

1;
