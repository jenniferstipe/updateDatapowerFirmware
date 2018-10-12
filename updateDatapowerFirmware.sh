#!/bin/bash

FIRMWARE=$1
DPENV=$2
FIRMWARE_DIR=
LOGDATE=`date +%F`
LOGTIME=`date +%T`
UPLOADFILE=/dp/firmware-update/upload_commands.txt
UPDATEFILE=/dp/firmware-update/update_commands.txt
DISABLEFILE=/dp/firmware-update/disable_commands.txt
ENABLEFILE=/dp/firmware-update/enable_commands.txt
ENABLEADTSBFILE=/dp/firmware-update/enable_adtsb_commands.txt
REBOOTFILE=/dp/firmware-update/reboot_commands.txt
DOMAINSFILE=/dp/firmware-update/domains_commands.txt
EMAIL_DISTR_LIST=
DPUID=
DPPWD=

usageMessage ()
{
	echo "___________________________________________________________________________________________________"
	echo ""
	echo " NAME"
	echo "   updateDatapowerFirmware.sh"
	echo ""
	echo " PURPOSE"
	echo "    Automatically update firmware on a given appliance"	
	echo ""
	echo " USAGE"
	echo '    updateDatapowerFirmware.sh "$1" "$2" '
	echo '         "$1"=Firmware Filename that exists in /home/wdpmgmt/firmware directory (e.g. xi7522.scrypt4)'
    echo '         "$2"=Datapower Environment '	
}

initialize()
{

    if [ -d /dp/firmware-update ];
      then
        echo "/dp/firmware-update directory exists" 
    else
        echo "/dp/firmware-update does not exist, attempting to create" 
        mkdir /dp/firmware-update
        if [ -d /dp/firmware-update ];
          then
            echo "/dp/firmware-update directory successfully created."
        else
            echo "Error creating /dp/firmware-update.  Exiting."
            exit 1
        fi
    fi

    if [ -f $LOGFILE ];
      then
        echo "Log file exists: $LOGFILE" >> $LOGFILE
    else
        echo "Logging all activities to $LOGFILE, tail -f this log to follow the firmware update process."
        touch $LOGFILE
    fi

    if [ -f $UPLOADFILE ];
      then
        echo "Upload command file exists: $UPLOADFILE" >> $LOGFILE
    else
        echo "Upload command file does not exist, creating $UPLOADFILE" >> $LOGFILE
        touch $UPLOADFILE
    fi

    if [ -f $UPDATEFILE ];
      then
        echo "Update command file exists: $UPDATEFILE" >> $LOGFILE
    else
        echo "Update command file does not exist, creating $UPDATEFILE" >> $LOGFILE
        touch $UPDATEFILE
    fi

    if [ -f $DISABLEFILE ];
      then
        echo "Disable domains command file exists: $DISABLEFILE" >> $LOGFILE
    else
        echo "Disable domains command file does not exist, creating $DISABLEFILE" >> $LOGFILE
        touch $DISABLEFILE
    fi

    if [ -f $ENABLEFILE ];
      then
        echo "Enable domains command file exists: $ENABLEFILE" >> $LOGFILE
    else
        echo "Enable domains command file does not exist, creating $ENABLEFILE" $LOGFILE
        touch $ENABLEFILE
    fi

    if [ -f $ENABLEADTSBFILE ];
      then
        echo "Enable ADT SB domains command file exists: $ENABLEADTSBFILE" >> $LOGFILE
    else
        echo "Enable ADT SB domains command file does not exist, creating $ENABLEADTSBFILE" $LOGFILE
        touch $ENABLEFILE
    fi
}

