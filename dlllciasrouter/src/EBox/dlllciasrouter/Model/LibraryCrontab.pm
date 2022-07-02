package EBox::dlllciasrouter::Model::LibraryCrontab;

use base 'EBox::Model::DataTable';

use strict;
use warnings;

use EBox::Gettext;

use EBox::Global;
use EBox::DNS;
use EBox::DNS::Model::Services;
use EBox::DNS::Model::DomainTable;

use EBox::Exceptions::Internal;
use EBox::Exceptions::External;
use EBox::Exceptions::DataExists;

use LWP::Simple;
use POSIX qw(strftime);
use Try::Tiny;

##
# 讀取LibraryToolkit
# @author Pulipuli Chen
##
sub getLibrary
{
    my ($self) = @_;
    return $self->parentModule()->model("LibraryToolkit");
}

##
# 讀取指定的Model
#
# 我這邊稱之為Library，因為這些Model是作為Library使用，而不是作為Model顯示資料使用
# @author 20140312 Pulipuli Chen
sub getLoadLibrary
{
    my ($self, $library) = @_;
    return $self->parentModule()->model($library);
}

# ------------------------------------------------

##
# 初始化排程工作
# 20170815 Pulipuli Chen
##
sub initRootCrontab
{
     my ($self) = @_;

    #if (-e '/etc/crontab') {

        # ------------------------

        my $dirPath = "/root/dlllciasrouter";

        if (! -d $dirPath) {
            system('sudo mkdir -p ' . $dirPath);
        }

        # ------------------------

        my $settings = $self->getLoadLibrary('RouterSettings');
        my @backupParams = ();

        my $extIP = $self->getLoadLibrary('LibraryNetwork')->getExternalIpaddr();
        my $port = $self->getLoadLibrary('RouterSettings')->value('webadminPort');
        my $date = POSIX::strftime( "%A, %B %d, %Y", localtime());
        # my $date = strftime "%a %b %e %H:%M:%S %Y", gmtime;
        # printf("date and time - $date\n");
        # DateTime->now->ymd;

        my $backupMailAddress = $settings->value('backupMailAddress');
        push(@backupParams, 'backupMailAddress' => $backupMailAddress);

        my $backupMailSubject = $settings->value('backupMailSubject');
        $backupMailSubject =~ s/\{IP\}/$extIP/g;
        $backupMailSubject =~ s/\{PORT\}/$port/g;
        push(@backupParams, 'backupMailSubject' => $backupMailSubject);

        my $backupMailBody = $settings->value('backupMailBody');
        # my $backupMailBody = "Zentyal backup (DLLL-CIAS Router) from {IP}";
        # my $IP = "192.168.11.101";
        
        # print $backupMailBody;
        $backupMailBody =~ s/\{DATE\}/$date/g;
        $backupMailBody =~ s/\{IP\}/$extIP/g;
        $backupMailBody =~ s/\{PORT\}/$port/g;
        push(@backupParams, 'backupMailBody' => $backupMailBody);
        
        push(@backupParams, 'backupLimit' => $settings->value('backupLimit'));
        $self->parentModule()->writeConfFile(
            '/root/dlllciasrouter/backup-zentyal.sh',
            "dlllciasrouter/backup-zentyal.sh.mas",
            \@backupParams,
            { uid => '0', gid => '0', mode => '777' }   #這邊權限必須是7才能執行
        );

        # -------------------------------------

        my @startupParams = ();

        push(@startupParams, 'mailAddress' => $backupMailAddress);

        my $startupMailSubject = $settings->value('startupMailSubject');
        $startupMailSubject =~ s/\{IP\}/$extIP/g;
        $startupMailSubject =~ s/\{PORT\}/$port/g;
        push(@startupParams, 'mailSubject' => $startupMailSubject);

        my $startupMailBody = $settings->value('startupMailBody');
        $startupMailBody =~ s/\{DATE\}/$date/g;
        $startupMailBody =~ s/\{IP\}/$extIP/g;
        $startupMailBody =~ s/\{PORT\}/$port/g;
        my $veDomainName = $self->getLoadLibrary('VEServerSetting')->value("domainName");
        if( length $veDomainName ) {
          $startupMailBody =~ s/\{VEDomainName\}/$veDomainName/g;
        }

        push(@startupParams, 'mailBody' => $startupMailBody);

        $self->parentModule()->writeConfFile(
            '/root/dlllciasrouter/startup-message.sh',
            "dlllciasrouter/startup-message.sh.mas",
            \@startupParams,
            { uid => '0', gid => '0', mode => '777' }   #這邊權限必須是7才能執行
        );
    #}  # if (-e '/etc/crontab') {
}

# -----------------------------------------------

1;
