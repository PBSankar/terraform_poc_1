data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
  })
}

locals {
  subnet_offset = var.public_subnet_count
  az_count      = length(data.aws_availability_zones.available.names)
}

resource "null_resource" "nat_az_check" {
  count = var.public_subnet_count > local.az_count ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: public_subnet_count exceeds available AZs' && exit 1"
  }
}

resource "aws_subnet" "public" {
  count = var.public_subnet_count

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[
    count.index % length(data.aws_availability_zones.available.names)
  ]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Public"
  })
}

resource "aws_subnet" "private" {
  count = var.private_subnet_count

  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + local.subnet_offset)

  availability_zone = data.aws_availability_zones.available.names[
    count.index % length(data.aws_availability_zones.available.names)
  ]

  tags = merge(var.tags, {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = var.environment
    Type        = "Private"
  })
}

resource "aws_eip" "nat" {
  count  = var.public_subnet_count
  domain = "vpc"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-nat-eip-${count.index + 1}"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = var.public_subnet_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name        = "${var.project_name}-nat-gateway-${count.index + 1}"
    Environment = var.environment
  })

  lifecycle {
    prevent_destroy = false # Set to true to prevent accidental deletion
  }

  depends_on = [
    aws_internet_gateway.main,
    aws_eip.nat,
    aws_subnet.public
  ]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  })

  depends_on = [aws_internet_gateway.main]
}

resource "null_resource" "private_nat_check" {
  count = var.private_subnet_count > 0 && var.public_subnet_count == 0 ? 1 : 0

  provisioner "local-exec" {
    command = "echo 'ERROR: private subnets require at least one public subnet for NAT gateway' && exit 1"
  }
}

resource "aws_route_table" "private" {
  count  = var.private_subnet_count
  
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index % var.public_subnet_count].id
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-private-rt-${count.index + 1}"
    Environment = var.environment
  })

  depends_on = [
    aws_nat_gateway.main,
    null_resource.private_nat_check
  ]
}

resource "aws_route_table_association" "public" {
  count = var.public_subnet_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  depends_on = [aws_route_table.public]
}

resource "aws_route_table_association" "private" {
  count = var.private_subnet_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id

  depends_on = [aws_route_table.private]
}


