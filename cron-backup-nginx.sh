#!/bin/bash
# Author - Josh Grancell
# Purpose - Creates a .tar.gz backup of your webroot directory
# and uploads it to your Amazon S3 account.

#Defining our folders
month_folder=$(date +%Y-%m)
date_folder=$(date +%F)
destination_folder=/backup/"$month_folder"/"$date_folder"
s3_container="grancell-vps-backup"
webroot="/web"

#Archiving our file
archive_file="nginx-backup-$(date +%F).tar.gz"
mkdir -p "$destination_folder"
/bin/tar -czvf "$destination_folder"/"$archive_file" "$webroot" > /dev/null

#Logging our archiving
if [ -e "$destination_folder"/"$archive_file" ]; then
        echo "Backup of nginx files complete for $(date +%F)" >> /var/log/backup.log
        
        #Sending the archive to Amazon S3 for data redundancy
        /usr/local/bin/aws s3 cp "$destination_folder"/"$archive_file" s3://"$s3_container"/"$month_folder"/"$date_folder"/"$archive_file" >> /var/log/backup-aws.log
else
        #Our backup failed - logging accordingly
        echo "Backup FAILED for nginx files for $(date +%F)" >> /var/log/backup.log
        if grep "No backups have failed recently" /var/log/backup-failures.log; then
                echo "Backup failed for Nginx files for $(date +%F)" > /var/log/backup-failures.log
        else
                echo "Backup failed for Nginx files for $(date +%F)" >> /var/log/backup-failures.log
        fi
fi
