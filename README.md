# aws-image-devops-session

## Account No for Images : 125523088429
## Redhat AMI : 174003430611

## Public AMIs (us-east-1)

| Name | AMI ID | OS | Login |
|---|---|---|---|
| Redhat-10-DevOps-Practice | ami-0eec78ea4cbaaf5bd | RHEL 10.2 | root / DevOps321, ec2-user / DevOps321 |
| Redhat-9-DevOps-Practice | ami-0055977a6e828a4f4 | RHEL 9.7 | root / DevOps321, ec2-user / DevOps321 |
| Centos-8-DevOps-Practice | ami-0b4f379183e5706b9 | CentOS 8 | |

RHEL disk layout (LVM `RootVG`): `/` 6G, swap 2G, `/var` 2G, `/var/tmp` 2G, `/var/log` 2G, rest for `/home`.

Build RHEL 10: `bash rhel-10/build-ami.sh`

MOTD Maker: https://patorjk.com/software/taag/#p=testall&f=Graffiti&t=RHEL%209
