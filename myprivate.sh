#!/bin/bash
yum install httpd -y
yum update -y
service httpd start
chkconfig httpd on
echo "<html><h1>Welcome to my private Home</h1></html>" > /var/www/html/index.html