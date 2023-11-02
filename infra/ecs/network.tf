# VPC
resource "aws_vpc" "pkcl-vpc" {
  cidr_block       = "10.0.0.0/21"
  instance_tenancy = "default"

  tags = {
    Name = "pkcl-vpc"
  }
}

# Subnets
resource "aws_subnet" "pkcl-public-a" {
  vpc_id            = aws_vpc.pkcl-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "pkcl-public-a"
  }
}

resource "aws_subnet" "pkcl-public-b" {
  vpc_id            = aws_vpc.pkcl-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "pkcl-public-b"
  }
}

resource "aws_subnet" "pkcl-private-a" {
  vpc_id            = aws_vpc.pkcl-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "pkcl-private-a"
  }
}

resource "aws_subnet" "pkcl-private-b" {
  vpc_id            = aws_vpc.pkcl-vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "pkcl-private-b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "pkcl-igw" {
  vpc_id = aws_vpc.pkcl-vpc.id
  tags = {
    Name = "pkcl-igw"
  }
}

# NAT Gateways com alocação de ip
resource "aws_eip" "pkcl-ei-a" {
  domain = "vpc"
}

resource "aws_eip" "pkcl-ei-b" {
  domain = "vpc"
}

resource "aws_nat_gateway" "pkcl-nat-gw-a" {
  subnet_id     = aws_subnet.pkcl-public-a.id
  allocation_id = aws_eip.pkcl-ei-a.id
  tags = {
    Name = "pkcl-nat-gw-a"
  }
}

resource "aws_nat_gateway" "pkcl-nat-gw-b" {
  subnet_id     = aws_subnet.pkcl-public-b.id
  allocation_id = aws_eip.pkcl-ei-b.id
    tags = {
    Name = "pkcl-nat-gw-b"
  }
}

# Route Tables publica
resource "aws_route_table" "pkcl-public-rt" {
  vpc_id = aws_vpc.pkcl-vpc.id

  tags = {
    Name = "pkcl-public-rt"
  }
}

# adiciona rota para internet gateway
resource "aws_route" "pkcl-public-rt-route" {
  route_table_id         = aws_route_table.pkcl-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.pkcl-igw.id
}

## associa subnets publica A na route table publica
resource "aws_route_table_association" "pkcl-rta-public-subnet-a" {
  route_table_id = aws_route_table.pkcl-public-rt.id
  subnet_id      = aws_subnet.pkcl-public-a.id
}

## associa subnets publica B na route table publica
resource "aws_route_table_association" "pkcl-rta-public-subnet-b" {
  route_table_id = aws_route_table.pkcl-public-rt.id
  subnet_id      = aws_subnet.pkcl-public-b.id
}

# Route Tables privada A
resource "aws_route_table" "pkcl-private-a-rt" {
  vpc_id = aws_vpc.pkcl-vpc.id

  tags = {
    Name = "pkcl-private-a-rt"
  }
}

# adiciona rota para NAT Gateway A
resource "aws_route" "pkcl-private-a-rt-route" {
  route_table_id         = aws_route_table.pkcl-private-a-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.pkcl-nat-gw-a.id
}

# associa subnets privada A na route table privada A
resource "aws_route_table_association" "pkcl-rta-private-subnet-a" {
  route_table_id = aws_route_table.pkcl-private-a-rt.id
  subnet_id      = aws_subnet.pkcl-private-a.id
}

# Route Tables privada B
resource "aws_route_table" "pkcl-private-b-rt" {
  vpc_id = aws_vpc.pkcl-vpc.id

  tags = {
    Name = "pkcl-private-b-rt"
  }
}

# adiciona rota para NAT Gateway B
resource "aws_route" "pkcl-private-b-rt-route" {
  route_table_id         = aws_route_table.pkcl-private-b-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.pkcl-nat-gw-b.id
}

# associa subnets privada B na route table privada B
resource "aws_route_table_association" "pkcl-rta-private-subnet-b" {
  route_table_id = aws_route_table.pkcl-private-b-rt.id
  subnet_id      = aws_subnet.pkcl-private-b.id
}