checkParms ()
{
	if [ -z "$FIRMWARE" ];
	then
		usageMessage
		exit 1
	fi
    if [ -z "$DPENV" ];
    then
        usageMessage
        exit 1
    fi

    case $DPENV in
      SBX|ADT-SB|QAT-SB|SPTx-SB|SPTy-SB)
         THISENV="NP"
         UTILID=
         UTILPWD=
         THISHOST=`echo $HOSTNAME`
         ;;
      ADT-ESG|QAT-ESG|SPT-ESG)
         THISENV="NP"
         UTILID=
         UTILPWD=
         THISHOST=`echo $HOSTNAME`
         ;;
      PRDw-SB|PRDx-SB|PRDy-SB|PRDz-SB)
         THISENV="PRD"
         UTILID=
         UTILPWD=
         THISHOST=`echo $HOSTNAME`
         ;;
      PRDx-ESG|PRDy-ESG)
         THISENV="PRD"
         UTILID=
         UTILPWD=
         THISHOST=dputil01094n01.np.costco.com
         ;;
      *)
         echo "Unrecognized environment parameter provided - $DPENV" 
         usageMessage
         exit 1
         ;;
    esac

	# Update this with how environments are mapped to which Datapower appliance they point to - this is a convenience so people running the script don't have to type in the entire appliance path each time
    case $DPENV in  
      SBX)
         DPHOST=""
         ;;
      ADT-SB)
         DPHOST=""
         ;;
      ADT-ESG)
         DPHOST=""
         ;;
      QAT-SB) 
         DPHOST=""
         ;;
      QAT-ESG)
         DPHOST=""
         ;;
      SPTx-SB) 
         DPHOST=""
         ;;
      SPTy-SB) 
         DPHOST=""
         ;;
      SPT-ESG)
         DPHOST=""
         ;;
      PRDw-SB)
         DPHOST=""
         ;;
      PRDx-SB)
         DPHOST=""
         ;;
      PRDy-SB)
         DPHOST=""
         ;;
      PRDz-SB)
         DPHOST=""
         ;;
      PRDx-ESG)
         DPHOST=""
         ;;
      PRDy-ESG)
         DPHOST=""
         ;;
    esac

    LOGFILE=/dp/firmware-update/firmware-update-$DPENV-$LOGDATE-$LOGTIME.txt
}
			
checkFirmwareFile ()
{
    if [ -r $FIRMWARE_DIR/$FIRMWARE ];
    then 
      echo "Firmware file $FIRMWARE_DIR/$FIRMWARE found." >> $LOGFILE
    else
      echo "Firmware file $FIRMWARE_DIR/$FIRMWARE not found, exiting." >> $LOGFILE
      exit 1
    fi
}

uploadFirmwareFile ()
{
   ssh -T $DPHOST < $UPLOADFILE >> $LOGFILE

   COPYMSGCOUNT=`grep "File copy success" $LOGFILE | wc -l`

   if [ $COPYMSGCOUNT = 2 ];
    then
     echo "Firmware file $FIRMWARE successfully uploaded at `date +%F%T`" >> $LOGFILE
   else
     echo "Did not find 2 File copy success entries in $LOGFILE - found $COPYMSGCOUNT, aborting at `date +%F%T`" >> $LOGFILE
     sendEmailWithAttachment "Error occured on $DPHOST while uploading $FIRMWARE.\n  See $LOGFILE or attached file for more information." "Error"
     exit 1
   fi
}

disableDomains ()
{
   ssh -T $DPHOST < $DISABLEFILE >> $LOGFILE

   CFGMSGCOUNT=`grep "Configuration saved successfully" $LOGFILE | wc -l`

   if [ $CFGMSGCOUNT = 1 ];
    then
     echo "All domains other than default successfully disabled at `date +%F%T`" >> $LOGFILE
   else
     echo "Disable domains was unsuccessful, aborting at `date +%F%T`" >> $LOGFILE
     sendEmailWithAttachment "Error occured on $DPHOST while disabling domains.\n  See $LOGFILE or attached file for more information." "Error"
     exit 1
   fi
}

enableDomains ()
{
    ssh -T $DPHOST < $ENABLEFILE >> $LOGFILE

    CFGMSGCOUNT=`grep "Configuration saved successfully" $LOGFILE | wc -l`

    #At this point in the script, there will be 2 Configuration saved successfully messages if everything worked so far
    if [ $CFGMSGCOUNT = 2 ];
     then
      echo "All domains other than default successfully enabled at `date +%F%T`" >> $LOGFILE
    else
      echo "Enable domains was unsuccessful at `date +%F%T`.  Domains will need to be enabled manually." >> $LOGFILE
      sendEmailWithAttachment "Error occured on $DPHOST while enabling domains.\n  See $LOGFILE or attached file for more information." "Error"
      exit 1
    fi

}

updateFirmware ()
{
   ssh -T $DPHOST < $UPDATEFILE  >> $LOGFILE

   # The success message for firmware update differs between 7.2 and 7.5, but this line is consistent.  Will change this line after all appliances are on 7.5+
   # On 7.5, the message is "Operation successful" - on 7.2 it is "Firmware upgrade successful"
   UPDMSGCOUNT=`grep "Device is rebooting now" $LOGFILE | wc -l`

   if [ $UPDMSGCOUNT = 1 ];
    then
     echo "Firmware successfully updated. Sleeping for 60 seconds at `date +%F%T`" >> $LOGFILE
     sleep 60
   else
     echo "Firmware update was unsuccessful, aborting at `date +%F%T`" >> $LOGFILE
     sendEmailWithAttachment "Error occured on $DPHOST while updating firmware.\n  See $LOGFILE or attached file for more information." "Error"
     exit 1
   fi
}

showDomains ()
{
   ssh -T $DPHOST < $DOMAINSFILE  >> $LOGFILE

   echo "Show Domains successfully run." >> $LOGFILE
}

