# Copyright (C) 2009-2013 Zentyal S.L.
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

# Class: EBox::WebMail
#
#      Class description
#

use strict;
use warnings;

package EBox::WebMail;

use base qw(EBox::Module::Service);

use EBox::Gettext;
use EBox::Service;
use EBox::Sudo;
use EBox::Config;
use EBox::WebServer;
use EBox::Exceptions::External;
use EBox::DBEngineFactory;
use File::Slurp;

use constant {
    MAIN_INC_FILE => '/etc/roundcube/main.inc.php',
    HTACCESS_FILE => '/etc/roundcube/htaccess',
    DES_KEY_FILE  => EBox::Config::conf() . 'roundcube.key',
    SIEVE_PLUGIN_INC_USR_FILE =>
           '/usr/share/roundcube/plugins/managesieve/config.inc.php',
    SIEVE_PLUGIN_INC_ETC_FILE =>
           '/etc/roundcube/managesieve-config.inc.php',
    ROUNDCUBE_DIR => '/var/lib/roundcube',
    HTTPD_WEBMAIL_DIR => '/var/www/webmail',
    MAX_UPLOAD_SIZE => 50,
};

# Group: Protected methods

# Constructor: _create
#
#        Create an module
#
# Overrides:
#
#        <EBox::Module::Service::_create>
#
# Returns:
#
#        <EBox::WebMail> - the recently created module
#
sub _create
{
    my $class = shift;
    my $self = $class->SUPER::_create(name => 'webmail',
                                      printableName => __('Webmail'),
                                      @_);
    bless($self, $class);
    return $self;
}

# Method: _setConf
#
#        Regenerate the configuration
#
# Overrides:
#
#       <EBox::Module::Service::_setConf>
#
sub _setConf
{
    my ($self) = @_;

    my $params;
    if ($self->_usesEBoxMail()) {
        $params = $self->_confFromMail();
    } else {
        $params = $self->_confForRemoteServer();
    }

    my $managesieve = $self->_managesieveEnabled();
    my $openchange = $self->_openchangeEnabled();

    my $options = $self->model('Options');
    push @{$params}, (
        managesieve => $managesieve,
        openchange  => $openchange,
        productName => $options->productName,
        desKey      => $self->desKey(),
    );

    $self->writeConfFile(
                         MAIN_INC_FILE,
                         'webmail/main.inc.php.mas',
                         $params,
                        );

    $params = [];
    push @{$params}, (
        uploadLimit => $self->_retrieveMaxMailSize(),
    );
    $self->writeConfFile(
                         HTACCESS_FILE,
                         'webmail/htaccess.mas',
                         $params,
                        );

    if ($managesieve) {
        $self->_setManageSievePluginConf();
    }

    $self->_setWebServerConf();
}

sub _retrieveMaxMailSize
{
    my ($self) = @_;

    my $mailLimit = 0;
    my $mail = $self->global()->modInstance('mail');

    if (defined ($mail) and $mail->isEnabled()) {
        $mailLimit = $mail->getMaxMsgSize();
    }

    return $mailLimit ? $mailLimit : MAX_UPLOAD_SIZE;
}

sub _openchangeEnabled
{
    my ($self) = @_;

    # TODO: remove this when roundcube plugins are enabled again
    return 0;

    my $openchange = $self->global()->modInstance('openchange');
    return (defined ($openchange) and $openchange->isEnabled() and $openchange->isProvisioned());
}

sub _managesieveEnabled
{
    my ($self) = @_;
    if ($self->_usesEBoxMail()) {
        my $mail = EBox::Global->modInstance('mail');
        return $mail->managesieve();
    } else {
        my $remoteConfRow = $self->model('RemoteServerConfiguration')->row();
        return $remoteConfRow->elementByName('managesieve')->value();
    }
}

sub _setManageSievePluginConf
{
    my ($self) = @_;

    my $params;
    if ($self->_usesEBoxMail()) {
        $params = [
                   host => 'localhost',
                   port => 4190,
                   tls  => 0,
                  ]
    } else {
        $params =
            $self->model('RemoteServerConfiguration')->getSieveConfiguration();
    }

    $self->writeConfFile(
                         SIEVE_PLUGIN_INC_ETC_FILE,
                         'webmail/managesieve-config.php.inc.mas',
                         $params
                        );
    # removing /usr file  and creatign a link to avoid package upgrades troubles
    EBox::Sudo::root('rm -f ' . SIEVE_PLUGIN_INC_USR_FILE);
    EBox::Sudo::root('ln -s ' . SIEVE_PLUGIN_INC_ETC_FILE . ' ' .
                                SIEVE_PLUGIN_INC_USR_FILE);

}

