#!/bin/bash
# PHP Swiss Army Knife
# Version 1.2
# Author: Josh Grancell
#
# Requirements: Server is an A2 Hosting Managed Shared Server
# PHP Versions: 5.3, 5.4, 5.5. Untested, but most likely workable, with 5.2 and 5.1
# Supported PHP Flags: magic quotes, fopen, upload size, input vars, date.timezone
# The tabbed comments will be removed once the script is finalized
#  ------------------------------------------------------------------------------  #

#All required prompts to get the server running.
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
    else                                                        #User exists. Giving mode choices
        echo "What would you like to do?"
        echo "1. Debug a broken/erroring PHP."
        echo "2. Create a default custom php.ini file."
        echo "3. Modify php flags in a custom php.ini file.."
        read -p "Selection: " choice 

        if [ "$choice" == "1" ]; then
            mode="debug"                                        #PHP error debugging mode
            echo "PHP Debugging mode enabled."
        elif [ "$choice" == "2" ]; then
            mode="default"                                      #Default custom php.ini creation mode
            echo "Default php.ini creation mode enabled."
        elif [ "$choice" == "3" ]; then
            mode="flags"                                        #Customized custom php.ini creation mode
            echo "Custom-flagged php.ini creation mode enabled."
            echo "Select php.ini flag: "
            echo "1. Set allow_url_fopen to On          4. Set max_input_vars to a custom value"
            echo "2. Set magic_quotes_gpc to Off        5. Change the default timezone"
            echo "3. Change file upload size            6. Change the PHP memory limit"
            read -p "Selection: " flag

            #Getting and saving more information to $value for specific flags
            if [ "$flag" = ="3" ]; then
                echo -n "Please provide an updated upload size, including suffix (example: 512M): "
                read value
            elif [ "$flag" == "4" ]; then
                echo -n "Please provide a new max_input_vars value: "
                read value
            elif [ "$flag" == "5" ]; then
                echo "Legal timezones can be found at this address: http://www.php.net/manual/en/timezones.php"
                echo -n "Please specify a legal PHP timezone: "
                read value
            elif [ "$flag" == "6" ]; then
                echo -n "Please provide an updated memory_limit, including suffix (example: 512M): "
                read value
            fi
        else
            echo -ne "\033[31m"                                 #Red color
            echo "Selection is not a numerical choice. Aborting."
            echo -ne "\033[0;39m"                               #Resetting color
            exit 1                                              #Clean exit on failed input
        fi

        if grep -qs "CloudLinux" /etc/redhat-release; then
            server="shared"
        else
            server="dedicated"
        fi

        #Setting the $server variable, and specifying the php version we're using.
        if [ "$mode" == "flags" -o "$mode" == "default" ]; then
            echo "Conditional statement completed successfully."
            #Determining server type
            ini=/home/$user/public_html/php.ini
            if [ ! -e "$ini" ]; then                            #No php.ini, we'll create
                echo "A current php.ini file does not exist. Please select the PHP version to copy:"
                echo "1. Server Default (Usually PHP 5.3.2x)"
                echo "2. PHP 5.4.8"
                echo "3. PHP 5.5.0"
                read -p "Selection: " php

                if [ "$php" == "1" ] || [ "$php" == "2" ] || [ "$php" == "3" ]; then
                    #Nothing here. We're just using this as a conditional to catch a bad input.
                    randomvariable="true"
                else
                    echo -ne "\033[31m"                                 #Red color
                    echo "Selection is not a numerical choice. Aborting."
                    echo -ne "\033[0;39m"                               #Resetting color
                    exit 1                                              #Clean exit on failed input
                fi
            fi
        fi 
    fi      
}

#All Shared .ini manupulation is in this fuction
function sharedini() {                                          
    if [ "$php" == "2" ]; then                                   #PHP version 5.4.8
        if [ -e /opt/php/php-5.4.8/lib/php.ini ]; then          #PHP version exists on server
            echo "Creating the custom PHP 5.4.8 php.ini file."
            cp /opt/php/php-5.4.8/lib/php.ini "$ini"
        else
            echo -ne "\033[31m"                                 #Red color
            echo "PHP 5.4.8 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
            cp /usr/local/lib/php.ini "$ini"
            echo -ne "\033[32m"                                 #Green color
        fi
    elif [ "$php" == "3" ]; then                                 #PHP version 5.5.0
        if [ -e /opt/php/php-5.5.0/lib/php.ini ]; then          #PHP version exists on server
            echo "Creating the custom PHP 5.5.0 php.ini file."
            cp /opt/php/php-5.5.0/lib/php.ini "$ini"
        else
            echo -ne "\033[31m"                                 #Red color
            echo "PHP 5.5.0 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
            cp /usr/loca/lib/php.ini "$ini"
            echo -ne "\033[32m"                                 #Green color
        fi
    elif [ "$php" == "1" ]; then                                 #Default server php.ini
        echo "Creating the custom PHP php.ini file using the server default."
        cp /usr/local/lib/php.ini "$ini"
    fi

    #chmod/chowning the file for safety.
    chown "$user":"$user" "$ini"
    chmod 640 "$ini"

    echo "The custom php.ini file has successfully been created, chowned, and chmoded for safety."
}


function flagwork() {

    #Fopen
    if [ "$flag" == "1" ]; then
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
    elif [ "$flag" == "2" ]; then
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
    elif [ "$flag" == "3" ]; then
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
    elif [ "$flag" == "4" ]; then
        echo "Setting max_input_vars to $value."
        sed -i '/max_input_vars/d' "$ini"
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
            echo max_input_vars = "$value"
        } >> "$ini"

    #Timezone Flag
    elif [ "$flag" == "5" ]; then
        echo "Setting date.timezone to $value."
        sed -i '/date.timezone/d' "$ini"
        {
            echo ""
            echo ";Lines below this automatically added by A2 Hosting per support request on $(date +%F)"
            echo date.timezone = "$value"
        } >> "$ini"

    #Memory Limit Flag
    elif [ "$flag" == "6" ]; then
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

    echo "Flag updated. The php.ini file is now ready for use."
}

function shareddebug() {
    #Final check to see if there is an .htaccess that would affect PHP
    find /home/"$user"/ -name "php.ini" | while read phpname; do
        echo "Notice: php.ini file found at $phpname"
    done

    #Final check to see if there is an .htaccess file that would affect PHP
    find /home/"$user"/ -name ".htaccess" | while read htname; do
        if grep -q "x-httpd-php" "$htname"; then
            echo -ne "\033[31m"                                 #Red color
            echo "There is an .htaccess in $htname with PHP version directives."
            grep "x-httpd-php" "$htname"
            #read -p "Would you like to remove it? (y/n) " delme
            echo -ne "\033[0;39m"                               #Reset color
            if [ "$delme" == "y" ]; then
                sed -i '/x-httpd-php/d' "$htname"
            fi
        fi
    done
}

prompts

if [ "$server" == "shared" ]; then
    if [ "$mode" == "flags" ]; then
        sharedini
        flagwork
        shareddebug
        echo "The custom php.ini file has been created successfully, with all specified flags. Exiting..."
    elif [ "$mode" == "default" ]; then
        sharedini
        shareddebug
        echo "The default custom php.ini file has been created successfully. Exiting."
    elif [ "$mode" == "debug" ]; then
        shareddebug
        echo "Debugging complete. If the problem still exists, please continue manual investigation and/or live escalate."
    else
        echo "Script failure. Aborting..."
    fi
elif [ "$server" = "dedicated" ]; then
    echo "This is not a Shared server. You will need to manually edit the WHM php configuration."
fi

exit 0
