# fswatch_watchfolder_script

** A "file-system events" script built to avoid scanning a folder
Using operating system specific filesystem events it also monitors for "growing files" before acting**

It looks for to fswatch event names "Updated", "Renamed", "MovedTo" so files don't trigger until ready.

"Renamed" event accepts file moves into the watch folder

"Updated" accepts a “file-closed” event after a file copy into the watch folder occurs

"MovedTo" event is operating system specific to Linux and identifies file moves into the watchfolder

If a file is removed from the watch folder, the script checks for this
false event by examining the folder for the same file.  If the file doesn’t exist,
the event is ignored.


** MUST CONFIGURE LINES WITHIN CONFIGURATION SECTION **
