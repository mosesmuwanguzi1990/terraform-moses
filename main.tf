# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
    tags = {
    Name = "dev_vpc"
    Environment = "Development"
  }
}

resource "aws_internet_gateway" "gw" {
 #vpc_id = aws_vpc.dev.id

  tags = {
    Name = "dev_igw"
    Environment = "Development"
  }
}

resource "aws_internet_gateway_attachment" "attachment_igw" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id              = aws_vpc.dev.id
}


resource "aws_eip" "dev_eip_nat_public" {
 # domain = "standard"

    tags = {
    Name = "dev_eip_nat_public"
    Environment = "Development"
  }
}


## create NAT Gateway and ensure attachment
resource "aws_nat_gateway" "dev_nat_gateway" {
  allocation_id = aws_eip.dev_eip_nat_public.id
  subnet_id     = aws_subnet.dev_subnet_public.id

  tags = {
    Name = "gw NAT"
    Environment = "Development"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}


## create a route table for public subnet
resource "aws_route_table" "route_pub" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
    tags = {
    Name = "dev_route_table_pub"
    Environment = "Development"
  }
}


## create a route table for private subnet
resource "aws_route_table" "route_prv" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.dev_nat_gateway.id
  }
    tags = {
    Name = "dev_route_table_prv"
    Environment = "Development"
  }
}


resource "aws_subnet" "dev_subnet_public" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "dev_subnet_public"
    Environment = "Development"
  }
}

## private subnet
resource "aws_subnet" "dev_subnet_private" {
  vpc_id     = aws_vpc.dev.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "dev_subnet_private"
    Environment = "Development"
  }
}

resource "aws_route_table_association" "rt_public_association" {
  subnet_id      = aws_subnet.dev_subnet_public.id
  route_table_id = aws_route_table.route_pub.id
}

resource "aws_route_table_association" "rt_private_association" {
  subnet_id      = aws_subnet.dev_subnet_private.id
  route_table_id = aws_route_table.route_prv.id
}