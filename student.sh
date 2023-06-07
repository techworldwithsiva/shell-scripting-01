#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
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

#install mariadb server
yum install mariadb-server -y
VALIDATE $? "Installing MariaDB"

#Starting mariadb server
systemctl start mariadb
VALIDATE $? "Starting MariaDB"

#Enabling mariadb server
systemctl enable mariadb
VALIDATE $? "Enabling MariaDB"

echo "create database if not exists studentapp;
use studentapp;

CREATE TABLE if not exists Students(student_id INT NOT NULL AUTO_INCREMENT, student_name VARCHAR(100) NOT NULL, student_addr VARCHAR(100) NOT NULL, student_age VARCHAR(3) NOT NULL, student_qual VARCHAR(20) NOT NULL, student_percent VARCHAR(10) NOT NULL, student_year_passed VARCHAR(10) NOT NULL, PRIMARY KEY (student_id));

grant all privileges on studentapp.* to 'student'@'localhost' identified by 'student@1';" > /tmp/student.sql

mysql < /tmp/student.sql
VALIDATE $? "Creating DB Schema, table, grant priveleges"