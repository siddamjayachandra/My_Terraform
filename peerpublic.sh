#!/bin/bash
yum install httpd -y
yum update -y
service httpd start
chkconfig httpd on
echo "<html><h1>Welcome to public peer server</h1></html>" > /var/www/html/index.html