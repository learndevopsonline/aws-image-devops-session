provider "aws" {
  region = "us-east-1"
}

//
terraform {
  backend "s3" {
    bucket = "d55-training"
    key    = "rhel-9/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "ami-instance" {
  ami                         = "ami-008e7b65af911ed5c"
  instance_type               = "t3.small"
  vpc_security_group_ids      = ["sg-006ca1fec44eedca8"]
  key_name                    = "devops"

  tags = {
    Name = "rhel-9-ami"
  }
}

resource "null_resource" "ami-create-apply" {
  provisioner "remote-exec" {
    connection {
      user      = "maintuser"
      host      = aws_instance.ami-instance.public_ip
      private_key = file("~/devops.pem")
    }

    inline = [
      "sudo yum install git -y",
      "cd /tmp && rm -rf aws-image-devops-session && git clone https://github.com/learndevopsonline/aws-image-devops-session.git",
      "cd aws-image-devops-session/rhel-9",
      "sudo bash ami-setup.sh",
      "cd /tmp && rm -rf /tmp/aws-image-devops-session"
    ]
  }
}

resource "aws_ami_from_instance" "ami" {
  depends_on                      = [null_resource.ami-create-apply]
  name                            = "RHEL-9-DevOps-Practice"
  source_instance_id              = aws_instance.ami-instance.id
  tags                            = {
    Name                          = "RHEL-9-DevOps-Practice"
  }
}

resource "null_resource" "public-ami" {
  provisioner "local-exec" {
    command =<<EOF
aws ec2 modify-image-attribute --image-id ${aws_ami_from_instance.ami.id} --launch-permission "Add=[{Group=all}]" --region us-east-1
EOF
  }
}

