#! /bin/bash


# ********************************************************
# CONFIGURE START
# ********************************************************

# ********************************************************
#           REMINDERS
# 1. Choose your default cipher in the configure section (use "ssh -Q cipher" to see which ciphers your client supports
# 2. Add public key from your source machine to destination server to avoid authentication request for scp copy
# (https://www.linode.com/docs/security/use-public-key-authentication-with-ssh)
# 3. Add config file to /etc/newssyslog.d folder (fswatch_watchfolder.conf) to manage logs
# (http://www.real-world-systems.com/docs/newsyslog.1.html)
#
# ********************************************************

# identify location of fswatch binary
FSWATCH_PATH="/usr/local/bin/fswatch"
sshPath="/usr/bin/ssh"

# Redirect Log location ***REMEMBER TO CREATE the file fswatch_watchfolder.log and set permissions to 777***
LOG_FILE_PATH="/Library/Logs/fswatch_watchfolder.log"    
exec >> "$LOG_FILE_PATH"
exec 2>&1

# identify local location of Watchfolder
LOCAL_WATCHFOLDER_PATH="<Path to WatchFolder>"

# Set Finished File Folder Path
TARGET_TRANSITION_PATH="<Path to Transition Folder>"
# Set remote path if using remote destination
REMOTE_DESTINATION_PATH="user@<IP>:<REMOTE PATH>"

# Choose cipher to use for SSH (choices best choices arcfour256, aes256-ctr, aes128-ctr)
SSH_cipher="aes128-ctr"

# fswatch parameter to control how often a trigger will be detected when watching for a folder change
LATENCY=3

# ********************************************************
# CONFIGURE END
# ********************************************************


# Watch for changes and sync (exclude hidden files)
# MacOS event types to trigger on = "Updated" or "Renamed"
# Linux event types to trigger on = "Updated" or "MovedTo"
echo    "Watching for changes. Quit anytime with Ctrl-C."
${FSWATCH_PATH} -0 --event Updated --event Renamed --event MovedTo -l $LATENCY $LOCAL_WATCHFOLDER_PATH --exclude="/\.[^/]*$" \
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
echo "$TriggerFilePath File exists in watchfolder"
echo "Moving file to Transition Folder"
mv "$TriggerFilePath" "$TARGET_TRANSITION_PATH"
#echo "$TriggerFileBaseName"
scpFilePathSource="${TARGET_TRANSITION_PATH}${TriggerFileBaseName}"

# Copy file(s) using faster arcfour256 cipher - This for this cipher must be added to sshd config file
# A public ssh key needs to be set up to avoid authentication requests from scp
echo "Copying "$TriggerFileBaseName" to Destination Server"
	rsync -aW \
	--size-only \
    --include-from="$TempFileName" \
    --stats \
    -e "ssh -T -c "$SSH_cipher" -o Compression=no -x" \
    "$scpFilePathSource" "$REMOTE_DESTINATION_PATH" \
    | tee -a "$LOG_FILE_PATH"
	else
echo ""
#echo "$TriggerFilePath File has been removed from watchfolder"
fi

sleep 2

# Removing temp event file and looping to next event
 rm "$TempFileName"


done
