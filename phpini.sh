#!/bin/bash
#Custom PHP.ini Creator and Updater
#Author: Josh Grancell
#Updated: 5-21-2014
#This script takes no command-line arguments, and prompts for all necessary information.
#Currently available PHP versions: 5.5.0, 5.4.8, 5.3.2x (Server Default)
#The following PHP changes are supported: Magic Quotes, fopen, upload size, max_input_vars, and date.timezone

function prompts() {
    echo -ne "\033[32m" #Green text color
    echo -n "Enter username: "
    read user
    echo "You have selected cPanel user: $user"

    if [ ! -f /var/cpanel/users/"$user" ]; then
        #Username given is invalid
        echo -ne "\033[31m" #Red text color
        echo "\033[31m Invalid User. Exiting"
        echo -ne "\033[0;39m" #Reset shell color
        exit 1
    else
        #Username is valid, now requesting the php flag that needs to be customized and setting that to $flag
        echo "Select php.ini flag: "
        echo "1. Set allow_url_fopen to On          4. Set max_input_vars to a custom value"
        echo "2. Set magic_quotes_gpc to Off        5. Change the default timezone"
        echo "3. Change file upload size            6. Change the PHP memory limit"
        read -p "Selection: " flag

        #Getting more information for certain flags and saving into variable $value
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

        #Determining whether this is a Shared server running CloudLinux or a ManVPS with CentOS
        if grep -s "CloudLinux" /etc/redhat-release; then
            #Server is running CL, probably a shared server
            server="shared"
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
        elif grep -s "CentOS" /etc/redhat-release; then
            #Server is running CentOS, probably a VPS/Dedi
            server="dedicated"
        fi


    fi
}

#All intial .ini manipulation, including creation and setting ownership, are in this function
function sharedini() {  
    if [ "$php" = "2" ]; then
        #WPHP version 5.4.8
        if [ -e /opt/php/php-5.4.8/lib/php.ini ]; then #PHP version exists on server
            echo "Creating the custom PHP 5.4.8 php.ini file."
            cp /opt/php/php-5.4.8/lib/php.ini "$ini"
        else
            echo -ne "\033[31m" #Red
            echo "PHP 5.4.8 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
            cp /usr/local/lib/php.ini "$ini"
            echo -ne "\033[32m" # Green
        fi
    elif [ "$php" = "3" ]; then
        #PHP version 5.5.0
        if [ -e /opt/php/php-5.5.0/lib/php.ini ]; then #PHP version exists on server

            echo "Creating the custom PHP 5.5.0 php.ini file."
            cp /opt/php/php-5.5.0/lib/php.ini "$ini"
        else
            echo -ne "\033[31m" #Red
            echo "PHP 5.5.0 does not currently exist on the server. Creating the custom PHP php.ini file using the server default instead."
            cp /usr/loca/lib/php.ini "$ini"
            echo -ne "\033[32m" #Green
        fi
    elif [ "$php" = "1" ]; then
        #Default server php.ini
        echo "Creating the custom PHP php.ini file using the server default."
        cp /usr/local/lib/php.ini "$ini"
    fi

    #chmod/chowning the file for safety.
    chown $user:$user "$ini"
    chmod 600 "$ini"
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
        echo -ne "\033[31m" #Red
        echo "A correct flag was not specified. Re-run the script, and use the number for the flag you would like to specify."
        echo -ne "\033[0;39m" #Reset
        exit 1
    fi

    #Final check to see if there is an .htaccess that would affect PHP
    if [ -e /home/"$user"/.htaccess ]; then
        if grep -q "x-httpd-php" /home/"$user"/.htaccess; then
            echo -ne "\033[31m" #Red
            echo -n "There is an .htaccess in /home/$user with PHP version directives, would you like to remove it? (y/n) "
            read delme
            if [ "$delme" = "y" ]; then
                sed -i '/x-httpd-php/d' /home/"$user"/.htaccess
            fi
        fi
    fi
    if [ -e /home/"$user"/public_html/.htaccess ]; then
        if grep -q "x-httpd-php" /home/"$user"/public_html/.htaccess; then
            echo -ne "\033[31m" #Red
            echo -n "There is an .htaccess in /home/$user/public_html with PHP version directives, would you like to remove it? (y/n) "
            read delme
            if [ "$delme" = "y" ]; then
                sed -i '/x-httpd-php/d' /home/"$user"/public_html/.htaccess
            fi
        fi
    fi

    echo -ne "\033[32m" #Green
    echo "Script complete. Please verify the new php.ini, or run the script again if you need another flag updated."
    echo -ne "\033[0;39m" #Reset

}

prompts

if [ $server = "shared" ]; then
    sharedini
    sharedwork
elif [ $server = "dedicated" ]; then
    #dediini
    #dediwork
fi

exit 0
