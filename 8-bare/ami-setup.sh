#!/bin/bash

## Following code can help in setting up AMI in AWS for practice of DevOps Tools 
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/.local/bin:/root/bin"
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

## Remove cockpit message 
yum remove cockpit* -y 
rm -f /etc/motd.d/cockpit

## Perform OS Update
yum update -y
yum clean all &>/dev/null 

## Fixing SSH timeouts
sed -i -e '/TCPKeepAlive/ c TCPKeepAlive no' -e '/ClientAliveInterval/ c ClientAliveInterval 10' -e '/ClientAliveCountMax/ c ClientAliveCountMax 240'  /etc/ssh/sshd_config
Stat $? "Fixing SSH timeouts"

## Enable color prompt
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/ps1.sh -o /etc/profile.d/ps1.sh
chmod +x /etc/profile.d/ps1.sh
Stat $? "Enable Color Prompt"

## Uptime
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/tuptime >/bin/tuptime
chmod +x /bin/tuptime

echo "@reboot passwd -u centos" >>/var/spool/cron/root
chmod 600 /var/spool/cron/root

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


curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/centos-7/scripts/motd >/etc/motd

## Create directory for journalctl failure
mkdir -p /var/log/journal