sub _confFromMail
{
    my ($self) = @_;
    my $mail = EBox::Global->modInstance('mail');
    my @conf;

    if ($mail->imap()) {
        @conf = (
                 imapServer => '127.0.0.1',
                 imapPort   => 143,
                );
    } elsif ($mail->imaps()) {
        @conf = (
                 imapServer => 'ssl://127.0.0.1',
                 imapPort => 993,
                );
    } elsif ($self->isEnabled) {
            throw EBox::Exceptions::External(__('Neither IMAP nor IMAPS service enabled.'));
    }

    push @conf, (
                 smtpServer => '127.0.0.1',
                 smtpPort   => 25,
                );

    return \@conf;
}

sub _confForRemoteServer
{
    my ($self) = @_;
    return $self->model('RemoteServerConfiguration')->getConfiguration();
}

# Group: Public methods

# Method: menu
#
#       Add an entry to the menu with this module
#
# Overrides:
#
#       <EBox::Module::menu>
#
sub menu
{
    my ($self, $root) = @_;

#    XXX commented out until external connections work as intended
#     my $folder = new EBox::Menu::Folder(
#                       'name' => 'WebMail',
#                       'text' => $self->printableName(),
#                       'separator' => 'Communications',
#                       'order' => 700,
#     );

#     $folder->add(
#                  new EBox::Menu::Item(
#                         'url' => 'WebMail/Composite/Backend',
#                         'text' => __('Backend')
#                    )
#     );

#     $folder->add(
#                  new EBox::Menu::Item(
#                         'url' => 'WebMail/View/Options',
#                         'text' => __('Options')
#                    )
#     );

#     $root->add($folder);

    $root->add(
               new EBox::Menu::Item(
                   'url' => 'WebMail/View/Options',
                   'icon' => 'webmail',
                   'text' => $self->printableName(),
                   'separator' => 'Communications',
              )
    );
}

# Method: usedFiles
#
#        Indicate which files are required to overwrite to configure
#        the module to work. Check overriden method for details
#
# Overrides:
#
#        <EBox::Module::Service::usedFiles>
#
sub usedFiles
{
    my ($self) = @_;

    my $files = [
        {
            'file' => MAIN_INC_FILE,
            'reason' => __('To configure Roundcube webmail.'),
            'module' => 'webmail'
        },
        {
            'file' => HTACCESS_FILE,
            'reason' => __('To customize PHP for the webmail.'),
            'module' => 'webmail'
        },
        {
            'file' => SIEVE_PLUGIN_INC_USR_FILE,
            'reason' => __('To configure managesieve Roundcube webmail plugin.'),
            'module' => 'webmail'
        },
    ];

    my $destFile = EBox::WebServer::CONF_AVAILABLE_DIR . 'zentyal-webmail.conf';
    push(@{$files}, { 'file' => $destFile, 'module' => 'webmail',
                      'reason' => __('To configure the webmail on the webserver.') });
    return $files;
}

# Method: actions
#
#        Explain the actions the module must make to configure the
#        system. Check overriden method for details
#
# Overrides:
#
#        <EBox::Module::Service::actions>
sub actions
{
    return [
            {
             'action' => __('Create MySQL Roundcube webmail database.'),
             'reason' => __('This database will store the data needed by Roundcube.'),
             'module' => 'webmail'
            },
            {
             'action' => __('Add webmail link to www data directory.'),
             'reason' => __('Webmail will be accesible at http://ip/webmail/.'),
             'module' => 'webmail'
            },

           ];
}

# Method: initialSetup
#
#     Perform the required migrations
#
# Overrides:
#
#     <EBox::Module::Base::initialSetup>
#
sub initialSetup
{
    my ($self, $version) = @_;

    if (defined ($version) and (EBox::Util::Version::compare($version, '3.4') < 0)) {
        EBox::Sudo::silentRoot('ln -s /etc/php5/conf.d/mcrypt.ini /etc/php5/mods-available');
        EBox::Sudo::silentRoot('php5enmod mcrypt');
    }

}

