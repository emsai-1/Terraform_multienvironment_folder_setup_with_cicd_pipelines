#!/bin/bash
# This script is run on instance startup

# Update packages and install a simple Apache web server
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd

# Create a simple index.html file that shows which environment this is
echo "<h1>Hello World from the ${environment} Environment!</h1>" > /var/www/html/index.html
