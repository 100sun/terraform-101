############### VPC ###############
# Virtual Private Cloud: Amazon’s Private Network
# CIDR: 10.10.0.0/16
resource "aws_vpc" "sofia-vpc" {
  # VPC name is "sofia-vpc"
  cidr_block = "10.0.0.0/16" # can have 32-16 = 2^16 addresses

  tags = {
    Name = "terraform-101"
  }
}

############### Subnet ###############
# To achieve high availability, it's always recommended to deploy services to at least two availability zones.

# public subnet CIDR: 10.10.0~1.0/24
# If a subnet is associated with a route table that does not have a route to an internet gateway, it's known as a private subnet.
resource "aws_subnet" "sofia-subnet_1" {
  vpc_id     = aws_vpc.sofia-vpc.id
  cidr_block = "10.0.0.0/24" # can have 32-24 = 2^8 addresses

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "101subnet-1"
  }
}

resource "aws_subnet" "sofia-subnet_2" {
  vpc_id     = aws_vpc.sofia-vpc.id
  cidr_block = "10.0.1.0/24"

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "101subnet-2"
  }
}

# private subnet CIDR: 10.10.2~3.0/24
# If a subnet is associated with a route table that has a route to an internet gateway, it's known as a public subnet.
resource "aws_subnet" "sofia-private_subnet_1" {
  vpc_id     = aws_vpc.sofia-vpc.id
  cidr_block = "10.0.2.0/24"

  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "101subnet-private-1"
  }
}

resource "aws_subnet" "sofia-private_subnet_2" {
  vpc_id     = aws_vpc.sofia-vpc.id
  cidr_block = "10.0.3.0/24"

  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "101subnet-private-2"
  }
}

############### Internet Gateway ###############
# a gateway to VPC to activate between VPC resource <-> internet (public subnet)
resource "aws_internet_gateway" "sofia-igw" {
  vpc_id = aws_vpc.sofia-vpc.id

  tags = {
    Name = "sofia-vpc"
  }
}

############### NAT Gateway & Elastic IP Adrdress ###############
# a gateway from private subnet to internet(aws service) by changing network address
# must need EIP to export all the request from private subnet to the external
# ex. 10.0.4.1(internal IP) → 13.1.1.1(elastic IP) → (external IP)

resource "aws_nat_gateway" "sofia-nat_gateway_1" {
  allocation_id = aws_eip.sofia-eip_1.id

  # Private subnet이 아니라 public subnet을 연결하셔야 합니다.
  subnet_id = aws_subnet.sofia-subnet_1.id

  tags = {
    Name = "NAT-GW-1"
  }
}

resource "aws_nat_gateway" "sofia-nat_gateway_2" {
  allocation_id = aws_eip.sofia-eip_2.id

  subnet_id = aws_subnet.sofia-subnet_2.id

  tags = {
    Name = "NAT-GW-2"
  }
}

resource "aws_eip" "sofia-eip_1" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "sofia-eip_2" {
  vpc = true

  lifecycle {
    create_before_destroy = true
  }
}

############### Route Table ###############
# Routing rules to deliver network traffic, can be associated w several subnets at the same time
# Public Subnet은 0.0.0.0/0 라우팅 시 Internet Gateway와 연결
# Private Subnet은 외부 연동 필요 시 NAT Gateway를 통해 연결
# Private DB Subnet은 외부 연동 필요시 설정

# "aws_route_table" provides details about a specific Route Table.
resource "aws_route_table" "sofia-route_table" {
  vpc_id = aws_vpc.sofia-vpc.id

  tags = {
    Name = "sofia-vpc"
  }
}

resource "aws_route_table" "sofia-route_table_private_1" {
  vpc_id = aws_vpc.sofia-vpc.id

  tags = {
    Name = "sofia-vpc-private-1"
  }
}

resource "aws_route_table" "sofia-route_table_private_2" {
  vpc_id = aws_vpc.sofia-vpc.id

  tags = {
    Name = "sofia-vpc-private-2"
  }
}

# "aws_route_table_association" provides a resource to create an association
# between a route table and a subnet or a route table and an internet gateway or virtual private gateway.
# Please note that one of either subnet_id or gateway_id is required.
resource "aws_route_table_association" "sofia-route_table_association_1" {
  subnet_id      = aws_subnet.sofia-subnet_1.id
  route_table_id = aws_route_table.sofia-route_table.id
}

resource "aws_route_table_association" "sofia-route_table_association_2" {
  subnet_id      = aws_subnet.sofia-subnet_2.id
  route_table_id = aws_route_table.sofia-route_table.id
}
#
resource "aws_route_table_association" "sofia-route_table_association_private_1" {
  subnet_id      = aws_subnet.sofia-private_subnet_1.id
  route_table_id = aws_route_table.sofia-route_table_private_1.id
}

resource "aws_route_table_association" "sofia-route_table_association_private_2" {
  subnet_id      = aws_subnet.sofia-private_subnet_2.id
  route_table_id = aws_route_table.sofia-route_table_private_2.id
}

# "aws_route" provides details about a specific Route.
resource "aws_route" "sofia-private_nat_1" {
  route_table_id         = aws_route_table.sofia-route_table_private_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sofia-nat_gateway_1.id
}

resource "aws_route" "sofia-private_nat_2" {
  route_table_id         = aws_route_table.sofia-route_table_private_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.sofia-nat_gateway_2.id
}

