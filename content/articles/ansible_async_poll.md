---
author:
  name: "Jack Collins"
title: "Ansible asynchronous actions and polling"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2023-04-23T16:41:40+01:00
draft: false
toc: false
images:
tags:
  - ansible
  - cheatsheet
---

Ansible will normally run Tasks synchronously, keeping a connection open for the entire time a Task runs.  
If we have an especially long running task, for example an apt upgrade/dnf update or a long-running shell script, it may be better to close the connection and then re-establish it every now and then to see if the task has completed.

We might not want connections to stay open for a few reasons;
- the Task might run for longer than the configured SSH timeout on the server, in which case the Ansible Task would fail when the connection gets dropped
- we may have many other Tasks to run in the Playbook, and we don't want to wait for one of them to run for a long time before continuing, but we still want to check it's outcome
- if the Playbook has a Serial of a high number of servers, we may not want to keep the connection open for a Task to all of them simultaneously, for a long period, because of local or network resources

This is where something called "Asynchronous actions and polling" comes in to play, or Async / Poll.

Async / Poll is a way for Ansible to run a Task on a remote server, but then immediately close the connection rather than waiting for the Task to complete.   
After a given period of time, Ansible will re-establish a connection and check whether the Task has completed. If not, it will close the connection again, wait, and then re-establish and confirm if the Task completed. We can do this as many times as we want, for as long as we want.

---

We can use Async / Poll against any Ansible task. In this example, we're using the Shell module.

```
- name: "Running a command"
  shell:
    cmd: ls -l
  async: 1920
  poll: 0
  register: command_sleeper
```

- **async** sets the maximum amount of time in seconds that a task can run asynchronously before it is considered to have failed
- **poll** sets the interval, in seconds, at which Ansible should check the status of an asynchronous task. Setting it to 0 (zero) means that Ansible will not check the status of the asynchronous task during its execution. This can be useful in situations where you want to submit a long-running Task in the background without waiting for it to complete, and you don't need to know its status until later.
- **register** is used so that we can refer back to this Task in the next step

After creating the Task with an Async and Poll, we then need to create a second Task to query whether the first has completed.  
Ansible uses async_status for this purpose.

```
- name: "Waiting for command to complete"
  async_status:
    jid: "{{ command_sleeper.ansible_job_id }}"
  register: job_result
  until: job_result.finished
  retries: 60
  delay: 30
```

- **jid** retrieves the Job ID from the first Task, which is stored in the registered output we named "command_sleeper"
- we **register** again, this time so that the job_result can be queried from within the same Task
- **delay** is the number of seconds to wait between re-connects. As explained above, Asynchronous actions and polling means that the connection is not kept open whilst a long-running Task completes, this is the number of seconds between those re-connects when we check whether the task has completed.
- **retries** is the number of times to retry the connection and see if our previous Task completed. In this case, we'll be retrying 60 times, with a delay of 30 seconds, so a total of 30 minutes before the Task fails

***Note***: you don't have to run these two Tasks in sequence. It's possible to run the first Task, creating the async, poll and command_sleeper, and then run a load of other Tasks before we then come back to async_status.  
In this way, we can save a *lot* of time in some Playbooks; a very long running command, that we don't necessarily need to know the outcome of immediately, can continue to run whilst our Playbook does other things, then we can simply check back on it later in the Play. Nice.

---

[Ansible official documentation on Async / Poll](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_async.html)

---

[Top of page](#top)