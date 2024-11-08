#!/bin/bash

############################################################################################
################################### Specify User Info ###################################
############################################################################################

USERNAME1="{USERNAME1}"
PUBLICKEY1="{PUBLICKEY1}"

USERNAME2="{USERNAME2}"
PUBLICKEY2="{PUBLICKEY2}"

######################################################################################
################################### install docker ###################################
######################################################################################

sudo yum update -y

sudo yum install docker -y

sudo service docker start

###############################################################################################
################################### start rstudio container ###################################
###############################################################################################

sudo docker run -d -p 8787:8787 -e PASSWORD=UrbanCloud2019 -e ROOT=true -v /home/ec2-user:/home/rstudio --name rstudio rocker/geospatial:latest

#########################################################################################
################################### install urbnverse ###################################
#########################################################################################

sudo docker exec rstudio R -e "remotes::install_github('UrbanInstitute/urbnmapr', repos = 'http://cran.rstudio.com')"
sudo docker exec rstudio R -e "remotes::install_github('UrbanInstitute/urbnthemes', repos = 'http://cran.rstudio.com')"

############################################################################################################
################################### install awscli into rocker container ###################################
############################################################################################################

sudo docker exec rstudio sudo apt-get install -y python-pip
sudo docker exec rstudio sudo pip install awscli

########################################################################################################
################################### pull and run anaconda3 container ###################################
########################################################################################################

sudo docker run -d -p 8888:8888 --name jupyter jupyter/scipy-notebook start-notebook.sh --NotebookApp.password='sha1:b2d1b4eee6e8:af2ca564c2db504fb659b501bb01bd9d50250bf3'

###############################################################################################
################################### write instance id to s3 ###################################
###############################################################################################

instance=$(sudo curl http://169.254.169.254/latest/meta-data/instance-id)
sudo echo $instance > $instance.txt
sudo aws s3 cp $instance.txt s3://ui-elastic-analytics/notifications/$instance.txt

####################################################################################################
################################### New additons below this line ###################################
####################################################################################################

############################################################################################
################################### Install User account ###################################
############################################################################################

sudo luseradd $USERNAME1
sudo su -c "mkdir -p /home/$USERNAME1/.ssh/"
sudo su -c "chown $USERNAME1:$USERNAME1 /home/$USERNAME1/.ssh"
sudo su -c "chmod 700 /home/$USERNAME1/.ssh"
sudo su -c "touch /home/$USERNAME1/.ssh/authorized_keys"
sudo su -c "chown $USERNAME1:$USERNAME1 /home/$USERNAME1/.ssh/authorized_keys"
sudo su -c "chmod 600 /home/$USERNAME1/.ssh/authorized_keys"
sudo su -c "gpasswd -a $USERNAME1 wheel"
sudo su -c "passwd -d $USERNAME1"
sudo su -c "passwd -e $USERNAME1"
sudo sh -c "echo '$PUBLICKEY1' >> /home/$USERNAME1/.ssh/authorized_keys"

################################################################################################
################################### Install awsadmin account ###################################
################################################################################################

sudo luseradd $USERNAME2
sudo su -c "mkdir -p /home/$USERNAME2/.ssh/"
sudo su -c "chown $USERNAME2:$USERNAME2 /home/$USERNAME2/.ssh"
sudo su -c "chmod 700 /home/$USERNAME2/.ssh"
sudo su -c "touch /home/$USERNAME2/.ssh/authorized_keys"
sudo su -c "chown $USERNAME2:$USERNAME2 /home/$USERNAME2/.ssh/authorized_keys"
sudo su -c "chmod 600 /home/$USERNAME2/.ssh/authorized_keys"
sudo su -c "gpasswd -a $USERNAME2 wheel"
sudo su -c "passwd -d $USERNAME2"
sudo su -c "passwd -e $USERNAME2"
sudo sh -c "echo '$PUBLICKEY2' >> /home/$USERNAME2/.ssh/authorized_keys"

########################################################################################
################################### Install fail2ban ###################################
########################################################################################
sudo amazon-linux-extras install epel
sudo yum install fail2ban -y
sudo -u root cat /dev/null > /etc/fail2ban/jail.local
sudo -u root tee -a /etc/fail2ban/jail.local <<EOF
# Fail2Ban jail specifications file
#
# Comments: use '#' for comment lines and ';' (following a space) for inline comments
#
# Changes:  in most of the cases you should not modify this
#           file, but provide customizations in jail.local file, e.g.:
#
# [DEFAULT]
# bantime = 3600
#
# [ssh-iptables]
# enabled = true
#

# The DEFAULT allows a global definition of the options. They can be overridden
# in each jail afterwards.

[DEFAULT]

# "ignoreip" can be an IP address, a CIDR mask or a DNS host. Fail2ban will not
# ban a host which matches an address in this list. Several addresses can be
# defined using space separator.
ignoreip = 127.0.0.1/8

# "bantime" is the number of seconds that a host is banned.
bantime  = 600

# A host is banned if it has generated "maxretry" during the last "findtime"
# seconds.
findtime  = 600

# "maxretry" is the number of failures before a host get banned.
maxretry = 3

# "backend" specifies the backend used to get files modification.
# Available options are "pyinotify", "gamin", "polling" and "auto".
# This option can be overridden in each jail as well.
#
# pyinotify: requires pyinotify (a file alteration monitor) to be installed.
#              If pyinotify is not installed, Fail2ban will use auto.
# gamin:     requires Gamin (a file alteration monitor) to be installed.
#              If Gamin is not installed, Fail2ban will use auto.
# polling:   uses a polling algorithm which does not require external libraries.
# auto:      will try to use the following backends, in order:
#              pyinotify, gamin, polling.
backend = auto

# "usedns" specifies if jails should trust hostnames in logs,
#   warn when DNS lookups are performed, or ignore all hostnames in logs
#
# yes:   if a hostname is encountered, a DNS lookup will be performed.
# warn:  if a hostname is encountered, a DNS lookup will be performed,
#        but it will be logged as a warning.
# no:    if a hostname is encountered, will not be used for banning,
#        but it will be logged as info.
usedns = warn


# This jail corresponds to the standard configuration in Fail2ban 0.6.
# The mail-whois action send a notification e-mail with a whois request
# in the body.

[ssh-iptables]

enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=ssh, protocol=tcp]
           sendmail-whois[name=SSH, dest=root, sender=fail2ban@example.com]
