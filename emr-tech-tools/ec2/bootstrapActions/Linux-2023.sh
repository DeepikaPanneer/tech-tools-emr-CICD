#!/bin/bash

USERNAME1="{USERNAME1}"
PUBLICKEY1="{PUBLICKEY1}"
USERNAME2="{USERNAME2}"
PUBLICKEY2="{PUBLICKEY2}"

sudo yum update -y
sudo yum install docker -y
sudo service docker start
sudo docker run -d -p 8787:8787 -e PASSWORD=UrbanCloud2019 -e ROOT=true -v /home/ec2-user:/home/rstudio --name rstudio rocker/geospatial:latest
sudo docker exec rstudio sudo apt-get install -y python-pip
sudo docker exec rstudio sudo pip install awscli
sudo docker run -d -p 8888:8888 --name jupyter jupyter/scipy-notebook start-notebook.sh --NotebookApp.password='sha1:b2d1b4eee6e8:af2ca564c2db504fb659b501bb01bd9d50250bf3'

instance=$(sudo curl http://169.254.169.254/latest/meta-data/instance-id)
sudo echo $instance > $instance.txt
sudo aws s3 cp $instance.txt s3://ui-elastic-analytics/notifications/$instance.txt

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

sudo amazon-linux-extras install epel
sudo yum install fail2ban -y
sudo -u root cat /dev/null > /etc/fail2ban/jail.local
sudo -u root tee -a /etc/fail2ban/jail.local <<EOF

[DEFAULT]

ignoreip = 127.0.0.1/8
bantime  = 600
findtime  = 600
maxretry = 3
backend = auto
usedns = warn

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

[sasl-iptables]

enabled  = false
filter   = sasl
backend  = polling
action   = iptables[name=sasl, port=smtp, protocol=tcp]
           sendmail-whois[name=sasl, dest=you@example.com]
logpath  = /var/log/mail.log

[assp]
enabled  = false
filter   = assp
action = iptables-multiport[name=assp,port="25,465,587"]
logpath  = /root/path/to/assp/logs/maillog.txt

[ssh-tcpwrapper]

enabled     = false
filter      = sshd
action      = hostsdeny
              sendmail-whois[name=SSH, dest=you@example.com]
ignoreregex = for myuser from
logpath     = /var/log/sshd.log

[ssh-route]

enabled = false
filter = sshd
action = route
logpath = /var/log/sshd.log
maxretry = 5

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

[ssh-bsd-ipfw]
enabled  = false
filter   = sshd
action   = bsd-ipfw[port=ssh,table=1]
logpath  = /var/log/auth.log
maxretry = 5

[apache-tcpwrapper]

enabled  = false
filter   = apache-auth
action   = hostsdeny
logpath  = /var/log/apache*/*error.log
           /home/www/myhomepage/error.log
maxretry = 6

[postfix-tcpwrapper]

enabled  = false
filter   = postfix
action   = hostsdeny[file=/not/a/standard/path/hosts.deny]
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/postfix.log
bantime  = 300

[vsftpd-notification]

enabled  = false
filter   = vsftpd
action   = sendmail-whois[name=VSFTPD, dest=you@example.com]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

[vsftpd-iptables]

enabled  = false
filter   = vsftpd
action   = iptables[name=VSFTPD, port=ftp, protocol=tcp]
           sendmail-whois[name=VSFTPD, dest=you@example.com]
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1800

[apache-badbots]

enabled  = false
filter   = apache-badbots
action   = iptables-multiport[name=BadBots, port="http,https"]
           sendmail-buffered[name=BadBots, lines=5, dest=you@example.com]
logpath  = /var/www/*/logs/access_log
bantime  = 172800
maxretry = 1

[apache-shorewall]

enabled  = false
filter   = apache-noscript
action   = shorewall
           sendmail[name=Postfix, dest=you@example.com]
logpath  = /var/log/apache2/error_log

[roundcube-iptables]

enabled  = false
filter   = roundcube-auth
action   = iptables[name=RoundCube, port="http,https"]
logpath  = /var/log/roundcube/userlogins

[sogo-iptables]

enabled  = false
filter   = sogo-auth

action   = iptables[name=SOGo, port="http,https"]
logpath  = /var/log/sogo/sogo.log

[php-url-fopen]

enabled = false
action  = iptables[name=php-url-open, port="http,https"]
filter  = php-url-fopen
logpath = /var/www/*/logs/access_log
maxretry = 1

[lighttpd-fastcgi]

enabled = false
filter  = lighttpd-fastcgi
action  = iptables[name=lighttpd-fastcgi, port="http,https"]
logpath = /var/log/lighttpd/error.log
maxretry = 2

[lighttpd-auth]

enabled = false
filter  = lighttpd-auth
action  = iptables[name=lighttpd-auth, port="http,https"]
logpath = /var/log/lighttpd/error.log
maxretry = 2

[ssh-ipfw]

enabled  = false
filter   = sshd
action   = ipfw[localhost=192.168.0.1]
           sendmail-whois[name="SSH,IPFW", dest=you@example.com]
logpath  = /var/log/auth.log
ignoreip = 168.192.0.1

[named-refused-tcp]

enabled  = false
filter   = named-refused
action   = iptables-multiport[name=Named, port="domain,953", protocol=tcp]
           sendmail-whois[name=Named, dest=you@example.com]
logpath  = /var/log/named/security.log
ignoreip = 168.192.0.1

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

[mysqld-iptables]

enabled  = false
filter   = mysqld-auth
action   = iptables[name=mysql, port=3306, protocol=tcp]
           sendmail-whois[name=MySQL, dest=root, sender=fail2ban@example.com]
logpath  = /var/log/mysqld.log
maxretry = 5

[recidive]

enabled  = false
filter   = recidive
logpath  = /var/log/fail2ban.log
action   = iptables-allports[name=recidive]
           sendmail-whois-lines[name=recidive, logpath=/var/log/fail2ban.log]
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5

[ssh-pf]

enabled=false
filter = sshd
action = pf
logpath  = /var/log/sshd.log
maxretry=5
EOF

sudo -u root cat /dev/null > /etc/fail2ban/fail2ban.conf
sudo -u root tee -a /etc/fail2ban/fail2ban.conf <<EOF

loglevel = 3

logtarget = SYSLOG

socket = /var/run/fail2ban/fail2ban.sock

pidfile = /var/run/fail2ban/fail2ban.pid
EOF

sudo -u root sed '1d' /etc/fail2ban/jail.local
sudo -u root sed '1d' /etc/fail2ban/fail2ban.conf
sudo systemctl enable fail2ban ||true
sudo chkconfig fail2ban on ||true
sudo service fail2ban start ||true
sudo systemctl start fail2ban ||true

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

sudo -u root cat /duv/null > /etc/ssh/sshd_config
sudo -u root tee -a /etc/ssh/sshd_config <<EOF

HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

SyslogFacility AUTHPRIV

PermitRootLogin forced-commands-only

AuthorizedKeysFile .ssh/authorized_keys

PasswordAuthentication no

ChallengeResponseAuthentication no

GSSAPIAuthentication yes
GSSAPICleanupCredentials no

UsePAM yes

X11Forwarding yes
PrintLastLog yes
UsePrivilegeSeparation sandbox
ClientAliveInterval 600
ClientAliveCountMax 3

AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES
AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT
AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE
AcceptEnv XMODIFIERS

Subsystem sftp  /usr/libexec/openssh/sftp-server

AuthorizedKeysCommand /opt/aws/bin/eic_run_authorized_keys %u %f
AuthorizedKeysCommandUser ec2-instance-connect
kexalgorithms diffie-hellman-group14-sha1,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha1,diffie-hellman-group-exchange-sha256,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,curve25519-sha256,curve25519-sha256@libssh.org
macs umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha1-etm@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512,hmac-sha1
ForceCommand /usr/sbin/login_duo
EOF

sudo cat /duv/null > /etc/ssh/ssh_config
sudo -u root tee -a /etc/ssh/ssh_config <<EOF
Ciphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128,aes128-cbc

Host *
        GSSAPIAuthentication yes

HashKnownHosts yes

EOF

sudo -u root systemctl restart sshd
