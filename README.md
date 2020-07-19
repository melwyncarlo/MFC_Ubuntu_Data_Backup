# MFC_Ubuntu_Data_Backup
A Bash based Application to Backup Folders (and compress them, optionally) onto an external media drive.

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
sudo rm -f /usr/share/applications/mfcdb.desktop && sudo rm -f /usr/share/applications/mfcdbl.desktop
</pre>

<br><br>
### To run the application from its source :

1.  The Original Version  :  `./databackup.sh`
2.  The Lite Version      :  `./databackuplitestart.sh`

<br><br>
### For any other queries :

<ins>Email me on :</ins>
- _Github_
- _carlo.melwyn@outlook.com_

