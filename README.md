# updateDatapowerFirmware
This is a shell script to automatically update Datapower Firmware from a central linux server repository.  You will need a linux server that can run bash shell scripts, the firmware update file from IBM, and Datapower appliance(s).

./updateDatapowerFirmware.sh $1 $2

Parameters:
FIRMWARE=$1  (path to firmware update file)
DPENV=$2     (DP environment that is being updated)

Variables to set before running:

FIRMWARE_DIR=  (path to firmware update file)
EMAIL_DISTR_LIST= (email address for notifications of start/success/failure)
DPUID= (user id of DP account to login to the appliance via CLI)
DPPWD= (password of DP account above)
UTILID= (user id of the Linux server this script runs on)
UTILPWD= (password for the above id)
LOGFILE= (path for the log file)

Code to adjust before running:

In the checkParms() function there is a mapping of DPENV parm to the actual host of the Datapower appliance, this is a shortcut so the appliance hostname doesn't need to be passed to the script
and instead just the env name can be passed.  This will all need to be adjusted or rewritten entirely for your own environment.
