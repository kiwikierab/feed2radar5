#!/bin/bash

#####################################################################################
#           RADAR NZ SETUP SCRIPT FOR FEEDER ALREADY SENDING DATA 
#           TO ADSBx using FA PiAWare and ADSBx script method ONLY
#####################################################################################


## CHECK IF SCRIPT WAS RAN USING SUDO

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

## CHECK FOR PACKAGES NEEDED BY THIS SCRIPT

echo -e "\033[33m"
echo "Checking for packages needed to run this script..."

if [ $(dpkg-query -W -f='${STATUS}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing the curl package..."
    echo -e "\033[37m"
    sudo apt-get update
    sudo apt-get install -y curl socat
fi
echo -e "\033[37m"

## ASSIGN VARIABLES

LOGDIRECTORY="$PWD/logs"
MLATCLIENTVERSION="0.2.6"
MLATCLIENTTAG="v0.2.6"

## WHIPTAIL DIALOGS

BACKTITLETEXT="Radar NZ MLAT Forward"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "This script should be ran AFTER setup.sh. It will setup MLAT forwarding from ADSBx mlat-client.\n\nWould you like to continue setup?" 13 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi

RECEIVERPORT=$(whiptail --backtitle "$BACKTITLETEXT" --title "RadarNZ Feed Port" --nocancel --inputbox "\nChange only if you were assigned a custom feed port.\nFor most all users it is required this port remain set to port 4995." 10 78 "4995" 3>&1 1>&2 2>&3)


whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "We are now ready to begin setting up your receiver to feed Radar5.\n\nDo you wish to proceed?" 9 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi

## BEGIN SETUP

{

    # Make a log directory if it does not already exist.
    if [ ! -d "$LOGDIRECTORY" ]; then
        mkdir $LOGDIRECTORY
    fi
    LOGFILE="$LOGDIRECTORY/image_setup-$(date +%F_%R)"
    touch $LOGFILE

    echo 4
    sleep 0.25

    # BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

    echo "INSTALLING SOCAT IF NEEDED" >> $LOGFILE
    echo "--------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    if [ $(dpkg-query -W -f='${STATUS}' socat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install -y socat >> $LOGFILE  2>&1
    fi

    echo 28
    sleep 0.25

        echo "" >> $LOGFILE
    echo " CREATE AND CONFIGURE MLAT FORWARD SCRIPTS" >> $LOGFILE
    echo "-------------------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

#
#  Forward MLAT to radarnz script from MLAT listener
# 
  tee radarnz-mlat_maint.sh > /dev/null <<EOF
#!/bin/sh
while true
  do
    sleep 30
    /usr/bin/socat -u TCP:localhost:30105 TCP:feed.radar5.nz:$RECEIVERPORT
   done
EOF

    echo 76
    sleep 0.25

    # Set permissions on the file radarnz-netcat_maint.sh.
    chmod +x radarnz-mlat_maint.sh >> $LOGFILE

    echo 82
    sleep 0.25

    # Add a line to execute the radarnz mlat forward script to /etc/rc.local so it is started after each reboot if one does not already exist.
    if ! grep -Fxq "$PWD/radarnz-mlat_maint.sh &" /etc/rc.local; then
        lnum=($(sed -n '/exit 0/=' /etc/rc.local))
        ((lnum>0)) && sudo sed -i "${lnum[$((${#lnum[@]}-1))]}i $PWD/radarnz-mlat_maint.sh &\n" /etc/rc.local >> $LOGFILE
    fi

    echo 88
    sleep 0.25

    # Kill any currently running instances of the radarnz-mlat_maint.sh script.
    PIDS=`ps -efww | grep -w "radarnz-mlat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        sudo kill $PIDS >> $LOGFILE
        sudo kill -9 $PIDS >> $LOGFILE
    fi

    echo 94
    sleep 0.25

    # Execute the radarnz mlat forward script.
    sudo nohup $PWD/radarnz-mlat_maint.sh > /dev/null 2>&1 & >> $LOGFILE
    echo 100
    sleep 0.25

} | whiptail --backtitle "$BACKTITLETEXT" --title "Setting MLAT forwarding for RadarNZ"  --gauge "\nSetting up your receiver to feed Radar5.\nThe setup process may take awhile to complete..." 8 60 0

## SETUP COMPLETE

# Display the thank you message box.
whiptail --title "Radar5 Setup Script" --msgbox "\nSetup is now complete.\n\nYour feeder is now sending MLAT from ADSBx to Radar5.nz.\nThanks again for choosing to share your data with Radar5!\n\nIf you have questions \n\nhttps://radar5.nz" 17 73

exit 0
