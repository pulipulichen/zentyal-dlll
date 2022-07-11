package EBox::dlllciasrouter::Model::LibraryStorage;

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
# Date Setter


# 20150527 Pulipuli Chen
sub initMooseFS
{
    # 暫時不使用了 20220711-2030 
    return 0;


    my ($self) = @_;

    my @params = ();
    $self->parentModule()->writeConfFileOnce(
        '/var/lib/mfs/metadata.mfs',
        "dlllciasrouter/mfs/lib/metadata.mfs.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    # 變更權限 
    system('chown mfs:mfs  /var/lib/mfs/metadata.mfs');

    # ---------------------------------------------------------

    #$self->parentModule()->writeConfFile(
    #    '/etc/default/moosefs-cgiserv',
    #    "dlllciasrouter/mfs/default/moosefs-cgiserv.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);
    #$self->parentModule()->writeConfFile(
    #    '/etc/default/moosefs-chunkserver',
    #    "dlllciasrouter/mfs/default/moosefs-chunkserver.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);
    #$self->parentModule()->writeConfFile(
    #    '/etc/default/moosefs-master',
    #    "dlllciasrouter/mfs/default/moosefs-master.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);
    #$self->parentModule()->writeConfFile(
    #    '/etc/default/moosefs-metalogger',
    #    "dlllciasrouter/mfs/default/moosefs-metalogger.mas",
    #    \@params,
    #    { uid => '0', gid => '0', mode => '644' }
    #);

    # --------------------------------------------

    $self->parentModule()->writeConfFileOnce(
        '/etc/mfs/mfschunkserver.cfg',
        "dlllciasrouter/mfs/etc/mfschunkserver.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->parentModule()->writeConfFileOnce(
        '/etc/mfs/mfsmaster.cfg',
        "dlllciasrouter/mfs/etc/mfsmaster.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->parentModule()->writeConfFileOnce(
        '/etc/mfs/mfsmetalogger.cfg',
        "dlllciasrouter/mfs/etc/mfsmetalogger.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->parentModule()->writeConfFileOnce(
        '/etc/mfs/mfsmount.cfg',
        "dlllciasrouter/mfs/etc/mfsmount.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
    $self->parentModule()->writeConfFileOnce(
        '/etc/mfs/mfstopology.cfg',
        "dlllciasrouter/mfs/etc/mfstopology.cfg.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    if (! -e '/etc/mfs/mfsexports.cfg') {
        my @mfsParams = ();
        $self->parentModule()->writeConfFileOnce(
            '/etc/mfs/mfsexports.cfg',
            "dlllciasrouter/mfs/etc/mfsexports.cfg.mas",
            \@mfsParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }

    if (! -e '/etc/exports') {
        my @nfsParams = ();
        push(@nfsParams, 'paths' => []);
        
        $self->parentModule()->writeConfFileOnce(
            '/etc/exports',
            "dlllciasrouter/nfs-server/exports.mas",
            \@nfsParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }

    if (! -e '/etc/mfs/mfshdd.cfg') {
        my @hddParams = ();
        my $mfsMod = $self->getLoadLibrary("MfsSetting");
        push(@hddParams, 'size' => $mfsMod->value("localhostSize"));
        push(@hddParams, 'paths' => []);
        $self->parentModule()->writeConfFileOnce(
            '/etc/mfs/mfshdd.cfg',
            "dlllciasrouter/mfs/etc/mfshdd.cfg.mas",
            \@hddParams,
            { uid => '0', gid => '0', mode => '644' }
        );
    }
}

# 20150529 Pulipuli Chen
sub startMooseFS
{    
    # 暫時不使用了 20220711-2030 
    return 0;

    my ($self) = @_;

    # mfsEnable
    my $mfsMod = $self->getLoadLibrary("MfsSetting");
    if ($mfsMod->value("mfsEnable") == 0) {
      return 0;
    }

    try {
        if (readpipe("sudo netstat -plnt | grep '/mfsmaster'") eq "") {
            system('sudo service moosefs-master start');
            system('sudo service moosefs-metalogger start');
        }
        if (readpipe("sudo netstat -plnt | grep '/mfschunkserve'") eq "") {
            system('sudo service moosefs-chunkserver start');
            #system("echo 'chunkserver start a'");
        }
        if (readpipe("sudo netstat -plnt | grep ':9425'") eq "") {
            system('sudo service moosefs-cgiserv start');
        }
        if (readpipe("sudo netstat -plnt | grep '/mfsmount'") eq "") {
            system('sudo mfsmount');
        }
    } catch {
        $self->getLoadLibrary("LibraryToolkit")->show_exceptions($_ . '( dlllciasrouter->startMooseFS() )');
    };
}

# 20150528 Pulipuli Chen
sub initNFSServer
{
    
    my ($self) = @_;

    my @params = ();

    $self->parentModule()->writeConfFile(
        '/etc/default/nfs-kernel-server',
        "dlllciasrouter/nfs-server/nfs-kernel-server.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );

    $self->parentModule()->writeConfFile(
        '/etc/default/nfs-common',
        "dlllciasrouter/nfs-server/nfs-common.mas",
        \@params,
        { uid => '0', gid => '0', mode => '644' }
    );
}

# 20150529 Pulipuli Chen
sub startNFSServer
{
    my ($self) = @_;
    my $mod = $self->getLoadLibrary('StorageServer');
    if ($mod->size() == 0) {
        return 0;
    }

    if (readpipe("sudo netstat -plnt | grep '/rpc.mountd'") eq "") {
        system('sudo service nfs-kernel-server start');
    }
}

# 20150528 Pulipuli Chen
sub initNFSClient
{
    my ($self) = @_;

    if (! -e '/opt/mfschunkservers/nfs-mount.sh') {
        my @mountParams = ();
        push(@mountParams, 'servers' => []);
        $self->parentModule()->writeConfFileOnce(
            '/opt/mfschunkservers/nfs-mount.sh',
            "dlllciasrouter/nfs-client/nfs-mount.sh.mas",
            \@mountParams,
            { uid => '0', gid => '0', mode => '755' }
        );
    }

    my @params = ();
    $self->parentModule()->writeConfFileOnce(
        '/opt/mfschunkservers/nfs-umount.sh',
        "dlllciasrouter/nfs-client/nfs-umount.sh.mas",
        \@params,
        { uid => '0', gid => '0', mode => '755' }
    );

    $self->parentModule()->writeConfFileOnce(
        '/opt/mfschunkservers/mfs-clear-metaid.sh',
        "dlllciasrouter/nfs-client/mfs-clear-metaid.sh.mas",
        \@params,
        { uid => '0', gid => '0', mode => '755' }
    );
}


##
# 20150528 Pulipuli Chen
# 把NFS掛載到本機伺服器上
##
sub updateNFSExports
{
    # 從這邊取得資料出來
    #my $expMod = $self->getLoadLibrary("ExportSettings");
    my ($self) = @_;

    my $mod = $self->getLoadLibrary("ExportsSetting");

    my $dirs = ();
    # 第一次迴圈，先取出資料出來
    for my $id (@{$mod->ids()}) {
        my $row = $mod->row($id);

        # /mnt/mfs/pve 10.6.0.0/24(rw,fsid=0,async,no_root_squash,subtree_check)
        my $host = $row->valueByName("host");
        my $ro = $row->valueByName("readOnly");
        if ($ro == 1) {
            $ro = "ro";
        }
        else {
            $ro = "rw";
        }
        my $async = $row->valueByName("async");
        if ($async == 1) {
            $async = "async";
        }
        else {
            $async = "sync";
        }
        my $squash = $row->valueByName("squash");
        
        my $hostConfig = $host."(".$ro.",fsid=0,".$async.",".$squash.",subtree_check".")\t";

        # ---------------------

        my $dir = $row->valueByName("dir");
        my $dirPath = "/mnt/mfs/".$dir;

        if (! -d $dirPath) {
            system('sudo mkdir -p ' . $dirPath);
        }

        if ( ! exists $dirs->{$dir} ) {
            $dirs->{$dir} = $dirPath."\t";
        }
        $dirs->{$dir} = $dirs->{$dir} . $hostConfig;
    }

    my @paths = [];    # 稍後要從StorageServer取出細節
    my $i = 0;
    # 第二次迴圈
    while (my ($dir, $path) = each(%$dirs)) {
        $paths[$i] = $path;
        $i++;
    }
    
    my $pveDirPath = "/mnt/mfs/pve";
    if (! -d $pveDirPath) {
        system('sudo mkdir -p ' . $pveDirPath);
    }

    my @nfsParams = ();
    # 從這邊取得資料出來
    #my $expMod = $self->getLoadLibrary("ExportSettings");
    push(@nfsParams, 'paths' => @paths);
    #push(@nfsParams, 'paths' => []);
    
    my $nfsChanged = $self->parentModule()->checkConfigChange(
        '/etc/exports',
        "dlllciasrouter/nfs-server/exports.mas",
        \@nfsParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    # 20150529 本來是要修改的……後來還是算了吧
    my @mfsParams = ();
    my $mfsChanged = $self->parentModule()->checkConfigChange(
        '/etc/mfs/mfsexports.cfg',
        "dlllciasrouter/mfs/etc/mfsexports.cfg.mas",
        \@mfsParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    return ($nfsChanged == 1 || $mfsChanged == 1 );
}

##
# 20150528 Pulipuli Chen
##
sub updateMountServers
{
    my ($self) = @_;

    #system('sudo /opt/mfschunkservers/nfs-umount.sh');

    my @servers = [];    # 稍後要從StorageServer取出細節
    my @paths = [];    # 稍後要從StorageServer取出細節
    my $i = 0;
    my $mod = $self->getLibrary('StorageServer');
    for my $id (@{$mod->ids()}) {
        my $row = $mod->row($id);

        if ($row->valueByName("mountEnable") == 0 || !defined($row->valueByName("mountPath")) ) {
            next;
        }

        my $ipaddr = $row->valueByName("ipaddr");
        my $type = $row->valueByName("mountType");
        my $option = $row->valueByName("mountPath");
        if ($type eq "cifs") {
            my $username = $row->valueByName("cifsUsername");
            my $password = $row->valueByName("cifsPassword");
            $option = 'username="'.$username.'",password="'.$password.'" //' . $ipaddr . $option;
        }
        elsif ($type eq "nfs") {
            $option = $ipaddr . ":" . $option;
        }
        
        # 如果沒有目錄，則新增目錄
        my $path = "/opt/mfschunkservers/" . $ipaddr;
        if (!-d $path) {
            system('sudo mkdir -p ' . $path);
            system('sudo chown mfs:mfs ' . $path);
        }
        my $mfsPath = $path . "/mfs";

        # mount -t cifs -o username="Username",password="Password" //10.6.1.1/mnt/smb /opt/mfschunkservers/10.6.1.1
        my $conf = "mount -t " . $type . " " . $option . " " . $path;
        $servers[$i] = $conf;
        $paths[$i] = $mfsPath;

        # 此處進行掛載
        system('sudo ' + $conf + " &");
        
        my $isMounted = readpipe("mountpoint " . $path); #10.6.1.1 is not a mountpoint
        # 建立掛載後的路徑 
        if ($isMounted eq $path . " is a mountpoint" && !-d $mfsPath) {
            system('sudo mkdir -p ' . $mfsPath);
            system('sudo chown mfs:mfs ' . $mfsPath);
        }

        $i++;
    }   # for my $id (@{$mod->ids()}) {}

    # -----------------------------------

    my $mountChanged = 0;

    my @mountParams = ();
    push(@mountParams, 'servers' => @servers);

    
    #$self->parentModule()->writeConfFile(
    my $nfsmountChanged = $self->parentModule()->checkConfigChange(
        '/opt/mfschunkservers/nfs-mount.sh',
        "dlllciasrouter/nfs-client/nfs-mount.sh.mas",
        \@mountParams,
        { uid => '0', gid => '0', mode => '755' }
    );

    system('sudo /opt/mfschunkservers/nfs-mount.sh');

    # -------------------------------------

    my @hddParams = ();
    my $mfsMod = $self->getLoadLibrary("MfsSetting");
    push(@hddParams, 'size' => $mfsMod->value("localhostSize"));
    push(@hddParams, 'paths' => @paths);

    
    #$self->parentModule()->writeConfFile(
    my $mfshddChanged = $self->parentModule()->checkConfigChange(
        '/etc/mfs/mfshdd.cfg',
        "dlllciasrouter/mfs/etc/mfshdd.cfg.mas",
        \@hddParams,
        { uid => '0', gid => '0', mode => '644' }
    );

    if ($nfsmountChanged == 1 || $mfshddChanged == 1) {
        $mountChanged = 1;
    }

    return $mountChanged;
    #system('sudo mfsmount');
}

# 20150528 Pulipuli Chen
sub restartMooseFS
{
    # 暫時不使用了 20220711-2030 
    return 0;

    system('sudo service moosefs-master restart');
    system('sudo service moosefs-metalogger restart');
    system('sudo service moosefs-cgiserv restart');
}

# 20150528 Pulipuli Chen
sub remountChunkserver
{
    system('sudo service moosefs-chunkserver stop');
    system('sudo /opt/mfschunkservers/nfs-umount.sh');
    #system('sudo /opt/mfschunkservers/nfs-mount.sh');
    system('sudo service moosefs-chunkserver start');
    #system("echo 'chunkserver start b'");
    if (readpipe("sudo netstat -plnt | grep '/mfschunkserve'") eq "") {
        # 修復後重新掛載
        system('sudo /opt/mfschunkservers/mfs-clear-metaid.sh');
        
        system('sudo service moosefs-chunkserver start');
        #system("echo 'chunkserver start c'");
    }
    system('sudo mfsmount');
}

# 20150528 Pulipuli Chen
sub restartNFSServer
{
    my ($self) = @_;
    my $mod = $self->getLoadLibrary('StorageServer');
    if ($mod->size() == 0) {
        return 0;
    }

    #system('sudo service nfs-kernel-server restart');
    system('sudo exportfs -ar');
}

# 20150528 Pulipuli Chen
sub stopMount
{
    system('sudo service nfs-kernel-server stop');

    system('sudo service moosefs-cgiserv stop');
    system('sudo service moosefs-chunkserver stop');
    system('sudo service moosefs-master stop');
    system('sudo service moosefs-metalogger stop');
    system('sudo umount /mnt/mfs');

    system('sudo service moosefs-chunkserver stop');
    system('sudo /opt/mfschunkservers/nfs-umount.sh');
}

1;
