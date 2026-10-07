provider "aws" {
  region = "us-east-1"
}

//
terraform {
  backend "s3" {
    bucket = "d55-training"
    key    = "rhel-10/terraform.tfstate"
    region = "us-east-1"
  }
}

// Latest official Red Hat RHEL 10.2 AMI (Red Hat owner id 309956199498)
data "aws_ami" "rhel10" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-10.2.*_HVM*-x86_64-*-Hourly2-GP3"]
  }
}

resource "aws_security_group" "ami-sg" {
  name        = "rhel-10-ami"
  description = "SSH access for RHEL-10 AMI build"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ami-instance" {
  ami                         = data.aws_ami.rhel10.id
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.ami-sg.id]
  key_name                    = "devops"

  tags = {
    Name = "rhel-10-ami"
  }
}

resource "null_resource" "ami-create-apply" {
  provisioner "remote-exec" {
    connection {
      user      = "ec2-user"
      host      = aws_instance.ami-instance.public_ip
      private_key = file("~/devops.pem")
    }

    inline = [
      "sudo yum install git -y",
      "cd /tmp && rm -rf aws-image-devops-session && git clone https://github.com/learndevopsonline/aws-image-devops-session.git",
      "cd aws-image-devops-session/rhel-10",
      "sudo bash ami-setup.sh",
      "cd /tmp && rm -rf /tmp/aws-image-devops-session"
    ]
  }
}

resource "aws_ami_from_instance" "ami" {
  depends_on                      = [null_resource.ami-create-apply]
  name                            = "Redhat-10-DevOps-Practice"
  source_instance_id              = aws_instance.ami-instance.id
  tags                            = {
    Name                          = "Redhat-10-DevOps-Practice"
  }
}

resource "null_resource" "public-ami" {
  provisioner "local-exec" {
    command =<<EOT
aws ec2 modify-image-attribute --image-id ${aws_ami_from_instance.ami.id} --launch-permission "Add=[{Group=all}]" --region us-east-1
EOT
  }
}
