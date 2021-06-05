#!/bin/bash

## Following code can help in setting up AMI in AWS for practice of DevOps Tools 

## Checking Internet 
ping -c 2 google.com &>/dev/null 
if [ $? -ne 0 ]; then 
    echo "Internet connection is now working.. Check it .. !!"
    exit 1
fi
## Common Functions 
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/ubuntu-20/scipts/common.sh -o /tmp/common.sh &>/dev/null 
source /tmp/common.sh

## Check ROOT USER 
if [ $(id -u) -ne 0 ]; then 
    error "You should be a root/sudo user to perform this script"
    exit 1
fi

chattr -i /root/.ssh/authorized_keys /etc/ssh/sshd_config

apt-get update 
PACK_LIST="zip unzip make net-tools jq"
info "Installing Base Packages"
apt install $PACK_LIST -y


## Fixing SSH timeouts
sed -i -e '/TCPKeepAlive/ c TCPKeepAlive yes' -e '/ClientAliveInterval/ c ClientAliveInterval 10' /etc/ssh/sshd_config
Stat $? "Fixing SSH timeouts"

## Enable color prompt
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/ubuntu-20/scipts/ps1.sh -o /tmp/ps1.sh
cat /tmp/ps1.sh >>/home/ubuntu/.bashrc
cat /tmp/ps1.sh >>/root/.bashrc 
cat /tmp/ps1.sh >>/etc/skel/.bashrc

## Enable idle shutdown
curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/scipts/idle.sh -o /boot/idle.sh 
chmod +x /boot/idle.sh
STAT1=$?

echo "*/10 * * * * sh -x /boot/idle.sh &>/tmp/idle.out" >/var/spool/cron/crontabs/root
echo "@reboot passwd -u ubuntu" >>/var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root
STAT2=$?
if [ $STAT1 -eq 0 -a $STAT2 -eq 0 ]; then 
    STAT=0
else
    STAT=1
fi 
Stat $? "Enable idle shutdown"

## Enable Password Logins
sed -i -e '/^PasswordAuthentication/ c PasswordAuthentication yes' -e '/^PermitRootLogin/ c PermitRootLogin yes' /etc/ssh/sshd_config
chattr +i /etc/ssh/sshd_config
Stat $? "Enable Password Login"

## Setup user passwords
PASS="DevOps321"
PASS="DevOps321"
echo "echo "
echo root:DevOps321 | chpasswd
echo ubuntu:DevOps321 | chpasswd
echo -e "echo root:DevOps321 | chpasswd\necho ubuntu:DevOps321 | chpasswd"   >>/etc/rc.local 
echo "passwd -u ubuntu"
echo "sed -i -e 's/^ubuntu:!!/ubuntu:/' /etc/shadow" >>/etc/rc.local
info "   Following are the Usernames and Passwords"
Infot "ubuntu / $PASS"
Infot "  root / $PASS"
echo
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIfSCB5MtXe54V3lWGBGSxMWPue5CjmSA4ky7E8GUoeZdXxI+df7msJL93PzmtwU3v+O+NLNJJRfmaGpEkgidVXoi6mnYUVCHb1y4zd6QIFEyglGDlvZ4svhHt7T15B13bJC3mTaR2A/xqlvE0/a4XKN1ATYyn6K6CTFJT8I4TIDQmO3PbcNsNFXoO1ef657aqNf0AXC1QWum3HulIt6iJ4s0pQI4hDTmR5EskJxr2K62F4JDOYmVu8bGhFT6ohYbXBCGQtmdp716RnF0Cp1htmxM001wvCSjWLPZuuBjtHXX+op+MJGr0aIqqxdVZ2gw0JeIDfVo7pkSIdTu+p2Yn devops' >/root/.ssh/authorized_keys
chmod +x /etc/rc.local 
systemctl enable rc-local

## Make local keys 
cat /dev/zero | ssh-keygen -q -N ""
cat /root/.ssh/id_rsa.pub >>/root/.ssh/authorized_keys
chattr +i /root/.ssh/authorized_keys

echo 'Host *
    User root
    StrictHostKeyChecking no' >/root/.ssh/config 
chmod 600 /root/.ssh/config

# Install AWS CLI 
cd /tmp 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 
unzip awscliv2.zip | tail -5
/tmp/aws/install


# curl -s https://raw.githubusercontent.com/linuxautomations/labautomation/master/labauto >/bin/labauto 
# chmod +x /bin/labauto 

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/ubuntu-20/scipts/disable-auto-shutdown >/bin/disable-auto-shutdown
chmod +x /bin/disable-auto-shutdown

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/ubuntu-20/scipts/enable-auto-shutdown >/bin/enable-auto-shutdown
chmod +x /bin/enable-auto-shutdown

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/ubuntu-20/scipts/set-hostname >/bin/set-hostname
chmod +x /bin/set-hostname

curl -s https://raw.githubusercontent.com/linuxautomations/aws-image-devops-session/master/ubuntu-20/scipts/motd >/etc/motd 

#hint "System is going to shutdown now.. Make a note of the above passwords and save them to use with all your servers .."
#echo
#echo -e "★★★ Shutting Down the Server ★★★"
#echo;echo
#sudo init 0 &>/dev/null 
