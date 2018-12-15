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
PORTAL_PYTHON_DIRECTORY="$PORTAL_BUILD_DIRECTORY/python"

DATABASE_ENGINE=$ADSB_DATABASEENGINE
DATABASE_HOSTNAME=$ADSB_DATABASEHOSTNAME
DATABASE_USER=$ADSB_DATABASEUSER
DATABASE_PASSWORD_1=$ADSB_DATABASEPASSWORD1
DATABASE_NAME=$ADSB_DATABASENAME

## SETUP FLIGHT LOGGING

echo -e ""
echo -e "\e[95m  Setting up core advanced portal features...\e[97m"
echo -e ""

case $DATABASE_ENGINE in
    "MySQL")
        echo -e "\e[94m  Creating the flight Python configuration file for MySQL...\e[97m"
        tee $PORTAL_PYTHON_DIRECTORY/config.json > /dev/null <<EOF
{
    "database":{"type":"mysql",
                "host":"${DATABASE_HOSTNAME}",
                "user":"${DATABASE_USER}",
                "passwd":"${DATABASE_PASSWORD_1}",
                "db":"${DATABASE_NAME}"}
}
EOF
            ;;
    "SQLite")
        echo -e "\e[94m  Creating the Python configuration file for SQLite...\e[97m"
        tee $PORTAL_PYTHON_DIRECTORY/config.json > /dev/null <<EOF
{
    "database":{"type":"sqlite",
                "host":"${DATABASE_HOSTNAME}",
                "user":"${DATABASE_USER}",
                "passwd":"${DATABASE_PASSWORD_1}",
                "db":"${DATABASE_NAME}"}
}
EOF
        ;;
    *)
        echo -e "\e[94m  No core setup required...\e[97m"
        ;;
esac
