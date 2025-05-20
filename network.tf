data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)
  availability_zone               = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_instance_sg" {
  name        = "${var.project_name}-ecs-instance-sg"
  description = "Security group for ECS EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.ssh_access_cidr
    ipv6_cidr_blocks = var.ssh_access_ipv6_cidr
    description      = "Allow SSH access"
  }

  ingress {
    from_port        = var.couchdb_access_port
    to_port          = var.couchdb_access_port
    protocol         = "tcp"
    cidr_blocks      = var.couchdb_access_cidr
    ipv6_cidr_blocks = var.couchdb_access_ipv6_cidr
    description      = "Allow CouchDB access"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-instance-sg"
  }
}
