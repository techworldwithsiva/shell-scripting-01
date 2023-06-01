#!/bin/bash

directory=/home/centos/logs

DATE=$(date +%F)
LOG_FILE="$DATE.log"

INPUT=$(find $directory -name "*.log" -type f -mtime +14)

while IFS= read line;
do
    echo "Deleting log file: $line" &>>$LOG_FILE
    rm -rf $line
done <<< "$INPUT"