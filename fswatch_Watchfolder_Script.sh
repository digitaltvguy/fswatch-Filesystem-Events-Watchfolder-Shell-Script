#! /bin/bash

FSWATCH_PATH="/usr/local/bin/fswatch"

LOCAL_PATH="<Local WatchFolder Path"

# Set Finished File Folder Path
TARGET_PATH="Local Transition Destination Path"
# Set remote path if using remote destination
REMOTE_PATH="user@<IP>:<Remote File Path>"

# fswatch parameter to control how often a trigger will be detected when watching for a folder change
LATENCY=3

# Watch for changes and sync (exclude hidden files)
echo    "Watching for changes. Quit anytime with Ctrl-C."
${FSWATCH_PATH} -0 --event Updated --event Renamed -l $LATENCY $LOCAL_PATH --exclude="/\.[^/]*$" \
| while read -d "" event
  do
# Create Unique temp file name  
    TempFileName="/tmp/fswatch_temp_file_`date +"%m-%d-%Y_%H-%M-%S"`"
#   echo "$TempFileName"
    echo $event > "$TempFileName"
#    echo -en "${green}" `date '+%m-%d-%Y_%H:%M:%S'` "${nocolor}\"$event\" changed. Synchronizing... "
#    echo ""
#    echo \"$event\"

# Get specific columns seperated by zeros
#awk '{print $1 " "$2 " "$3 " " $4 " " $5}' /tmp/fswatch_temp_file

# Store trigger file path in variable
TriggerFilePath="`cat $TempFileName`"
#echo "$TriggerFilePath"

# Get base name of Trigger File
TriggerFileBaseName=`echo "$TriggerFilePath" | sed 's/.*\///'`

# Test variables
# echo "$TriggerFilePath"
# cat "$TempFileName"

# Wait for files to be moved
sleep 1

#Check for false tripper because of file being moved out of the watchfolder to destination
if [ -f "$TriggerFilePath" ]
	then
echo ""
echo "$TriggerFilePath File exists"
mv "$TriggerFilePath" "$TARGET_PATH"
echo "$TriggerFileBaseName"
scpFilePathSource="${TARGET_PATH}${TriggerFileBaseName}"

# Copy file(s) using faster arcfour256 cipher - This for this cipher must be added to sshd config file
# A public ssh key needs to be set up to avoid authentication requests from scp
scp -o Cipher=arcfour256 "$scpFilePathSource" "$REMOTE_PATH"
	else
echo ""
#echo "$TriggerFilePath File has been removed from watchfolder"
fi

sleep 2

# Removing temp event file and looping to next event
 rm "$TempFileName"


done