---
author:
  name: "Jack Collins"
title: "An Ansible patching Playbook"
subtitle: "jackcollins.me.uk | Platform Engineer & Linux Admin | UK"
date: 2025-02-03T20:14:48+01:00
draft: false
toc: false
images:
tags:
  - ansible
---

A couple of years ago I completed the *Red Hat Certified Specialist in Ansible Automation* course and then took on full onus of patching 600+ Linux servers, where patching was still being done mostly manually.  
The solution was of course Ansible, and initially I created a large Playbook on the CLI of our administration server, which worked very well but needed a proper CI/CD solution.

Fast forward a few months and I worked alongside colleagues within Platform Engineering to implement my Playbook in to Git and Visual Studio Code, and then further on I was involved with getting the whole thing covered by Ansible Automation Platform (AAP) and Red Hat Satellite, and triggerable via Azure Devops.

One would think that a Playbook for patching would be fairly simplistic (dnf update, reboot?), however there are a lot more stages to patching to be considered;

- Confirming each server has correct configuration for patching
- Checking each server against a 'blacklist'
- Placing servers in Maintenance Mode within monitoring software
- Checking each server for updates and not going ahead with further tasks should no updates be available (conforming to the Integrity and Availability of the CIA Triad)
- Sending wall messages
- Detecting applications that may have issues if the server just reboots, and shutting them down safely
- Taking a server snapshot/backup
- Making sure the servers come back up after reboot
- Logging everything

With all of the above in mind I wrote the following Ansible Playbook, which was then taken up by our business as *the* patching solution for Linux, moved over to Git, and has worked very well ever since.  
It scales nicely, it's easy to maintain and it integrates well in to CI/CD solutions.

