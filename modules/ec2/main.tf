# A Security Group acts as a virtual firewall for the instance
resource "aws_security_group" "instance_sg" {
  name        = "instancess-${var.environment}"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id = var.vpc_id

  # Allow HTTP traffic from anywhere
  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world
  }

  # Allow SSH traffic (port 22) from anywhere for debugging
  # WARNING: For production, you should restrict this to your office IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-instance-${var.environment}"
  }
}

# This is the script that will run when the EC2 instance first boots up
# It installs and starts a simple web server
data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")
  vars = {
    environment = var.environment
  }
}

# The EC2 Instance resource
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data              = data.template_file.user_data.rendered # Run the script on boo
  
  tags = {
    Name = "AppServer-${var.environment}"
    Environment = var.environment
  }
}
