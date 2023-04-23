---
author:
  name: "Jack Collins"
title: "Automating AWS AMI Image Snapshots from CLI / Ansible"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-04-19T10:43:25+01:00
draft: true
toc: false
images:
  - "images/profile_pic.png"
tags:
  - aws
  - ansible
  - linux
---

## Scenario

You have a requirement to take AMI Image backups/snapshots, but want to automate them rather than have to go manually in to the AWS GUI.  
For example, during patching of servers via Ansible, it would be nice to add a task to quickly take a backup of each EC2 server before it's patched.

---

## Resolution

For this, you'll want to use AWS CLI, as well as set up IAM access to be able to run it.

1. 

---

[Top of page](#top)