logpath  = /var/log/secure
findtime = 600
maxretry = 5
bantime = 31104000

[proftpd-iptables]

enabled  = false
filter   = proftpd
action   = iptables[name=ProFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=ProFTPD, dest=you@example.com]
logpath  = /var/log/proftpd/proftpd.log
maxretry = 6

# This jail forces the backend to "polling".

[sasl-iptables]

enabled  = false
filter   = sasl
backend  = polling
action   = iptables[name=sasl, port=smtp, protocol=tcp]
           sendmail-whois[name=sasl, dest=you@example.com]
logpath  = /var/log/mail.log

# ASSP SMTP Proxy Jail
[assp]
enabled  = false
filter   = assp
action = iptables-multiport[name=assp,port="25,465,587"]
logpath  = /root/path/to/assp/logs/maillog.txt

# Here we use TCP-Wrappers instead of Netfilter/Iptables. "ignoreregex" is
# used to avoid banning the user "myuser".

[ssh-tcpwrapper]

enabled     = false
filter      = sshd
action      = hostsdeny
              sendmail-whois[name=SSH, dest=you@example.com]
ignoreregex = for myuser from
logpath     = /var/log/sshd.log

# Here we use blackhole routes for not requiring any additional kernel support
# to store large volumes of banned IPs

[ssh-route]

enabled = false
filter = sshd
action = route
logpath = /var/log/sshd.log
maxretry = 5

# Here we use a combination of Netfilter/Iptables and IPsets
# for storing large volumes of banned IPs
#
# IPset comes in two versions. See ipset -V for which one to use
# requires the ipset package and kernel support.
[ssh-iptables-ipset4]

enabled  = false
filter   = sshd
action   = iptables-ipset-proto4[name=SSH, port=ssh, protocol=tcp]
logpath  = /var/log/sshd.log
maxretry = 5

[ssh-iptables-ipset6]
enabled  = false
filter   = sshd
action   = iptables-ipset-proto6[name=SSH, port=ssh, protocol=tcp, bantime=600]
logpath  = /var/log/sshd.log
maxretry = 5

