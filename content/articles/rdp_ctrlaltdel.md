---
author:
  name: "Jack Collins"
title: "Getting to the CTRL+ALT+DEL menu within multiple nested RDP sessions"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2026-07-15T08:00:00+01:00
draft: false
toc: false
images:
tags:
  - windows
---
Just a short article today, but hopefully a useful one.

If you have multiple nested RDP sessions, CTRL+ALT+DEL and CTRL+ALT+END won't be sufficient to open the menu in order to reset your password, etc.  
On-screen keyboard might be useful via typing *osk.exe* in to the start menu, but that didn't work for me either.  
What did work is to create a desktop shortcut to the following location, within the nested RDP session;  
`𝗖:\𝗪𝗶𝗻𝗱𝗼𝘄𝘀\𝗲𝘅𝗽𝗹𝗼𝗿𝗲𝗿.𝗲𝘅𝗲 𝘀𝗵𝗲𝗹𝗹:::{𝟮𝟱𝟱𝟵𝗮𝟭𝗳𝟮-𝟮𝟭𝗱𝟳-𝟭𝟭𝗱𝟰-𝗯𝗱𝗮𝗳-𝟬𝟬𝗰𝟬𝟰𝗳𝟲𝟬𝗯𝟵𝗳𝟬}`
Opening that then got the CTRL+ALT+DEL menu open, where I could reset my password.

---

[Top of page](#top)