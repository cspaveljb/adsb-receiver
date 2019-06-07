#!/bin/bash

#####################################################################################
#                                  ADS-B RECEIVER                                   #
#####################################################################################
#                                                                                   #
# This script is not meant to be executed directly.                                 #
# Instead execute install.sh to begin the installation process.                     #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2015-2018 Joseph A. Prochazka                                       #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## VARIABLES

PORTAL_BUILD_DIRECTORY="$RECEIVER_BUILD_DIRECTORY/portal"

## INCLUDE EXTERNAL SCRIPTS

source $RECEIVER_BASH_DIRECTORY/variables.sh
source $RECEIVER_BASH_DIRECTORY/functions.sh

if [ "$RECEIVER_AUTOMATED_INSTALL" = "true" ] && [ -s $RECEIVER_CONFIGURATION_FILE ] ; then
    source $RECEIVER_CONFIGURATION_FILE
fi

## BEGIN SETUP

clear
echo -e "\n\e[91m   $RECEIVER_PROJECT_TITLE"
echo -e ""
echo -e "\e[92m  Setting up the ADS-B Receiver Project Portal..."
echo -e "\e[93m  ------------------------------------------------------------------------------\e[96m"
echo -e ""
if [ "$RECEIVER_AUTOMATED_INSTALL" = "false" ] ; then
    whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "ADS-B ADS-B Receiver Project Portal Setup" --yesno "The ADS-B ADS-B Receiver Project Portal adds a web accessable portal to your receiver. The portal contains allows you to view performance graphs, system information, and live maps containing the current aircraft being tracked.\n\nBy enabling the portal's advanced features you can also view historical data on flight that have been seen in the past as well as view more detailed information on each of these aircraft.\n\nTHE ADVANCED PORTAL FEATURES ARE STILL IN DEVELOPMENT\n\nIt is recomended that only those wishing to contribute to the development of these features or those wishing to test out the new features enable them. Do not be surprised if you run into any major bugs after enabling the advanced features at this time!\n\nDo you wish to continue with the ADS-B Receiver Project Portal setup?" 23 78
    CONTINUE_SETUP=$?
    if [[ "${CONTINUE_SETUP}" = 1 ]] ; then
        # Setup has been halted by the user.
        echo -e "\e[91m  \e[5mINSTALLATION HALTED!\e[25m"
        echo -e "  Setup has been halted at the request of the user."
        echo -e ""
        echo -e "\e[93m  ------------------------------------------------------------------------------"
        echo -e "\e[92m  ADS-B Receiver Project Portal setup halted.\e[39m"
        echo -e ""
        read -p "Press enter to continue..." CONTINUE
    fi
    exit 1
fi

## GATHER NEEDED INFORMATION FROM THE USER

# We will need to make sure Lighttpd is installed first before we go any further.
echo -e "\e[95m  Installing packages needed to fulfill dependencies...\e[97m"
echo -e ""
CheckPackage lighttpd

# Assign the Lighthttpd document root directory to a variable.
RAW_DOCUMENT_ROOT=`/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf -p | grep server.document-root`
LIGHTTPD_DOCUMENT_ROOT=`sed 's/.*"\(.*\)"[^"]*$/\1/' <<< $RAW_DOCUMENT_ROOT`

# Check if there is already an existing portal installation.
if [ -f $LIGHTTPD_DOCUMENT_ROOT/classes/settings.class.php ] ; then
    RECEIVER_PORTAL_INSTALLED="true"
else
    RECEIVER_PORTAL_INSTALLED="false"
fi

if [ "$RECEIVER_PORTAL_INSTALLED" = "true" ] ; then
    # Assign needed variables using the driver setting in settings.class.php.
    DATABASE_ENGINE=`grep 'db_driver' $LIGHTTPD_DOCUMENT_ROOT/classes/settings.class.php | tail -n1 | cut -d\' -f2`
    if [ "$DATABASE_ENGINE" = "xml" ] ; then
        ADVANCED="false"
    else
        ADVANCED="true"
    fi
    if [[ "$ADVANCED" = "true" ]] ; then
        case "$DATABASE_ENGINE" in
            "mysql") DATABASE_ENGINE="MySQL" ;;
            "sqlite") DATABASE_ENGINE="SQLite" ;;
        esac
        DATABASE_HOSTNAME=`grep 'db_host' $LIGHTTPD_DOCUMENT_ROOT/classes/settings.class.php | tail -n1 | cut -d\' -f2`
        DATABASE_USER=`grep 'db_username' $LIGHTTPD_DOCUMENT_ROOT/classes/settings.class.php | tail -n1 | cut -d\' -f2`
        DATABASE_PASSWORD_1=`grep 'db_password' $LIGHTTPD_DOCUMENT_ROOT/classes/settings.class.php | tail -n1 | cut -d\' -f2`
        DATABASE_NAME=`grep 'db_database' $LIGHTTPD_DOCUMENT_ROOT/classes/settings.class.php | tail -n1 | cut -d\' -f2`
    fi