# bsd-ipfw is ipfw used by BSD. It uses ipfw tables.
# table number must be unique.
#
# This will create a deny rule for that table ONLY if a rule
# for the table doesn't ready exist.
#
[ssh-bsd-ipfw]
enabled  = false
filter   = sshd
action   = bsd-ipfw[port=ssh,table=1]
logpath  = /var/log/auth.log
maxretry = 5

# This jail demonstrates the use of wildcards in "logpath".
# Moreover, it is possible to give other files on a new line.

[apache-tcpwrapper]

enabled  = false
filter   = apache-auth
action   = hostsdeny
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 6

# The hosts.deny path can be defined with the "file" argument if it is
# not in /etc.

[postfix-tcpwrapper]

enabled  = false
filter   = postfix
action   = hostsdeny[file=/not/a/standard/path/hosts.deny]
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/postfix.log
bantime  = 300

# Do not ban anybody. Just report information about the remote host.
# A notification is sent at most every 600 seconds (bantime).

[vsftpd-notification]

enabled  = false
filter   = vsftpd
action   = sendmail-whois[name=VSFTPD, dest=you@example.com]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

# Same as above but with banning the IP address.

[vsftpd-iptables]

enabled  = false
filter   = vsftpd
action   = iptables[name=VSFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=VSFTPD, dest=you@example.com]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

# Ban hosts which agent identifies spammer robots crawling the web
# for email addresses. The mail outputs are buffered.

[apache-badbots]

enabled  = false
filter   = apache-badbots
action   = iptables-multiport[name=BadBots, port="http,https"]
           sendmail-buffered[name=BadBots, lines=5, dest=you@example.com]
logpath  = /var/www/*/logs/access_log
bantime  = 172800
maxretry = 1

# Use shorewall instead of iptables.

[apache-shorewall]

enabled  = false
filter   = apache-noscript
action   = shorewall
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/apache2/error_log

# Monitor roundcube server

[roundcube-iptables]

enabled  = false
filter   = roundcube-auth
action   = iptables[name=RoundCube, port="http,https"]
logpath  = /var/log/roundcube/userlogins


# Monitor SOGo groupware server

[sogo-iptables]

enabled  = false
filter   = sogo-auth
# without proxy this would be:
# port    = 20000
action   = iptables[name=SOGo, port="http,https"]
logpath  = /var/log/sogo/sogo.log

# Ban attackers that try to use PHP's URL-fopen() functionality
# through GET/POST variables. - Experimental, with more than a year
# of usage in production environments.

[php-url-fopen]

enabled = false
action  = iptables[name=php-url-open, port="http,https"]
filter  = php-url-fopen
logpath = /var/www/*/logs/access_log
maxretry = 1

# A simple PHP-fastcgi jail which works with lighttpd.
# If you run a lighttpd server, then you probably will
# find these kinds of messages in your error_log:
# ALERT – tried to register forbidden variable ‘GLOBALS’
# through GET variables (attacker '1.2.3.4', file '/var/www/default/htdocs/index.php')
# This jail would block the IP 1.2.3.4.

[lighttpd-fastcgi]

enabled = false
filter  = lighttpd-fastcgi
action  = iptables[name=lighttpd-fastcgi, port="http,https"]
# adapt the following two items as needed
logpath = /var/log/lighttpd/error.log
maxretry = 2

# Same as above for mod_auth
# It catches wrong authentications

[lighttpd-auth]

enabled = false
filter  = lighttpd-auth
action  = iptables[name=lighttpd-auth, port="http,https"]
# adapt the following two items as needed
logpath = /var/log/lighttpd/error.log
maxretry = 2

# This jail uses ipfw, the standard firewall on FreeBSD. The "ignoreip"
# option is overridden in this jail. Moreover, the action "mail-whois" defines
# the variable "name" which contains a comma using "". The characters '' are
# valid too.

[ssh-ipfw]

enabled  = false
filter   = sshd
action   = ipfw[localhost=192.168.0.1]
           sendmail-whois[name="SSH,IPFW", dest=you@example.com]
logpath  = /var/log/auth.log
ignoreip = 168.192.0.1