# Method: enableActions
#
#        Run those actions explain by <actions> to enable the module
#
# Overrides:
#
#        <EBox::Module::Service::enableActions>
#
sub enableActions
{
    my ($self) = @_;

    if ($self->_usesEBoxMail()) {
        my $mail = EBox::Global->modInstance('mail');
        if ((not $mail->imap()) and (not $mail->imaps())) {
            throw EBox::Exceptions::External(__x('Webmail module needs IMAP or IMAPS service enabled if ' .
                                                 'using Zentyal mail service. You can enable it at ' .
                                                 '{openurl}Mail -> General{closeurl}.',
                                                 openurl => q{<a href='/Mail/Composite/General'>},
                                                 closeurl => q{</a>}));
        }
    }

    # Make sure the MySQL conf file is correct
    my $db = EBox::DBEngineFactory::DBEngine();
    $db->updateMysqlConf();

    # Execute enable-module script
    $self->SUPER::enableActions();

    $self->_generateDesKeyFile();
}

# Method: disableActions
#
#        Rollback those actions performed by <enableActions> to
#        disable the module
#
# Overrides:
#
#        <EBox::Module::Service::disableActions>
#
sub disableActions
{

}

#  Method: enableModDepends
#
#   Override EBox::Module::Service::enableModDepends
#
sub enableModDepends
{
    my ($self) = @_;
    if ($self->_usesEBoxMail()) {
        return ['mail', 'webserver'];
    }

    return ['webserver'];
}

sub _usesEBoxMail
{
    my ($self) = @_;

    return $self->model('OperationMode')->usesEBoxMail();
}

sub validateIMAPChanges
{
    my ($self, $imap, $imaps) = @_;
    if (not $self->_usesEBoxMail()) {
        return;
    }

    if ($imap or $imaps) {
        $self->setAsChanged();
    } else {
        throw EBox::Exceptions::External(__('You cannot disable both IMAP and IMAPS service because they are used by Webmail module.'));
    }
}

sub _generateDesKeyFile
{
    my $desKey = '';
    my $keyLength = 24;
    # length of 24 chars
    my @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9,
                 '(', ')', ',', '#',
                 qw([ ] . : " ! @ $ % ^ & * < > ~ + /)
                );
    my $sizeChars = scalar @chars;

    for (1 .. $keyLength) {
        my $i = int(rand($sizeChars));
        $desKey .= $chars[$i];
    }

    EBox::Sudo::root('rm -f ' . DES_KEY_FILE);

    EBox::Sudo::command('touch ' . DES_KEY_FILE);
    EBox::Sudo::command('chmod og-rwx ' . DES_KEY_FILE);
    File::Slurp::write_file(DES_KEY_FILE, $desKey);
}

sub desKey
{
    my $desKey = File::Slurp::read_file(DES_KEY_FILE);
    return $desKey;
}

sub _setWebServerConf
{
    my ($self) = @_;

    # Delete all possible zentyal-webmail configuration
    my @cmd = ();
    push(@cmd, 'rm -f ' . HTTPD_WEBMAIL_DIR);
    my $vHostPattern = EBox::WebServer::SITES_AVAILABLE_DIR . 'user-' .
                       EBox::WebServer::VHOST_PREFIX. '*/zentyal-webmail';
    push(@cmd, 'rm -f ' . "$vHostPattern");
    EBox::Sudo::root(@cmd);

    my $vhost = $self->model('Options')->vHostValue();
    my $vhostEnabled = ((defined $vhost) and ($vhost ne 'disabled'));

    my $destFile = EBox::WebServer::CONF_AVAILABLE_DIR . 'zentyal-webmail.conf';
    if ($vhostEnabled) {
        $destFile = EBox::WebServer::SITES_AVAILABLE_DIR . 'user-' .
                    EBox::WebServer::VHOST_PREFIX. "$vhost/zentyal-webmail";
    }
    $self->writeConfFile($destFile, 'webmail/apache.mas', [ vhost => $vhostEnabled ]);

    if ($self->isEnabled()) {
        EBox::Sudo::root('a2enconf zentyal-webmail');
    } else {
        EBox::Sudo::silentRoot('a2disconf zentyal-webmail');
    }
}

1;
