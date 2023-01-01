#AWS VPC
resource "aws_vpc" "terra_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "terra_vpc" #AWS Object Name
  }
}

#AWS Subnet
resource "aws_subnet" "terra_public_subnet" {
  vpc_id                  = aws_vpc.terra_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "terra_public_subnet" #AWS Object Name
  }
}

# AWS Internet Gateway
resource "aws_internet_gateway" "terra_internet_gateway" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_igw"
  }
}

# AWS Route Table
resource "aws_route_table" "terra_public_rt" {
  vpc_id = aws_vpc.terra_vpc.id

  tags = {
    Name = "terra_public_rt"
  }
}

# AWS Default Route
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.terra_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.terra_internet_gateway.id
}

# Route Table Association
resource "aws_route_table_association" "terra_public_asc" {
  subnet_id      = aws_subnet.terra_public_subnet.id
  route_table_id = aws_route_table.terra_public_rt.id
}

# Security Group
resource "aws_security_group" "terra_sg" {
  name        = "terra_sg"
  description = "terra_sg"
  vpc_id      = aws_vpc.terra_vpc.id

  ingress {
    description = "terra_sg inbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "terra_sg"
  }
}

# KeyPair
resource "aws_key_pair" "terra-key" {
  key_name = "terra-key"
  #public_key = "ssh-rsa b3BlbnNzaC1rZXktdjEAAAAACmFlczI1Ni1jdHIAAAAGYmNyeXB0AAAAGAAAABDmOMdthXblis9sz1245DCfAAAAEAAAAAEAAAAzAAAAC3NzaC1lZDI1NTE5AAAAIOTM3vse7lvKiR3ZCAIB+lLxqxm9qTXLysWRUqvHAtcHAAAAoJ2hcGxRimIwST91kf3fp/gsGuXBAb7GsB2yPgbm8cm9qSf7ZtSdWJbECh1rPzRPRzoePB3BQ+cxr+INdePFSftNP7IAo7CUHswXhEP56bweUQOHMkFdCabj6QKrPh7rVIKU3wlTzsCQKBKHaHnNPrNKpFjVKteEiSa5wErFtOYgBthBhZARuULlfPxDmdIKh69wW7knzEah+Zlh2lCjaNk= email@example.com"
  public_key = file("~/.ssh/terra-aws.pub")
}

# EC2 Instance
resource "aws_instance" "terra-linux01" {
    instance_type = "t2.micro"
    ami = data.aws_ami.terra_ami.id
    key_name = aws_key_pair.terra-key.id
    vpc_security_group_ids = [aws_security_group.terra_sg.id]
    subnet_id = aws_subnet.terra_public_subnet.id
    user_data = file("userdata.tpl")
    tags = {
        Name = "terra-linux01"
    }
    root_block_device  {
        volume_size = 10
    }


    provisioner "local-exec" {
      command = templatefile("windows-ssh-script.tpl",{
        hostname = self.public_ip,
        user = "ubuntu",
        identityfile = "~/.ssh/terra-aws"
      })
    interpreter = ["Powershell", "-Command"]
    #interpreter = ["bash", "-c"]

    }

}