# These jails block attacks against named (bind9). By default, logging is off
# with bind9 installation. You will need something like this:
#
# logging {
#     channel security_file {
#         file "/var/log/named/security.log" versions 3 size 30m;
#         severity dynamic;
#         print-time yes;
#     };
#     category security {
#         security_file;
#     };
# };
#
# in your named.conf to provide proper logging.
# This jail blocks UDP traffic for DNS requests.

# !!! WARNING !!!
#   Since UDP is connection-less protocol, spoofing of IP and imitation
#   of illegal actions is way too simple.  Thus enabling of this filter
#   might provide an easy way for implementing a DoS against a chosen
#   victim. See
#    http://nion.modprobe.de/blog/archives/690-fail2ban-+-dns-fail.html
#   Please DO NOT USE this jail unless you know what you are doing.
#
# [named-refused-udp]
#
# enabled  = false
# filter   = named-refused
# action   = iptables-multiport[name=Named, port="domain,953", protocol=udp]
#            sendmail-whois[name=Named, dest=you@example.com]
# logpath  = /var/log/named/security.log
# ignoreip = 168.192.0.1

# This jail blocks TCP traffic for DNS requests.

[named-refused-tcp]

enabled  = false
filter   = named-refused
action   = iptables-multiport[name=Named, port="domain,953", protocol=tcp]
           sendmail-whois[name=Named, dest=you@example.com]
logpath  = /var/log/named/security.log
ignoreip = 168.192.0.1

# Multiple jails, 1 per protocol, are necessary ATM:
# see https://github.com/fail2ban/fail2ban/issues/37
[asterisk-tcp]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-tcp, port="5060,5061", protocol=tcp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

[asterisk-udp]

enabled  = false
filter   = asterisk
action   = iptables-multiport[name=asterisk-udp, port="5060,5061", protocol=udp]
           sendmail-whois[name=Asterisk, dest=you@example.com, sender=fail2ban@example.com]
logpath  = /var/log/asterisk/messages
maxretry = 10

# To log wrong MySQL access attempts add to /etc/my.cnf:
# log-error=/var/log/mysqld.log
# log-warning = 2
[mysqld-iptables]

enabled  = false
filter   = mysqld-auth
action   = iptables[name=mysql, port=3306, protocol=tcp]
           sendmail-whois[name=MySQL, dest=root, sender=fail2ban@example.com]
logpath  = /var/log/mysqld.log
maxretry = 5


# Jail for more extended banning of persistent abusers
# !!! WARNING !!!
#   Make sure that your loglevel specified in fail2ban.conf/.local
#   is not at DEBUG level -- which might then cause fail2ban to fall into
#   an infinite loop constantly feeding itself with non-informative lines
[recidive]

enabled  = false
filter   = recidive
logpath  = /var/log/fail2ban.log
action   = iptables-allports[name=recidive]
           sendmail-whois-lines[name=recidive, logpath=/var/log/fail2ban.log]
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5

# PF is a BSD based firewall
[ssh-pf]

enabled=false
filter = sshd
action = pf
logpath  = /var/log/sshd.log
maxretry=5
EOF

sudo -u root cat /dev/null > /etc/fail2ban/fail2ban.conf
sudo -u root tee -a /etc/fail2ban/fail2ban.conf <<EOF
# Fail2Ban main configuration file
#
# Comments: use '#' for comment lines and ';' (following a space) for inline comments
#
# Changes:  in most of the cases you should not modify this
#           file, but provide customizations in fail2ban.local file, e.g.:
#
# [Definition]
# loglevel = 4
#

[Definition]

# Option:  loglevel
# Notes.:  Set the log level output.
#          1 = ERROR
#          2 = WARN
#          3 = INFO
#          4 = DEBUG
# Values:  NUM  Default:  3
#
loglevel = 3

# Option:  logtarget
# Notes.:  Set the log target. This could be a file, SYSLOG, STDERR or STDOUT.
#          Only one log target can be specified.
#          If you change logtarget from the default value and you are
#          using logrotate -- also adjust or disable rotation in the
#          corresponding configuration file
#          (e.g. /etc/logrotate.d/fail2ban on Debian systems)
# Values:  STDOUT STDERR SYSLOG file  Default:  /var/log/fail2ban.log
#
logtarget = SYSLOG