else
    # Ask if advanced features should be enabled.
    whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "ADS-B Receiver Portal Selection" --defaultno --yesno "NOTE THAT THE ADVANCED FEATURES ARE STILL IN DEVELOPMENT AT THIS TIME\nADVANCED FEATURES SHOULD ONLY BE ENABLED BY DEVELOPERS AND TESTERS ONLY\n\nBy enabling advanced features the portal will log all flights seen as well as the path of the flight. This data is stored in either a MySQL or SQLite database. This will result in a lot more data being stored on your devices hard drive. Keep this and your devices hardware capabilities in mind before selecting to enable these features.\n\nENABLING ADVANCED FEATURES ON DEVICES USING SD CARDS CAN SHORTEN THE LIFE OF THE SD CARD IMMENSELY\n\nDo you wish to enable the portal advanced features?" 19 78
    RESPONSE=$?
    case $RESPONSE in
        0) ADVANCED="true" ;;
        1) ADVANCED="false" ;;
    esac

    if [ "$ADVANCED" = "true" ] ; then
        # Ask which type of database to use.
        DATABASE_ENGINE=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Choose Database Type" --nocancel --menu "\nChoose which type of database to use." 11 80 2 "MySQL" "" "SQLite" "" 3>&1 1>&2 2>&3)

        if [[ "$DATABASE_ENGINE" = "MySQL" ]] ; then
            # Ask if the database server will be installed locally.
            whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "MySQL Database Location" --yesno "Will the database be hosted locally on this device?" 7 80
            RESPONSE=$?
            case ${RESPONSE} in
                0) LOCAL_MYSQL_SERVER="true" ;;
                1) LOCAL_MYSQL_SERVER="false" ;;
            esac
            if [ "$LOCAL_MYSQL_SERVER" = "false" ] ; then
                # Ask for the remote MySQL servers hostname.
                DATABASE_HOSTNAME_TITLE="MySQL Database Server Hostname"
                while [ -z $DATABASE_HOSTNAME ] ; do
                    DATABASE_HOSTNAME=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_HOSTNAME_TITLE" --nocancel --inputbox "\nWhat is the remote MySQL server's hostname?" 10 60 3>&1 1>&2 2>&3)
                    DATABASE_HOSTNAME_TITLE="MySQL Database Server Hostname (REQUIRED)"
                done

                # Ask if the remote MySQL database already exists.
                whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Does MySQL Database Exist" --yesno "Has the database already been created?" 7 80
                RESPONSE=$?
                case $RESPONSE in
                    0) DATABASE_EXISTS="true" ;;
                    1) DATABASE_EXISTS="false" ;;
                esac
            else
                # Install the MySQL server package now if it is not already installed.
                whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "MySQL Server Setup" --msgbox "This script will now check for the MySQL server package. If the MySQL server package is not installed it will be installed at this time.\n\nPlease note you may be asked questions used to secure your database server installation after the setup process." 12 78
                CheckPackage mysql-server
                if [[ $(dpkg-query -W -f='${STATUS}' mariadb-server-10.1 2>/dev/null | grep -c "ok installed") -eq 1 ]] ; then
                    echo -e "\e[94m  Executing the mysql_secure_installation script...\e[97m"
                    sudo mysql_secure_installation
                    echo ""
                fi

                # Since this is a local installation assume the MySQL database does not already exist.
                DATABASE_EXISTS="false"

                # Since the MySQL database server will run locally assign localhost as it's hostname.
                DATABASE_HOSTNAME="localhost"
            fi

            # Ask for the MySQL administrator credentials if the database does not already exist.
            if [ "$LOCAL_MYSQL_SERVER" = "true" ] || [ "$DATABASE_EXISTS" = "false" ] ; then
                whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Create Remote MySQL Database" --msgbox "This script can attempt to create the MySQL database for you.\nYou will now be asked for the credentials for a MySQL user who has the ability to create a database on the MySQL server." 9 78
                DATABASE_ADMIN_USER_TITLE="MySQL Administrator User"
                while [ -z $DATABASE_ADMIN_USER ] ; do
                    DATABASE_ADMIN_USER=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_USER_TITLE" --nocancel --inputbox "\nEnter the MySQL administrator user." 8 78 "root" 3>&1 1>&2 2>&3)
                    DATABASE_ADMIN_USER_TITLE="MySQL Administrator User (REQUIRED)"
                done
                DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password"
                DATABASE_ADMIN_PASSWORD_1_MESSAGE="\nEnter the password for the MySQL adminitrator user."
                while [ -z $DATABASE_ADMIN_PASSWORD_1 ] ; do
                    DATABASE_ADMIN_PASSWORD_1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_1_TITLE" --nocancel --passwordbox "$DATABASE_ADMIN_PASSWORD_1_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                    DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password (REQUIRED)"
                done
                DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password"
                DATABASE_ADMIN_PASSWORD_2_MESSAGE="\nConfirm the password for the MySQL adminitrator user."
                while [ -z $DATABASE_ADMIN_PASSWORD_2 ] ; do
                    DATABASE_ADMIN_PASSWORD_2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_2_TITLE" --nocancel --passwordbox "$DATABASE_ADMIN_PASSWORD_2_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                    DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password (REQUIRED)"
                done
                while [ ! "$DATABASE_ADMIN_PASSWORD_1" = "$DATABASE_ADMIN_PASSWORD_2" ] ; do
                    DATABASE_ADMIN_PASSWORD_1=""
                    DATABASE_ADMIN_PASSWORD_2=""
                    whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Passwords Did Not Match" --msgbox "Passwords did not match.\nPlease enter your password again." 9 78
                    DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password"
                    while [ -z $DATABASE_ADMIN_PASSWORD_1 ] ; do
                        DATABASE_ADMIN_PASSWORD_1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_1_TITLE" --nocancel --passwordbox "DATABASE_ADMIN_PASSWORD_1_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                        DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password (REQUIRED)"
                    done
                    DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password"
                    while [ -z $DATABASE_ADMIN_PASSWORD_2 ] ; do
                        DATABASE_ADMIN_PASSWORD_2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_2_TITLE" --nocancel --passwordbox "DATABASE_ADMIN_PASSWORD_2_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                        DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password (REQUIRED)"
                    done
                done
            fi

            # Get the login information pertaining to the MySQL database itself.
            whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Create Remote MySQL Database" --msgbox "You will now be asked to supply the name of the database which will store the portal data as well as the login credentials for the MySQL user that has access to this database." 9 78

            DATABASE_NAME_TITLE="ADS-B Receiver Portal Database Name"
            while [ -z $DATABASE_NAME ] ; do
                DATABASE_NAME=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_NAME_TITLE" --nocancel --inputbox "\nEnter your ADS-B Receiver Portal database name." 8 78 3>&1 1>&2 2>&3)
                DATABASE_NAME_TITLE="ADS-B Receiver Portal Database Name (REQUIRED)"
            done
            DATABASE_USER_TITLE="ADS-B Receiver Portal Database User"
            while [ -z $DATABASE_USER ] ; do
                DATABASE_USER=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_USER_TITLE" --nocancel --inputbox "\nEnter the user for the ADS-B Receiver Portal database." 8 78 3>&1 1>&2 2>&3)
                DATABASE_USER_TITLE="ADS-B Receiver Portal Database User (REQUIRED)"
            done
            DATABASE_PASSWORD_1_TITLE="ADS-B Receiver Portal Password"
            DATABASE_PASSWORD_1_MESSAGE="\nEnter your ADS-B Receiver Portal database password."
            while [ -z "$DATABASE_PASSWORD_1" ] ; do
                DATABASE_PASSWORD_1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_PASSWORD_1_TITLE" --nocancel --passwordbox "$DATABASE_PASSWORD_1_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                DATABASE_PASSWORD_1_TITLE="ADS-B Receiver Portal Password (REQUIRED)"
            done
            DATABASE_PASSWORD_2_TITLE="Confirm The ADS-B Receiver Portal Password"
            DATABASE_PASSWORD_2_MESSAGE="\nConfirm your ADS-B Receiver Portal database password."
            while [ -z "$DATABASE_PASSWORD_2" ] ; do
                DATABASE_PASSWORD_2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_PASSWORD_2_TITLE" --nocancel --passwordbox "$DATABASE_PASSWORD_2_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                DATABASE_PASSWORD_2_TITLE="Confirm The ADS-B Receiver Portal Password (REQUIRED)"
            done
            while [ ! "$DATABASE_PASSWORD_1" = "$DATABASE_PASSWORD_2" ] ; do
                DATABASE_PASSWORD_1=""
                DATABASE_PASSWORD_2=""
                whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Passwords Did Not Match" --msgbox "Passwords did not match.\nPlease enter your password again." 9 78
                DATABASE_PASSWORD_1_TITLE="ADS-B Receiver Portal Password"
                while [ -z $DATABASE_PASSWORD_1 ] ; do
                    DATABASE_PASSWORD_1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_PASSWORD_1_TITLE" --nocancel --passwordbox "$DATABASE_PASSWORD_1_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                    DATABASE_PASSWORD_1_TITLE="ADS-B Receiver Portal Password (REQUIRED)"
                done
                DATABASE_PASSWORD_2_TITLE="Confirm The ADS-B Receiver Portal Password"
                while [ -z $DATABASE_PASSWORD_2 ] ; do
                    DATABASE_PASSWORD_2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_PASSWORD_2_TITLE" --nocancel --passwordbox "$DATABASE_PASSWORD_2_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                    DATABASE_PASSWORD_2_TITLE="Confirm The ADS-B Receiver Portal Password (REQUIRED)"
                done
            done
        fi
    fi
