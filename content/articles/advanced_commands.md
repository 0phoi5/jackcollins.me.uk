---
author:
  name: "Jack Collins"
title: "Some useful commands for Linux administration"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2025-05-16T12:28:00+01:00
draft: false
toc: false
images:
tags:
  - linux
  - cheatsheet
---

I will update this page as I come across more interesting and less-known commands for Linux Administration, for my and your reference.

---

## Resource Management

View the CPU load of a specific process only  
`top -p $(pgrep -d, appserver)`

Limit the CPU usage of a process to 25%  
`cpulimit -e backup.sh -l 25`

Migrate a running process to a different CPU core without restarting it  
`taskset -p 2 <PID>`

Bind a process to specific CPU cores  
`taskset -c 0,2 <app>`

Check which NUMA (Non-Uniform Memory Access) nodes a process is using  
`cat /proc/<PID>/numa_maps`

Show processes actively using I/O and their real-time disk I/O usage  
`iotop -o`

---

## Storage Management

Unlock and mount a LUKS-encrypted partition  
`cryptsetup luksOpen /dev/sdb1 secure_data && mount /dev/mapper/secure_data /mnt/secure`

Unmount and close/re-lock a LUKS-encrypted partition  
`umount /mnt/secure && cryptsetup luksClose secure_data`

Create a RAID 5 array using 3x specified disks  
`mdadm --create --level=5 --raid-devices=3 /dev/md0 /dev/sdb /dev/sdc /dev/sdd`

---

## Networking

Set up a static route so that all traffic to a specific IP goes through a specific network interface  
`ip route add 192.168.2.0/24 dev eth1`

Execute a self-test on a NIC  
`ethtool -t eth0`

---

## Text Manipulation

Make the first 'column' of a file lowercase, leave the rest as-is  
`awk -F'\t' 'BEGIN{OFS=FS} {$1=tolower($1); print}' input.txt`

---

[Top of page](#top)