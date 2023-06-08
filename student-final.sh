#!/bin/bash

USAGE(){
    echo "USAGE: $0 <tomcat-version>" #$0--> scriptname, $#--> no of args #@--> all args $!--> PID
}


USERID=$(id -u)
DATE=$(date +%F)
LOGFILE="$DATE.log"
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
TOMCAT_VERSION=$1 #9.0.75



if [ -z $TOMCAT_VERSION ]
then
    USAGE
    exit 1
fi
#extracting tomcat major version
TOMCAT_MAJOR_VERSION=$(echo $TOMCAT_VERSION | cut -d "." -f1)

#forming download URL
TOMCAT_URL=https://dlcdn.apache.org/tomcat/tomcat-$TOMCAT_MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

#forming tar file
TOMCAT_TAR_FILE=$(echo $TOMCAT_URL | awk -F "/" '{print $NF}')

#forming tomcat dir
TOMCAT_DIR=$(echo $TOMCAT_TAR_FILE | sed -e 's/.tar.gz//g')

STUDENT_WAR_FILE=https://raw.githubusercontent.com/techworldwithsiva/shell-scripting-01/master/application/student.war
MYSQL_DRIVER=https://raw.githubusercontent.com/techworldwithsiva/shell-scripting-01/master/application/mysql-connector-5.1.18.jar

if [ $USERID -ne 0 ]
then
    echo -e "$R Please run this script with root access $N"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILED $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}


#install basic commands
yum install wget vim net-tools java-1.8.0-openjdk-devel -y &>>$LOGFILE

#install mariadb server
yum install mariadb-server -y &>>$LOGFILE
VALIDATE $? "Installing MariaDB"

#Starting mariadb server
systemctl start mariadb &>>$LOGFILE
VALIDATE $? "Starting MariaDB"

#Enabling mariadb server
systemctl enable mariadb &>>$LOGFILE
VALIDATE $? "Enabling MariaDB"

echo "create database if not exists studentapp;
use studentapp;

CREATE TABLE if not exists Students(student_id INT NOT NULL AUTO_INCREMENT, student_name VARCHAR(100) NOT NULL, student_addr VARCHAR(100) NOT NULL, student_age VARCHAR(3) NOT NULL, student_qual VARCHAR(20) NOT NULL, student_percent VARCHAR(10) NOT NULL, student_year_passed VARCHAR(10) NOT NULL, PRIMARY KEY (student_id));

grant all privileges on studentapp.* to 'student'@'localhost' identified by 'student@1';" > /tmp/student.sql

mysql < /tmp/student.sql
VALIDATE $? "Creating DB Schema, table, grant priveleges"

### Tomcat
mkdir -p /opt/tomcat
cd /opt/tomcat

if [ -d $TOMCAT_DIR ]
then
    echo -e "$Y Tomcat alread exists $N"
else
    wget $TOMCAT_URL &>>$LOGFILE
    VALIDATE $? "Downloading tomcat"
    tar -xf $TOMCAT_TAR_FILE &>>$LOGFILE
    VALIDATE $? "Untar tomcat"
fi

cd $TOMCAT_DIR/webapps

wget $STUDENT_WAR_FILE &>>$LOGFILE
VALIDATE $? "Downloading Student app"

cd ../lib
wget $MYSQL_DRIVER &>>$LOGFILE
VALIDATE $? "Downloading MySQL Driver"

cd ../conf
sed -i '/TestDB/ d' context.xml
VALIDATE $? "Removed existing DB config"
sed -i '$ i <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource" maxTotal="100" maxIdle="30" maxWaitMillis="10000" username="student" password="student@1" driverClassName="com.mysql.jdbc.Driver" url="jdbc:mysql://localhost:3306/studentapp"/>' context.xml
VALIDATE $? "Added DB resource in context.xml"

#NgINX
yum install nginx -y &>>$LOGFILE
VALIDATE $? "Installing Nginx"

echo 'location / {
     proxy_pass          http://127.0.0.1:8080/;
	 proxy_set_header Host $host;
	 proxy_set_header X-Real-IP $remote_addr;   
}' > /etc/nginx/default.d/student.conf
VALIDATE $? "Added student.conf"

sed -i '/location \/ {/,/}/d' /etc/nginx/nginx.conf
VALIDATE $? "Removed default location block"

# SELINUX to enable traffic from Nginx to tomcat
yum install policycoreutils-python-utils -y &>>$LOGFILE
VALIDATE $? "SELINUX related pacakges"
audit2allow -a -M nginx_tomcat_connect &>>$LOGFILE
semodule -i nginx_tomcat_connect.pp
VALIDATE $? "Allow Nginx to Tomcat"

cd /opt/tomcat/$TOMCAT_DIR/bin
sh shutdown.sh &>>$LOGFILE
sh startup.sh &>>$LOGFILE
VALIDATE $? "Tomcat started"

systemctl restart nginx
VALIDATE $? "NgInx restarted"

