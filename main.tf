terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Ensures compatibility with recent AWS provider versions
    }
  }
  
  required_version = ">= 1.0.0" # Ensures Terraform version is compatible
}

provider "aws" {
  region = "us-east-2" # Specify the AWS region
}

# Step 1: Create Security Group in Default VPC
resource "aws_security_group" "devops_sg" {
  name        = "My-security-group"
  description = "Allow SSH, HTTP, HTTPS, and custom ports"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (Not secure for production)
    description = "SSH access"
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access from anywhere
    description = "HTTP access"
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS access from anywhere
    description = "HTTPS access"
  }
  
  # Allow Custom Ports
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to frontend port
    description = "Frontend port access"
  }
  
  ingress {
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to backend port
    description = "Backend port access"
  }
     
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to MongoDB port
    description = "MongoDB port access"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = {
    Name = "My-security-group"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Step 2: Create EC2 Instance with Security Group
resource "aws_instance" "free_tier_instance" {
  ami                    = "ami-0100e595e1cc1ff7f" # Amazon Linux 2023 AMI
  instance_type          = "t2.micro"              # Free tier eligible instance type
  key_name               = "devops"                # Make sure this key pair exists in your AWS account
  
  # Attach Security Group by ID
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  
  # Improved user data script with error handling
  user_data = <<-EOF
              #!/bin/bash
              # Update system packages
              sudo dnf update -y || echo "Failed to update packages"
              
              # Install Docker
              sudo dnf install -y docker || echo "Failed to install Docker"
              
              # Start and enable Docker service
              sudo systemctl start docker || echo "Failed to start Docker"
              sudo systemctl enable docker || echo "Failed to enable Docker"
              
              # Add ec2-user to docker group
              sudo usermod -aG docker ec2-user || echo "Failed to add user to Docker group"
              
              # Create a flag file to indicate successful provisioning
              touch /tmp/provisioning_completed
              EOF
              
  root_block_device {
    volume_size = 8  # Default is usually 8 GB, but explicitly set for clarity
    volume_type = "gp3"  # Using gp3 for better performance at the same cost
    encrypted   = true   # Enable encryption for better security
  }
  
  # Enable detailed monitoring (optional, but useful for monitoring)
  monitoring = true
  
  tags = {
    Name        = "AmazonLinux2023Instance"
    Environment = "Development"
    Provisioner = "Terraform"
  }
}

# Step 3: Output important information
output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.free_tier_instance.id
}

output "instance_public_ip" {
  description = "The public IP of the created EC2 instance"
  value       = aws_instance.free_tier_instance.public_ip
}

output "instance_public_dns" {
  description = "The public DNS of the created EC2 instance"
  value       = aws_instance.free_tier_instance.public_dns
}

output "security_group_id" {
  description = "The ID of the created security group"
  value       = aws_security_group.devops_sg.id
}