resource "aws_vpc" "default" {
  cidr_block            = "172.31.0.0/16"
  enable_dns_hostnames  = true
  enable_dns_support    = true
  tags {
    Name = "Test VPC",
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "InternetGateway"
  }
}

resource "aws_subnet" "public_subnet_us_east_1" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "172.31.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
  tags = {
    Name = "Subnet az 1"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

resource "aws_eip" "default_eip" {
  vpc = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.default_eip.id}"
    subnet_id = "${aws_subnet.public_subnet_us_east_1.id}"
    depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route_table_association" "public_subnet_us_east_1_association" {
    subnet_id = "${aws_subnet.public_subnet_us_east_1.id}"
    route_table_id = "${aws_vpc.default.main_route_table_id}"
}

resource "aws_security_group" "test" {
    name = "test"
    description = "Allows inbound and outband traffic from instances in VPC"
    vpc_id = "${aws_vpc.default.id}"

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
    }

    tags {
        Name = "test"
    }
}

resource "aws_instance" "web" {
    ami = "ami-4ae1fb5d"
    count = "${var.count}"
    source_dest_check = false
    instance_type = "m1.small"
    subnet_id = "${aws_subnet.public_subnet_us_east_1.id}"
    security_groups = ["${aws_security_group.test.id}"]
    provisioner "remote-exec" {
      inline = [
      "sudo apt-get update",
      "sudo apt-get -y install docker-engine",
      "docker run hello-world:latest"
      ]
      connection {
        agent = false
      }
    }
    tags  {
        Name = "test"
    }
}



