
# Feed to Radar5/ADSB Exchange

## ONLY run SETUP.SH if you are NOT already feeding ADSBexchange.com


You will need to know the Latitude Logitude and Altitude of the reciever in order to proceed.

## Run these commands FIRST

sudo apt-get install git

git clone https://github.com/kiwikierab/feed2radar5

cd feed2radar5


## Run below commands if you are NOT feeding ADSBexchange and wish to send data to radar5.nz & ADSBx


chmod +x setup.sh

sudo ./setup.sh
