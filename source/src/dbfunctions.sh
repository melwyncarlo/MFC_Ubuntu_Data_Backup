#!/bin/bash


readonly MFC_DIR="/home/`whoami`/mfcubuntudatabackup"


source "$MFC_DIR/src/headerdesign.sh"


readonly DB_LITE_LOG="$MFC_DIR/data/dblite.log"

readonly MINIMUM_FREE_DISKSPACE_ALLOCATION=$((50 * 1000000))	# 50 Megabytes


# Parameter 1 - Data
# Parameter 2 - Mode ( 1 => Alpha; 2 => Num; 3 => AlphaNum; ?* => Specific Characters)
# Parameter 3 - Return Data	[ REFERENCE ]
mfc_remove()
{
	local tmpNum=0

	local mainStr=$1
	local mode=$2
	local -n returnStr=$3
	returnStr=""
	
	for ((i = 0 ; i < ${#mainStr} ; i++))
	do
		if [[ "$mode" == "1" ]] && ! [[ "${mainStr:$i:1}" =~ ^[a-zA-Z]+$ ]]; then
			returnStr+="${mainStr:$i:1}"
		elif [[ "$mode" == "2" ]] && ! [[ "${mainStr:$i:1}" =~ ^[0-9]+$ ]]; then
			returnStr+="${mainStr:$i:1}"
		elif [[ "$mode" == "3" ]] && ! [[ "${mainStr:$i:1}" =~ ^[0-9a-zA-Z]+$ ]]; then
			returnStr+="${mainStr:$i:1}"
		else
			let "tmpNum = ${#mode} - 1"
			if [[ "${mode:0:1}" == "?" ]] && [[ "${mainStr:$i:$tmpNum}" == "${mode:1:$tmpNum}" ]]; then
				let "i = i + tmpNum - 1"
			else
				if [[ "$mode" != "1" ]] && [[ "$mode" != "2" ]] && [[ "$mode" != "3" ]]; then
					returnStr+="${mainStr:$i:1}"
				fi
			fi
		fi
	done
}


# Parameter 1 - Value	[ REFERENCE ]
function_addzero()
{
	local -n returnValue="$1"

	if [[ "${returnValue:0:1}" == "." ]]; then
		returnValue="0$returnValue"
	elif [[ "${returnValue:0:1}" == "-" ]] && [[ "${returnValue:1:1}" == "." ]]; then
		returnValue="-0${returnValue:1}"
	fi
}


# Parameter 1 - Message
function_msg()
{
	local msg="$1"

	clear
	clear
	if [[ "$msg" != "" ]]; then
		echo
		echo
		echo -e "$msg"
	fi
}


# Parameter 1 - Lite Mode
function_end()
{
	local tmpStr0=""

	local litemode="$1"

	if [ $litemode -ne 1 ]; then
		tmpArray1=("\n" "THIS PROGRAM HAS BEEN INTENTIONALLY" "TERMINATED !" "\n")
		mfc_rectangularheader "80" "" "0" "2" "1" "3" "1" "1" "3" "" "#" "${tmpArray1[@]}"
		tmpStr0="$mfc_headerdesignresult"
		whiptail --title "ERROR :  DESTINATION DEVICE" --msgbox "\n\n$tmpStr0" 16 84
		function_msg
	else
		tmpStr0+="\n\n--------------------------------------------------------------\n"
		tmpStr0+=" THIS PROGRAM HAS BEEN INTENTIONALLY TERMINATED !"
		tmpStr0+="\n--------------------------------------------------------------\n\n\n"
		echo -e "$tmpStr0" >> $DB_LITE_LOG
	fi
	sleep 2
	echo "-1" > "$MFC_DIR/data/dbliteprocessdone"
	exit 0
}


# Parameter 1 - String Data
# Parameter 2 - Return Variable [ REFERENCE ]
function_extract_num()
{
	local param1="$1"
	local -n extractedResult="$2"
	extractedResult=""

	for ((i=1; i<=${#param1}; i++))
	do
		let "j = i - 1"
		if [[ "${param1:$j:1}" =~ ^[0-9]+$ ]]; then
			extractedResult+=${param1:$j:1}
		fi
	done
}


# Parameter 1 - Check External Device Path
# Parameter 2 - Lite Mode
function_checkexterndevice()
{
	local tmpStr0=""
	local errorExists=0

	local externdevicepath="$1"
	local litemode="$2"

	if [[ "$litemode" != "1" ]]; then
		while :
		do
			function_msg "Checking if the external device is connected . . ."

			if [ -e "$externdevicepath" ]; then
				break
			else
				tmpStr0="\n  The external device for backup seems to be disconnected !"
				tmpStr0+="\n  Please check the device and try again."
				whiptail --title "ERROR :  DESTINATION DEVICE" --msgbox "$tmpStr0" 10 65
				function_opt "1"
			fi
		done
	else
		echo -ne "Checking if the external device is connected . . ." >> $DB_LITE_LOG
		if [ -e "$externdevicepath" ]; then
			tmpStr0+="\n INFO :: DESTINATION DEVICE \n"
			tmpStr0+="<=============================>\n"
			tmpStr0+="Device Path :  $externdevicepath\n"
			tmpStr0="The external device is Connected!\n"
			tmpStr0+="Proceeding further ...\n\n\n"
		else
			errorExists=1
			tmpStr0+="\n ERROR :: DESTINATION DEVICE \n"
			tmpStr0+="<=============================>\n"
			tmpStr0+="Device Path :  $externdevicepath\n"
			tmpStr0="The external device for backup seems to be disconnected.\n"
			tmpStr0+="Cannot Proceed Further!\n\n\n"
		fi
		echo -e " Done!\n\n$tmpStr0" >> $DB_LITE_LOG
		if [ $errorExists -eq 1 ]; then
			function_end "1"
		fi
	fi
}


# Parameter 1 - Mode ( 1 => Continue Process; 2 => Repeat Process )
function_opt()
{
	local optMsg=""
	local titleMsg=""

	local mode="$1"

	function_msg

	if [[ "$mode" == "2" ]]; then
		optMsg="\n  Do you wish to  << REPEAT >>  the process ?\n\n"
		titleMsg="REPEAT PROCESS"
	else
		optMsg="\n  Do you wish to  << CONTINUE >>  ??\n\n"
		titleMsg="CONTINUE PROCESS"
	fi

	if (whiptail --title "QUERY :  $titleMsg" --yesno "$optMsg" --yes-button "No" --no-button "Yes" 10 80); then
		if [ $1 -eq 1 ]; then
			function_msg " Ending the program . . .\n\n"
			sleep 1.5
			function_end "0"
		fi
		return 0
	else
		return 1
	fi
}


# Parameter 1 - Destination
# Parameter 2 - Compressed Mode
# Parameter 3 - Return Path	[ REFERENCE ]
function_backupdirname()
{
	local tmpStr0=""

	local tmpDest="$1"
	local compressmode="$2"
	local -n returnDestPath="$3"
	returnDestPath=""

	if [ ! -d "$tmpDest/Backup" ]; then
		mkdir "$tmpDest/Backup"
	fi
	tmpStr0=`hostname`
	returnDestPath=$(echo $tmpStr0 | tr -c [:alnum:] '_')
	while :
	do
		if [[ "${returnDestPath:$((${#returnDestPath}-1)):1}" == "_" ]]; then
			returnDestPath="${returnDestPath:0:$((${#returnDestPath}-1))}"
		else
			break
		fi
	done
	if [[ "$compressmode" == "1" ]]; then
		returnDestPath+=".zpaq"
	else
		if [ ! -d "$tmpDest/Backup/$returnDestPath" ]; then
			mkdir "$tmpDest/Backup/$returnDestPath"
		fi
	fi

	returnDestPath="$tmpDest/Backup/$returnDestPath"
}


function_transfer_processing()
{
	local sumx=0
	local sumy=0
	local mval=0
	local bval=0
	local xval=0
	local sumx2=0
	local sumxy=0
	local perc1=0
	local perc2=0
	local time0=0
	local count=0
	local timeArr=()
	local percArr=()
	local tmpVar1=0
	local tmpVar2=0
	local tmpVar3=0
	local reftime=0
	local percout1=""
	local percout2=""
	local tmpStr00=""
	local tmpStr01=""
	local tmpStr02=""
	local tmpStr03=""
	local tmpStr04=""
	local tmpStr05=""
	local tmpStr06=""
	local tmpStr07=""
	local tmpStr08=""
	local diffperc=""
	local timeleft=0
	local timeleft0=0
	local prockilled=0
	local procsuccess=0
	local prevdiffperc=2
	local simpcompname=""
	local frstln=""
	local midln=""
	local transferFilePath=""
	local readonly firstmsg="Unknown time remaining ..."
	local readonly lastmsg="less than a min. remaining ..."

	local devicePath="$1"
	local compressedmode="$2"
	local litemode="$3"
	local compressionlevel="$4"
	local processorsnum="$5"
	shift 5
	local transfersourceslist=("${@}")


	if [ $compressedmode -eq 1 ]; then
		simpcompname="Compressed"
		function_backupdirname "$devicePath" "1" transferFilePath
	else
		simpcompname="Simple"
		function_backupdirname "$devicePath" "0" transferFilePath
	fi

	if [ $litemode -eq 1 ]; then
		logFileName="$MFC_DIR/data/dblitetransfer.log"
		if [ $compressedmode -ne 1 ]; then
			srcFileName="$MFC_DIR/data/paths_list.dat"
		fi
		errorFileName="$MFC_DIR/data/dblitetempfile"
		numoutputFileName="$MFC_DIR/data/dblitetransferprogress"
		textoutputFileName="$MFC_DIR/data/dblitetransfermessage"
		attmptoutputFileName="$MFC_DIR/data/dbliteattempt"
		procsoutputFileName="$MFC_DIR/data/dbliteproccorenum"
		echo "#Backup in Progress.\n $firstmsg##" > "$MFC_DIR/data/dblitemsg"
		tmpStr00=`echo -n "#Backup in Progress.\n $firstmsg##" | md5sum | cut -d" " -f1`
		echo "$tmpStr00" > "$MFC_DIR/data/dblitemsgmd5"
		tmpStr01="\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬"
		tmpStr01+="\n▮   Refer to the File 'TRANSFER LOG' for transfer    ▮"
		tmpStr01+="\n▮   messages and errors.                             ▮"
		tmpStr01+="\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n\n\n"
		echo -e "$tmpStr01" >> $DB_LITE_LOG
		echo -n "$simpcompname Transfer has been now begun . . ." >> $DB_LITE_LOG
	else
		logFileName="$MFC_DIR/data/db.log"
		if [ $compressedmode -ne 1 ]; then
			srcFileName="$MFC_DIR/data/dbpathslist"
			echo -n "" > $srcFileName
			for tmpStr01 in ${transferpathslist[@]}
			do
				echo "$tmpStr01" >> $srcFileName
			done
		fi
		errorFileName="$MFC_DIR/data/dbtempfile"
		numoutputFileName="$MFC_DIR/data/dbtransferprogress"
		textoutputFileName="$MFC_DIR/data/dbtransfermessage"
		attmptoutputFileName="$MFC_DIR/data/dbattempt"
		procsoutputFileName="$MFC_DIR/data/dbproccorenum"
	fi

	sleep 1.5

	echo -n "" > "$MFC_DIR/data/db.tmp"
	echo -e "\n\n" > $logFileName
	echo -e "\n\n" > $errorFileName
	echo -n "" > $numoutputFileName
	echo -n "" > $textoutputFileName
	echo -n "" > $attmptoutputFileName
	echo -n "" > $procsoutputFileName

	frstln="#$simpcompname Backup in Progress.\n"

	trap "exit" INT TERM ERR
	trap "kill 0" EXIT


	while [ $procsuccess -eq 0 ]
	do
		exec 1> "$MFC_DIR/data/db.tmp" 2>&1

		if [ $(($processorsnum-1)) -ne 1 ]; then
			prockilled=0
			echo -e "\n\n" > $logFileName
			echo -e "\n\n" > $errorFileName
			let "count = count + 1"
			echo "$count" > $attmptoutputFileName
			echo "$processorsnum" > $procsoutputFileName
		else
			break
		fi

		percout1=0
		percout2=0
		echo "0" > $numoutputFileName
		if [ $compressedmode -eq 1 ]; then
			eval "{ stdbuf -oL nohup zpaq715/zpaq a $transferFilePath \
			${transfersourceslist[@]} -m$compressionlevel -t$processorsnum -f; } |& tee -a $logFileName>>$errorFileName;" &
		else
			{ { rsync -airv --delete-before --info=all2 --human-readable --no-relative --log-file="$logFileName" \
			--files-from="$srcFileName" / $transferFilePath; } |& tee -a $errorFileName; } &
		fi

		while [ $prockilled -eq 0 ]
		do
			for ((i = 3; i <= 10; i++))
			do
				tmpStr01=`tail -n "$i" "$errorFileName"`
				tmpStr02=$(echo "$tmpStr01" | grep -oE '§' | tr -d '\n' | tr -d '\t' | tr -d '\r'| tr -d ' ')
				if [ "${#tmpStr02}" -lt 3 ]; then
					echo "§" >> "$errorFileName"
					continue
				elif [ ${#tmpStr02} -ge 3 ] && [[ "$tmpStr01" == *"§"* ]]; then
					if [[ "$tmpStr01" == "§" ]]; then
						continue
					elif [[ "$tmpStr01" == *"%"* ]] && [[ "$tmpStr01" == *":"* ]]; then
						percout2=$(echo "$tmpStr01" | grep -oE \
	'[0-9][0-9]\.[0-9][0-9]\%|[0-9][0-9]\.[0-9]\%|[0-9]\.[0-9][0-9]\%|[0-9]\.[0-9]\%|[0-9][0-9]\%|[0-9]\%|100.00\%|100.0\%|100\%')
						percout2=${percout2%"."*}
						percout2=$(echo $percout2 | tr -d '\n')
						percout2=${percout2##*"% "}
						percout2=${percout2%"%"*}
						if [ ${#percout2} -ne 0 ] && [[ "$percout2" != "$percout1" ]]; then
							percout1="$percout2"
							echo "$percout2" > "$numoutputFileName"
						fi
						break
					elif [[ "${tmpStr01^^}" == *"(ALL OK)"* && "$compressedmode" == "1" ]] || \
					[[ "$tmpStr03" != "" && "$compressedmode" != "1" ]]; then
						echo "100" > "$numoutputFileName"
						echo "Completed" > "$textoutputFileName"
						procsuccess=1
						prockilled=1
						break
					else
						if [ "$compressedmode" -eq 1 ]; then
							tmpStr03=$(cat "$errorFileName")
						else
							tmpStr03=$(echo "$tmpStr01" | grep -oE 'rsync error|write error|read error')
						fi
						if [ ${#tmpStr03} -ne 0 ]; then
							if [[ "${tmpStr03^^}" == *"KILLED"* ]] || [[ "${tmpStr03^^}" == *"BAD_ALLOC"* ]] || \
							[[ "${tmpStr01^^}" == *"BAD_ALLOC"* ]] || [ "$compressedmode" -ne 1 ]; then
								echo "Killed" > "$textoutputFileName"
								prockilled=1
								if [ "$compressedmode" -ne 1 ]; then
									procsuccess=1
								fi
								sleep 20
								break
							fi
						fi
					fi
				fi
			done
			sleep 0.05
		done
	done &


	if [ $litemode -eq 1 ]; then
		exec 1> "$errorFileName" 2>&1

		while :
		do
			tmpVar1=`cat $numoutputFileName`
			tmpStr05=`cat $attmptoutputFileName`
			tmpStr06=`cat $procsoutputFileName`
			tmpStr07=`cat $textoutputFileName`
			midln="ATTEMPT=$tmpStr05; PROCESSORS=$tmpStr06;"
			if [[ "${tmpStr07^^}" == "COMPLETED" ]] || [[ "${tmpStr07^^}" == "KILLED" ]]; then
				break
			elif [ ${#tmpVar1} -eq 0 ] || [ "$tmpVar1" -eq 0 ]; then
				tmpStr08="$frstln"
				if [ "$compressedmode" -eq 1 ]; then
					tmpStr08+=" $midln [0%];\n"
				fi
				tmpStr08+=" $firstmsg##"
			elif [ "$tmpVar1" -eq 100 ]; then
				tmpStr08=""
				if [ "$compressedmode" -eq 1 ]; then
					tmpStr08+="#$midln [100%];\n"
				fi
				tmpStr08+=" $simpcompname Backup almost done ...##"
			else
				if [ "$tmpVar2" -eq 0 ]; then
					tmpVar2="$tmpStr05"
				fi
				if [ "$tmpVar2" -eq "$tmpStr05" ]; then
					perc1="$perc2"
				else
					perc1=0
					reftime=0
					timeArr=()
					percArr=()
					prevdiffperc=2
				fi
				time0=`date +%s%3N`
				perc2="$tmpVar1"
				diffperc=$(($perc2-$perc1))
				if [ "$reftime" -eq 0 ]; then reftime=$time0; fi
				if [ "$diffperc" -eq 0 ]; then
					if [ "$prevdiffperc" -ne 0 ]; then
						if [ "$perc2" -eq 0 ]; then
							timeArr=("0")
							percArr=("0")
						fi
					fi
					tmpStr08=`echo "scale = 15; ($timeleft0+$time0-${timeArr[-1]}-$reftime)/1000" | bc`
					function_addzero tmpStr08
					tmpStr08=${tmpStr08%.*}
					if [ "$tmpStr08" -ge "$timeleft" ]; then
						timeleft=`echo "scale = 15; $tmpStr08*2" | bc`
					fi
					prevdiffperc=0
				else
					timeArr+=($(($time0-$reftime)))
					percArr+=("$perc2")
					prevdiffperc=1
				fi

				if [ "$prevdiffperc" -eq 1 ]; then
					sumx=0
					sumy=0
					sumx2=0
					sumxy=0
					for ((i = 0; i < ${#timeArr[@]}; i++))
					do
						sumx=`echo "scale = 15; $sumx+${percArr[$i]}" | bc`
						sumy=`echo "scale = 15; $sumy+${timeArr[$i]}" | bc`
						sumx2=`echo "scale = 15; $sumx2+(${percArr[$i]}^2)" | bc`
						sumxy=`echo "scale = 15; $sumxy+(${percArr[$i]}*${timeArr[$i]})" | bc`
					done
					mval=`echo "scale = 15; ((${#timeArr[@]}*$sumxy)-($sumx*$sumy))" | bc`
					function_addzero mval
					mval=`echo "scale = 15; $mval/((${#timeArr[@]}*$sumx2)-($sumx*$sumx))" | bc`
					function_addzero mval
					bval=`echo "scale = 15; ($sumy-($mval*$sumx))/${#timeArr[@]}" | bc`
					function_addzero bval
					xval=`echo "scale = 15; ($mval*100)+$bval" | bc`
					function_addzero xval
					timeleft=`echo "scale = 15; ($reftime+$xval-$time0)/1000" | bc`
					function_addzero timeleft
					timeleft0=`echo "scale = 15; $reftime+$xval-$time0" | bc`
					function_addzero timeleft0
				fi
				timeleft=${timeleft%.*}
				if [ "$timeleft" -le 60 ]; then
					tmpStr08="$frstln"
					if [ "$compressedmode" -eq 1 ]; then
						tmpStr08+=" $midln [$perc2%]\n"
					else
						tmpStr08+=" ... [$perc2%]\n"
					fi
					tmpStr08+=" $lastmsg##"
				elif [ "$timeleft" -lt 3600 ]; then
					tmpVar3=$(($timeleft/60))
					tmpStr08="$frstln"
					if [ "$compressedmode" -eq 1 ]; then
						tmpStr08+=" $midln [$perc2%]\n"
					else
						tmpStr08+=" ... [$perc2%]\n"
					fi
					tmpStr08+=" $tmpVar3 mins. remaining ...##"
				else
					tmpVar3=$(($timeleft/3600))
					tmpStr08="$frstln"
					if [ "$compressedmode" -eq 1 ]; then
						tmpStr08+=" $midln [$perc2%]\n"
					else
						tmpStr08+=" ... [$perc2%]\n"
					fi
					if [ "$tmpVar3" -lt 5 ]; then
						tmpStr08+=" $tmpVar3 hours remaining ...##"
					else
						tmpStr08+=" $firstmsg##"
					fi
				fi

			fi
			echo "$tmpStr08" > "$MFC_DIR/data/dblitemsg"
			tmpStr08=`echo -n "$tmpStr08" | md5sum | cut -d" " -f1`
			echo "$tmpStr08" > "$MFC_DIR/data/dblitemsgmd5"
			sleep 0.1
		done
	else
		exec 1> $(tty) 2>&1

		{
			while :
			do
				tmpVar1=`cat $numoutputFileName`
				tmpStr07=`cat $textoutputFileName`
				i=$tmpVar1
				if [[ "${tmpStr07^^}" == "COMPLETED" ]] || [[ "${tmpStr07^^}" == "KILLED" ]]; then
					sleep 1.5
					break
				elif [[ "$tmpVar1" == *"100"* ]]; then
					tmpStr04="\n Please wait. $simpcompname Backup almost Completed ..."
					if [ $compressedmode -eq 1 ]; then
						tmpStr04+="\n [ Attempt #$tmpStr05 with $tmpStr06 processors ]"
					fi
				else
					tmpStr05=`cat $attmptoutputFileName`
					tmpStr06=`cat $procsoutputFileName`
					tmpStr04="\n Please wait. $simpcompname Backup in Progress !"
					tmpStr04+="\n This may take a while . . .  "
					if [ $compressedmode -eq 1 ]; then
						tmpStr04+="[ Attempt #$tmpStr05 with $tmpStr06 processors ]"
					fi
				fi
				echo XXX
				echo $i
				echo "$tmpStr04"
				echo XXX
				sleep 0.05
			done
		} | whiptail --gauge "\n Please wait. $simpcompname Backup in Progress !\n This may take a while . . ." 10 80 0
	fi

	echo -e "\n\n\n" >> $logFileName
	echo -e "\n\n\n" >> $errorFileName
}


# Parameter 1 - Destination
# Parameter 2 - Lite Mode
# Parameter 3 - Total Backup Size
# Parameter N - Sources Array
function_simple_transfer()
{
	local tmpStr01=""
	local endstatus=""

	local destpath="$1"
	local litemode="$2"
	local totbkupsize="$3"
	shift 3
	local transferpathslist=("${@}")

	function_checkexterndevice "$destpath" "$litemode"

	exec 1> "$MFC_DIR/data/db.tmp" 2>&1

	function_transfer_processing "$destpath" "0" "$litemode" "" ""

	if [ $litemode -eq 1 ]; then
		endstatus=`cat "$MFC_DIR/data/dblitetransfermessage"`
	else
		endstatus=`cat "$MFC_DIR/data/dbtransfermessage"`
	fi

	if [[ "$endstatus" == "Completed" ]]; then
		echo -e " Completed!\n" >> $DB_LITE_LOG
	else
		echo -e " NOT Completed!\n" >> $DB_LITE_LOG
	fi
}


# Parameter 1 - Destination
# Parameter 2 - Lite Mode
# Parameter N - Sources Array
function_compressed_transfer()
{
	local tmpStr00=""
	local tmpStr01=""
	local endstatus=""
	local compresslevel=""

	local destpath="$1"
	local litemode="$2"
	shift 2
	local transferpathslist=("${@}")

	function_checkexterndevice "$destpath" "$litemode"

	exec 1> "$MFC_DIR/data/db.tmp" 2>&1

	compresslevel=`cat "$MFC_DIR/data/dbcompresslevel"`
	tmpStr01="$compresslevel"
	function_extract_num "$tmpStr01" compresslevel
	if [ ${#compresslevel} -eq 0 -o $compresslevel -gt 5 ]; then
		compresslevel=5
	elif [ $compresslevel -lt 1 ]; then
		compresslevel=1
	fi

	tmpStr00=`head -1 "$MFC_DIR/data/dbthreadsopt"`
	function_extract_num "$tmpStr00" proccorenum
	if [ ${#proccorenum} -eq 0 -o $proccorenum -lt 1 -o $proccorenum -gt `nproc` ]; then
		proccorenum=`nproc`
		proccorenum=$(($proccorenum/2))
	fi

	function_transfer_processing "$destpath" "1" "$litemode" "$compresslevel" "$proccorenum" \
		"${transferpathslist[@]}"

	if [ $litemode -eq 1 ]; then
		endstatus=`cat "$MFC_DIR/data/dblitetransfermessage"`
	else
		endstatus=`cat "$MFC_DIR/data/dbtransfermessage"`
	fi

	if [[ "$endstatus" == "Completed" ]]; then
		echo -e " Completed!\n" >> $DB_LITE_LOG
	else
		echo -e " NOT Completed!\n" >> $DB_LITE_LOG
	fi
}


# Parameter 1 - Destination
# Parameter 2 - Lite Mode
# Parameter 3 - Compressed Mode
# Parameter N - Sources Array
function_begin_transfer()
{
	local availMemElem=""
	local backup_opt=""
	local exitstatus=""
	local reqMemElem=""
	local tmpElem=""
	local tmpStr0=""
	local tmpStr02=""	
	local reqMem=0
	local tmpVar1=0
	local tmpVar2=0
	local memCalc=0
	local availMem=0

	local destpath="$1"
	local litemode="$2"
	local compressedmode="$3"
	shift 3
	local sourceslist=("${@}")

	if [ $litemode -eq 1 ]; then
		echo -n "Calculating the total size of the source elements . . ." >> $DB_LITE_LOG
	else
		function_msg " Calculating the total size of the source elements . . ."
	fi
	for tmpElem in "${sourceslist[@]}"
	do
		reqMemElem=`du --si -s -b $tmpElem`
		tmpStr0="$reqMemElem"
		mfc_remove "$tmpStr0" "?$tmpElem" reqMemElem
		function_extract_num "$reqMemElem" tmpVar1
		let "reqMem += tmpVar1"
	done
	sleep 0.7
	if [ $litemode -eq 1 ]; then
		tmpStr0=" Done!\n Total Size of Backup Directories/Folders :    $reqMem Bytes"
		tmpStr02=`printf ' %.0s' {1..45}`
		tmpVar2=`echo "scale = 3; $reqMem/1000" | bc`
		function_addzero tmpVar2
		tmpStr0+="\n$tmpStr02~ $tmpVar2 Kilobytes"
		tmpVar2=`echo "scale = 3; $reqMem/1000000" | bc`
		function_addzero tmpVar2
		tmpStr0+="\n$tmpStr02~ $tmpVar2 Megabytes"
		tmpVar2=`echo "scale = 3; $reqMem/1000000000" | bc`
		function_addzero tmpVar2
		tmpStr0+="\n$tmpStr02~ $tmpVar2 Gigabytes\n\n"
		echo -e "$tmpStr0" >> $DB_LITE_LOG
	else
		echo -e "\n\n Done !"
	fi
	sleep 0.7

	if [ $litemode -eq 1 ]; then
		echo -n "Checking if space is available for storing backup in external device . . ." >> $DB_LITE_LOG
	else
		function_msg " Checking if space is available for storing backup in external device . . ."
	fi
	availMemElem=`df --output='avail' $destpath`
	function_extract_num "$availMemElem" availMem	# Value in 1K size blocks
	let "availMem = availMem * 1000"		# Value in Bytes
	sleep 0.7
	if [ $litemode -eq 1 ]; then
		tmpStr0=" Done!\n Available Space in External Device :    $availMem Bytes"
		tmpStr02=`printf ' %.0s' {1..39}`
		tmpVar2=`echo "scale = 3; $availMem/1000" | bc`
		function_addzero tmpVar2
		tmpStr0+="\n$tmpStr02~ $tmpVar2 Kilobytes"
		tmpVar2=`echo "scale = 3; $availMem/1000000" | bc`
		function_addzero tmpVar2
		tmpStr0+="\n$tmpStr02~ $tmpVar2 Megabytes"
		tmpVar2=`echo "scale = 3; $availMem/1000000000" | bc`
		function_addzero tmpVar2
		tmpStr0+="\n$tmpStr02~ $tmpVar2 Gigabytes\n\n"
		echo -e "$tmpStr0" >> $DB_LITE_LOG
	else
		echo -e "\n\n Done !"
	fi
	sleep 0.7

	let "memCalc = availMem - reqMem"

	if [ $litemode -ne 1 ]; then
		function_msg
	fi

	if [ $memCalc -gt $MINIMUM_FREE_DISKSPACE_ALLOCATION ]; then
		if [ $litemode -ne 1 ]; then
			whiptail --title "INFO :  EXTERNAL DEVICE DISK SPACE" --msgbox \
			"\n  Good News !\n\n  Sufficient memory is available for the backup transfer." 12 65
		else
			echo -e "Good News! Sufficient memory is available for the backup transfer.\n\n\n\n" >> $DB_LITE_LOG
		fi
	else
		if [ $litemode -ne 1 ]; then
			whiptail --title "ERROR :  EXTERNAL DEVICE DISK SPACE" --msgbox \
			"\n  Bad News !\n\n  Memory is NOT sufficient for the backup transfer." 12 60
			function_end "0"
		else
			echo -e "Bad News! Memory is NOT sufficient for the backup transfer.\n\n\n\n" >> $DB_LITE_LOG
			function_end "1"
		fi
	fi

	if [ $litemode -ne 1 ]; then
		while :
		do
			backup_opt=$(whiptail --title "QUERY :  FILE TRANSFER" --radiolist \
			"\n\n  How do you wish to transfer the backup data ?\n\n" 15 80 3 \
			"[1]" "  Simple Transfer" ON \
			"[2]" "  Compressed Transfer  " OFF 3>&2 2>&1 1>&3)
			exitstatus=$?
			if [ $exitstatus -eq 0 ]; then
				backup_opt="${backup_opt:1:1}"
				if [ $backup_opt == "1" ]; then
					function_simple_transfer "$destpath" "0" "$reqMem" "${sourceslist[@]}"
				else
					function_compressed_transfer "$destpath" "0" "${sourceslist[@]}"
				fi
				break
			else
				function_opt "1"
			fi
		done
	else
		if [ $compressedmode -eq 1 ]; then
			echo -e "Initializing Compressed Transfer Mode . . .\n\n\n" >> $DB_LITE_LOG
			function_compressed_transfer "$destpath" "1" "${sourceslist[@]}"
		else
			echo -e "Initializing Simple Transfer Mode . . .\n\n\n" >> $DB_LITE_LOG
			function_simple_transfer "$destpath" "1" "$reqMem" "${sourceslist[@]}"
		fi
	fi
}



