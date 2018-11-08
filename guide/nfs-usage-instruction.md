Zentyal NFS Usage
====

## Proxmox Virtual Environment 3.4 ##

1. **Add NFS Server**: Datacenter > Stroage > Add > NFS<br />
![](https://lh3.googleusercontent.com/-By60MPJhEIw/W-PcmpTGiUI/AAAAAAAD6U0/mTDizZhHzJUlVg6HIgbfGyD6VnOLnybIQCHMYCw/s0/2018-11-08_14-48-41.png)

2. **Add: NFS**
	* ID: zentyal
	* Server: 10.0.0.254
	* Export: /mnt/mfs/pve
	* Content: Disk image, ISO image, OpenVZ template, VZDump backup file 

![](https://lh3.googleusercontent.com/-OtGGXQP72vU/W-Pc1a3sRPI/AAAAAAAD6U4/T8T87pvDQJEZexfbCH5SGpHtR5z0HorwQCHMYCw/s0/2018-11-08_144533%2B-%2BCopy.png)


----------

## Ubuntu Linux command ##

Premission: Only servers under 10.6.0.0/24 can mount Zentyal's NFS server.

````
[root@pve ~]# vim /etc/fstab
10.0.0.254:/mnt/mfs/pve /local/path/to/mount nfs nosuid,noexec,nodev,rw,bg,soft   0   0
[root@pve ~]# mount -a
````