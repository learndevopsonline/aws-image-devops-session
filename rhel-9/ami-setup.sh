#!/bin/bash

## Following code can help in setting up AMI in AWS for practice of DevOps Tools 
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/.local/bin:/root/bin"
## Common Functions 
curl -s https://raw.githubusercontent.com/learndevopsonline/scripts/master/common-functions.sh -o /tmp/common.sh &>/dev/null
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
yum remove insights-client -y
rm -f /etc/motd.d/insights-client

## Perform OS Update
#yum update -y
yum install vim https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm net-tools bind-utils sshpass jq nmap telnet -y


## Fixing SSH timeouts
sed -i -e '/TCPKeepAlive/ c TCPKeepAlive no' -e '/ClientAliveInterval/ c ClientAliveInterval 10' -e '/ClientAliveCountMax/ c ClientAliveCountMax 240'  /etc/ssh/sshd_config


## Profile Environment
cp /tmp/aws-image-devops-session/rhel-9/scripts/ps1.sh /etc/profile.d/ps1.sh
cp /tmp/aws-image-devops-session/rhel-9/scripts/aliases.sh /etc/profile.d/aliases.sh
cp /tmp/aws-image-devops-session/rhel-9/scripts/boot-env.sh /etc/profile.d/boot-env.sh
cp /tmp/aws-image-devops-session/rhel-9/scripts/profile /etc/profile
chmod +x /etc/profile /etc/profile.d/*

useradd ec2-user
mkdir -p /home/ec2-user/.ssh
chown ec2-user:ec2-user /home/ec2-user/.ssh
chmod 700 /home/ec2-user/.ssh

echo "@reboot passwd -u ec2-user" >>/var/spool/cron/root
chmod 600 /var/spool/cron/root

## Enable Password Logins
sed -i -e '/^PasswordAuthentication/ c PasswordAuthentication yes' -e '/^PermitRootLogin/ c PermitRootLogin yes' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf


## Setup user passwords
ROOT_PASS="DevOps321"
CENTOS_PASS="DevOps321"

echo "echo $ROOT_PASS | passwd --stdin root"   >>/etc/rc.d/rc.local 
echo "echo $CENTOS_PASS | passwd --stdin ec2-user"   >>/etc/rc.d/rc.local
echo "sed -i -e 's/^ec2-user:!!/ec2-user:/' /etc/shadow" >>/etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local

echo
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFoOQSSWSX4iJ1F42FODfS7Ct7wxnzRMuKAoTK67Zd5JkjETvroEOcwJHKeRVbjLT8hZuWMz3JdowR25+7W5N23GaBvBq7HbQwec2UGGA6AFAMmijpY1KDZznfBsqVvMY5yT/4XB1RU78dffRuNUs/IeMYnxoh6UO62Zg33JLtJY6waIFNtCFPTN8m4JrsPlt4s6X8E15Jn9Qh9TDNw+R7piDZ/KRDE+paMkflMpptfcNIbK8kzC9/p3DiAMBjmfrReGueI9vrSN66L/BepPTRoUvv9iavKbmu8DEITETlhGnn79V0r0ekXDE6WgZtnTBbbjSFsilNmLw7xjGMS0Bx root@ip-172-31-15-115.ec2.internal' >>/root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/home/ec2-user/.ssh/authorized_keys
sed -i -e 's/showfailed//' /etc/pam.d/postlogin


sed -i -e '4 i colorscheme desert' /etc/vimrc

echo 'ec2-user ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/ec2-user
chattr +i /etc/ssh/sshd_config /etc/ssh/sshd_config.d/50-cloud-init.conf /etc/sudoers.d/ec2-user

cp /tmp/aws-image-devops-session/rhel-9/scripts/04-ssh-config.conf /etc/ssh/ssh_config.d/04-ssh-config.conf
cp /tmp/aws-image-devops-session/rhel-9/scripts/motd /etc/motd

## Create directory for journalctl failure
mkdir -p /var/log/journal
curl -L -o /tmp/install-snoopy.sh https://github.com/a2o/snoopy/raw/install/install/install-snoopy.sh
bash /tmp/install-snoopy.sh stable && rm -f /tmp/install-snoopy.sh


# Commands to /bin
cp /tmp/aws-image-devops-session/rhel-9/scripts/set-hostname /bin/set-prompt
cp /tmp/aws-image-devops-session/rhel-9/scripts/mysql_secure_installation /usr/sbin/mysql_secure_installation
chmod +x /bin/set-prompt /usr/sbin/mysql_secure_installation

# Install AWS CLI
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip &>/dev/null
/tmp/aws/install
/usr/local/bin/aws --version || true

yum clean all &>/dev/null
rm -rf /var/lib/yum/*  /tmp/*
sed -i -e '/aws-hostname/ d' -e '$ a r /tmp/aws-hostname' /usr/lib/tmpfiles.d/tmp.conf

# labauto Scripts
curl -s https://raw.githubusercontent.com/learndevopsonline/labautomation/master/labauto >/bin/labauto
chmod +x /bin/labauto

curl -s https://raw.githubusercontent.com/learndevopsonline/labautomation/master/awsauto >/bin/awsauto
chmod +x /bin/awsauto

# Empty All log files
truncate -s 0 `find /var/log -type f |xargs`

rm -rf /tmp/*
