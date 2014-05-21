#!/bin/bash
#Custom PHP.ini Creator and Updater
#Author: Josh Grancell
#Updated: 5-19-2014
#
#This script takes no command-line arguments, and prompts for all necessary information.
#Currently available PHP versions: 5.5.0, 5.4.8, 5.3.2x (Server Default)
#This script only works on cPanel enabled servers, however the paths can be updated to work on any servertype
#The following PHP changes are supported: Magic Quotes, fopen, upload size, max_input_vars, and date.timezone

function prompts() {
    echo -ne "\033[32m"
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
        echo "3. Change File Upload Size (post and upload values)"
        echo "4. Set max_input_vars to a custom value"
        echo "5. Change default timezone (date.timezone)"
        echo "6. Change the PHP memory_limit"
        read -p "Selection: " flag

        #Getting more information for certain flags
        if [ "$flag" = "3" ]; then
            echo -n "Please provide an updated Upload Size, including M/G suffix: "
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
        elif [ "$flag" = "6" ]; then
            echo -n "Please provide an updated memory_limit, including M/G suffix: "
            read value
        fi

        #Defining the INI file location
        ini=/home/$user/public_html/php.ini

        if [ ! -e "$ini" ]; then
            #No php.ini file currently, asking for what version to create (using global versions)
            echo  "A current php.ini file does not exist. Please select the PHP version to copy:"
            echo "1. Server Default (Usually PHP 5.3.2x)"
            echo "2. PHP 5.4.8"
            echo "3. PHP 5.5.0"
            read -p "Selection: " php
        fi
    fi
}

#All intial .ini manipulation, including creation and setting ownership, are in this function
function inimanip() {  
    #All code that creates the new php.ini is found in this function
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
    elif [ "$php" = "1" ]; then
        #We're using the server default php.ini
        echo "Creating the custom PHP php.ini file using the server default."
        cp /usr/local/lib/php.ini "$ini"
    else
        #The custom php.ini already exists, and I haven't figured out how to find version of a specific php.ini yet.
        #Purposefully em
    fi

    #chmod/chowning the file for safety.
    chown $user:$user "$ini"
    chmod 600 "$ini"
}


function work() {

    #Fopen
    if [ "$flag" = "1" ]; then
        if grep -xq "allow_url_fopen = Off" "$ini"; then
            #Fopen is disabled, so let's enable it
            echo "Setting allow_url_fopen to On in existing php.ini file."
            #Deleting the current fopen settings in the php.ini
            sed -i '/allow_url_fopen/d' "$ini"
            sed -i '/allow_url_include/d' "$ini"
            #Adding our new settings at the end
            {
                echo ""
                echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
                echo allow_url_fopen = On
                echo allow_url_include = On
            } >> $ini
        else
            echo "allow_url_fopen is already enabled for this account."
        fi

    #Magic Quotes [ Removed PHP 5.4+ ]
    elif [ "$flag" = "2" ]; then
        if grep -xq "magic_quotes_gpc = On" "$ini"; then
            #This is v5.3 or earlier, so let's disablee MQGPC
            echo "Setting magic_quotes_gpc to Off in existing php.ini file"
            #Deleting the current magic quotes line
            sed -i '/allow_url_fopen/d' "$ini"
            #Adding our new magic quotes line
            {
                echo ""
                echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
                echo magic_quotes_gpc = Of
            } >> $ini
        else
            echo "Magic Quotes is already disabled for this account."
            echo "Please note: Magic Quotes is removed from PHP 5.4+"
        fi

    #Upload/Post Size
    elif [ "$flag" = "3" ]; then
        echo "Setting post_max_size and upload_max_filesize to $value."
        #Deleting the current upload lines
        sed -i '/upload_max_filesize/d' "$ini"
        sed -i '/post_max_size/d' "$ini"
        #Adding our new upload lines
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
            echo upload_max_filesize = "$value"
            echo post_max_size = "$value"
        } >> $ini

    #Max Input Vars Flag
    elif [ "$flag" = "4" ]; then
        echo "Setting max_input_vars to $value."
        #Deleting the max_input_vars line
        sed -i '/max_input_vars/d' "$ini"
        #Adding our new max_input_vars line
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
            echo max_input_vars = "$value"
        } >> $ini

    #Timezone Flag
    elif [ "$flag" = "5" ]; then
        echo "Setting date.timezone to $value."
        #Deleting date.timezone line
        sed -i '/date.timezone/d' "$ini"
        #Adding our date.timezone line
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
            echo date.timezone = "$value"
        } >> $ini

    #Memory Limit Flag
    elif [ "$flag" = "6" ]; then
        echo "Setting memory_limit to $value."
        #Deleting the max_input_vars line
        sed -i '/memory_limit/d' "$ini"
        #Adding our new max_input_vars line
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on `date +%F`"
            echo memory_limit = "$value"
        } >> $ini
    else
        echo "A correct flag was not specified. Re-run the script, and use the number for the flag you would like to specify."
        exit 1
    fi

    #Final check to see if there is an .htaccess that would affect PHP
    if [ -e /home/$user/.htaccess ]; then
        if grep "x-httpd-php" /home/$user/.htaccess; then
            echo "There is an .htaccess in the /home/$user with PHP version directives."
        fi
    fi
    if [ -e /home$user/public_html/.htaccess ]; then
        if grep "x-httpd-php" /home/$user/public_html/.htaccess; then
            echo "There is an .htaccess in /home/$user/public_html with PHP version directives."
        fi
    fi
}

prompts
inimanip
work

echo "Script complete. Please verify the new php.ini, or run the script again if you need another flag updated."

exit 0
