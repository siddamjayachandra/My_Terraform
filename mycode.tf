terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

#data "aws_availability_zones" "available" {
# state = "available"
#}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  #instance_tenancy = "dedicated"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_vpc" "peervpc" {
  cidr_block = "10.1.0.0/16"
  #instance_tenancy = "dedicated"

  tags = {
    Name = "peervpc"
  }
}



#variable "azs" {

#type        = list(string)

#description = "Availability Zones"

#default     = ["ap-south-1a"]

#} 

#variable "public" {

# type = list(string)

#description = "Public Subnet CIDR values"

#default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

#}

#variable "azs" {

# type = list(string)

#description = "Availability Zones"

#default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

#}

resource "aws_subnet" "mysubnet" {
  #count      = length(var.public)
  vpc_id = aws_vpc.myvpc.id
  #cidr_block = element(var.public, count.index)
  cidr_block = "10.0.1.0/24"
  #availability_zone = element(var.azs, count.index)
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mysubnet"
  }
}

resource "aws_subnet" "myprivatesubnet" {
  #count      = length(var.public)
  vpc_id = aws_vpc.myvpc.id
  #cidr_block = element(var.public, count.index)
  cidr_block = "10.0.2.0/24"
  #availability_zone = element(var.azs, count.index)
  availability_zone = "ap-south-1b"
  #map_public_ip_on_launch = true
  map_public_ip_on_launch = false

  tags = {
    Name = "myprivatesubnet"
  }
}

resource "aws_subnet" "peersubnet" {
  #count      = length(var.public)
  vpc_id = aws_vpc.peervpc.id
  #cidr_block = element(var.public, count.index)
  cidr_block = "10.1.1.0/24"
  #availability_zone = element(var.azs, count.index)
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mysubnet"
  }
}

resource "aws_subnet" "peerprivatesubnet" {
  #count      = length(var.public)
  vpc_id = aws_vpc.peervpc.id
  #cidr_block = element(var.public, count.index)
  cidr_block = "10.1.2.0/24"
  #availability_zone = element(var.azs, count.index)
  availability_zone = "ap-south-1b"
  #map_public_ip_on_launch = true
  map_public_ip_on_launch = false

  tags = {
    Name = "myprivatesubnet"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_internet_gateway" "peerigw" {
  vpc_id = aws_vpc.peervpc.id

  tags = {
    Name = "peerigw"
  }
}

resource "aws_eip" "myeip" {
  depends_on = [aws_internet_gateway.myigw]
}

resource "aws_nat_gateway" "myprivatenatgw" {
  #connectivity_type = "private"
  subnet_id     = aws_subnet.mysubnet.id
  allocation_id = aws_eip.myeip.id

  tags = {
    Name = "myprivatenatgw"
  }
}

resource "aws_route_table" "myroute" {
  vpc_id = aws_vpc.myvpc.id
  #subnet_id = aws_subnet.mysubnet.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "myroute"
  }
}

resource "aws_route_table" "myprivateroute" {
  vpc_id = aws_vpc.myvpc.id
  #subnet_id = aws_subnet.mysubnet.id

  route {
    cidr_block = "0.0.0.0/0"
    #gateway_id = aws_internet_gateway.myigw.id
    gateway_id = aws_nat_gateway.myprivatenatgw.id
  }

  tags = {
    Name = "myprivateroute"
  }
}

resource "aws_route_table_association" "myrta" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.myroute.id
}

resource "aws_route_table_association" "myprivaterta" {
  subnet_id      = aws_subnet.myprivatesubnet.id
  route_table_id = aws_route_table.myprivateroute.id
}

resource "aws_security_group" "mysecurity" {
  name        = "mysecurity"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "mysecurity"
  }
}

resource "aws_security_group" "myprivatesecurity" {
  name        = "myprivatesecurity"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "myprivatesecurity"
  }
}

resource "aws_security_group_rule" "public_out" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.mysecurity.id

}

resource "aws_security_group_rule" "private_out" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.myprivatesecurity.id

}

resource "aws_security_group_rule" "private_in" {

  type = "ingress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.myprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_http" {

  type = "ingress"

  from_port = 80

  to_port = 80

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.myprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_ssh" {

  type = "ingress"

  from_port = 22

  to_port = 22

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.myprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_https" {

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.myprivatesecurity.id

}



resource "aws_security_group_rule" "public_in_ssh" {

  type = "ingress"

  from_port = 22

  to_port = 22

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mysecurity.id

}



resource "aws_security_group_rule" "public_in_http" {

  type = "ingress"

  from_port = 80

  to_port = 80

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mysecurity.id

}



resource "aws_security_group_rule" "public_in_https" {

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mysecurity.id

}

resource "aws_instance" "myprojectinstance" {
  ami           = "ami-0e53db6fd757e38c7"
  instance_type = "t2.micro"
  key_name      = "MyALB"
  subnet_id     = aws_subnet.mysubnet.id
  #subnet_id                   = aws_subnet.myprivatesubnet.id
  associate_public_ip_address = true
  #security_group_id = aws_security_group.mysecurity.id
  #vpc_id            = aws_vpc.myvpc.id
  vpc_security_group_ids = [aws_security_group.mysecurity.id]
  #vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
  #security_group_id = aws_security_group.mysecurity.id
  user_data = file("myproject.sh")

  tags = {
    Name = "myprojectinstance"
  }
}

#resource "aws_instance" "myprojectprivateinstance" {
#ami           = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name      = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#subnet_id                   = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#security_group_id = aws_security_group.mysecurity.id
#vpc_id            = aws_vpc.myvpc.id
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#security_group_id = aws_security_group.mysecurity.id
#user_data = file("myprivate.sh")

#tags = {
#Name = "myprojectprivateinstance"
#}
#}


#resource "aws_instance" "my_testing" {
#ami = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#user_data = file("testing.sh")

#tags = {
#Name = "my_testing"
#}
#

resource "aws_instance" "my_private_instance" {
  ami                         = "ami-0e53db6fd757e38c7"
  instance_type               = "t2.micro"
  key_name                    = "MyALB"
  subnet_id                   = aws_subnet.myprivatesubnet.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.myprivatesecurity.id]
  user_data                   = file("testing.sh")

  tags = {
    Name = "my_private_instance"
  }
}

