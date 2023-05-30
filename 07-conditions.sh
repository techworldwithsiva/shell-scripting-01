#!/bin/bash

#getting the user ID.
USERID=$(id -u)

#checking the user is root or not
if [ $USERID -eq 0 ] #-eq, -ne,-gt, -lt
then
    echo "User has root access"
else
    echo "You are not root user, Please run with root privelege"
    exit 1
fi

echo "Installing GIT"

yum install git -y

#checking the exit status
if [ $? -eq 0 ]
then
    echo "Installed Git successfully"
else
    echo "Git is not installed"
    exit 12
fi