# Option: socket
# Notes.: Set the socket file. This is used to communicate with the daemon. Do
#         not remove this file when Fail2ban runs. It will not be possible to
#         communicate with the server afterwards.
# Values: FILE  Default:  /var/run/fail2ban/fail2ban.sock
#
socket = /var/run/fail2ban/fail2ban.sock

# Option: pidfile
# Notes.: Set the PID file. This is used to store the process ID of the
#         fail2ban server.
# Values: FILE  Default:  /var/run/fail2ban/fail2ban.pid
#
pidfile = /var/run/fail2ban/fail2ban.pid
EOF

sudo -u root sed '1d' /etc/fail2ban/jail.local
sudo -u root sed '1d' /etc/fail2ban/fail2ban.conf
sudo systemctl enable fail2ban ||true
sudo chkconfig fail2ban on ||true
sudo service fail2ban start ||true
sudo systemctl start fail2ban ||true

###################################################################################
################################### Install Duo ###################################
###################################################################################

sudo -u root cat /dev/null > /etc/yum.repos.d/duosecurity.repo
sudo -u root tee -a /etc/yum.repos.d/duosecurity.repo <<EOF
[duosecurity]
name=Duo Security Repository
baseurl=https://pkg.duosecurity.com/CentOS/7/x86_64/$basearch
enabled=1
gpgcheck=1
EOF

sudo -u root groupadd duoexcluded
if getent passwd bamboo > /dev/null 2>&1; then
sudo -u root gpasswd -a bamboo duoexcluded
fi
#if getent passwd ec2_user > /dev/null 2>&1; then
#sudo -u root gpasswd -a ec2-user duoexcluded
#fi
if getent passwd docker1 > /dev/null 2>&1; then
sudo -u root gpasswd -a docker1 duoexcluded
fi
if getent passwd it > /dev/null 2>&1; then
sudo -u root gpasswd -a it duoexcluded
fi
sudo -u root rpm --import https://duo.com/DUO-GPG-PUBLIC-KEY.asc
sudo -u root yum install duo_unix -y --nogpgcheck
sudo -u root rm -rf /etc/duo/login_duo.conf
sudo -u root touch /etc/duo/login_duo.conf
sudo -u root chown sshd:root /etc/duo/login_duo.conf
sudo -u root chmod 600 /etc/duo/login_duo.conf
sudo -u root tee -a /etc/duo/login_duo.conf <<EOF
[duo]
; Duo integration key
ikey = DIGF75RGP0PHKNTOLGOZ
; Duo secret key
skey = 7K0rhCXxDeZDFonnGM3W3pGKCdoM6fun2m7v5mAB
; Duo API host
host = api-15978a5d.duosecurity.com
; `failmode = safe` In the event of errors with this configuration file or connection to the Duo service
; this mode will allow login without 2FA.
; `failmode = secure` This mode will deny access in the above cases. Misconfigurations with this setting
; enabled may result in you being locked out of your system.
failmode = safe
; Send command for Duo Push authentication
pushinfo = yes
groups= *,!duoexcluded
EOF

sudo -u root echo 'ForceCommand /usr/sbin/login_duo' |sudo tee -a /etc/ssh/sshd_config
sudo -u root systemctl restart sshd

#######################################################################################################
################################### Install Security configurations ###################################
#######################################################################################################

##########################################################################################
################################### SSH Configurations ###################################
##########################################################################################

sudo -u root cat /duv/null > /etc/ssh/sshd_config
sudo -u root tee -a /etc/ssh/sshd_config <<EOF
#       $OpenBSD: sshd_config,v 1.100 2016/08/15 12:32:04 naddy Exp $

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

# If you want to change the port on a SELinux system, you have to tell
# SELinux about this change.
# semanage port -a -t ssh_port_t -p tcp #PORTNUMBER
#
#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
SyslogFacility AUTHPRIV
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin yes
# Only allow root to run commands over ssh, no shell
PermitRootLogin forced-commands-only
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile .ssh/authorized_keys

#AuthorizedPrincipalsFile none


# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no
PasswordAuthentication no