fi

## CHECK FOR PREREQUISITE PACKAGES

DISTRO_PHP_VERSION="5"
case $RECEIVER_OS_DISTRIBUTION in
    debian|raspbian)
        if [ $RECEIVER_OS_RELEASE -ge "9" ]]; then DISTRO_PHP_VERSION="7.0"; fi
        ;;
    ubuntu)
        if [ `bc -l <<< "$RECEIVER_OS_RELEASE >= 16.04"` -eq 1 ]; then DISTRO_PHP_VERSION="7.0"; fi
        if [ `bc -l <<< "$RECEIVER_OS_RELEASE >= 17.10"` -eq 1 ]; then DISTRO_PHP_VERSION="7.1"; fi
        if [ `bc -l <<< "$RECEIVER_OS_RELEASE >= 18.04"` -eq 1 ]; then DISTRO_PHP_VERSION="7.2"; fi
        ;;
esac

# Install PHP.
CheckPackage php${DISTRO_PHP_VERSION}-cgi
CheckPackage php${DISTRO_PHP_VERSION}-json

# Performance graph dependencies.
CheckPackage collectd-core
CheckPackage rrdtool

# Portal dependencies.
if [ -z $RECEIVER_MTA ] || [ "$RECEIVER_MTA" == "POSTFIX" ] ; then
    CheckPackage postfix
