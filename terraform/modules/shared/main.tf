

resource "aws_vpc" "main" {
  cidr_block = "10.100.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  tags {
    Name = "${var.env_name}-vpc"
    Environment = "${var.env_name}"
    Terraformed = 1
  }
}

resource "aws_subnet" "a" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.100.1.0/24"
  availability_zone = "${var.env_region}a"
  map_public_ip_on_launch = true
  tags {
    Environment = "${var.env_name}"
    Terraformed = "1"
    Name = "${var.env_name}-a"
  }
}


resource "aws_subnet" "b" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.100.2.0/24"
  availability_zone = "${var.env_region}b"
  map_public_ip_on_launch = true
  tags {
    Environment = "${var.env_name}"
    Terraformed = "1"
    Name = "${var.env_name}-b"
  }
}

data external "ipify" {
  program = ["curl", "https://api.ipify.org?format=json"]
}


resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.env_name}-default"
    Environment = "${var.env_name}"
    Terraformed = 1
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["69.162.169.108/32"]
    description = "internal communication"
  }


  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${data.external.ipify.result.ip}/32"]
    description = "terraforming computer"
  }


  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol  = "tcp"
    from_port = 3309
    to_port   = 3309
    cidr_blocks = ["0.0.0.0/0"]
    description = "tcp-ping utility"
  }


  ingress {
    protocol  = "tcp"
    from_port = 1234
    to_port   = 1234
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow latency test to skip load balancer"
  }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow https from outside"
  }


    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
  tags {
    Name = "${var.env_name}-gateway"
    Environment = "${var.env_name}"
    Terraformed = 1
  }
}

resource "aws_default_route_table" "main" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }
}