#!/bin/bash
set -eE -o functrace
failure() {
  local lineno=$1
  local msg=$2
  echo "Failed at $lineno: $msg"
}
trap 'failure ${LINENO} "$BASH_COMMAND"' ERR

USERID=$(id -u)
LOGFILE="docker-install.log"

R="\e[31m"
N="\e[0m"
G="\e[32m"

if [ $USERID -ne 0 ]
then
    echo -e "$R Please run this script with root access $N"
    exit 1
fi

yum install -y yum-utils &>>$LOGFILE
echo -e "yum-utils ... $G Installed $N"

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>>$LOGFILE
echo -e "Adding Docker repo ... $G Done $N"

yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y &>>$LOGFILE

echo -e "Docker Enginer $G Installed $N"

echo "Starting Docker"
systemctl start docker &>>$LOGFILE

echo "Enabling Docker"
systemctl enable docker &>>$LOGFILE

usermod -aG docker centos

echo "Dockr installation completed, logout and login again"