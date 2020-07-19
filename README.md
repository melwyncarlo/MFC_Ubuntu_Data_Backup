# MFC_Ubuntu_Data_Backup
A Bash based Application to Backup Folders (and compress them, optionally) onto an external media drive.

<br><br>
### Important Tip
<pre>
The first backup is always going to be tedious and time-consuming.
The subsequent backups, however, will be quicker.
This is because the backups take place incrementally.
</pre>

<br><br>
### To install :
<pre>
Download the archived file 'mfcubuntudatabackup.tar' into the 'Downloads' directory of your system.

Open a terminal by pressing the following keys : Control + Alt + T

Type the following :
cd Downloads && sudo tar -xvf mfcubuntudatabackup.tar && cd mfcubuntudatabackup_container && ./install.sh


NOTE :  Enter the system password when requested. This is to allow access to the 
        thumbnail (icons) directory for adding a new thumbnail.
</pre>

<br><br>
### To uninstall :
<pre>
Open a terminal by pressing the following keys : Control + Alt + T

Type the following :
rm -rfv "/home/`whoami`/mfcubuntudatabackup" && rm -rfv "/home/`whoami`/Desktop/MFC-Ubuntu-Backup-Userbase"

Then, type the following :
sudo rm -fv /usr/share/applications/mfcdb.desktop && sudo rm -fv /usr/share/applications/mfcdbl.desktop
</pre>

<br><br>
### To run the application from its source :

1.  The Original Version  :  `./databackup.sh`
2.  The Lite Version      :  `./databackuplitestart.sh`

<br><br>
### Manual for inputting data into File : ~/Desktop/MFC-Ubuntu-Backup-Userbase/App-Parameters/MFC-DB-Lite-Arguments
<pre>
MFC_UBackup
1
0
0

/************************************************************************************/
/*****										*****/
/*****										*****/
/*****		ONLY EDIT THE "FIRST FOUR LINES" OF THIS FILE.			*****/
/*****										*****/
/*****		FOR THE FIRST LINE :						*****/
/*****		TYPE ONLY THE NAME OF THE EXTERNAL MEDIA DEVICE			*****/
/*****		TO WHICH YOU WISH TO BACKUP. (NOT FILE PATH)			*****/
/*****										*****/
/*****		FOR THE SECOND LINE :						*****/
/*****		TYPE '1' FOR SIMPLE TRANSFER, OR				*****/
/*****		TYPE '2' FOR COMPRESSED TRANSFER.				*****/
/*****										*****/
/*****		FOR THE THIRD LINE, IF SOME FILES/FOLDERS REQUIRE		*****/
/*****		ROOT ACCESS TO ACCESS THEM, THEN :				*****/
/*****		TYPE '1' TO PROCEED ANYWAY, OR					*****/
/*****		(SOME FILES/FOLDERS WILL NOT BE BACKED UP)			*****/
/*****		TYPE '2' TO EXIT THE APPLICATION, OR				*****/
/*****		TYPE '3' TO DISCARD THE CHOSEN DIRECTORY ALTOGETHER.		*****/
/*****										*****/
/*****		FOR THE FOURTH LINE, IF SOME FILES/FOLDERS ARE THE		*****/
/*****		SAME, OR IF THEY OVERLAP, THEN :				*****/
/*****		TYPE '1' TO PROCEED ANYWAY, OR					*****/
/*****		(SOME FILES/FOLDERS WILL BE BACKED UP MORE THAN ONCE)		*****/
/*****		TYPE '2' TO EXIT THE APPLICATION, OR				*****/
/*****		TYPE '3' TO DISCARD THE CHOSEN DIRECTORY ALTOGETHER.		*****/
/*****										*****/
/*****										*****/
/************************************************************************************/
</pre>

<br><br>
### Manual for inputting data into File : ~/Desktop/MFC-Ubuntu-Backup-Userbase/App-Parameters/List-of-Backup-Paths
<pre>
/home/[username]/Downloads/Random-Folder-1
/home/[username]/Downloads/Random-Folder-2

/************************************************************************************/
/*****										*****/
/*****										*****/
/*****		ADD ABSOLUTE DIRECTORY PATHS ONLY.				*****/
/*****										*****/
/*****		START TYPING AT THE TOP, FROM THE FIRST LINE OF THIS FILE.	*****/
/*****										*****/
/*****		TYPE ONLY ONE PATH PER LINE.					*****/
/*****										*****/
/*****										*****/
/************************************************************************************/
</pre>

<br><br>
### For any other queries :

<ins>Email me on :</ins>
- _Github_
- _carlo.melwyn@outlook.com_

