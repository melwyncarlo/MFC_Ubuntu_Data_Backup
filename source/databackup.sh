#!/bin/bash



exec 2> "data/db.tmp"


source src/headerdesign.sh
source src/dbfunctions.sh


sourcesStorage=()
sourcesInput=()
tmpArray1=()
tmpArray2=()


export readonly START_DIRECTORY="/home/`whoami`/Desktop"
readonly DEFAULT_DATFILEPATH="data/paths_list.dat"
readonly DB_TEMP_FILE="data/dbtempfile"


if [ ! -f "$DEFAULT_DATFILEPATH" ]; then
	echo -n "" > "$DEFAULT_DATFILEPATH"
fi



function_finalisebackuppaths()
{
	local count=1
	local tmpStr01=""
	local tmpStr02=""
	local elem1=""

	echo "\n" > $DB_TEMP_FILE
	for elem1 in ${sourcesStorage[@]}
	do
		printf -v tmpStr01 "%02d" $count
		echo " Directory/Folder #$tmpStr01 :  ${elem1:0:80}" >> $DB_TEMP_FILE
		if [ ${#elem1} -gt 80 ]; then
			printf -v tmpStr01 "% 25s"
			echo "\n$tmpStr01${elem1:80}" >> $DB_TEMP_FILE
		fi
		echo "\n\n" >> $DB_TEMP_FILE
		let "count = count + 1"
	done
	while :
	do
		whiptail --textbox $DB_TEMP_FILE --scrolltext 30 120
		tmpStr01="QUERY 01 :  FINALIZE BACKUP DIRECTORY PATHS"
		tmpStr02="\n  Have you read the 'Directory Paths' list ?"
		if (whiptail --title "$tmpStr01" --yesno "$tmpStr02" 10 80); then
			tmpStr01="QUERY 02 :  FINALIZE BACKUP DIRECTORY PATHS"
			tmpStr02="\n  Choose an option :"
			if (whiptail --title "$tmpStr01" --yesno "$tmpStr02" --yes-button "< PROCEED >" \
			--no-button "< RESTART PROGRAM >" 10 80); then
				return 1
			else
				return 0
			fi
		fi
	done
}


function_checkdirroot()
{
	local line=""
	local elem1=""
	local tmpVar1=""
	local tmpVar2=""
	local tmpStr01=""
	local tmpStr02=""

	tmpArray1=()

	for elem1 in ${!sourcesInput[@]}
	do
		echo "0" > $DB_TEMP_FILE
		tmpVar1=`du -bsh "${sourcesInput[$elem1]}" 2> $DB_TEMP_FILE`
		tmpVar2=""
		while read -rs line
		do
			tmpVar2+="$line"
		done < $DB_TEMP_FILE
		if [[ "$tmpVar2" != "0" ]] && [[ "$tmpVar2" != "" ]]; then
			tmpStr01="QUERY :  RESTRICTED DIRECTORY ROOT ACCESS"
			tmpStr02="\n  Directory/Folder Path is :\n  ${sourcesInput[$elem1]}\n"
			tmpStr02+="  ========================================================================\n\n"
			tmpStr02+="  Some of the files and folders in this directory are only accessible by \n  'Root Access'."
			tmpStr02+=" If you proceed, and do not discard this directory path, \n  some restricted files and folders"
			tmpStr02+=" may not be backed up.\n\n\n  Do you wish to  << DISCARD >>  this directory path ?\n\n"
			if ! (whiptail --title "QUERY :  $tmpStr01" --yesno "$tmpStr02" --yes-button "No" --no-button "Yes" 20 80); then
				unset sourcesInput[$elem1]
			fi
		fi
	done
}


function_checksimilardir()
{
	local elem1=""
	local elem2=""

	tmpArray1=()
	tmpArray2=()

	for elem1 in ${sourcesInput[@]}
	do
		for elem2 in ${sourcesStorage[@]}
		do
			if [[ "$elem1" == *"$elem2"* ]] || [[ "$elem2" == *"$elem1"* ]]; then
				tmpArray1+=("$elem1")
				tmpArray2+=("$elem2")
			fi
		done
	done
}


function_clearsimilardir()
{
	local i=0
	local cleared=0
	local removeArr=()
	local opt=""
	local elem0=""
	local elem1=""
	local elem2=""

	for i in ${!tmpArray1[@]}
	do
		opt=$(whiptail --title "QUERY :  DUPLICATION REMOVAL" --radiolist --nocancel \
		"\n\n  Which one of these paths do you wish to use ?\n\n" 20 78 4 \
		"[1]" "  ${tmpArray1[$i]}  " ON \
		"[2]" "  ${tmpArray2[$i]}  " OFF \
		3>&1 1>&2 2>&3)
		if [ "${opt:1:1}" == "1" ]; then	
			removeArr+=("${tmpArray2[$i]}")
		else
			removeArr+=("${tmpArray1[$i]}")
		fi
	done

	for elem0 in ${removeArr[@]}
	do
		cleared=0
		for elem1 in ${!sourcesInput[@]}
		do
			if [[ "${sourcesInput[$elem1]}" == "$elem0" ]]; then
				unset sourcesInput[$elem1]
				cleared=1
				break
			fi
		done
		if [ $cleared -eq 0 ]; then
			for elem2 in ${!sourcesStorage[@]}
			do
				if [[ "${sourcesStorage[$elem2]}" == "$elem0" ]]; then
					unset sourcesStorage[$elem2]
					break
				fi
			done
		fi
	done

	tmpArray1=()
	tmpArray2=()
}


# Parameter 1 - Return Array	[ REFERENCE ]
# Parameter 2 - Mode ( 1 => *.dat File; 2 => Source Directories)
function_explorer()
{
	local line=""

	local -n returnArr=$1
	returnArr=()
	local mode="$2"

	if [ $mode -eq 1 ]; then
	gnome-terminal --title="MFC Linux File Explorer" -- bash -c \
	'source src/mfc_linux_fileexplorer.sh 24 80 37 150; mfc_fileexplore "$START_DIRECTORY" "0" "0" "0" "0" "0" "3" "0" "load" "0"'
	else
	gnome-terminal --title="MFC Linux File Explorer" -- bash -c \
	'source src/mfc_linux_fileexplorer.sh 24 80 37 150; mfc_fileexplore "$START_DIRECTORY" "0" "0" "0" "0" "1" "3" "1" "backup" "0"'
	fi

	while :
	do
		line=`head "src/data/mfc_fileexplorer_processdone.txt"`
		if [[ "$line" == "1" ]]; then
			while read -rs line
			do
				returnArr+=("$line")
			done < "src/data/mfc_fileexplorer_filepath.txt"
			break
		elif [[ "$line" == "-1" ]]; then
			break
		fi
	done
}


# Parameter 1 - Return String	[ REFERENCE ]
# Parameter 2 - Title
# Parameter 3 - Message
function_input()
{
	local exitstatus=""

	local -n returnStr=$1
	returnStr=""
	local title="$2"
	local message="$3"

	while :
	do
		returnStr=$(whiptail --inputbox "$message" 13 80 --title "$title" 3>&1 1>&2 2>&3)
		exitstatus=$?
		if [ $exitstatus -eq 0 ]; then
			break
		fi
	done
}




exitstatusglobal=""
destdirpath=""
transferopt=""
lineglobal=""
deviceopt=""
selectopt=""
datinput=""
dirElem=""
destdir=""
tmpElem=""
tmpStr1=""
tmpStr2=""
tmpStr3=""
loopPos=4
dirList=()


exec 2>&1


resize -s 35 145

clear
clear


tmpArray1=("\n" "WELCOME  TO  THE LINUX DATA-BACKUP PROGRAM !" "\n")
tmpArray1+=("-------------------------------------------------------")
tmpArray1+=("\n" "This program belongs to Mr. Melwyn Francis Carlo." "\n")
mfc_scrollheader "80" "" "" "0" "2" "3" "1" "#" "${tmpArray1[@]}"
tmpStr0="$mfc_headerdesignresult"
whiptail --title "HOME :: MFC LINUX DATA-BACKUP" --msgbox "$tmpStr0" 21 84


tmpStr1="\n   TIPS :\n  ========================================================================"
tmpStr1+="\n\n   1.  To enter a source directory path, go to the directory using "
tmpStr1+="\n       Nautilus/File-Explorer. Then press 'Ctrl+L' (Control & L).\n"
tmpStr1+="       This should put focus on the directory URL.\n\n"
tmpStr1+="   2.  Note that the URL must be of the form :  '/home/{username}/ . . .'\n\n"
tmpStr1+="   3.  Copy the URL and Paste it into the terminal where requested.\n\n"
tmpStr1+="   4.  Repeat the process as and when required."
whiptail --title "INFO :  BACKUP DIRECTORY/FOLDER PATHS" --msgbox "$tmpStr1" 20 80



while :
do
	if [ $loopPos -eq 0 ]; then
		break
	else
		loopPos=4
	fi

	function_msg "Checking external media directory . . ."
	sleep 1.5

	dirList=()
	tmpArray1=()
	destdirpath="/media/`whoami`"
	dirList=($(ls -A $destdirpath))
	for dirElem in "${dirList[@]}"
	do
		if [ -d "$destdirpath/$dirElem" ]; then
			tmpArray1+=("$dirElem")
		fi
	done

	function_msg

	if [ ${#tmpArray1[@]} -eq 0 ]; then
		tmpStr1="\n  Error :  No external media devices are currently connected to the"
		tmpStr1+="\n           computer system. Please check the device connection and"
		tmpStr1+="\n           try again.\n"
		whiptail --title "ERROR :  BACKUP DEVICE" --msgbox "$tmpStr1" 11 80
		function_opt "1"
	else
		while :
		do
			if [ $loopPos -le 1 ]; then
				break
			else
				loopPos=4
			fi

			function_msg "Please wait . . ."

			tmpArray2=()
			for tmpElem in "${!tmpArray1[@]}"
			do
				if [ $tmpElem -eq 0 ]; then
					tmpArray2+=("[$(($tmpElem+1))]" "  ${tmpArray1[tmpElem]}  " "ON")
				else
					tmpArray2+=("[$(($tmpElem+1))]" "  ${tmpArray1[tmpElem]}  " "OFF")
				fi
			done

			while :
			do
				function_msg

				tmpStr1="\n\n  ▮▮▮▮▮  ${#tmpArray1[@]} devices have been found !  ▮▮▮▮▮\n\n"
				tmpStr1+="  Select a device to which you wish to backup :\n\n"
				deviceopt=$(whiptail --title "QUERY :  DESTINATION DEVICE CHOICE" --radiolist "$tmpStr1" 25 80 12 \
				"${tmpArray2[@]}" 3>&2 2>&1 1>&3)
				exitstatusglobal=$?
				if [ $exitstatusglobal -eq 0 ]; then
					tmpStr2="${deviceopt:1:$((${#deviceopt}-2))}"
					let "tmpStr2 = tmpStr2 - 1"
					destdir=${tmpArray1[$tmpStr2]}
					break
				else
					function_opt "1"
				fi
			done

			function_checkexterndevice "$destdirpath/$destdir"


			sourcesStorage=()
			while :
			do
				if [ $loopPos -le 2 ]; then
					break
				else
					loopPos=4
				fi

				while :
				do
					transferopt=$(whiptail --title "QUERY :  TRANSFER METHOD" --radiolist \
					"\n\n  Which transfer method do you prefer ?\n\n" 20 87 4 \
					"[1]" "  Using the MFC Linux File Explorer" ON \
					"[2]" "  Using a '*.dat' (Data) file containing a list of directory paths  " OFF \
					"[3]" "  Typing in directory paths manually" OFF \
					3>&1 1>&2 2>&3)
					exitstatusglobal=$?
					if [ $exitstatusglobal = 0 ]; then
						transferopt="${transferopt:1:1}"
						break
					else
						function_opt "1"
					fi
				done


				while :
				do
					if [ $loopPos -le 3 ]; then
						break
					else
						loopPos=4
					fi

					if [ $transferopt -eq 1 ]; then
						while :
						do
							function_msg "Please wait . . ."

							sourcesInput=()
							function_explorer sourcesInput "2"

							function_msg "Verifying Files/Folders Input . . ."

							for tmpElem in ${sourcesInput[@]}
							do
								if [ ! -d "$tmpElem" ]; then
									tmpStr1="\n  You can NOT select a regular file.\n"
									tmpStr1+="  Select directories/folders only !\n\n"
									tmpStr1+="  Error File is :\n  '$tmpElem'\n"
									whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
									"$tmpStr1" 13 80
									sourcesInput=()
									break
								fi
							done

							if [ ${#sourcesInput[@]} -ne 0 ]; then
								tmpArray1=("---")
								while [ ${#tmpArray1[@]} -ne 0 ]
								do
									function_checksimilardir
									if [ ${#tmpArray1[@]} -ne 0 ]; then
										function_clearsimilardir
									fi
								done
								function_checkdirroot
							fi
							sourcesStorage+=("${sourcesInput[@]}")
							tmpStr2="\n   ${#sourcesStorage[@]} directory/folder paths have been "
							tmpStr2+="selected so far !\n\n"
							whiptail --title "INFO :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
							"$tmpStr2" 10 65
							function_opt "2"
							exitstatusglobal=$?
							if [ $exitstatusglobal -eq 1 ]; then
								loopPos=3
							fi
							break
						done

					elif [ $transferopt -eq 2 ]; then
						while :
						do
							function_msg

							sourcesInput=()

							tmpArray1=()
							selectopt=$(whiptail --title "QUERY :  DATA FILE SELECTION" --radiolist \
							"\n\n  Which file selection method do you prefer ?\n\n" 20 78 4 \
							"[1]" "  Use the default 'paths_list.dat' file  " ON \
							"[2]" "  Using the MFC Linux File Explorer  " OFF \
							"[3]" "  Typing in file path manually" OFF \
							3>&1 1>&2 2>&3)
							exitstatusglobal=$?
							if [ $exitstatusglobal = 0 ]; then
								selectopt="${selectopt:1:1}"
							else
								loopPos=3
								break
							fi

							if [[ "$selectopt" == "1" ]]; then
								datinput="$DEFAULT_DATFILEPATH"
							elif [[ "$selectopt" == "2" ]]; then
								function_explorer tmpArray1 "1"
								datinput="${tmpArray1[@]}"
							else
								tmpStr1="\n\n  Enter the location of the '*.dat' file containing a list of "
								tmpStr1+="\n  backup directory paths :\n\n"
								function_input datinput "QUERY :  DATA FILE SELECTION" "$tmpStr1"
							fi


							function_msg "Verifying Files/Folders Input . . ."

							if [[ "$datinput" == "" ]]; then
								whiptail --title "ERROR :  DATA FILE SELECTION" --msgbox \
								"\n  You have NOT entered a file path !\n" 9 80
							elif [[ "${datinput:$((${#datinput}-4))}" != ".dat" ]]; then
								tmpStr1="\n           You can NOT select a regular file/folder.\n"
								tmpStr1+="           Select a DATA (*.dat) file only !\n\n"
								whiptail --title "ERROR :  DATA FILE SELECTION" --msgbox \
								"$tmpStr1" 10 60
							elif [ ! -f "$datinput" ]; then
								whiptail --title "ERROR :  DATA FILE SELECTION" --msgbox \
								"\n  The entered filepath does NOT exist !\n" 9 80
							else
								tmpStr2=1
								while read -rs lineglobal
								do
									if [ ! -d "$lineglobal" ]; then
										lineglobal=$(echo -e $lineglobal | tr -d '\t')
										lineglobal=$(echo -e $lineglobal | tr -d '\n')
										lineglobal=$(echo -e $lineglobal | tr -d ' ')
										if [[ "$lineglobal" != "" ]]; then
											tmpStr2=0
											break
										fi
									else
										sourcesInput+=("$lineglobal")
									fi
								done < "$datinput"

								if  [ $tmpStr2 -eq 0 ]; then
									tmpStr1="\n  You can NOT enter the path of a regular file.\n"
									tmpStr1+="  Only paths of directories/folders are alowed !\n\n"
									tmpStr1+="  Error File is :\n  '$tmpElem'\n"
									whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
									"$tmpStr1" 13 80
								else
									for tmpElem in ${sourcesInput[@]}
									do
										if [ ! -d "$tmpElem" ]; then
											tmpStr1="\n  You can NOT select a regular file.\n"
											tmpStr1+="  Select directories/folders only !\n\n"
											tmpStr1+="  Error File is :\n  '$tmpElem'\n"
											whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" \
											--msgbox "$tmpStr1" 13 80
											sourcesInput=()
											break
										fi
									done

									if [ ${#sourcesInput[@]} -ne 0 ]; then
										tmpArray1=("---")
										while [ ${#tmpArray1[@]} -ne 0 ]
										do
											function_checksimilardir
											if [ ${#tmpArray1[@]} -ne 0 ]; then
												function_clearsimilardir
											fi
										done
										function_checkdirroot
									fi
									sourcesStorage+=("${sourcesInput[@]}")
									tmpStr3="\n   ${#sourcesStorage[@]} directory/folder paths have been "
									tmpStr3+="selected so far !\n\n"
									whiptail --title "INFO :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
									"$tmpStr3" 10 65
								fi
								
								function_opt "2"
								exitstatusglobal=$?
								if [ $exitstatusglobal -eq 1 ]; then
									loopPos=3
								fi
								break
							fi
						done

					else
						while :
						do
							function_msg

							sourcesInput=()
							function_input tmpStr1 "QUERY :  BACKUP FILES/FOLDERS SELECTION" \
							"\n\n  Enter the location of a backup directory/folder :\n\n"

							function_msg "Verifying Files/Folders Input . . ."

							if [[ "$tmpStr1" == "" ]]; then
								whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
								"\n  You have NOT entered anything !\n" 9 80
								sourcesInput=()
							elif [ ! -e "$tmpStr1" ]; then
								whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
								"\n  The entered filepath does NOT exist !\n" 9 80
								sourcesInput=()
							elif [ ! -d "$tmpStr1" ]; then
								tmpStr1="\n           You can NOT select a regular file.\n"
								tmpStr1+="           Select directories/folders only !\n\n"
								whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
								"$tmpStr1" 10 60
								sourcesInput=()
							else
								sourcesInput=("$tmpStr1")
								function_checksimilardir
								if [ ${#tmpArray1[@]} -ne 0 ]; then
									function_clearsimilardir
								fi
								function_checkdirroot
								sourcesStorage+=("${sourcesInput[@]}")
								tmpStr3="\n   ${#sourcesStorage[@]} directory/folder paths have been "
								tmpStr3+="selected so far !\n\n"
								whiptail --title "INFO :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
								"$tmpStr3" 10 65
							fi
							
							function_opt "2"
							exitstatusglobal=$?
							if [ $exitstatusglobal -eq 1 ]; then
								loopPos=3
							fi
							break
						done

					fi

					if [ $loopPos -le 3 ]; then
						break
					fi

					if [ ${#sourcesStorage[@]} -eq 0 ]; then
						whiptail --title "ERROR :  BACKUP FILES/FOLDERS SELECTION" --msgbox \
						"\n  You have NOT selected a single backup file/folder !\n" 9 80
						function_opt "1"
						loopPos=3
					else
						loopPos=2
					fi

				done
			done


			function_finalisebackuppaths
			exitstatusglobal=$?
			if [ $exitstatusglobal -eq 1 ]; then
				function_checkexterndevice "$destdirpath/$destdir"
				function_begin_transfer "$destdirpath/$destdir" "0" "" "${sourcesStorage[@]}"
				loopPos=0
			else
				loopPos=1
			fi

		done
		
	fi
done


exec 2> "data/db.tmp"

function_msg

tmpArray1=("\n" "ALL  BACKED  UP !" "THIS PROGRAM WILL SUCCESFULLY TERMINATE NOW !" "\n")
mfc_rectangularheader "80" "" "0" "2" "1" "3" "1" "1" "3" "" "#" "${tmpArray1[@]}"
tmpStr1="$mfc_headerdesignresult"
whiptail --title "ERROR :  DESTINATION DEVICE" --msgbox "\n\n$tmpStr1" 16 84
exit 0



