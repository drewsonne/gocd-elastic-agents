variable "cidr-prefix" {
  type = "string"
  default = "10.0"
}

variable "zone-suffixes" {
  type = "list"
  default = ["a", "b"]
}

#############################
# Outer layer VPC resources #
#############################
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr-prefix}.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"
  tags = {
    Environment = "${var.environment}"
    Name = "${var.environment}"
  }
}

resource "aws_vpc_dhcp_options" "vpc-dhcp-options" {
  domain_name = "ec2.internal"
  domain_name_servers = [
    "AmazonProvidedDNS"]
  tags = {
    Name = "${var.environment}"
  }
}

resource "aws_vpc_dhcp_options_association" "vpc-dhcp-options-association"{
  vpc_id = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.vpc-dhcp-options.id}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Environment = "${var.environment}"
    Name = "${var.environment}"
  }
}

######################
# Public Subnet Tier #
######################

resource "aws_subnet" "public-subnets" {
  count = "${length(var.zone-suffixes)}"
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr-prefix}.${count.index}.0/24"
  availability_zone = "${var.region}${element(var.zone-suffixes, count.index)}"
  tags = {
    Environment = "${var.environment}"
    Tier = "public"
    Name = "${var.environment}-public-${element(var.zone-suffixes, count.index)}"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Environment = "${var.environment}"
    Tier = "public"
    Name = "${var.environment}"
  }
}

resource "aws_route" "public-route" {
  route_table_id = "${aws_route_table.public-route-table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

resource "aws_route_table_association" "public-subnet-a-rt-association" {
  count = "${length(var.zone-suffixes)}"
  subnet_id = "${element(aws_subnet.public-subnets.*.id, count.index)}"
  route_table_id = "${aws_route_table.public-route-table.id}"
}

#######################
# Private Subnet Tier #
#######################

resource "aws_subnet" "private-subnets" {
  count = "${length(var.zone-suffixes)}"
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.cidr-prefix}.${length(var.zone-suffixes)+count.index}.0/24"
  availability_zone = "${var.region}${element(var.zone-suffixes, count.index)}"
  tags = {
    Environment = "${var.environment}"
    Tier = "private"
    Name = "${var.environment}-private-${element(var.zone-suffixes, count.index)}"
  }
}

resource "aws_eip" "eip-nats" {
  count = "${length(var.zone-suffixes)}"
  vpc = true
}

resource "aws_nat_gateway" "nat-gateways" {
  count = "${length(var.zone-suffixes)}"
  subnet_id = "${element(aws_subnet.public-subnets.*.id, count.index)}"
  allocation_id = "${element(aws_eip.eip-nats.*.id, count.index)}"
}

resource "aws_route_table" "private-route-tables" {
  count = "${length(var.zone-suffixes)}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Environment = "${var.environment}"
    Tier = "private"
    Name = "${var.environment}-private-routetable-${element(var.zone-suffixes, count.index)}"
  }
}

resource "aws_route" "private-routes-to-nat" {
  count = "${length(var.zone-suffixes)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${element(aws_nat_gateway.nat-gateways.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private-route-tables.*.id, count.index)}"
}