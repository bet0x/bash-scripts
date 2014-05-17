#!/bin/bash
#Custom PHP.ini Creator and Updater
#Author: Josh Grancell
#Updated: 5-17-2014
#
#This script takes no command-line arguments, and prompts for all necessary information.
#Currently available PHP versions: 5.5.0, 5.4.8, 5.3.2x (Server Default)
#This script only works on cPanel enabled servers, however the paths can be updated to work on any servertype
#The following PHP changes are supported: Magic Quotes, fopen, upload size, max_input_vars, and date.timezone

function main() {
    echo -n "Enter username: "
    read user
    echo "You have selected cPanel user: $user"

    if [ ! -f /var/cpanel/users/"$user" ]; then
        #Username given is invalid
        echo "Invalid User. Exiting"
        exit 1
    else
        #Username is valid, now requesting the php flag that needs to be customized and setting that to $flag
        echo "Select php.ini flag: "
        echo "1. Set allow_url_fopen to On"
        echo "2. Set magic_quotes_gpc to Off"
        echo "3. Change File Upload Size"
        echo "4. Set max_input_vars to a custom value"
        echo "5. Change Default Timezone"
        read -p "Selection: " flag

        if [ "$flag" = "3" ]; then
            echo -n "Please provide an updated Upload Size, including MB/GB suffix: "
            read value
        elif [ "$flag" = "4" ]; then
            echo -n "Please provide a new max_input_vars value: "
            read value
        elif [ "$flag" = "5" ]; then
            echo "Legal timezones can be found at this address: http://www.php.net/manual/en/timezones.php"
            echo "Common timezones include: UTC, Europe/London (GMT) Europe/Berlin (GMT+1), Europe/Athens (GMT+2), Europe/Moscow (GMT+3), Asia/Damascus (GMT+4)"
            echo "Asia/Yekaterinburg (GMT+5), Asia/Ho_Chi_Minh (GMT+6), Asia/Beijing (GMT+7), Asia/Tokyo (GMT+8), Australia/Sydney (GMT+8)"
            echo "US/Central, US/Eastern, US/Mountain, US/Pacific"
            echo -n "Please specify a legal PHP timezone: "
            read value
        fi
    fi
}

function work() {
    ini=/home/$user/public_html/php.ini
    #Checking to see if the php.ini file exists
    if [ ! -e "$ini" ]; then
        #A custom php.ini file does not already exist. Let's go head and create one
        echo  "A current php.ini file does not exist. Please select the PHP version to copy:"
        echo "1. Server Default (Usually PHP 5.3.2x)"
        echo "2. PHP 5.4.8"
        echo "3. PHP 5.5.0"
        read -p "Selection: " php

        if [ "$php" = "2" ]; then
            #We're using PHP version 5.4.8
            if [ -e /opt/php/php-5.4.8/lib/php.ini ]; then
                #This version of PHP exists on the server, so now we will copy it to the cPanel user directory
                echo "Creating the custom PHP 5.4.8 php.ini file."
                cp /opt/php/php-5.4.8/lib/php.ini "$ini"
            else
                #This version of PHP does not exist on the server
                echo "PHP 5.4.8 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
                cp /usr/loca/lib/php.ini "$ini"
            fi
        elif [ "$php" = "3" ]; then
            #We're using PHP version 5.5.0
            if [ -e /opt/php/php-5.5.0/lib/php.ini ]; then
                #This version of PHP exists on the server, so now we will copy it to the cPanel user directory
                echo "Creating the custom PHP 5.5.0 php.ini file."
                cp /opt/php/php-5.5.0/lib/php.ini "$ini"
            else
                #This version of PHP does not exist on the server
                echo "PHP 5.5.0 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
                cp /usr/loca/lib/php.ini "$ini"
            fi
        else
            #We're using the server default php.ini
            echo "Creating the custom PHP php.ini file using the server default."
            cp /usr/local/lib/php.ini "$ini"
        fi
    fi


    #The php.ini file exists, either because we created it or because it already existed.
    chown $user:$user "$ini"
    chmod 600 "$ini"

    if [ "$flag" = "1" ]; then
        if grep -xq "allow_url_fopen = Off" "$ini"; then
            #Fopen is disabled, so let's enable it
            echo "Setting allow_url_fopen to On in existing php.ini file."
            #Deleting the current fopen settings in the php.ini
            sed -i '/allow_url_fopen/d' "$ini"
            sed -i '/allow_url_include/d' "$ini"
            #Adding our new settings at the end
            echo "" >> "$ini"
            echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`" >> "$ini"
            echo allow_url_fopen = On >> "$ini"
            echo allow_url_include = On >> "$ini"
        else
            echo "allow_url_fopen is already enabled for this account."
        fi

    elif [ "$flag" = "2" ]; then
        if grep -xq "magic_quotes_gpc = On" "$ini"; then
            #This is v5.3 or earlier, so let's disablee MQGPC
            echo "Setting magic_quotes_gpc to Off in existing php.ini file"
            #Deleting the current magic quotes line
            sed -i '/allow_url_fopen/d' "$ini"
            #Adding our new magic quotes line
            echo "" >> "$ini"
            echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`" >> "$ini"
            echo magic_quotes_gpc = Off >> "$ini"
        else
            echo "Magic Quotes is already disabled for this account."
            echo "Please note: Magic Quotes is removed from PHP 5.4+"
        fi
    elif [ "$flag" = "3" ]; then
        echo "Setting post_max_size and upload_max_filesize to $value."
        #Deleting the current upload lines
        sed -i '/upload_max_filesize/d' "$ini"
        sed -i '/post_max_size/d' "$ini"
        #Adding our new upload lines
        echo "" >> "$ini"
        echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
        echo upload_max_filesize = "$value" >> "$ini"
        echo post_max_size = "$value" >> "$ini"
    elif [ "$flag" = "4" ]; then
        echo "Setting max_input_vars to $value."
        #Deleting the max_input_vars line
        sed -i '/max_input_vars/d' "$ini"
        #Adding our new max_input_vars line
        echo "" >> "$ini"
        echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
        echo max_input_vars = "$value" >> "$ini"
    elif [ "$flag" = "5" ]; then
        echo "Setting max_input_vars to $value."
        #Deleting the max_input_vars line
        sed -i '/max_input_vars/d' "$ini"
        #Adding our new max_input_vars line
        echo "" >> "$ini"
        echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
        echo max_input_vars = "$value" >> "$ini"
    elif [ "$flag" = "6" ]; then
        echo "Setting date.timezone to $value."
        #Deleting date.timezone line
        sed -i '/date.timezone/d' "$ini"
        #Adding our date.timezone line
        echo "" >> "$ini"
        echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
        echo date.timezone = "$value" >> "$ini"
    else
        echo "A correct flag was not specified. Re-run the script, and use the number for the flag you would like to specify"
        exit 1
    fi
}

main
work

echo "Process complete. Please verify in the .htaccess file for $user that no PHP Version changer code exists that may cause this to not function properly"

exit 0
