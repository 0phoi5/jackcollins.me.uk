---
author:
  name: "Jack Collins"
title: "Huge Pages on Red Hat Linux"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-04-14T10:32:22+01:00
draft: false
toc: false
images:
tags:
  - rhel
---

- [What are Huge Pages?](#intro)
- [Checking the current status of Huge Pages](#status)
- [How do I amend Huge Pages on a RHEL server?](#amend)
- [Calculating Huge Pages](#calc)
- [Miscellaneous notes on Huge Pages](#notes)

---

## What are Huge Pages?{#intro}

Systems with large amounts of RAM may mean Huge Pages need to be implemented.

Each process has several physical memory segments allocated. To keep them all ‘tidy’ and as near to each other as possible, to keep the system running as fast as possible, the system builds a ‘memory map’, a table, to organise the memory segments. This ‘table’ is typically called the **Translation Lookaside Buffer** table.

The Translation Lookaside Buffer table is limited in size, meaning that if it gets full, we end up in a situation where swapping is required, with processes sharing Memory back and forth, slowing everything down considerably.

Each process will have it’s own **PageTable**, to map it’s virtual memory requirements on to physical memory.

Each **PageTable Entry** (PTE) is around 8 bytes on 64 bit systems, which is quite low. Given that the Translation Lookaside Buffer table is limited in how many PTEs it can handle, we want the PTEs to be as big as possible, else we’ll end up with that swapping situation mentioned above. Enter ‘Huge Pages’.

---

## Checking the current status of Huge Pages{#status}

```sysctl -a | grep vm.nr_hugepages``` will tell you the currently allocated number of Huge Pages on the system.  
If the value is zero, then Huge Pages are disabled.

The current size of Huge Pages can be confirmed via ```grep Hugepagesize /proc/meminfo```

---

## How do I amend Huge Pages on a RHEL server?{#amend}

To amend Huge Pages, you'll need to edit ***/etc/sysctl.conf***, or create/amend a conf file in ***/etc/sysctl.d/***, such as /etc/sysctl.conf/hugepages.conf.  
Note that the 'modern' way of doing it is via sysctl.d files, using sysctl.conf is relevant on older systems but is now deprecated.

Amend the line ```vm.nr_hugepages = #```, where the hash is the number of Huge Pages to apply.  
After amendment, refresh Kernel parameters using ```sysctl -p```.

A reboot is not mandatory, but highly recommended, since the provided amount of memory must be correctly reserved by the kernel.

---

## Calculating how many Huge Pages should be allocated{#calc}

Huge Page allocation should be calulated based on application(s) RAM requirements; one way to calculate the number of Huge Pages required on a Linux box is to divide the working set of an application (the amount of active RAM it needs) by the size of each Huge Page. If more than one major application runs on a box, use the total working set for all of them in the calculation.  
For example, if the working set of an application on the Linux box is 12GB, and the size of each Huge Page is 2MB (grep Hugepagesize /proc/meminfo), then we can calculate ***12GB / 2MB = 6000***  
We should also add a small amount as a buffer, for example ***6000 * 1.005 = 6030***

For systems with an Oracle Database, we could find the total size of the System Global Area (SGA) via ```SELECT sum(value)/1024/1024 "TOTAL SGA (MB)" FROM v$sga;```, then calculate ***System Global Area (SGA) size (in MB) / 2MB * 1.005***

---

## Miscellaneous notes on Huge Pages{#notes}

- Oracle Automatic Memory Management (AMM) is incompatible with HugePages (not really done any more, AMM is an old concept).  
If AMM is used, you will see /dev/shm, which is used by Oracle AMM to store shared memory pages.  
/dev/shm is automatically set to 50% of RAM.
- Transparent HugePages (THP) do not work well with Oracle.
- The default Memory Page Size on Red Hat is 4KB. This doesn’t work well for Oracle systems.
- The recommended HugePages size for Oracle database servers is 2MB.
- It’s recommended that HugePages be used if a system has more than 4GB of RAM
- The hugeadm utility, provided by package **libhugetlbfs-utils** can also be used to display and configure a systems huge page pools.

Huge Pages are a lot more in-depth and have a lot more configuration considerations and options available than listed here. You can find out more information about configuring Huge Pages via [Red Hat's own site](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/configuring-huge-pages_monitoring-and-managing-system-status-and-performance)

---

[Top of page](#top)