#!/bin/bash

set -x
## Following code can help in setting up AMI in AWS for practice of DevOps Tools 
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/.local/bin:/root/bin"
## Checking Internet 
ping -c 2 google.com &>/dev/null 
if [ $? -ne 0 ]; then 
    echo "Internet connection is now working.. Check it .. !!"
    exit 1
fi
## Common Functions 
curl -s https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh -o /tmp/common.sh &>/dev/null 
source /tmp/common.sh
case $ELV in 
    el7) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ;;
    el8) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm ;;
esac


## Check ROOT USER 
if [ $(id -u) -ne 0 ]; then 
    error "You should be a root/sudo user to perform this script"
    exit 1
fi

## Disabling SELINUX
sed -i -e '/^SELINUX/ c SELINUX=disabled' /etc/selinux/config
Stat $? "Disabling SELINUX"


## Disable firewall 
systemctl disable firewalld &>/dev/null
Stat 0 "Disabling Firewall"

## Updating System Updates
#info "Updating System Updates"
#yum update -y #&>/dev/null 
#Stat $? "Updating System Updates"

## Remove cockpit message 
yum remove cockpit* -y 
rm -f /etc/motd.d/cockpit

## Install Base Packages
#yum install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm -y
PACK_LIST="wget zip unzip gzip vim make net-tools $EPEL bind-utils python2-pip jq nc telnet bc sshpass python3"
info "Installing Base Packages"
for package in $PACK_LIST ; do 
    [ "$package" = "$EPEL" ] && rpm -qa | grep epel &>/dev/null && Statt 0 "Installed EPEL" && continue
    yum install $package -y &>/dev/null  
    Statt $? "Installed $package"
done

dnf update libmodulemd -y &>/dev/null
yum remove mariadb-libs -y &>/dev/null
yum clean all &>/dev/null 

## Fixing SSH timeouts
sed -i -e '/TCPKeepAlive/ c TCPKeepAlive no' -e '/ClientAliveInterval/ c ClientAliveInterval 10' -e '/ClientAliveCountMax/ c ClientAliveCountMax 240'  /etc/ssh/sshd_config
Stat $? "Fixing SSH timeouts"

## Enable color prompt
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/ps1.sh -o /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh
Stat $? "Enable Color Prompt"

## Enable idle shutdown
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/idle.sh -o /boot/idle.sh
chmod +x /boot/idle.sh
STAT1=$?

## Setup Sudoers
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/sudoers >/etc/sudoers

## Uptime
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/tuptime >/bin/tuptime
chmod +x /bin/tuptime

sed -i -e '/idle/ d' /var/spool/cron/root &>/dev/null
echo "*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out" >/var/spool/cron/root
echo "@reboot passwd -u centos" >>/var/spool/cron/root
chmod 600 /var/spool/cron/root
STAT2=$?
if [ $STAT1 -eq 0 -a $STAT2 -eq 0 ]; then 
    STAT=0
else
    STAT=1
fi 
Stat $? "Enable idle shutdown"

## MISC
echo -e "LANG=en_US.utf-8\nLC_ALL=en_US.utf-8" >/etc/environment
echo -e "ANSIBLE_FORCE_COLOR=1" >>/etc/environment
echo -e "ANSIBLE_FORCE_COLOR=1" >>/root/.bashrc

## Enable Password Logins
sed -i -e '/^PasswordAuthentication/ c PasswordAuthentication yes' -e '/^PermitRootLogin/ c PermitRootLogin yes' /etc/ssh/sshd_config
chattr +i /etc/ssh/sshd_config
Stat $? "Enable Password Login"

