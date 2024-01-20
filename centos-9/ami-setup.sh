#!/bin/bash

## Following code can help in setting up AMI in AWS for practice of DevOps Tools 
export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/.local/bin:/root/bin"
## Common Functions 
curl -s https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh -o /tmp/common.sh &>/dev/null 
source /tmp/common.sh
case $ELV in 
    el7) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ;;
    el8) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm ;;
    el9) EPEL=https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm ;;
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

## Perform OS Update
yum update -y

PACK_LIST="wget zip vim make net-tools $EPEL bind-utils jq nc telnet bc sshpass"
for package in $PACK_LIST ; do
    yum install $package -y &>/dev/null
done

yum remove mariadb-libs -y &>/dev/null
yum clean all &>/dev/null

## Fixing SSH timeouts
sed -i -e '/TCPKeepAlive/ c TCPKeepAlive no' -e '/ClientAliveInterval/ c ClientAliveInterval 10' -e '/ClientAliveCountMax/ c ClientAliveCountMax 240'  /etc/ssh/sshd_config
Stat $? "Fixing SSH timeouts"

## Enable color prompt
cp /tmp/aws-image-devops-session/centos-9/scripts/ps1 /etc/profile.d/ps1.sh
## Uptime
cp /tmp/aws-image-devops-session/centos-9/scripts/tuptime /bin/tuptime
cp /tmp/aws-image-devops-session/centos-9/scripts/bootstrap.sh /boot/bootstrap.sh
echo '@reboot /boot/bootstrap.sh' >>/var/spool/cron/root

cp /tmp/aws-image-devops-session/centos-9/scripts/set-hostname /bin/set-hostname
cp /tmp/aws-image-devops-session/centos-9/scripts/motd /etc/motd
cp /tmp/aws-image-devops-session/centos-9/scripts/mysql_secure_installation /usr/sbin/mysql_secure_installation

cp /tmp/aws-image-devops-session/centos-9/scripts/id_rsa /root/.ssh/id_rsa
cp /tmp/aws-image-devops-session/centos-9/scripts/id_rsa.pub /root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa
chmod 644 /root/.ssh/id_rsa.pub
chattr +i /root/.ssh/authorized_keys
echo 'Host *
    User root
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no' >/root/.ssh/config
echo 'Host *
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no' >/home/ec2-user/.ssh/config
chmod 600 /root/.ssh/config /home/ec2-user/.ssh/config
chown ec2-user:ec2-user /home/ec2-user/.ssh/config


chmod /etc/profile.d/ps1.sh /bin/tuptime /boot/bootstrap.sh /bin/set-hostname /usr/sbin/mysql_secure_installation


## MISC
echo -e "LANG=en_US.utf-8\nLC_ALL=en_US.utf-8" >/etc/environment
echo -e "ANSIBLE_FORCE_COLOR=1" >>/etc/environment
echo -e "ANSIBLE_FORCE_COLOR=1" >>/root/.bashrc
echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin' >>/etc/environment

sed -i -e 's/showfailed//' /etc/pam.d/postlogin
sed -i -e '4 i colorscheme desert' /etc/vimrc

## Enable Password Logins
sed -i -e '/^PasswordAuthentication/ c PasswordAuthentication yes' -e '/^PermitRootLogin/ c PermitRootLogin yes' /etc/ssh/sshd_config
chattr +i /etc/ssh/sshd_config

## Setup user passwords
ROOT_PASS="DevOps321"
CENTOS_PASS="DevOps321"
echo "echo $ROOT_PASS | passwd --stdin root"   >>/etc/rc.d/rc.local
echo "echo $CENTOS_PASS | passwd --stdin ec2-user"   >>/etc/rc.d/rc.local
echo "sed -i -e 's/^ec2-user:!!/ec2-user:/' /etc/shadow" >>/etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
systemctl enable rc-local

echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFoOQSSWSX4iJ1F42FODfS7Ct7wxnzRMuKAoTK67Zd5JkjETvroEOcwJHKeRVbjLT8hZuWMz3JdowR25+7W5N23GaBvBq7HbQwec2UGGA6AFAMmijpY1KDZznfBsqVvMY5yT/4XB1RU78dffRuNUs/IeMYnxoh6UO62Zg33JLtJY6waIFNtCFPTN8m4JrsPlt4s6X8E15Jn9Qh9TDNw+R7piDZ/KRDE+paMkflMpptfcNIbK8kzC9/p3DiAMBjmfrReGueI9vrSN66L/BepPTRoUvv9iavKbmu8DEITETlhGnn79V0r0ekXDE6WgZtnTBbbjSFsilNmLw7xjGMS0Bx root@ip-172-31-15-115.ec2.internal' >>/root/.ssh/authorized_keys
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/home/centos/.ssh/authorized_keys

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

cp /tmp/aws-image-devops-session /root/.gitconfig
cp /tmp/aws-image-devops-session /home/ec2-user/.gitconfig
chown ec2-user:ec2-user /home/centos/.gitconfig; chmod 644 /home/centos/.gitconfig

## Create directory for journalctl failure
mkdir -p /var/log/journal


