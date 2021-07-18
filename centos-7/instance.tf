provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "ami-instance" {
  ami                         = "ami-02946ce583813a223"
  instance_type               = "t3.small"
  vpc_security_group_ids      = ["sg-03a6af6735757ed3e"]
  key_name                    = "devops"
}

resource "null_resource" "ami-create-apply" {
  provisioner "remote-exec" {
    connection {
      user      = "centos"
      host      = aws_instance.ami-instance.public_ip
      private_key = file("~/devops.pem")
    }

    inline = [
      "sudo yum install git -y",
      "rm -rf aws-image-devops-session && git clone https://github.com/linuxautomations/aws-image-devops-session.git",
      "cd aws-image-devops-session/centos-7",
      "sudo bash ami-setup.sh",
      "rm -rf /home/centos/aws-image-devops-session"
    ]
  }
}

resource "aws_ami_from_instance" "ami" {
  depends_on                      = [null_resource.ami-create-apply]
  name                            = "Centos-7-DevOps-Practice"
  source_instance_id              = aws_instance.ami-instance.id
  tags                            = {
    Name                          = "Centos-7-DevOps-Practice"
  }
}

resource "null_resource" "public-ami" {
  provisioner "local-exec" {
    command =<<EOF
aws ec2 modify-image-attribute --image-id ${aws_ami_from_instance.ami.id} --launch-permission "Add=[{Group=all}]" --region us-east-1
EOF
  }
}

