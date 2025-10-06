#!/bin/bash
yum -y update
#### install ssm - already installed on AL2 so try commenting out this line
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
#### install cafe app
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum -y install httpd mariadb-server wget nmap
systemctl enable httpd
systemctl start httpd
systemctl enable mariadb
systemctl start mariadb
echo '<html><h1>Hello From Your Web Server!</h1></html>' > /var/www/html/index.html
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo '<?php phpinfo(); ?>' > /var/www/html/phpinfo.php
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/05-lab-mod6-challenge-RDS/s3/setup.tar.gz
tar -zxvf setup.tar.gz
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/05-lab-mod6-challenge-RDS/s3/db.tar.gz
tar -zxvf db.tar.gz
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/05-lab-mod6-challenge-RDS/s3/cafe.tar.gz
tar -zxvf cafe.tar.gz -C /var/www/html/
cd setup
echo "Setting the application parameter values in the Secrets Manager..."
#first get the region
region="us-east-1"
publicDNS=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
echo "Public DNS =" $publicDNS
#the set ssm params
aws secretsmanager create-secret --name "/cafe/showServerInfo" --secret-string "false" --region $region
aws secretsmanager create-secret --name "/cafe/timeZone" --secret-string "America/New_York"  --region $region
aws secretsmanager create-secret --name "/cafe/currency" --secret-string "$"  --region $region
aws secretsmanager create-secret --name "/cafe/dbUrl" --secret-string $publicDNS  --region $region
aws secretsmanager create-secret --name "/cafe/dbName" --secret-string "cafe_db"  --region $region
aws secretsmanager create-secret --name "/cafe/dbUser" --secret-string "root"  --region $region
aws secretsmanager create-secret --name "/cafe/dbPassword" --secret-string "Re:Start!9"  --region $region
#DONE running set-app-parameters.sh steps inline
#Configure the database
cd ../db/
./set-root-password.sh
./create-db.sh
#insert 24 rows of orders
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-200-ACACAD-3-113230/05-lab-mod6-challenge-RDS/s3/CafeDbDump.sql
sleep 2
sec="Re:Start!9"
mysql -u root -p$sec < CafeDbDump.sql
rm CafeDbDump.sql
hostnamectl set-hostname cafeserver