---
author:
  name: "Jack Collins"
title: "Amazon Workspaces on RHEL based distros"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-02-23T20:06:30+01:00
draft: false
toc: false
images:
tags:
  - linux
  - aws
  - rhel
  - github
---

Amazon Workspaces is a brilliant offering by AWS to allow users access to Windows 10 (or Amazon Linux) based Virtual Machines in the cloud, from anywhere in the world.
Unlike EC2, it much more easily scales up for companies to allow remote and cloud based, Active-Directory integrated fleets of VMs for employees. However we can also use it on an individual scale to give access to a true Windows 10 box (not Windows server 2019) from anywhere in the World, without the need for using local CPU, RAM and disk resources for the VM. Certainly handy for Pentesting, especially when you use Linux as your OS of choice and a T430 laptop that can handle about as many VMs as I've had dates with Samantha Mumba.

To access these VMs, there are many options, including using any web browser. Sounds good, right? Well, not so much; after playing about with Workspaces myself, I found the browser access to be too laggy and often it left weird artifacts on the screen. Fine for a quick in-and-out to fix an issue with a server, remotely, from anywhere I might happen to be. Not so great for longer-term use.

Enter Amazon's other options for accessing their Workspaces VMs; The Amazon Workspaces Application. It's available for Windows, Mac, even Android and ChromeOS. But the Linux offering, as of March 2021, is for Ubuntu only, a .deb package. No good to me, an avid bare-metal Fedora user! I need an rpm, and one that works.

---

[Get my GitHub script for applying the solution automatically](https://github.com/0phoi5/fedora_workspaces)

---

## The Solution

Alien! No, really.

The following has been tested in March 2021, using Fedora release 33 and workspacesclient.x86_64 v3.1.3.925-2

We can actually start with Amazon's .deb package for Workspaces. You can grab it here.
Ignore the instructions around setting up a repo, click the direct download link to download the .deb package instead.

If you don't already have them, install alien and rpmrebuild

```
sudo yum install alien rpmrebuild
```

Run the following to convert the .deb package you downloaded to a .rpm

```
sudo alien --to-rpm workspacesclient_amd64.deb
```

The created rpm will contain an error that will currently prevent it from installing; namely that it tries to modify the / directory and that isn't allowed. To fix this, run;

```
rpmrebuild --package --edit-spec workspacesclient-*.x86_64.rpm
```

Delete the following line from the opened rpm, then save;

```
%dir %attr(0755, root, root) "/"
```

Now install the rpm, noting that the output location for the newly amended rpm is different, so use the path below;

```
sudo rpm --install /home/[USER]/rpmbuild/RPMS/x86_64/workspacesclient-*.x86_64.rpm
```

And hey presto! You should hopefully now have a working version of Amazon Workspaces installed.

The only downside to this method is that, as we're not installing Amazon's Ubuntu repo, you will need to manually upgrade the application going forwards. Hopefully Amazon will add Red Hat support one day. At least it's an easy process!