---
author:
  name: "Jack Collins"
title: "Using AWS Lambda to automate EBS snapshot deletion"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-04-18T11:34:11+01:00
draft: true
toc: false
images:
tags:
  - aws
---

- [Scenario](#scenario)
- [Create an IAM Role](#iam)

---

## Scenario{#scenario}

- You have multiple AWS accounts with a root account overseeing them
- The account user's and/or automation reguarly take EBS Snapshots, but they are not being cleared down (AWS Images have an expiry on them, EBS Snapshots do not).
- You want an automated way of keeping Snapshots older than X cleared down, to save on storage space and therefore money.

This would also work for a single AWS account, but you will need to amend the code and config to not require an Assume Role.

---

## Create an IAM Role{#iam}

1. 

---

## []

[Top of page](#top)