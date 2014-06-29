#!/bin/bash
# Nginx backup Script v1.0
# Author - Josh Grancell
# License - GNU GPL v3

#Defining the folders
webserver_folder="/web"
root_backup_director="/backup"

month_folder=$(date +%Y-%m)
date_folder=$(date +%F)
destination_folder="$root_backup_directory"/"$month_folder"/"$date_folder"
s3_container="grancell-vps-backup"

#Archiving the files
archive_file="nginx-backup-$(date +%F).tar.gz"
mkdir -p "$destination_folder"
/bin/tar -czvf "$destination_folder"/"$archive_file" "$webserver_folder" > /dev/null

#Updating out SSH MOTD and sending to Amazon S3
if [ -e "$destination_folder"/"$archive_file" ]; then
        echo "Backup of nginx files complete for $(date +%F)" >> /var/log/backup.log
        /usr/local/bin/aws s3 cp "$destination_folder"/"$archive_file" s3://"$s3_container"/"$month_folder"/"$date_folder"/"$archive_file" >> /var/log/backup-aws.log
else
        echo "Backup FAILED for nginx files for $(date +%F)" >> /var/log/backup.log
        if grep "No backups have failed recently" /var/log/backup-failures.log; then
                echo "Backup failed for Nginx files for $(date +%F)" > /var/log/backup-failures.log
        else
                echo "Backup failed for Nginx files for $(date +%F)" >> /var/log/backup-failures.log
        fi
fi
