# fswatch_watchfolder_script
shell script for fswatch which checks watchfolder for growing files via event type flags and delivers via scp to destination

This script uses file system events to check a watch folder and trans…
…fer the resulting file to a remote server

It looks for to fswatch events updated and renamed.

Renamed accepts file copies into the watch folder
updated accepts a “file-closed” event after a file copy into the watch
folder occurs

If a file is removed from the watch folder, the script checks for this
false event by examining the folder for the file.  If it doesn’t exist,
the event is ignored.