## Setup user passwords
ROOT_PASS="DevOps321"
CENTOS_PASS="DevOps321"
#usermod -a -G google-sudoers centos &>/dev/null
echo "echo $ROOT_PASS | passwd --stdin root"   >>/etc/rc.d/rc.local 
echo "echo $CENTOS_PASS | passwd --stdin centos"   >>/etc/rc.d/rc.local 
echo "sed -i -e 's/^centos:!!/centos:/' /etc/shadow" >>/etc/rc.d/rc.local
Stat $? "Setup Password for Users"
info "   Following are the Usernames and Passwords"
Infot "centos / $CENTOS_PASS"
Infot "  root / $ROOT_PASS"
echo
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFoOQSSWSX4iJ1F42FODfS7Ct7wxnzRMuKAoTK67Zd5JkjETvroEOcwJHKeRVbjLT8hZuWMz3JdowR25+7W5N23GaBvBq7HbQwec2UGGA6AFAMmijpY1KDZznfBsqVvMY5yT/4XB1RU78dffRuNUs/IeMYnxoh6UO62Zg33JLtJY6waIFNtCFPTN8m4JrsPlt4s6X8E15Jn9Qh9TDNw+R7piDZ/KRDE+paMkflMpptfcNIbK8kzC9/p3DiAMBjmfrReGueI9vrSN66L/BepPTRoUvv9iavKbmu8DEITETlhGnn79V0r0ekXDE6WgZtnTBbbjSFsilNmLw7xjGMS0Bx root@ip-172-31-15-115.ec2.internal' >>/root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/home/centos/.ssh/authorized_keys
sed -i -e 's/showfailed//' /etc/pam.d/postlogin
chmod +x /etc/rc.d/rc.local 
systemctl enable rc-local

sed -i -e '4 i colorscheme desert' /etc/vimrc

## Make local keys 
#cat /dev/zero | ssh-keygen -q -N ""
#cat /root/.ssh/id_rsa.pub >>/root/.ssh/authorized_key
## Moved from generting ssh keys to using the ones from repo.
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/id_rsa >/root/.ssh/id_rsa
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/id_rsa.pub >/root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa
chmod 644 /root/.ssh/id_rsa.pub
chattr +i /root/.ssh/authorized_keys
echo 'Host *
    User root
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no' >/root/.ssh/config
echo 'Host *
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no' >/home/centos/.ssh/config
chmod 600 /root/.ssh/config /home/centos/.ssh/config
chown centos:centos /home/centos/.ssh/config

# Auto Pull the things while creating the server
curl -L -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-8/scripts/bootstrap.sh -o /boot/bootstrap.sh
chmod +x /boot/bootstrap.sh
echo '@reboot /boot/bootstrap.sh' >>/var/spool/cron/root

# Install AWS CLI 
cd /tmp 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
unzip awscliv2.zip &>/dev/null
/tmp/aws/install
/usr/local/bin/aws --version || true

rm -rf /var/lib/yum/*  /tmp/*
sed -i -e '/aws-hostname/ d' -e '$ a r /tmp/aws-hostname' /usr/lib/tmpfiles.d/tmp.conf

curl -s https://raw.githubusercontent.com/linuxautomations/labautomation/master/labauto >/bin/labauto 
chmod +x /bin/labauto

curl -s https://raw.githubusercontent.com/linuxautomations/labautomation/master/awsauto >/bin/awsauto
chmod +x /bin/awsauto

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/disable-auto-shutdown >/bin/disable-auto-shutdown
chmod +x /bin/disable-auto-shutdown

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/enable-auto-shutdown >/bin/enable-auto-shutdown
chmod +x /bin/enable-auto-shutdown

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/set-hostname >/bin/set-hostname
#cp scripts/set-hostname /bin
chmod +x /bin/set-hostname

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/motd >/etc/motd

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/.gitconfig >/root/.gitconfig
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/.gitconfig >/home/centos/.gitconfig
chown centos:centos /home/centos/.gitconfig; chmod 644 /home/centos/.gitconfig

#hint "System is going to shutdown now.. Make a note of the above passwords and save them to use with all your servers .."
#echo
#echo -e "★★★ Shutting Down the Server ★★★"
#echo;echo
#sudo init 0 &>/dev/null
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-8/scripts/mysql_secure_installation >/usr/sbin/mysql_secure_installation
chmod +x /usr/sbin/mysql_secure_installation

## Create directory for journalctl failure
mkdir -p /var/log/journal


