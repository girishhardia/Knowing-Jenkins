# vpc.tf
# This file defines all our networking resources, including a NAT Gateway.

# Create a Virtual Private Cloud (VPC) to house our resources.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Get the list of available availability zones in the region.
data "aws_availability_zones" "available" {}

# Create public subnets. Our load balancer and NAT Gateway will live here.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = tolist(data.aws_availability_zones.available.names)[count.index]
  map_public_ip_on_launch = true # Instances in public subnets get a public IP
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# Create private subnets. Our containers will live here for security.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = tolist(data.aws_availability_zones.available.names)[count.index]
  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}

# --- PUBLIC ROUTING ---

# Create an Internet Gateway to allow communication with the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Create a route table for our public subnets.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0" # Route all traffic to the Internet Gateway
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Associate the public route table with our public subnets.
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# --- PRIVATE ROUTING (NEW) ---

# Create an Elastic IP for our NAT Gateway. This gives it a static public IP.
resource "aws_eip" "nat" {
  vpc        = true # *** THIS LINE HAS BEEN FIXED ***
  depends_on = [aws_internet_gateway.main]
  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

# Create the NAT Gateway itself. Place it in the first public subnet.
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags = {
    Name = "${var.project_name}-nat-gw"
  }
  depends_on = [aws_internet_gateway.main]
}

# Create a route table for our private subnets.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0" # Route all traffic to the NAT Gateway
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# Associate the private route table with our private subnets.
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
