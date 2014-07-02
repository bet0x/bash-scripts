#!/bin/bash
# MariaDB TarGZ Backup Cronjob
# Version 1.1
# Author: Josh Grancell
# License: GNU GPL v3
#
# Requirements: MariaDB or MySQL. AWS CLI.
# Runs a backup of any databases you provide information for and then compresses, 
# saves in the local backup directory, and uploads to Amazon AWS
#  ------------------------------------------------------------------------------  #

#User configurable Settings
root="/backup"
s3_container=""

dbname1=""
dbuser1=""
dbpass1=""

dbname2=""
dbuser2=""
dbpass2=""


#Automatically setting folder names
month_folder=$(date +%Y-%m)
date_folder=$(date +%F)
destination_folder="$root"/"$month_folder"/"$date_folder"
temp_folder="$root"/temp/
mkdir -p "$root"/temp

#The function that runs the dumps
function mariadump() {
	mysqldump -h localhost -u "$1" -p"$2" "$3" | gzip > "$4""$5".sql.gz
}

#Database 1
backup_filename1=$dbname1-$(date +%F)
mariadump "$dbuser1" "$dbpass1" "$dbname1" "$temp_folder" "$backup_filename1"

#Database 2
backup_filename2=$dbname2-$(date +%F)
mariadump "$dbuser2" "$dbpass2" "$dbname2" "$temp_folder" "$backup_filename2"

#Running the tarballing
archive_file="mariadb-backup-$(date +%F).tar.gz"
/bin/tar -czvf "$destination_folder"/"$archive_file" "$temp_folder"

if [ -e "$destination_folder"/"$archive_file" ]; then
        echo "Backup of MariaDB files complete for $(date +%F)" >> /var/log/backup.log
        rm -rf "$root"/temp
        /usr/local/bin/aws s3 cp "$destination_folder"/"$archive_file" s3://"$s3_container"/"$month_folder"/"$date_folder"/"$archive_file" >> /var/log/backup-aws.log
else
        echo "Backup FAILED for mariadb files for $(date +%F)" >> /var/log/backup.log
        if grep "No backups have failed recently" /var/log/backup-failures.log; then
                echo "Backup failed for MariaDB databases for $(date +%F)" > /var/log/backup-failures.log
        else
                echo "Backup failed for MariaDB databases for $(date +%F)" >> /var/log/backup-failures.log
        fi
fi