rebootAppliance ()
{
   ssh -T $DPHOST < $REBOOTFILE  >> $LOGFILE

   echo "Appliance rebooting after firmware update, sleeping for 60 seconds at `date +%F%T`" >> $LOGFILE
   sleep 60
}
 
checkApplianceState ()
{
  while ! ping -c 1 $DPHOST > /dev/null 2>&1 ;  
    do
      echo "Waiting for appliance to reboot at `date +%F%T` " >> $LOGFILE     
      sleep 30
    done

  echo "Appliance is responding to pings at `date +%F%T`" >> $LOGFILE

  CURLURL="https://$DPHOST:9090/login.xml"
  echo "Using curl to check for $CURLURL at `date +%F%T`" >> $LOGFILE
  until $(curl --output /dev/null --silent --head --fail --insecure -i -X GET $CURLURL); do
    printf '.' >> $LOGFILE
    sleep 5
  done
  echo "$CURLURL sucessfully fetched, sleeping for 30 seconds before continuing at `date +%F%T`" >> $LOGFILE

  sleep 30
}

##
# Set list of commands to execute in Datapower box
# This will login to the appliance in the default domain, switch to config, upload it from dputil, then exit
##
setUploadFirmwareCommands () 
{
cat << EOF > $UPLOADFILE
$DPUID
$DPPWD
default
co
copy -f scp://$UTILID:$UTILPWD@$THISHOST//home/wdpmgmt/firmware/$FIRMWARE image:///$FIRMWARE
copy -f scp://$UTILID:$UTILPWD@$THISHOST//home/wdpmgmt/firmware/license.accepted temporary:///license.accepted
exit
exit
EOF

echo "Populated Upload Firmware Command text File $UPLOADFILE" >> $LOGFILE
}

setUpdateFirmwareCommands ()
{
cat << EOF > $UPDATEFILE
$DPUID
$DPPWD
default
co
flash
boot image $FIRMWARE
EOF

echo "Populated Update Firmware Command text File $UPDATEFILE" >> $LOGFILE
}

setDisableDomainCommands ()
{
cat << EOF > $DISABLEFILE
$DPUID
$DPPWD
default
all-domains disabled
y
co
write mem
y
exit
exit
EOF

echo "Populated Disable Domains Command text File $DISABLEFILE" >> $LOGFILE
}

setEnableDomainCommands ()
{
cat << EOF > $ENABLEFILE
$DPUID
$DPPWD
default
all-domains enabled
y
co
write mem
y
exit
exit
EOF

echo "Populated Enable Domains Command text File $ENABLEFILE" >> $LOGFILE
}

setEnableADTSBDomainCommands ()
{
cat << EOF > $ENABLEADTSBFILE
$DPUID
$DPPWD
default
co
domain ADT-SERVICEBUS
admin-state enabled
show
exit
domain ADT-REST-SERVICEBUS
admin-state enabled
show
exit
write mem
y
exit
exit
EOF

echo "Populated ADT SB Enable Domains Command text File $ENABLEADTSBFILE" >> $LOGFILE
}

setRebootCommands ()
{
cat << EOF > $REBOOTFILE
$DPUID
$DPPWD
default
shutdown reboot
y
EOF

echo "Populated Reboot Command text File $REBOOTFILE" >> $LOGFILE
}


setShowDomainsCommands ()
{
cat << EOF > $DOMAINSFILE
$DPUID
$DPPWD
default
echo "#STARTDOMAINS#"
show domains
echo "#ENDDOMAINS#"
exit
EOF

echo "Populated Show Domains Command text File $DOMAINSFILE" >> $LOGFILE
}

sendEmail ()
{
   echo -e "$1" | mailx  -s "Datapower appliance $DPHOST Firmware Update - $2" "${EMAIL_DISTR_LIST}" 
}

sendEmailWithAttachment ()
{
   echo -e "$1" | mailx  -s "Datapower appliance $DPHOST Firmware Update - $2 " -a ${LOGFILE} "${EMAIL_DISTR_LIST}" 
}

#main 

checkParms
initialize
checkFirmwareFile
setUploadFirmwareCommands
sendEmail "Firmware update on $DPHOST using $FIRMWARE starting.\n  Domains will be disabled and appliance rebooted.\n  See $LOGFILE for more information." "Notice"
uploadFirmwareFile
setDisableDomainCommands
disableDomains
setUpdateFirmwareCommands
updateFirmware
checkApplianceState
setEnableDomainCommands
enableDomains
sendEmailWithAttachment "Firmware update on $DPHOST using $FIRMWARE completed.\n Run test case scripts to ensure functionality.\n  See $LOGFILE or attached log for more information.\n  Please cleanup firmware in $HOME/firmware/ directory if finished." "Success"
exit 0
