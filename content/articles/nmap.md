---
author:
  name: "Jack Collins"
title: "An overview of Nmap"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-03-02T20:14:52+01:00
draft: false
toc: false
images:
tags:
  - pentesting
  - software
  - cheatsheet
---

- [Background](#background)
- [Usage Examples](#usage)
- [Cheatsheet](#cheatsheet)
- [Official Documentation](#official)
- [Drawbacks](#drawbacks)
- [Similar Tools](#similar)

---

## Background {#background}

Nmap, or 'Network Mapper', was originally conceived in 1997 by Gordon Lyon, included as an article in Phrack Magazine along with it's source code. The community at the time were so impressed with it's early capabilities, it was taken up as a collaberative project by the tech community, and remains so right up until today.

Since it's initial creation, Nmap has gone through many big updates, each adding more capabilities. Nowadays, Nmap is capable of fingerprinting operating systems, recognising services running on ports, running custom scripts and now supports IPv6.

---

## Usage Examples {#usage}

Nmap is an open-source network scanner for discovering hosts on a network and services running on those hosts, by sending various types of network packets and analysing the results that come back.

It can;
- Identify what hosts are on a network and their IP address
- See which ports are open and responding on those hosts
- Detect which version of applications are broadcasting on each of those ports
- Determine which Operating System is installed on a host
- Provide custom scripting capabilities using the Nmap Scripting Engine and the Lua programming language.

These capabilities provide network administrators the ability to audit the security of their devices, spot unrecognised devices connecting to a network, provide automated inventory management and test firewall and port configurations.  
Of course, all of this comes with a cost; Nmap can also be used nefariously by hackers, to recon information about potential targets.

One thing to note, about Nmap scans, is that they can be intrusive; that is, they aren't always silent and they can even cause disruption if too many queries are sprayed at a certain IP/port. For this reason, it should be used with knowledge and caution. Pentesters need to be aware of which scans are easily detectable, which can be researched via the official documentation, linked lower on this page.

Let's look at some example scenarios and commands. To do a simple 'ping sweep' of a network, identifying what hosts are currently up and responding, but without anything further, we can run;

```
nmap -sn 192.168.1.0/24
```

This basic ping sweep can be a useful method for administrators to automate detection of servers on a given network, alerting against unrecognised machines appearing, or simply to monitor server availability. In a home setting, I often use it to discover the IP address of new devices I've added to my 192.168.1 subnet, and to automate alerting of new devices appearing which I may not be expecting.

Let's have a look at something that returns a bit more information;

```
nmap -v -sV -sC 192.168.1.0/24
```

Breaking this command down, we're asking Nmap to;

- give 'level 1' verbose output, useful for seeing the discovery of ports in real time, rather than waiting for a full scan to complete, which can take a while.
- use a non-specific set of Scripts, which uses a default set of Lua scripts with more in-depth capabilities than the default Nmap application has. Although these are often far more intrusive and detectable, they also often give better results when completing Capture The Flag scenarios, for example, although on an actual pentesting scenario, you'd likely want to refrain from just 'spraying and praying' with scripts.
- use Version Detection. Once a TCP/UDP port is discovered, Nmap will attempt to interrogate the port to see what is actually running on it.

The above command might give output similar to the below (-v verbosity removed so it actually fits on the page);

```
kali@somewhere:~$ sudo nmap -sV -sS 192.168.1.0/24
Starting Nmap 7.91 ( https://nmap.org ) at 2021-03-04 16:34 UTC

Nmap scan report for 192.168.1.100
Host is up (0.00075s latency).
Not shown: 994 closed ports
PORT STATE SERVICE VERSION
22/tcp open ssh OpenSSH 4.3 (protocol 2.0)
80/tcp open http Apache httpd 2.2.3 ((CentOS))
111/tcp open rpcbind 2 (rpc #100000)
957/tcp open status 1 (rpc #100024)
3306/tcp open mysql MySQL (unauthorized)
8888/tcp open http lighttpd 1.4.32
MAC Address: 08:00:27:##:##:## (Cadmus Computer Systems)
Service Info: OS: Linux; Device: WAP

Nmap scan report for 192.168.1.200
Host is up (0.013s latency).
All 1000 scanned ports on 192.168.1.200 are closed
MAC Address: B8:27:EB:##:##:## (Raspberry Pi Foundation)

Service detection performed. Please report any incorrect results at https://nmap.org/submit/
Nmap done: 256 IP addresses (2 hosts up) scanned in 60.99 seconds
```

As you can see, just from a quick 1 minute scan of the local subnet, 256 potential IP addresses, we've identified 2 IPs that are responding and at least 1 of them has multiple ports open with various services running. We even have the service versions, which a penetration tester could then use to search for vulnerabilities out on the internet, or via tools such as [Searchsploit](https://www.exploit-db.com/searchsploit).

Whilst the above general scan is good for early endeavours in to Capture The Flag scenarios, we'll want to do incorporate more advanced and targeted scans for advanced CTFs and real-life pentesting scenarios. This may be because we need to avoid detection from Intrusion Prevention, [circumnavigate a firewall](https://nmap.org/book/man-bypass-firewalls-ids.html) or generally just be stealthier. The scan above, with the inclusion of the sC option to use various default scripts, is very 'loud' on a network and can easily be detected. You may even find your IP automatically blocked from sending and receiving further packets.

Let's take a look at a 'stealthy' scan, one that is much less likely to be detected as potentially malicious;

```
nmap -sS -p80 -T1 -f --data-length 55 --spoof-mac 0 192.168.1.100
```

Here, we are;
- running a TCP SYN scan, using sS, which is non obtrusive and stealthy, since it never completes TCP connections
- Scanning port 80 only (don't try and run this really slow scan against more than a couple of ports)
- Using timing template 1, which only scans one port at a time (no parallelism) and sets a minimum of 15 seconds between packets (this can take an extraordinary long time though, so it would be best to narrow a scan using T0-2 down to just a few ports on a singular host)
- Fragment the IP packets sent. This will split up the TCP header over several packets to make it harder for packet filters, IDS and other annoyances to detect what you are doing
- Normally Nmap sends packets that only contain a header. But constant sending of this size of packet can be noted by IDS. So, we bulk out the packets with a little more data, making them look like they contain actual information rather than just being 'empty'
- Randomise our MAC address using option 0 of spoof-mac, or you can specify a specific MAC if you know of devices on a network that would look less suspicious

There are also options such as --randomize-hosts (if you are scanning a large list of IPs/a subnet, randomise the order in which they are scanned to make it slightly less obvious a pattern to IDS and administrators) and --proxies (so that you can proxy your scan, however other parameters may need to be adjusted so that this doesn't time out).  
The 'sneaky' scan above could take a very long time to complete, even up to a few days, but is much 'quieter' on a network. Although, it's important to note that, given modern detection systems, there is no truly silent scan. Most Nmap scan methods can be picked up in some way or another, however that also brings me on to an additional option to obfuscate yourself during pentest reconnaissance, which is also a technique used for other hacking steps such as exploitation; something I like to call 'obfuscation via too much information';

```
nmap -D 192.168.1.2,192.168.1.3,192.168.1.4 192.168.1.100
```

This command will run an nmap scan (with whatever other options you want to give), but will also make it look as though our scan is coming from 3 IP addresses. You'll need to include your own IP/the machine running the nmap scan in the IP range, but many, many IP addresses can be specified. Essentially, this means an administrator/investigator in to your activity wouldn't be able to tell which IP the scan actually came from, out of the list, and would have to investigate them all. Therefore, specifying hundreds of IPs could be worth while if complete anonymity is required (this site does not condone malicious use of nmap).  
Of course, this won't let you circumnavigate IDS or Firewalls, but it could hide your identity. If you don't pass many IP addresses to a target, your singular attack vector will be viewable in log files on target systems (unless you manage to gain access to clear them, but that's another topic for another day).

There are many more options and capabilities within Nmap.  
A cheat-sheet is included below, with examples of most of the remaining options, as well as a link to the official documentation so you can further your own research. Of course, you can also simply do a man Nmap within Linux.

---

## Cheatsheet {#cheatsheet}

```nmap -sn 192.168.1.100```	A simple 'ping scan' of one IP, to see if it's up

```nmap -Pn 192.168.1.100```	Disable host discovery, just scan ports

```nmap 192.168.1.100```	Scan one IP with default nmap settings

```nmap 192.168.1.1-254```	Scan a range of IPs

```nmap 192.168.1.0/24```	Scan a subnet using CIDR notation

```nmap -iL targets.txt```	Scan a list of targets from a file

```nmap -sS 192.168.1.100```	TCP SYN port scan (the default)

```nmap -sT 192.168.1.100```	TCP connect port scan (default non-root scan)

```nmap -sU 192.168.1.100```	UDP port scan

```nmap -sA 192.168.1.100```	TCP ACK port scan

```nmap -sW 192.168.1.100```	TCP Window port scan

```nmap -sM 192.168.1.100```	TCP Maimon port scan

```nmap -sV 192.168.1.100```	Version detection for found services

```nmap -O 192.168.1.100```	OS detection

```nmap -A 192.168.1.100```	OS detection, version detection, script scanning and traceroute

```nmap -sC 192.168.1.100```	Scan with the default NSE scripts

```nmap --script=banner 192.168.1.100```	Scan using a specific NSE script

```nmap -n 192.168.1.0/24```	Don't use DNS resolution

```nmap -PR 192.168.1.0/24```	ARP discovery on local subnet

```nmap -p 80 192.168.1.100```	Scan one port only

```nmap -p 80-1000 192.168.1.100```	Scan a range of ports only

```nmap -p- 192.168.1.100```	Scan all 65,535 available ports (slow)

```nmap -F 192.168.1.100```	Fast scan, look for the most popular 100 ports

```nmap -T3 192.168.1.100```	The default performance and timing profile

```nmap -T2 192.168.1.100```	Polite scan profile, sneakier

```nmap -T4 192.168.100```	Aggressive scan profile, faster but needs a good connection and is louder

```nmap -D 192.168.1.1,192.168.1.2,192.168.1.3 192.168.1.100```	Spoof IPs that a scan originates from. Include your own IP.

```nmap --proxies http://192.168.1.200:8080 192.168.1.100```	Scan via proxies

```nmap -oN output.file 192.168.1.100```	Output scan results to a file, using default format

```nmap -v 192.168.1.100```	Increase verbosity of output. Recommended, as else you have to wait for a full scan to complete in order to see found ports.

---

## Official Documentation {#official}

[Official Documentation - https://nmap.org/docs.html](https://nmap.org/docs.html)

---

## Drawbacks {#drawbacks}

Ironically, one of the major drawbacks of Nmap, for penetration testers, is that it's so popular. Sometimes companies may have monitoring in place that looks for Nmap scans specifically, or at least make a log of scan attempts, however other port scannings tools may fall prey to this as well.  
Nmap scans are always happening, all over the internet, all the time, though. Script Kiddies will regularly scan huge IP ranges looking for vulnerabilities anywhere on the web. So, often, Nmap scans can go overlooked when they are sprayed at an external internet-facing server. However, internally on a network that you may be pentesting against, this activity becomes less of the 'norm' and far more distinguishable, especially if the scans follow a pattern.

Common Port Scan Detectors include [PortSentry](https://sourceforge.net/projects/sentrytools/) and [Scanlogd](https://www.openwall.com/scanlogd/), and there are many Intrusion Detection Systems such as the one included with [Trend Micro](https://www.trendmicro.com/). They work pretty well.

Lastly, there's [Snort](https://www.snort.org/). It's a very popular and open-source Intrusion Prevention System that has the capability of watching for Nmap scans.

---

## Similar Tools {#similar}

#### Zenmap

[Zenmap](https://nmap.org/zenmap/) is the official open-source GUI for Nmap.  
It makes Nmap scanning easier for beginners whilst providing some more advanced features for experienced users. You can save frequently used scans as profiles, output scan data to external files to be viewed later and compare scan results for differences.
It also has, of course, GUI capabilities that make viewing and understanding the layout of larger networks easier, for example in the form of Spider Graphs.

#### Unicornscan

[Unicornscan](http://www.unicornscan.org/) has a TCP/IP stack, a distinguishing feature that sets it apart from other port scanners.
It also allows asynchronous TCP and UDP scanning.  
Scanning can therefore be much quicker with Unicornscan, than with other portscanners, because they use the target’s operating system’s TCP/IP stack.

#### Angry IP Scan

[Angry IP Scan](https://angryip.org/) runs nicely on Linux, Windows, and Mac OS X, with a full GUI a little similar to Zenmap.  
One of the best things about Angry IP Scanner is that it doesn't require installation. It can simply be carried around on a USB stick and used on-the-fly! It's therefore perfect for penetration testers doing in-the-field reconnaissance, or simply administrators that require a portable scanning solution.

#### RustScan

[Rustscan](https://github.com/RustScan/RustScan) actually runs nmap, but enhances it's speed and capabilities. I would highly recommend it!  
When running, RustScan conducts a preliminary scan using its own internal discovery technique: it creates sockets against its targets and waits for their responses.  
Once this first scanning stage is completed it executes a second round using Nmap as the tool with specific tags that, by default, aim to discover the targets’ operating systems.

The adaptive algorithms and initial scanning techniques of Rustscan make it super fast, greatly reducing the time Nmap scans take.

---

[Top of page](#top)