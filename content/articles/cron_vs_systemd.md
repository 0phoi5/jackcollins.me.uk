---
author:
  name: "Jack Collins"
title: "You should use Systemd Timers instead of Cron Jobs"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2023-12-30T09:00:11+01:00
draft: false
toc: false
images:
tags:
  - linux
  - cheatsheet
---

- [What are Cron Jobs?](#whatiscron)
- [What are Systemd Timers?](#whatissystemd)
- [Why use Systemd over Cron?](#why)
- [Systemd Timer Example](#example)

---

## What are Cron Jobs?{#whatiscron}

Cron is a job scheduler that has been around on Unix based operating systems for a long time.  
It is used to run commands or scripts at specific intervals of time, for example backing up a server via a shell script every Thursday at 9pm.

Cron uses something called the *crontab*, or *Command Run On Table*, to store it's jobs, usually located under */var/spool/cron/*. Each user has their own crontab and cron jobs, and the jobs run as that user, with that user's permissions and abilities.

Cron has been around a very long time, and some of it's advantages are that it is available on almost every Unix-based system (Linux being based on Unix) as well as the fact that it is really simple to learn and use.

Cron uses the *crontab* command to **e**dit and **l**ist Cron Jobs;

```
$ crontab -e
```

The format is;
```
* * * * * command
- - - - -
| | | | |
| | | | +----- Day of the week (0-6, Sunday is 0)
| | | +------- Month (1-12)
| | +--------- Day of the month (1-31)
| +----------- Hour (0-23)
+------------- Minute (0-59)
```


```
$ crontab -l

# Run a backup every Thursday at 9pm
0 21 * * 4 /directoy/backup.sh
```

The Cron service will then check the contents of the crontab every minute, running any commands/scripts that are scheduled for the current system time.

You can also have cron jobs run at a specific event taking place, such as after system boot.

On modern Linux systems, there is a better alternative now available that should be considered; Systemd Timers.

---

## What are Systemd Timers?{#whatissystemd}

Systemd timers are similar to cron jobs, in the way that they run specific commands or scripts at set intervals or after specific events take place like system boot.

You're probably already familiar with systemd's administrator-owned (writeable) unit files, stored in */etc/systemd/system*. Well, systemd timers are stored in the same location, with the extension *.timer*.  
You can view all timers that are currently in place using ```systemd status *timer```.

I'll cover the creation of a new systemd timer below.

---

## Why use Systemd over Cron?{#why}

There are a few good reasons to use systemd timers over cron jobs;

1. Systemd timers can be configured in a similar way to unit files; **dependencies can be defined**. This means we can wait for specific conditions to be in place before the timer triggers, such as certain services running.
2. **Failure handling** is available, meaning that if a job fails then we can define conditions for it to be tried again.
3. Systemd timers have **built-in logging**, so we can easily track when a timer last ran and whether it was successful, something not readily available in cron without manually adding to our scripts.
4. **More options** are available, without us having to add them in to scripts called by cron, such as randomised delays and tighter timer accuracy (cron is limited to full minutes only)

There are also a couple of considerations;

1. Cron is widely available on pretty much all Linux distributions. Whilst systemd is available on *most* systems, it may not be available everywhere, especially on older platforms such as HP-UX.
2. Overhead may be something to consider; whilst systemd offers a lot of great new features over cron, if none of them are needed, it may be easier to stick to cron. Although, personally, I can't think of a scenario where proper logging of jobs and decent failure handling wouldn't be a bonus, but maybe not everyone would feel the same.

---

## Systemd Timer Example{#example}

To set up a systemd timer;

1. Create a systemd .service file, for this example */etc/systemd/system/example.service*;

```
[Unit]
Description=Example Timer Service
After=network.target

[Service]
Type=oneshot
ExecStart=/path/to/your/script.sh
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
```

**Type=oneshot** defines that the service should exit before systemd starts follow-up units.  
**Restart=on-failure** ensures that if the service fails, it will be restarted.  
**RestartSec=5** is the time to sleep before restarting.  
**StandardOutput** and **StandardError** define where the service's logs will go. If you stick to *journal* (recommended) then you can view these logs using ```journalctl -u example.service```. This gives you an easy method of seeing when a service last ran and whether it was successful, or if not then give you errors you can work with to resolve issues.

2. Create a .timer file, in this example */etc/systemd/system/example.timer;

```
[Unit]
Description=Example Timer

[Timer]
OnCalendar=*-*-* 00:00:00

[Install]
WantedBy=timers.target
```

**OnCalendar** sets when the timer should trigger. In the above, it triggers daily at midnight.

> **NOTE :** Systemd timers use the same file name between .service and .timer files, to link them up. So *example.timer* would link to *example.service*.

3. If you need a task to run after a specific dependency (e.g., network.target), you can specify that in the **After** option in the service file.

4. After creating both files as above, reload the systemd daemon and enable/start your timer;

```sudo systemctl daemon-reload```  
```sudo systemctl enable example.timer```  
```sudo systemctl start example.timer```

---

[Top of page](#top)