# Change to no to disable s/key passwords
#ChallengeResponseAuthentication yes
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no
#KerberosUseKuserok yes

# GSSAPI options
GSSAPIAuthentication yes
GSSAPICleanupCredentials no
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no
#GSSAPIEnablek5users no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
# WARNING: 'UsePAM no' is not supported in Red Hat Enterprise Linux and may cause several
# problems.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
#PrintMotd yes
PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
UsePrivilegeSeparation sandbox
#PermitUserEnvironment no
#Compression delayed
ClientAliveInterval 600
ClientAliveCountMax 3
#ShowPatchLevel no
#UseDNS yes
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Accept locale-related environment variables
AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

# override default of no subsystems
Subsystem sftp  /usr/libexec/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server

AuthorizedKeysCommand /opt/aws/bin/eic_run_authorized_keys %u %f
AuthorizedKeysCommandUser ec2-instance-connect
kexalgorithms diffie-hellman-group14-sha1,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha1,diffie-hellman-group-exchange-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,curve25519-sha256,curve25519-sha256@libssh.org
macs umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha1-etm@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-sha1
ForceCommand /usr/sbin/login_duo
EOF

sudo cat /duv/null > /etc/ssh/ssh_config
sudo -u root tee -a /etc/ssh/ssh_config <<EOF
#       $OpenBSD: ssh_config,v 1.30 2016/02/20 23:06:23 sobrado Exp $

# This is the ssh client system-wide configuration file.  See
# ssh_config(5) for more information.  This file provides defaults for
# users, and the values can be changed in per-user configuration files
# or on the command line.

# Configuration data is parsed as follows:
#  1. command line options
#  2. user-specific file
#  3. system-wide file
# Any configuration value is only changed the first time it is set.
# Thus, host-specific definitions should be at the beginning of the
# configuration file, and defaults at the end.

# Site-wide defaults for some commonly used options.  For a comprehensive
# list of available options, their meanings and defaults, please see the
# ssh_config(5) man page.

# Host *
#   ForwardAgent no
#   ForwardX11 no
#   RhostsRSAAuthentication no
#   RSAAuthentication yes
#   PasswordAuthentication yes
#   HostbasedAuthentication no
#   GSSAPIAuthentication no
#   GSSAPIDelegateCredentials no
#   GSSAPIKeyExchange no
#   GSSAPITrustDNS no
#   BatchMode no
#   CheckHostIP yes
#   AddressFamily any
#   ConnectTimeout 0
#   StrictHostKeyChecking ask
#   IdentityFile ~/.ssh/identity
#   IdentityFile ~/.ssh/id_rsa
#   IdentityFile ~/.ssh/id_dsa
#   IdentityFile ~/.ssh/id_ecdsa
#   IdentityFile ~/.ssh/id_ed25519
#   Port 22
#   Protocol 2
#   Cipher 3des
Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-cbc
#kexalgorithms +diffie-hellman-group14-sha1,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha1,diffie-hellman-group-exchange-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,curve25519-sha256
#kexalgorithms -diffie-hellman-group1-sha1
#   MACs hmac-md5,hmac-sha1,umac-64@openssh.com,hmac-ripemd160
#   EscapeChar ~
#   Tunnel no
#   TunnelDevice any:any
#   PermitLocalCommand no
#   VisualHostKey no
#   ProxyCommand ssh -q -W %h:%p gateway.example.com
#   RekeyLimit 1G 1h
#
# Uncomment this if you want to use .local domain
# Host *.local
#   CheckHostIP no

Host *
        GSSAPIAuthentication yes
# If this option is set to yes then remote X11 clients will have full access
# to the original X11 display. As virtually no X11 client supports the untrusted
# mode correctly we set this to yes.
        ForwardX11Trusted yes
# Send locale-related environment variables
        SendEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
        SendEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
        SendEnv LC_IDENTIFICATION LC_ALL LANGUAGE
        SendEnv XMODIFIERS
# Don't show actual hostnames in .ssh/known_hosts
HashKnownHosts yes
#Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-cbc,3des-cbc
#kexalgorithms diffie-hellman-group14-sha1,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha1,diffie-hellman-group-exchange-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,curve25519-sha256,curve25519-sha256@libssh.org
EOF

sudo -u root systemctl restart sshd

