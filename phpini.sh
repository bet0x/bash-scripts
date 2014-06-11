#!/bin/bash
# PHP Swiss Army Knife
# Version 1.1.02
# Author: Josh Grancell
#
# Requirements: Server is an A2 Hosting Managed Shared Server
# PHP Versions: 5.3, 5.4, 5.5. Untested, but most likely workable, with 5.2 and 5.1
# Supported PHP Flags: magic quotes, fopen, upload size, input vars, date.timezone
# The tabbed comments will be removed once the script is finalized
#  ------------------------------------------------------------------------------  #

function prompts() {
    echo -ne "\033[32m"                                         #Green text color
    echo -n "Enter username: "
    read user
    echo "You have selected cPanel user: $user"

    if [ ! -f /var/cpanel/users/"$user" ]; then                 #Given username is invalid
        echo -ne "\033[31m"                                     #Red color
        echo "\033[31m Invalid User. Exiting"
        echo -ne "\033[0;39m"                                   #Reset color
        exit 1
    else                                                        #Username is valid
        echo "Select php.ini flag: "
        echo "1. Set allow_url_fopen to On          4. Set max_input_vars to a custom value"
        echo "2. Set magic_quotes_gpc to Off        5. Change the default timezone"
        echo "3. Change file upload size            6. Change the PHP memory limit"
        read -p "Selection: " flag

        #Getting and saving more information to $value
        if [ "$flag" = "3" ]; then
            echo -n "Please provide an updated upload size, including suffix (example: 512M): "
            read value
        elif [ "$flag" = "4" ]; then
            echo -n "Please provide a new max_input_vars value: "
            read value
        elif [ "$flag" = "5" ]; then
            echo "Legal timezones can be found at this address: http://www.php.net/manual/en/timezones.php"
            echo -n "Please specify a legal PHP timezone: "
            read value
        elif [ "$flag" = "6" ]; then
            echo -n "Please provide an updated memory_limit, including suffix (example: 512M): "
            read value
        fi

        #Determining server type
        if grep -s "CloudLinux" /etc/redhat-release; then       #Server is Reseller/Shared
            server="shared"
            ini=/home/$user/public_html/php.ini
            if [ ! -e "$ini" ]; then                            #No php.ini, we'll create
                echo "A current php.ini file does not exist. Please select the PHP version to copy:"
                echo "1. Server Default (Usually PHP 5.3.2x)"
                echo "2. PHP 5.4.8"
                echo "3. PHP 5.5.0"
                read -p "Selection: " php
            fi
        elif grep -s "CentOS" /etc/redhat-release; then         #Server is ManVPS/Dedi
            server="dedicated"
        fi
    fi
}

#All Shared .ini manupulation is in this fuction
function sharedini() {                                          
    if [ "$php" = "2" ]; then                                   #PHP version 5.4.8
        if [ -e /opt/php/php-5.4.8/lib/php.ini ]; then          #PHP version exists on server
            echo "Creating the custom PHP 5.4.8 php.ini file."
            cp /opt/php/php-5.4.8/lib/php.ini "$ini"
        else
            echo -ne "\033[31m"                                 #Red color
            echo "PHP 5.4.8 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
            cp /usr/local/lib/php.ini "$ini"
            echo -ne "\033[32m"                                 #Green color
        fi
    elif [ "$php" = "3" ]; then                                 #PHP version 5.5.0
        if [ -e /opt/php/php-5.5.0/lib/php.ini ]; then          #PHP version exists on server
            echo "Creating the custom PHP 5.5.0 php.ini file."
            cp /opt/php/php-5.5.0/lib/php.ini "$ini"
        else
            echo -ne "\033[31m"                                 #Red color
            echo "PHP 5.5.0 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
            cp /usr/loca/lib/php.ini "$ini"
            echo -ne "\033[32m"                                 #Green color
        fi
    elif [ "$php" = "1" ]; then                                 #Default server php.ini
        echo "Creating the custom PHP php.ini file using the server default."
        cp /usr/local/lib/php.ini "$ini"
    fi

    #chmod/chowning the file for safety.
    chown $user:$user "$ini"
    chmod 640 "$ini"
}


