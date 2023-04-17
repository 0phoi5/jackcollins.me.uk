---
author:
  name: "Jack Collins"
title: "RPM / Yum - Fatal Error, run database recovery"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-04-17T12:31:14+01:00
draft: false
toc: false
images:
tags:
  - linux
  - error resolution
---

## Scenario

When running ```yum clean all```, or ```yum update```, you get an error similar to the following;

```
error: rpmdb: BDB0113 Thread/process #/# failed: BDB1507 Thread died in Berkley DB library
error: db5 error(-30973) from dbenv->failchk BDB0087 DB_RUNRECOVERY: Fatal error, run database recovery
error: cannot open Packages database in /var/lib/rpm
CRITICAL:yum.main:
Error: rpmdb open failed
```
---

## Resolution

Firstly, try clearing the yum cache and then rebuilding it, via;

```
sudo rm -rf /var/cache/yum/*
sudo yum makecache
```

If that doesn't resolve, kill all yum related processes, delete the cache and all metadata, and rebuild;
```
sudo killall -9 yum
sudo rm -rf /var/cache/yum
sudo rm -rf /var/lib/rpm/__db*
sudo rpm --rebuilddb
sudo yum makecache
```

---

[Top of page](#top)