### 一、dos磁盘lvm新增磁盘
#### 1.1、新增dos磁盘分区
```shell
# 查看磁盘
fdisk -l

Disk /dev/sdb: 2147 MB, 2147483648 bytes, 4194304 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sda: 21.5 GB, 21474836480 bytes, 41943040 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0x000cd8ec

   Device Boot      Start         End      Blocks   Id  System
/dev/sda1   *        2048    41943039    20970496   83  Linux

Disk /dev/sdc: 536.9 GB, 536870912000 bytes, 1048576000 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```
#### 1.1、mbr分区
```
fdisk /dev/vdb

Welcome to fdisk (util-linux 2.23.2).

Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table
Building a new DOS disklabel with disk identifier 0xe80f8142.

Command (m for help): n
Partition type:
   p   primary (0 primary, 0 extended, 4 free)
   e   extended
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-1048575999, default 2048): 
Using default value 2048
Last sector, +sectors or +size{K,M,G} (2048-1048575999, default 1048575999): 
Using default value 1048575999
Partition 1 of type Linux and of size 500 GiB is set

Command (m for help): t
Selected partition 1
Hex code (type L to list all codes): 8e
Changed type of partition 'Linux' to 'Linux LVM'

Command (m for help): w
The partition table has been altered!

Calling ioctl() to re-read partition table.
Syncing disks.
```
#### 1.2、gpt分区
```shell
parted /dev/sdb
mklabel gpt
unit TB # 设置单位为TB
mkpart primary 0 3  设置3TB的分区
mkpart primary 0 1396MB 
mkpart primary 0 -1
toggle 1 lvm  # 打上lvm标签
```
#### 1.3、创建lvm
```shell
# 创建pv
> pvcreate /dev/sdc1 
  Physical volume "/dev/sdc1" successfully created
> pvdisplay 
  "/dev/sdc1" is a new physical volume of "500.00 GiB"
  --- NEW Physical volume ---
  PV Name               /dev/sdc1
  VG Name               
  PV Size               500.00 GiB
  Allocatable           NO
  PE Size               0   
  Total PE              0
  Free PE               0
  Allocated PE          0
  PV UUID               tBxBUK-gOTa-bdtK-1kbZ-01KQ-ASwQ-fuIwLi
# 创建vg
> vgcreate VolGroup00 /dev/sdc1 
  Volume group "VolGroup00" successfully created
> vgdisplay 
  --- Volume group ---
  VG Name               VolGroup00
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  1
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                0
  Open LV               0
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               500.00 GiB
  PE Size               4.00 MiB
  Total PE              127999
  Alloc PE / Size       0 / 0   
  Free  PE / Size       127999 / 500.00 GiB
  VG UUID               xjcgUh-oZ1N-Fytd-qGCa-9otf-YV4S-Jpjc7W
# 创建lv
> lvcreate -l 127999 -n lvData VolGroup00
  Logical volume "lvData" created.
> lvdisplay 
  --- Logical volume ---
  LV Path                /dev/VolGroup00/lvData
  LV Name                lvData
  VG Name                VolGroup00
  LV UUID                pVPwru-Eu7W-3lOp-JUKc-qQYF-c3DM-vQ39g1
  LV Write Access        read/write
  LV Creation host, time 3-9, 2016-06-22 15:47:18 +0800
  LV Status              available
  # open                 0
  LV Size                500.00 GiB
  Current LE             127999
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     256
  Block device           253:0
```
#### 1.4、格式化磁盘
```
> mkfs -t xfs /dev/VolGroup00/lvData 
mke2fs 1.42.9 (28-Dec-2013)
Discarding device blocks: done                            
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
32768000 inodes, 131070976 blocks
6553548 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=2279604224
4000 block groups
32768 blocks per group, 32768 fragments per group
8192 inodes per group
Superblock backups stored on blocks: 
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208, 
        4096000, 7962624, 11239424, 20480000, 23887872, 71663616, 78675968, 
        102400000

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (32768 blocks): done
Writing superblocks and filesystem accounting information: done
# 创建挂载目录
mkdir /apps
# 挂载
> mount /dev/VolGroup00/lvData /apps/
> df -h
Filesystem                     Size  Used Avail Use% Mounted on
/dev/sda1                       20G  2.8G   16G  15% /
devtmpfs                       912M     0  912M   0% /dev
tmpfs                          920M     0  920M   0% /dev/shm
tmpfs                          920M  8.4M  912M   1% /run
tmpfs                          920M     0  920M   0% /sys/fs/cgroup
tmpfs                          184M     0  184M   0% /run/user/0
tmpfs                          184M     0  184M   0% /run/user/1000
/dev/mapper/VolGroup00-lvData  493G   73M  467G   1% /apps
```
#### 1.4、lvm扩容
```shell
# 新增分区
fdisk /dev/sdd
# 创建pv
yum install -y lvm2
PV pvcreate /dev/sdd1 && partprob
# 扩展VG
vgextend VolGroup00 /dev/sdd1
# 拓展LV
lvextend -L +59G /dev/VolGroup00/lvData
# 检查LV
e2fsck -f /dev/VolGroup00/lvData  
# 更新文件系统
resize2fs /dev/VolGroup00/lvData # ext文件系统
xfs_growfs /dev/VolGroup00/lvData # xfs文件系统
# 添加开机起启动
1、 查看uuid
blkid
/dev/mapper/files-file1: UUID="f4bc2e98-1c5f-4792-84ed-6ecd5e94ea9b" TYPE="xfs"
2、添加到开机启动
vim /etc/fstab
UUID=f4bc2e98-1c5f-4792-84ed-6ecd5e94ea9b /data xfs defaults 0 0
``` 
#### 1.5、lv缩容
```shell
# 查看挂载
mount
# 卸载lv
umount /dev/centos-home
e2fsck -f /dev/centos-home
# 缩减逻辑边界
resize2fs /dev/centos-home  5G
# 缩减物理边界
lvchange  -a n /dev/centos-home
lvreduce -L 5G /dev/centos-home
lvchange  -a y /dev/centos-home
e2fsck  -f /dev/centos-home
# 挂载
mount /dev/centos-home /home
```