function sharedwork() {

    #Fopen
    if [ "$flag" = "1" ]; then
        if grep -xq "allow_url_fopen = Off" "$ini"; then

            echo "Setting allow_url_fopen to On in existing php.ini file."
            sed -i '/allow_url_fopen/d' "$ini"
            sed -i '/allow_url_include/d' "$ini"
            {
                echo ""
                echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
                echo allow_url_fopen = On
                echo allow_url_include = On
            } >> "$ini"
        else
            echo "allow_url_fopen is already enabled for this account."
        fi

    #Magic Quotes [ Removed PHP 5.4+ ]
    elif [ "$flag" = "2" ]; then
        if grep -xq "magic_quotes_gpc = On" "$ini"; then
            echo "Setting magic_quotes_gpc to Off in existing php.ini file"
            sed -i '/allow_url_fopen/d' "$ini"
            {
                echo ""
                echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
                echo magic_quotes_gpc = Of
            } >> "$ini"
        else
            echo "Magic Quotes is already disabled for this account."
            echo "Please note: Magic Quotes is removed from PHP 5.4+"
        fi

    #Upload/Post Size
    elif [ "$flag" = "3" ]; then
        echo "Setting post_max_size and upload_max_filesize to $value."
        sed -i '/upload_max_filesize/d' "$ini"
        sed -i '/post_max_size/d' "$ini"
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
            echo upload_max_filesize = "$value"
            echo post_max_size = "$value"
        } >> "$ini"

    #Max Input Vars Flag
    elif [ "$flag" = "4" ]; then
        echo "Setting max_input_vars to $value."
        sed -i '/max_input_vars/d' "$ini"
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
            echo max_input_vars = "$value"
        } >> "$ini"

    #Timezone Flag
    elif [ "$flag" = "5" ]; then
        echo "Setting date.timezone to $value."
        sed -i '/date.timezone/d' "$ini"
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
            echo date.timezone = "$value"
        } >> "$ini"

    #Memory Limit Flag
    elif [ "$flag" = "6" ]; then
        echo "Setting memory_limit to $value."
        sed -i '/memory_limit/d' "$ini"
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
            echo memory_limit = "$value"
        } >> "$ini"
    else
        echo -ne "\033[31m"                                     #Red color
        echo "A correct flag was not specified. Re-run the script, and use the number for the flag you would like to specify."
        echo -ne "\033[0;39m"                                   #Reset color
        exit 1
    fi

    #Final check to see if there is an .htaccess that would affect PHP
    for files in find /home/"$user"/ -name "php.ini"
    do
        echo "Notice: php.ini file found at $files"
        #This is the future home of the diff between new php.ini and the found php.ini
    done

    #Final check to see if there is an .htaccess file that would affect PHP
    for htaccesses in find /home/"$user"/ -name ".htaccess"     #New for loop that will check all directories, recusively
    do
        if grep -q "x-httpd-php" $htaccesses; then
            echo -ne "\033[31m"                                 #Red color
            echo "There is an .htaccess in $htaccesses with PHP version directives."
            grep "x-httpd-php" $htaccesses
            echo -n " would you like to remove it? (y/n) "
            read delme
            if [ "$delme" = "y" ]; then
                sed -i '/x-httpd-php/d' $htaccesses
            fi
        fi
    done

    echo -ne "\033[32m"                                         #Green color
    echo "Script complete. Please verify the new php.ini, or run the script again if you need another flag updated."
    echo -ne "\033[0;39m"                                       #Reset color
}

prompts

if [ $server = "shared" ]; then
    sharedini
    sharedwork
elif [ $server = "dedicated" ]; then
    echo "This is not a Shared server. You will need to manually edit the WHM php configuration."
fi

exit 0