resource "aws_eip" "peereip" {
  depends_on = [aws_internet_gateway.peerigw]
}

resource "aws_nat_gateway" "peernatgw" {
  #connectivity_type = "private"
  subnet_id     = aws_subnet.peersubnet.id
  allocation_id = aws_eip.peereip.id

  tags = {
    Name = "peernatgw"
  }
}

resource "aws_route_table" "peerroute" {
  vpc_id = aws_vpc.peervpc.id
  #subnet_id = aws_subnet.mysubnet.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.peerigw.id
  }

  tags = {
    Name = "peerroute"
  }
}

resource "aws_route_table" "peerprivateroute" {
  vpc_id = aws_vpc.peervpc.id
  #subnet_id = aws_subnet.mysubnet.id

  route {
    cidr_block = "0.0.0.0/0"
    #gateway_id = aws_internet_gateway.myigw.id
    gateway_id = aws_nat_gateway.peernatgw.id
  }

  tags = {
    Name = "peerprivateroute"
  }
}

resource "aws_route_table_association" "peerrta" {
  subnet_id      = aws_subnet.peersubnet.id
  route_table_id = aws_route_table.peerroute.id
}

resource "aws_route_table_association" "peerprivaterta" {
  subnet_id      = aws_subnet.peerprivatesubnet.id
  route_table_id = aws_route_table.peerprivateroute.id
}

resource "aws_security_group" "peersecurity" {
  name        = "peersecurity"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.peervpc.id

  tags = {
    Name = "peersecurity"
  }
}

resource "aws_security_group" "peerprivatesecurity" {
  name        = "myprivatesecurity"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.peervpc.id

  tags = {
    Name = "peerprivatesecurity"
  }
}

resource "aws_security_group_rule" "public_out_peer" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.peersecurity.id

}

resource "aws_security_group_rule" "private_out_peer" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.peerprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_peer" {

  type = "ingress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.peerprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_http_peer" {

  type = "ingress"

  from_port = 80

  to_port = 80

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.peerprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_ssh_peer" {

  type = "ingress"

  from_port = 22

  to_port = 22

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.peerprivatesecurity.id

}

resource "aws_security_group_rule" "private_in_https_peer" {

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.peerprivatesecurity.id

}



resource "aws_security_group_rule" "public_in_ssh_peer" {

  type = "ingress"

  from_port = 22

  to_port = 22

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.peersecurity.id

}



resource "aws_security_group_rule" "public_in_http_peer" {

  type = "ingress"

  from_port = 80

  to_port = 80

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.peersecurity.id

}



resource "aws_security_group_rule" "public_in_https_peer" {

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.peersecurity.id

}

resource "aws_instance" "peer_public_instance" {
  ami           = "ami-0e53db6fd757e38c7"
  instance_type = "t2.micro"
  key_name      = "MyALB"
  subnet_id     = aws_subnet.peersubnet.id
  #subnet_id                   = aws_subnet.myprivatesubnet.id
  associate_public_ip_address = true
  #security_group_id = aws_security_group.mysecurity.id
  #vpc_id            = aws_vpc.myvpc.id
  vpc_security_group_ids = [aws_security_group.peersecurity.id]
  #vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
  #security_group_id = aws_security_group.mysecurity.id
  user_data = file("peerpublic.sh")

  tags = {
    Name = "peer_project_instance"
  }
}

#resource "aws_instance" "myprojectprivateinstance" {
#ami           = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name      = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#subnet_id                   = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#security_group_id = aws_security_group.mysecurity.id
#vpc_id            = aws_vpc.myvpc.id
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#security_group_id = aws_security_group.mysecurity.id
#user_data = file("myprivate.sh")

#tags = {
#Name = "myprojectprivateinstance"
#}
#}


#resource "aws_instance" "my_testing" {
#ami = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#user_data = file("testing.sh")

#tags = {
#Name = "my_testing"
#}
#

resource "aws_instance" "my_test_peer" {
  ami                         = "ami-0e53db6fd757e38c7"
  instance_type               = "t2.micro"
  key_name                    = "MyALB"
  subnet_id                   = aws_subnet.peerprivatesubnet.id
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.peerprivatesecurity.id]
  user_data                   = file("peerprivate.sh")

  tags = {
    Name = "my_test_peer"
  }
}

resource "aws_vpc_peering_connection" "peering" {
  vpc_id      = aws_vpc.myvpc.id
  peer_vpc_id = aws_vpc.peervpc.id
  auto_accept = true
}

resource "aws_vpc_peering_connection_accepter" "peeraccepter" {
#provider                  = aws.peer
vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
auto_accept               = true

tags = {
Side = "Accepter"
}
}

resource "aws_route" "route_to_myvpc" {
  route_table_id         = aws_route_table.myprivateroute.id
  destination_cidr_block = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "route_to_peervpc" {
  route_table_id         = aws_route_table.myroute.id
  destination_cidr_block = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "myvpc_to_route" {
  route_table_id         = aws_route_table.peerprivateroute.id
  destination_cidr_block = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}

resource "aws_route" "peervpc_to_route" {
  route_table_id         = aws_route_table.peerroute.id
  destination_cidr_block = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
}