**This Playbook is [available on my GitHub](https://github.com/0phoi5/ansible/tree/main/patching_playbook).**


---

## patch.yml

This is the file that triggers the patching, located in the 'root' directory of your Playbook (where the 'roles' directory is also located).

It calls each of the roles within the *roles* directory, in the order shown below.  
Usually the call to each role is a bit simpler than the below syntax, but we're wrapping the whole thing in a *block*, with an *always*, in order to have a summary correctly displayed at the end, so use the same syntax as below if you want that to work.

To run it from the CLI, use `ansible-playbook patch.yml -e "deployment=to_be_patched"`

This particular Playbook works from /ansible/patching/, but you can amend any sections of it that specifically refer to that location, or use relative paths if appropriate.

The -e (--extra-vars) option is used because my inventory file has a group called 'to_be_patched' in it. This allows me to throw in new groups on-the-fly, should I ever need to mop-up a few servers at the end, for example (it saves waiting for the Ansible to do a yum check-update on all servers, every time).

```yaml
---
- name: "PLAY - Preflight / localhost stuff"
  hosts: localhost
  connection: local
  gather_facts: true

  roles:
    - trigger
    - check_deployment_var_defined
    - get_list_of_blacklisted_hosts


- name: "PLAY - Patching"
  hosts: "{{ deployment }}"
  gather_facts: true
  serial: 30

  tasks:
    - block:

      - include_role:
          name: blacklist

      - include_role:
          name: check_everything_configured

      - include_role:
          name: yum_clean_all

      - include_role:
          # This role sets variable "yumoutput.results" to non-zero if patches
          # are available for the server.
          name: check_server_needs_update

      - include_role:
          name: wall
        when: yumoutput.results|length > 0

      - include_role:
          name: place_in_maintenance_mode
        when: yumoutput.results|length > 0

      - include_role:
          name: stop_applications
        when: yumoutput.results|length > 0

      - include_role:
          name: take_snapshot
        when: yumoutput.results|length > 0

      - include_role:
          name: patch
        when: yumoutput.results|length > 0

      - include_role:
          name: reboot
        when: yumoutput.results|length > 0

      - include_role:
          name: yum_clean_all

      - include_role:
          name: post_check
        when: yumoutput.results|length > 0

      - include_role:
          name: remove_snapshot
        when: yumoutput.results|length > 0

      always:
       - import_role:
           name: summary
         delegate_to: localhost

- name: "PLAY - Final Word"
  hosts: localhost
  connection: local
  gather_facts: false

  roles:
    - summary
```

---

## roles/trigger/tasks/main.yml

The whole patching Playbook, and each role's tasks, are wrapped in a block that allows us to send information about the state of the patching to a log file, output.log.

We can then use output.log to see when the patching was run, and for each server how everything went. This first role is simply to start that log off, entering the current time and date to a new line.

```yaml
---
- name: "Adding trigger message to output.log"
  shell:
    cmd: "echo '################ Playbook triggered at {{ ansible_date_time.date }} {{ ansible_date_time.time }} ##############' >> /ansible/patching/output.log
    delegate_to: localhost
```

---

## roles/check_deployment_var_defined/tasks/main.yml

This is just making sure that, as mentioned above, the extra variable 'deployment' is defined, before we continue.

```yaml
---
- fail:
    msg:
      - "You need to define the Deployment type to patch in order to run this Playbook. Please use; ansible-playbook patch.yml -e 'deployment=[FOO]', where FOO is either to_be_patched (for manual patching purposes), or a group defined within the inventory file."
  when: deployment is not defined
  tags:
    - config
```

---

## roles/get_list_of_blacklisted_hosts/tasks/main.yml

This gathers a list of hosts from the file named 'blacklist' and saves it for later reference.

```yaml
---
- name: "Gathering a list of all the hosts in the blacklist file"
  shell: grep -v '^#' /ansible/patching/blacklist
  register: blacklist_output

- name: ""[[[ INFO ]]] - Here is the content of the blacklist file"
  debug:
    msg: "{{ blacklist_output.stdout_lines }}"

- name: "Set list of hosts found in the blacklist file as a fact for later use"
  set_fact: blacklist_hosts="{{ blacklist_output.stdout }}"
```

---

## roles/blacklist/tasks/main.yml

This uses the output fact from the role above to make sure none of the hostnames in the 'inventory' file are mentioned in the file named 'blacklist'.  
If they are, the Playbook will ignore them, with a failure message on-screen and sent to output.log.

```yaml
---
- block:
  - name: "Check that each server is not blacklisted from being patched via Ansible"
    assert:
      that:
        - "'{{ inventory_hostname }}' not in '{{ hostvars['localhost']['blacklist_hosts'] }}'"
      success_msg: "{{ inventory_hostname }} is not blacklisted and can therefore be patched via Ansible."
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Server is blacklisted' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Server {{ inventory_hostname }} is specifically blacklisted, via the 'blacklist' file, from being patched using this Playbook."
```

---

## roles/check_everything_configured/tasks/main.yml

You could add anything you want to here, whatever is appropriate for your environment.  
In my case, I wanted to;

- Make sure any servers being patched were RHEL (anything not RHEL wasn't under our remit to patch)
- Roll some bespoke monitoring files out, making sure the monitoring on all servers was kept aligned alongside patching
- Determine if the server was physical, and not virtual, because we don't want to then try and take a snapshot of it
- Clean up old rescue kernels that were no longer needed (housekeeping)

```yaml
---
- block:
  - name: "Checking server is Red Hat"
    assert:
      that:
        - ansible_distribution == 'RedHat'
      fail_msg: "This server is not RHEL."
      success_msg: "Server is RHEL."
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Server is not Red Hat' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Server {{ inventory_hostname }} is not Red Hat."

- block:
  - name: "Rolling out all Check_MK bespoke scripts and plugins within /usr/lib/check_mk_agent"
    synchronize:
      archive: true
      checksum: true
      recursive: true
      delete: true
      src: /usr/lib/check_mk_agent
      dest: /usr/lib/
      mode: push
      use_ssh_args: true
    tags:
      - config
      - cmk
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to roll out Check_MK bespoke scripts and plugins to /usr/lib/check_mk_agent' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to roll out Check_MK bespoke scripts and plugins to /usr/lib/check_mk_agent, on {{ inventory_hostname }}. Is the Check_MK agent installed?"

- block:
  - name: "Determining whether the server is Virtual or Physical"
    shell: dmidecode -s system-manufacturer | grep -i VMware
    register: server_phys_virt
    changed_when: server_phys_virt.rc == 1
    failed_when: server_phys_virt.rc not in [0,1]
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to determine if the server is physical or virtual, using dmidecode.' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to determine if the server is physical or virtual, using dmidecode, on {{ inventory_hostname }}. This is unexpected and you may have to patch this server manually and take a look at the Ansible script."

- name: "Setting whether the server is Virtual or Physical as a fact, for later use"
  set_fact: server_type="{{ server_phys_virt }}"

- name: "Cleaning up Rescue Kernels"
  shell: |
    for k in $(ls -1 /boot/vmlinuz-0-rescue-* 2>/dev/null | grep -v "$(cat /etc/machine-id)")
    do
      rm -f "$k" "${k/vmlinuz-/initramfs-}.img"
      grubby --remove-kernel="$k"
    done
```

---

## roles/yum_clean_all/tasks/main.yml

Before checking if there are any updates for each server, it's good practice to run a yum/dnf clean all.

```yaml
---
- block:
  - name: "Running yum clean all on each server"
    command: yum clean all
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Failed to run yum clean all' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Failed to run yum clean all, on {{ inventory_hostname }}."
```

---

## roles/check_server_needs_update/tasks/main.yml

Now we check whether each server has any updates available.  
If not, the server is skipped and a message goes to output.log (and our custom summary at the end of the Playbook), keeping in line with Integrity of data and Availability of the server (CIA Triad).

```yaml
---
- name: "Checking each server for outstanding yum updates"
  yum:
    list: updates
    update_cache: true
  register: yumoutput
  changed_when: yumoutput.results|length > 0

- name: "Adding servers that are already up-to-date in to output.log"
  shell:
    cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [  OK  ] No outstanding updates' >> /ansible/patching/output.log
  delegate_to: localhost
  when: yumoutput.results|length == 0
```

---

## roles/wall/tasks/main.yml

We have a few minutes between this role and the patching itself, so at this point we send a Wall message to the server to tell anyone logged on that it will be rebooted soon.  
This gives people opportunity to save work (or scream) before the patching goes ahead.  
99.9% of the time, of course, there's no one logged on, but better to be safe.

```yaml
---
- name: "Sending wall message"
  command: wall This server is about to be patched via Ansible and will likely reboot in the next few minutes. Please save any work immediately.
```

---

## roles/place_in_maintenance_mode/tasks/main.yml

This is a specialised role for the environment we had.  
In this case, the servers were being monitored by System Center Operations Manager (SCOM) and would alert administrators out-of-hours if the server was rebooted. We don't want that, so a SCORCH runbook was created to trigger Maintenance Mode on a server when a URL was called.

```yaml
---
- block:
  - name: "Placing each server in Maintenance Mode in SCOM"
    uri:
      url: "http://scom_mm_hostname/MM/Home/InstantMM/?ComputerName={{ inventory_hostname }}.company-name.co.uk&Min=240&MMAction=Start"
      return_content: false
      timeout: 120
      use_proxy: false
    delegate_to: localhost
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Couldn't place server in Maintenance Mode in SCOM' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Server {{ inventory_hostname }} failed to go in to Maintenance Mode in SCOM."
```

---

## roles/stop_applications/tasks/main.yml

This role will be very specific to your own applications and needs.

Sometimes there are applications or databases running on a server that we don't want to be affected by package updates or a reboot, so it's better to 'nicely' shut them down before we patch.

The below example is for Splunk, Tomcat and Oracle DBs.  
We can also use the data from this role later on, to determine that these applications/services come back up successfully after reboot (check what's running now, check it's still running later).

```yaml
---
- block:
  - name: "Detecting Splunk"
    shell: systemctl list-units | grep -wc splunk.service
    register: splunk_service
    failed_when: splunk_service.rc == 257

  - debug:
      msg: "No Splunk instances were found on {{ inventory_hostname }}"
    when: splunk_service.stdout == '0'

  - debug:
      msg: "!! WARNING !!! Splunk is running on {{ inventory_hostname }}"
    when: splunk_service.stdout > '0'

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to detect whether Splunk is running on the server.' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to determine if Splunk is running on {{ inventory_hostname }}. This is unexpected and may be an issue with the Ansible patching script."

- block:
  - name: "Stopping Splunk"
    service:
      name: splunk
      state: stopped
    when: splunk_service.stdout != '0'

  - name: "Making sure Splunk shut down successfully"
    shell: ps -e -o pid,cmd | grep "splunkd.*start" | grep -v -E "grep|process-runner" | awk '{ print $1 }' | head -n 1
    register: splunk_success
    failed_when: splunk_success.stdout != ""
    when: splunk_service.stdout != '0'

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Splunk did not shut down' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Splunk failed to shut down on {{ inventory_hostname }}."

##############################################################

- block:
  - name: "Detecting Tomcat"
    shell: systemctl list-units | grep -wc tomcat.service
    register: tomcat_service
    failed_when: tomcat_service.rc == 257

  - debug:
      msg: "No Tomcat instances were found on {{ inventory_hostname }}"
    when: tomcat_service.stdout == '0'

  - debug:
      msg: "!! WARNING !!! Tomcat is running on {{ inventory_hostname }}"
    when: tomcat_service.stdout > '0'

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to detect whether Tomcat is running on the server.' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to determine if Tomcat is running on {{ inventory_hostname }}. This is unexpected and may be an issue with the Ansible patching script."

- block:
  - name: "Stopping Tomcat"
    service:
      name: tomcat
      state: stopped
    when: tomcat_service.stdout != '0'

  - name: "Making sure Tomcat shut down successfully"
    shell: ps -e -o cmd | grep catalina.startup | grep -v grep | head -n 1
    register: tomcat_success
    failed_when: tomcat_success.stdout != ""
    when: tomcat_service.stdout != '0'

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Tomcat did not shut down' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Tomcat failed to shut down on {{ inventory_hostname }}."

##############################################################

- block:
  - name: "Detecting Oracle Databases"
    shell: ps -e -o cmd | grep ora_pmon_ | grep -v grep | cut -d"_" -f3 | sort
    register: oracledb_service

  - debug:
      msg: "No Oracle databases were found on {{ inventory_hostname }}"
    when: oracledb_service.stdout == ''

  - debug:
      msg: "!! WARNING !!! Oracle Databases are running on {{ inventory_hostname }}"
    when: oracledb_service.stdout != ''

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to detect Oracle DBs' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to determine if there are any Oracle Databases running on {{ inventory_hostname }}. This is unexpected and may be an issue with the Ansible patching script."

- block:
  - name: "Stopping Oracle Databases using script"
    shell:
      cmd: "/path/to/script/stop_dbs.sh"
    become: yes
    become_user: oracle
    when: oracledb_service.stdout != ''

  - name: "Making sure Oracle Databases shut down successfully"
    shell: ps -e -o cmd | grep ora_pmon_ | grep -v grep | cut -d"_" -f3 | sort
    register: oracle_success
    failed_when: oracle_success.stdout != ""
    when: oracledb_service.stdout != ''

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Oracle Databases failed to shut down' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Not all Oracle Databases successfully shut down on {{ inventory_hostname }}."
```

---

## roles/take_snapshot/tasks/main.yml

**Note that this role is calling a role located in /ansible/snapshots**.  
I have included that role below this one, for reference.

I chose to keep the snapshot role separate/stand-alone because it's very useful to call from other Playbooks as well.

```yaml
---
- block:

  - include_role:
      name: /ansible/snapshots/roles/take_snapshot
    vars:
      host_to_snap: "{{ inventory_hostname }}"
      snap_reason: "Patching"
      snap_source: "input_source_here"
    when: server_type.rc == 0

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to take vSphere snapshot' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to take a vSphere Snapshot of {{ inventory_hostname }}. This could be because it has disks that can't be snapshot, although the playbook should be accounting for those, or the Unix vSphere user SVC_Linux_Patching couldn't find the hostname. You may need to take a manual snapshot to be on the safe side."

- debug:
    msg: "Server {{ inventory_hostname }} is Physical, therefore a vSphere snapshot is irrelevant. Snapshot step will be skipped."
  when: server_type.rc != 0
```

---

## /ansible/snapshots/roles/take_snapshots/main.yml

See the comment on the previous role above.

This role connects to vSphere and takes a snapshot of the host, using variables defined in the last role in the description of the snapshot.

```yaml
---
- name: "Creating vSphere snapshot - Onprem servers"
  delegate_to: localhost
  shell:
    cmd: "echo 'Connect-VIServer host1234.company-name.co.uk -User USERNAME -Password blablabla; New-Snapshot -VM '{{ host_to_snap }}' -Name \"Ansible Automated Snapshot\" -Confirm:$false -Description \"Snapshot taken automatically via Ansible. The reason was given as: {{ snap_reason }}. The source was: {{ snap_source }}.\" -Memory:$false; Disconnect-VIServer -Confirm:$false' | pwsh | grep -i 'created'"
  when: "'onprem' in inventory_hostname"
  register: snapshot_output

- name: "Creating vSphere snapshot - DMZ servers"
  delegate_to: localhost
  shell:
    cmd: "echo 'Connect-VIServer host5678.company-name.co.uk -User USERNAME -Password blablabla; New-Snapshot -VM '{{ host_to_snap }}' -Name \"Ansible Automated Snapshot\" -Confirm:$false -Description \"Snapshot taken automatically via Ansible. The reason was given as: {{ snap_reason }}. The source was: {{ snap_source }}.\" -Memory:$false; Disconnect-VIServer -Confirm:$false' | pwsh | grep -i 'created'"
  when: "'dmz' in inventory_hostname"
  register: snapshot_output
```


---

## roles/patch/tasks/main.yml

Finally, we patch!

Async and poll are used here, so that the connection doesn't just stay open and 'hang'. This frees up network resources, as well as gives us a decent indication on-screen as to whether the patching is still taking place.  
It also allows the role to time out, should patching fail to complete within a reasonable amount of time (without async and poll, we could end up with our Playbook just hanging indefinitely).

```yaml
---
- block:
  # Trigger a yum update Ansible 'Job' on each server, with a fail timeout of 12 minutes
  - name: "Triggering yum update on each server"
    yum:
      name: "*"
      state: latest
      disable_gpg_check: true
    async: 1920
    poll: 0
    register: yum_sleeper

  - debug:
      msg: "Now patching {{ inventory_hostname }}. This may take a few minutes, please wait ... "

  # Await the result of the yum update, polling every 30 seconds for 10 minutes
  - name: "Awaiting yum update result"
    async_status:
      jid: "{{ yum_sleeper.ansible_job_id }}"
    register: job_result
    until: job_result.finished
    retries: 60
    delay: 30

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] The yum update failed' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Yum update failed on {{ inventory_hostname }}. Is the repository configured correctly, and can the server communicate with it?"
```

---

## roles/reboot/tasks/main.yml

Whilst we could add some additional tasks here to determine if a server does indeed need a reboot after patching (`needs-rebooting`), it was decided (and I think makes good sense) to reboot the servers every time.  
This makes sure that they are all stable enough to come up correctly, along with their services, after patching, and during the allotted maintenance window for patching.

```yaml
---
- block:

  - name: "Rebooting servers"
    debug:
      msg: "!!! WARNING !!! - Now rebooting {{ inventory_hostname }} and then testing it came back up. This may take a few minutes, please wait ... "

  - name: "Reboot output"
    reboot:
      connect_timeout: 10
      pre_reboot_delay: 0
      post_reboot_delay: 10
      reboot_timeout: 480
      test_command: "uname -a"

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Server failed to reboot' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Server {{ inventory_hostname }} either failed to reboot, or did not reboot in a timely manner. Please check it manually to make sure it has rebooted and come back up correctly."
```

---

## roles/post_check/tasks/main.yml

This is another role that is very specific to individual company requirements.

- We use the facts gathered during the *stop_applications* role above to determine what services were running on each server before reboot, and make sure they have come back up again after reboot.
- We send a list of updated packages to /tmp on each server, for reference if needed.
- Each server is now removed from Maintenance Mode in the monitoring software.

```yaml
---
- name: "Let's wait 1 minute for everything to finish coming back up, before checking patching was successful"
  pause:
    minutes: 1

- block:
  - name: "Making sure any relevant Oracle Databases came back up successfully"
    shell: ps -e -o cmd | grep ora_pmon_ | grep -v grep | cut -d"_" -f3 | sort
    register: oracle_back_up
    failed_when: oracle_back_up.stdout == ""
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Oracle DBs failed to come back up' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "There were Oracle DBs detected on {{ inventory_hostname }}, but they don't appear to have come back up. Please contact an Oracle DBA to make sure the DBs are restarted on {{ inventory_hostname }}."
  when:
    - oracledb_service.stdout != ''

- block:
    - name: "Making sure Splunk came back up successfully"
      shell: ps -e -o pid,cmd | grep "splunkd.*start" | grep -v -E "grep|process-runner" | awk '{ print $1 }' | head -n 1
      register: splunk_back_up
      failed_when: splunk_back_up.stdout == ""
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Splunk failed to come back up' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Splunk was detected on {{ inventory_hostname }}, but it doesn't appear to have come back up. Please check why and start it manually."
  when: splunk_service.stdout != '0'

- block:
    - name: "Making sure Tomcat came back up successfully"
      shell: ps -e -o cmd | grep catalina.startup | grep -v grep | head -n 1
      register: tomcat_back_up
      failed_when: tomcat_back_up.stdout == ""
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Tomcat failed to come back up' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Tomcat was detected on {{ inventory_hostname }}, but it doesn't appear to have come back up. Please check why and start it manually."
  when: tomcat_service.stdout != '0'

- name: "Gathering a list of updated packages"
  shell: 'rpm -qa --last | grep "$(date +%a\ %d\ %b\ %Y)" | cut -f 1 -d " "'
  register: yumlistresult
  changed_when: false

- name: "Adding list of packages, updated today, to a temporary log file in /tmp"
  shell:
    cmd: "echo '{{ ansible_date_time.date }} - {{ inventory_hostname }} - {{ yumlistresult.stdout }}' > /tmp/{{ inventory_hostname }}_packages_updated.log"
  delegate_to: localhost

- block:
  - name: "Taking each server out of Maintenance Mode in SCOM"
    uri:
      url: "http://hostname/MM/Home/InstantMM/?ComputerName={{ inventory_hostname }}.company-name.co.uk&MMAction=Stop"
      return_content: false
      timeout: 120
    delegate_to: localhost
  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Failed to remove server from SCOM Maintenance Mode' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Failed to remove {{ inventory_hostname }} from SCOM Maintenance Mode."

- name: "Adding successfully patched server to output.log"
  shell:
    cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [  OK  ] Patched' >> /ansible/patching/output.log
  delegate_to: localhost
```

---

## roles/remove_snapshot/tasks/main.yml

This is another call to vSphere, to delete the snapshots taken before patching.

Of course, you don't need to add this role, if you want to keep the snapshots for a while.

```yaml
---
- block:

   - name: "Removing snapshot for {{ inventory_hostname }} - onprem servers"
     delegate_to: localhost
     shell:
       cmd: "echo 'Connect-VIServer host1234.company-name.co.uk -User USERNAME -Password blablabla; Get-VM '{{ inventory_hostname }}' | Get-Snapshot | Where-Object Name -like \"Ansible Automated Snapshot\" | Remove-Snapshot -Confirm:$false; Disconnect-VIServer -Confirm:$false' | pwsh"
     when: "'onprem' in inventory_hostname"

   - name: "Removing snapshot for {{ inventory_hostname }} - dmz servers"
     delegate_to: localhost
     shell:
       cmd: "echo 'Connect-VIServer host5678.company-name.co.uk -User USERNAME -Password blablabla; Get-VM '{{ inventory_hostname }}' | Get-Snapshot | Where-Object Name -like \"Ansible Automated Snapshot\" | Remove-Snapshot -Confirm:$false; Disconnect-VIServer -Confirm:$false' | pwsh"
     when: "'dmz' in inventory_hostname"

  rescue:
    - name: "Adding reason for failure to output.log"
      shell:
        cmd: echo '{{ ansible_date_time.date }} {{ ansible_date_time.time }} - {{ inventory_hostname }} - [ FAIL ] Unable to remove vSphere snapshot' >> /ansible/patching/output.log
      delegate_to: localhost
    - fail:
        msg: "Unable to remove the vSphere Snapshot of {{ inventory_hostname }}. Please be sure to delete this snapshot manually!"
```

---

## roles/summary/tasks/main.yml

This gives a really a nice output (using our log file and the blocks wrapped around everything so far) at the end of the patching Play.  
We can easily see not only which servers failed to patch, but a summary of why, so we don't have to scroll back through thousands of lines of Ansible output to work it out.

```yaml
---
- name: "Getting contents of output.log"
  shell:
    cmd: tac /ansible/patching/output.log | grep '#######################' -m 1 -B 9999 | tac
  register: log_contents

- name: "Summary from the latest Playbook run"
  debug:
    msg: "{{ log_contents.stdout_lines | join('\n') }}"
```
---

Hopefully you find this Playbook useful.

There's obviously a lot of code here, so if you spot anything I've carried over from my working environment incorrectly either on this page or on [my GitHub](https://github.com/0phoi5/ansible/tree/main/patching_playbook), please do let me know via *jackcollins1434@yahoo.com*.

---

[Top of page](#top)