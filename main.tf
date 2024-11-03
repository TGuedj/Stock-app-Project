############################################
##########          VPC
############################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.1.0.0/16"  # Update to match the VPC CIDR block

  azs                = ["us-east-1a", "us-east-1b"]
  private_subnets    = ["10.1.3.0/24", "10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]  # Updated private subnets
  public_subnets     = ["10.1.1.0/24", "10.1.2.0/24"]  # Updated public subnets
  enable_nat_gateway = true
  create_igw         = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

############################################
##########    EC2  & EC2 SG    #############
############################################
resource "aws_security_group" "app_sg" {
  name        = "app_sg"
  description = "Security group for application instances"
  vpc_id      = module.vpc.vpc_id

  # ALB (Port 80) - Open to all
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic to ALB"
  }

  # Stock App (Port 5001) - Open to all
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow traffic to Stock app (open to the world)"
  }

  # MongoDB (Port 27017) - Restricted to specific IP and internal VPC
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["5.29.141.144/32", "10.1.0.0/16"]
    description = "Allow traffic to MongoDB from specified IP and within VPC"
  }

  # Mongo Express (Port 8081) - Restricted to specific IP and internal VPC
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["5.29.141.144/32", "10.1.0.0/16"]
    description = "Allow traffic to Mongo Express from specified IP and within VPC"
  }

  # Promtail (Port 9080) - Restricted to specific IP and internal VPC
  ingress {
    from_port   = 9080
    to_port     = 9080
    protocol    = "tcp"
    cidr_blocks = ["5.29.141.144/32", "10.1.0.0/16"]
    description = "Allow traffic to Promtail from specified IP and within VPC"
  }

  # Grafana (Port 3000) - Restricted to specific IP and internal VPC
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["5.29.141.144/32", "10.1.0.0/16"]
    description = "Allow traffic to Grafana from specified IP and within VPC"
  }

  # Loki (Port 3100) - Restricted to specific IP and internal VPC
  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["5.29.141.144/32", "10.1.0.0/16"]
    description = "Allow traffic to Loki from specified IP and within VPC"
  }

  # Prometheus Metrics (Port 8000) - Restricted to specific IP and internal VPC
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["5.29.141.144/32", "10.1.0.0/16"]
    description = "Allow traffic to Prometheus metrics from specified IP and within VPC"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "app_sg"
  }
}



module "web_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"
  depends_on = [ module.vpc ]
  for_each = var.instances

  name                   = each.key
  instance_type          = "t2.micro"
  key_name               = "vockey"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.allow_all_tcp_http_ssh.id] 

  # Use the output from the VPC module directly for private subnets
  subnet_id = element(module.vpc.private_subnets, index(keys(var.instances), each.key))


  user_data = each.value.user_data

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = each.key
  }
}