else
    CheckPackage $RECEIVER_MTA
fi

CheckPackage libpython2.7

# Install packages needed for advanced portal setups.
if [ "$ADVANCED" = "true" ] ; then
    CheckPackage python-pyinotify
    CheckPackage python-apt
    case "${DATABASEENGINE}" in
        "MySQL")
            CheckPackage mysql-client
            CheckPackage python-mysqldb
            CheckPackage php${DISTRO_PHP_VERSION}-mysql
            ;;
        "SQLite")
            CheckPackage sqlite3
            if [ `bc -l <<< "$DISTRO_PHP_VERSION >= 7.0"` -eq 1 ]; then
                CheckPackage php${DISTRO_PHP_VERSION}-sqlite3
            else
                CheckPackage php${DISTRO_PHP_VERSION}-sqlite
            fi
            ;;
    esac
else
    if [ ! $DISTRO_PHP_VERSION == "5" ]; then
        CheckPackage php${DISTRO_PHP_VERSION}-xml
    fi
fi

# Reload Lighttpd after installing the prerequisite packages.
echo -e "\e[94m  Reloading Lighttpd...\e[97m"
sudo service lighttpd force-reload
echo ""

## SETUP THE PORTAL WEBSITE

echo -e "\e[95m  Setting up the web portal...\e[97m"
echo -e ""

# If this is an existing Lite installation being upgraded backup the XML data files.
if [[ "${RECEIVER_PORTAL_INSTALLED}" = "true" ]] && [[ "${ADVANCED}" = "false" ]] ; then
    echo -e "\e[94m  Backing up the file ${LIGHTTPD_DOCUMENT_ROOT}/data/administrators.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/administrators.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/administrators.backup.xml
    echo -e "\e[94m  Backing up the file ${LIGHTTPD_DOCUMENT_ROOT}/data/blogPosts.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/blogPosts.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/blogPosts.backup.xml
    echo -e "\e[94m  Backing up the file ${LIGHTTPD_DOCUMENT_ROOT}/data/flightNotifications.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/flightNotifications.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/flightNotifications.backup.xml
    echo -e "\e[94m  Backing up the file ${LIGHTTPD_DOCUMENT_ROOT}/data/settings.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/settings.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/settings.backup.xml
    echo -e "\e[94m  Backing up the file ${LIGHTTPD_DOCUMENT_ROOT}/data/links.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/links.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/links.backup.xml
    echo -e "\e[94m  Backing up the file ${LIGHTTPD_DOCUMENT_ROOT}/data/notifications.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/notifications.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/notifications.backup.xml
fi

if [ -f $LIGHTTPD_DOCUMENT_ROOT/index.lighttpd.html ]; then
    echo -e "\e[94m  Removing default Lighttpd index file from document root...\e[97m"
    sudo rm $LIGHTTPD_DOCUMENT_ROOT/index.lighttpd.html
fi

echo -e "\e[94m  Placing portal files in Lighttpd's root directory...\e[97m"
sudo cp -R $PORTAL_BUILD_DIRECTORY/html/* $LIGHTTPD_DOCUMENT_ROOT

# If this is an existing installation being upgraded restore the original XML data files.
if [[ "${RECEIVER_PORTAL_INSTALLED}" = "true" ]] && [[ "${ADVANCED}" = "false" ]] ; then
    echo -e "\e[94m  Restoring the backup copy of the file ${LIGHTTPD_DOCUMENT_ROOT}/data/administrators.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/administrators.backup.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/administrators.xml
    echo -e "\e[94m  Restoring the backup copy of the file ${LIGHTTPD_DOCUMENT_ROOT}/data/blogPosts.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/blogPosts.backup.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/blogPosts.xml
    echo -e "\e[94m  Restoring the backup copy of the file ${LIGHTTPD_DOCUMENT_ROOT}/data/flightNotifications.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/flightNotifications.backup.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/flightNotifications.xml
    echo -e "\e[94m  Restoring the backup copy of the file ${LIGHTTPD_DOCUMENT_ROOT}/data/settings.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/settings.backup.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/settings.xml
    echo -e "\e[94m  Restoring the backup copy of the file ${LIGHTTPD_DOCUMENT_ROOT}/data/links.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/links.backup.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/links.xml
    echo -e "\e[94m  Restoring the backup copy of the file ${LIGHTTPD_DOCUMENT_ROOT}/data/notifications.xml...\e[97m"
    sudo mv ${LIGHTTPD_DOCUMENT_ROOT}/data/notifications.backup.xml ${LIGHTTPD_DOCUMENT_ROOT}/data/notifications.xml
fi

# Set the proper permissions on certain portal directories.
echo -e "\e[94m  Making the directory $LIGHTTPD_DOCUMENT_ROOT/graphs/ writable...\e[97m"
sudo chmod 777 $LIGHTTPD_DOCUMENT_ROOT/graphs/
echo -e "\e[94m  Making the directory $LIGHTTPD_DOCUMENT_ROOT/classes/ writable...\e[97m"
sudo chmod 777 $LIGHTTPD_DOCUMENT_ROOT/classes/
echo -e "\e[94m  Making the directory $LIGHTTPD_DOCUMENT_ROOT/data/ writable...\e[97m"
sudo chmod 777 $LIGHTTPD_DOCUMENT_ROOT/data/
echo -e "\e[94m  Making the files contained within the directory $LIGHTTPD_DOCUMENT_ROOT/data/ writable...\e[97m"
sudo chmod 666 $LIGHTTPD_DOCUMENT_ROOT/data/*

# Check if dump978 was setup.
echo -e "\e[94m  Checking if dump978 was set up...\e[97m"
if [ -f /etc/rc.local ] && [[ `grep -cFx "${RECEIVER_BUILD_DIRECTORY}/dump978/dump978-maint.sh &" /etc/rc.local` -eq 0 ]] ; then
    # Check if a heywhatsthat.com range file exists in the dump1090 HTML folder.
    echo -e "\e[94m  Checking for the file upintheair.json in the dump1090 HTML folder...\e[97m"
    if [ -f /usr/share/dump1090-mutability/html/upintheair.json ] || [ -f /usr/share/dump1090-fa/html/upintheair.json ] ; then
        echo -e "\e[94m  Copying the file upintheair.json from the dump1090 HTML folder to the dump978 HTML folder...\e[97m"
        if [[ $(dpkg-query -W -f='${STATUS}' dump1090-mutability 2>/dev/null | grep -c "ok installed") -eq 1 ]] ; then
            sudo cp /usr/share/dump1090-mutability/html/upintheair.json $LIGHTTPD_DOCUMENT_ROOT/dump978/
        fi
        if [[ $(dpkg-query -W -f='${STATUS}' dump1090-fa 2>/dev/null | grep -c "ok installed") -eq 1 ]] ; then
            sudo cp /usr/share/dump1090-fa/html/upintheair.json $LIGHTTPD_DOCUMENT_ROOT/dump978/
        fi
    fi
fi

if [[ $(dpkg-query -W -f='${STATUS}' dump1090-mutability 2>/dev/null | grep -c "ok installed") -eq 1 ]] ; then
    echo -e "\e[94m  Removing conflicting redirects from the Lighttpd dump1090.conf file...\e[97m"
    # Remove this line completely.
    sudo sed -i "/$(echo '  "^/dump1090$" => "/dump1090/gmap.html"' | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/d" /etc/lighttpd/conf-available/89-dump1090.conf
    # Remove the trailing coma from this line.
    sudo sed -i "s/$(echo '"^/dump1090/$" => "/dump1090/gmap.html",' | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/$(echo '"^/dump1090/$" => "/dump1090/gmap.html"' | sed -e 's/\\/\\\\/g' -e 's/\//\\\//g' -e 's/&/\\\&/g')/g"  /etc/lighttpd/conf-available/89-dump1090.conf
fi

# Add to the Lighttpd configuration.
echo -e "\e[94m  Adding the Lighttpd portal configuration file...\e[97m"
if [ -f /etc/lighttpd/conf-available/89-adsb-portal.conf ] ; then
    sudo rm -f /etc/lighttpd/conf-available/89-adsb-portal.conf
fi
sudo touch /etc/lighttpd/conf-available/89-adsb-portal.conf
if [[ $(dpkg-query -W -f='${STATUS}' dump1090-fa 2>/dev/null | grep -c "ok installed") -eq 1 ]] ; then
    sudo tee -a /etc/lighttpd/conf-available/89-adsb-portal.conf > /dev/null <<EOF
# Add dump1090 as an alias to the dump1090-fa HTML folder.
alias.url += (
  "/dump1090/data/" => "/run/dump1090-fa/",
  "/dump1090/" => "/usr/share/dump1090-fa/html/"
)
# Redirect the slash-less dump1090 URL
url.redirect += (
  "^/dump1090$" => "/dump1090/"
)
# Add CORS header
server.modules += ( "mod_setenv" )
\$HTTP["url"] =~ "^/dump1090/data/.*\.json$" {
  setenv.add-response-header = ( "Access-Control-Allow-Origin" => "*" )
}
EOF
fi
sudo tee -a /etc/lighttpd/conf-available/89-adsb-portal.conf > /dev/null <<EOF
# Block all access to the data directory accept for local requests.
\$HTTP["remoteip"] !~ "127.0.0.1" {
    \$HTTP["url"] =~ "^/data/" {
        url.access-deny = ( "" )
    }
}
EOF

if [ ! -L /etc/lighttpd/conf-enabled/89-adsb-portal.conf ] ; then
    echo -e "\e[94m  Enabling the Lighttpd portal configuration file...\e[97m"
    sudo ln -s /etc/lighttpd/conf-available/89-adsb-portal.conf /etc/lighttpd/conf-enabled/89-adsb-portal.conf
fi

if [ "$RECEIVER_PORTAL_INSTALLED" = "false" ] ; then
    echo -e "\e[94m  Enabling the Lighttpd fastcgi-php module...\e[97m"
    echo -e ""
    sudo lighty-enable-mod fastcgi-php
    echo -e ""
fi

# Reload or start Lighttpd.
if pgrep "lighttpd" > /dev/null; then
    echo -e "\e[94m  Reloading Lighttpd...\e[97m"
    sudo service lighttpd force-reload
else
    echo -e "\e[94m  Starting Lighttpd...\e[97m"
    sudo service lighttpd start
fi

## SETUP THE MYSQL DATABASE

if [ "$RECEIVER_PORTAL_INSTALLED" = "false" ] && [ "$ADVANCED" = "true" ] && [ "$DATABASE_ENGINE" = "MySQL" ] && [ "$DATABASE_EXISTS" = "false" ] ; then
    # If MariaDB is being used we will switch the plugin from unix_socket to mysql_native_password to keep things on the same page as MySQL setups.
    if [[ $(dpkg-query -W -f='${STATUS}' mariadb-server-10.1 2>/dev/null | grep -c "ok installed") -eq 1 ]] ; then
        echo -e "\e[94m  Switching the default MySQL plugin from unix_socket to mysql_native_password...\e[97m"
        sudo mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user = 'root' AND plugin = 'unix_socket';"
        echo -e "\e[94m  Flushing privileges on the  MySQL (MariaDB) server...\e[97m"
        sudo mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "FLUSH PRIVILEGES;"
        echo -e "\e[94m  Reloading MySQL (MariaDB)...\e[97m"
        sudo service mysql force-reload
    fi

    # Attempt to login with the supplied MySQL administrator credentials.
    echo -e "\e[94m  Attempting to log into the MySQL server using the supplied administrator credentials...\e[97m"
    while ! mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME}  -e ";" ; do
        echo -e "\e[94m  Unable to log into the MySQL server using the supplied administrator credentials...\e[97m"
        whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Create Remote MySQL Database" --msgbox "The script was not able to log into the MySQL server using the administrator credentials you supplied. You will now be asked to reenter the MySQL server administrator credentials." 9 78
        DATABASE_ADMIN_PASSWORD_1=""
        DATABASE_ADMIN_PASSWORD_2=""
        DATABASE_ADMIN_USER_TITLE="MySQL Administrator User"
        while [ -z ${DATABASE_ADMIN_USER} ] ; do
            DATABASE_ADMIN_USER=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_USER_TITLE" --nocancel --inputbox "\nEnter the MySQL administrator user." 8 78 "$DATABASE_ADMIN_USER" 3>&1 1>&2 2>&3)
            DATABASE_ADMIN_USER_TITLE="MySQL Administrator User (REQUIRED)"
        done
        DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password"
        DATABASE_ADMIN_PASSWORD_1_MESSAGE="\nEnter the password for the MySQL adminitrator user."
        while [ -z $DATABASE_ADMIN_PASSWORD_1 ] ; do
            DATABASE_ADMIN_PASSWORD_1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_1_TITLE" --nocancel --passwordbox "$DATABASE_ADMIN_PASSWORD_1_MESSAGE" 8 78 3>&1 1>&2 2>&3)
            DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password (REQUIRED)"
        done
        DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password"
        DATABASE_ADMIN_PASSWORD_2_MESSAGE="\nConfirm the password for the MySQL adminitrator user."
        while [ -z "$DATABASE_ADMIN_PASSWORD_2 ] ; do
            DATABASE_ADMIN_PASSWORD_2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_2_TITLE" --nocancel --passwordbox "$DATABASE_ADMIN_PASSWORD_2_MESSAGE" 8 78 3>&1 1>&2 2>&3)
            DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password (REQUIRED)"
        done
        while [ ! "$DATABASE_ADMIN_PASSWORD_1" = "$DATABASE_ADMIN_PASSWORD_2" ] ; do
            DATABASE_ADMIN_PASSWORD_1=""
            DATABASE_ADMIN_PASSWORD_2=""
            whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "Passwords Did Not Match" --msgbox "Passwords did not match.\nPlease enter your password again." 9 78
            DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password"
            while [ -z $DATABASE_ADMIN_PASSWORD_1 ] ; do
                DATABASE_ADMIN_PASSWORD_1=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_1_TITLE" --nocancel --passwordbox "DATABASE_ADMIN_PASSWORD_1_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                DATABASE_ADMIN_PASSWORD_1_TITLE="MySQL Administrator Password (REQUIRED)"
            done
            DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password"
            while [ -z $DATABASE_ADMIN_PASSWORD_2 ] ; do
                DATABASE_ADMIN_PASSWORD_2=$(whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "$DATABASE_ADMIN_PASSWORD_2_TITLE" --nocancel --passwordbox "DATABASE_ADMIN_PASSWORD_2_MESSAGE" 8 78 3>&1 1>&2 2>&3)
                DATABASE_ADMIN_PASSWORD_2_TITLE="Confirm The MySQL Administrator Password (REQUIRED)"
            done
        done
        echo -e "\e[94m  Attempting to log into the MySQL server using the new administrator credentials...\e[97m"
    done

    # Create the database use and database using the information supplied by the user.
    echo -e "\e[94m  Creating the MySQL database \"$DATABASE_NAME\"...\e[97m"
    mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "CREATE DATABASE ${DATABASE_NAME};"
    echo -e "\e[94m  Creating the MySQL user \"$DATABASE_USER\"...\e[97m"

    if [ "$LOCAL_MYSQL_SERVER" = "false" ] ; then
        # If the databse resides on a remote server be sure to allow the newly created user access to it remotly.
        mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "CREATE USER '${DATABASE_USER}'@'%' IDENTIFIED BY \"${DATABASE_PASSWORD_1}\";"
    else
        # Since this is a local database we will restrict this login to localhost logins only.
        mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "CREATE USER '${DATABASE_USER}'@'localhost' IDENTIFIED BY \"${DATABASE_PASSWORD_1}\";"
    fi
    echo -e "\e[94m  Granting priviledges on the MySQL database \"DATABASE_NAME\" to the user \"${DATABASE_USER}\"...\e[97m"
    mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '${DATABASE_USER}'@'localhost';"
    echo -e "\e[94m  Flushing priviledges on the MySQL database server...\e[97m"
    mysql -u ${DATABASE_ADMIN_USER} -p ${DATABASE_ADMIN_PASSWORD_1} -h ${DATABASE_HOSTNAME} -e "FLUSH PRIVILEGES;"
fi

## SETUP THE PERFORMANCE GRAPHS USING THE SCRIPT GRAPHS.SH

chmod +x $RECEIVER_BASH_DIRECTORY/portal/graphs.sh
$RECEIVER_BASH_DIRECTORY/portal/graphs.sh
if [ $? -ne 0 ] ; then
    echo -e ""
    echo -e "\e[91m  THE SCRIPT GRAPHS.SH ENCOUNTERED AN ERROR"
    echo -e ""
    exit 1
fi

## SETUP COMMON PORTAL FEATURES

# Export variables needed by logging.sh.
if [ "$DATABASE_ENGINE" = "MySQL" ]; then
    export ADSB_DATABASE_ENGINE=$DATABASE_ENGINE
    export ADSB_DATABASE_HOSTNAME=$DATABASE_HOSTNAME
    export ADSB_DATABASE_USER=$DATABASE_USER
    export ADSB_DATABASE_PASSWORD_1=$DATABASE_PASSWORD_1
    export ADSB_DATABASE_NAME=$DATABASE_NAME
elif [ "$DATABASE_ENGINE" = "SQLite" ]; then
    if [ -z $DATABASE_NAME ] ; then
        if [ ! -f $LIGHTTPD_DOCUMENT_ROOT/data/portal.sqlite ]; then
            echo -e "\e[94m  Creating an empty SQLite database file...\e[97m"
            sudo touch $LIGHTTPD_DOCUMENT_ROOT/data/portal.sqlite
            echo -e "\e[94m  Setting write permissions on the empty SQLite database file...\e[97m"
            sudo chmod 666 $LIGHTTPD_DOCUMENT_ROOT/data/portal.sqlite
        fi
        DATABASE_NAME="$LIGHTTPD_DOCUMENT_ROOT/data/portal.sqlite"
    fi
    export ADSB_DATABASE_ENGINE=$DATABASE_ENGINE
    export ADSB_DATABASE_HOSTNAME=""
    export ADSB_DATABASE_USER=""
    export ADSB_DATABASE_PASSWORD_1=""
    export ADSB_DATABASE_NAME=$DATABASE_NAME
else
    export ADSB_DATABASE_ENGINE="xml"
    export ADSB_DATABASE_HOSTNAME=""
    export ADSB_DATABASE_USER=""
    export ADSB_DATABASE_PASSWORD_1=""
    export ADSB_DATABASE_NAME=""
fi

# Execute the core setup script.
chmod +x $RECEIVER_BASH_DIRECTORY/portal/core.sh
$RECEIVER_BASH_DIRECTORY/portal/core.sh
if [[ $? -ne 0 ]] ; then
    echo -e ""
    echo -e "  \e[91m  THE SCRIPT CORE.SH ENCOUNTERED AN ERROR"
    echo -e ""
    exit 1
fi

## SETUP ADVANCED PORTAL FEATURES

if [ "$ADVANCED" = "true" ] ; then
    chmod +x $RECEIVER_BASH_DIRECTORY/portal/logging.sh
    $RECEIVER_BASH_DIRECTORY/portal/logging.sh
    if [[ $? -ne 0 ]] ; then
        echo -e ""
        echo -e "  \e[91m  THE SCRIPT LOGGING.SH ENCOUNTERED AN ERROR"
        echo -e ""
        exit 1
    fi
fi

# Remove exported variables that are no longer needed.
unset ADSB_DATABASE_ENGINE
unset ADSB_DATABASE_HOSTNAME
unset ADSB_DATABASE_USER
unset ADSB_DATABASE_PASSWORD_1
unset ADSB_DATABASE_NAME

## ADS-B RECEIVER PROJECT PORTAL SETUP COMPLETE

# This assigns the first IP address in the list to the $IP_ADDRESS variable.
IP_ADDRESS=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`

# Display final portal setup instructions to the user.
whiptail --backtitle "$RECEIVER_PROJECT_TITLE" --title "ADS-B Receiver Project Portal Setup" --msgbox "NOTE THAT PORTAL SETUP IS NOT YET COMPLETE!\n\nIn order to complete the portal setup process visit the following URL in your favorite web browser.\n\nhttp://$IP_ADDRESS/install/\n\nFollow the instructions and enter the requested information to complete the ADS-B Receiver Project Portal setup." 12 78

### SETUP COMPLETE

# Return to the project root directory.
echo -e "\e[94m  Entering the ADS-B Receiver Project root directory...\e[97m"
cd $RECEIVER_ROOT_DIRECTORY 2>&1

echo -e ""
echo -e "\e[93m  ------------------------------------------------------------------------------"
echo -e "\e[92m  ADS-B Receiver Project Portal setup is complete.\e[39m"
echo -e ""
if [ "$RECEIVER_AUTOMATED_INSTALL" = "false" ] ; then
    read -p "Press enter to continue..." CONTINUE
fi

exit 0
