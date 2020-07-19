#!/bin/bash



exec 2> "data/db.tmp"


source src/dbfunctions.sh


pathsArray=()
argsArray=()
tmpArray1=()
tmpArray2=()


readonly DEFAULT_DATFILEPATH="data/paths_list.dat"
readonly MFC_DBLITE_ARGUMENTS_FILE="data/dbliteargs"
readonly DB_LITE_LOG="data/dblite.log"
readonly MFC_DBLITE_ARGUMENTS_NUM="4"


echo -n "" > $DB_LITE_LOG
echo "#Preparing for Backup#...##" > "data/dblitemsg"


if [ ! -f "$DEFAULT_DATFILEPATH" ]; then
	echo -n "" > "$DEFAULT_DATFILEPATH"
fi



# Parameter 1 - Return Message String	[ REFERENCE ]
function_checkdirroot()
{
	local line=""
	local elem1=""
	local tmpStr01=""
	local tmpStr02=""
	local problemfound=0

	local -n returnStr="$1"
	returnStr=""

	for elem1 in ${!pathsArray[@]}
	do
		echo "0" > "data/dblitetempfile"
		tmpStr01=`du -bsh "${pathsArray[$elem1]}" 2> "data/dblitetempfile"`
		tmpStr02=""
		while read -rs line
		do
			tmpStr02+="$line"
		done < "data/dblitetempfile"
		if [[ "$tmpStr02" != "0" ]] && [[ "$tmpStr02" != "" ]]; then
			problemfound=1
			if [[ "${argsArray[2]}" == "0" ]]; then
				errorFound=1
				returnStr+="\n ERROR :: Flag = ±0 : PATH $(($elem1+1))\n"
				returnStr+="<==================================>\n"
				returnStr+="The entered directory/folder path contains certain files and folders\n"
				returnStr+="that are restricted to 'Root Access' only. Cannot Proceed Further!\n"
				returnStr+="Path Name :  ${pathsArray[$elem1]}\n\n\n"
			else
				unset pathsArray[$elem1]
				returnStr+="\n INFO :: Flag = -1 : PATH $(($elem1+1))\n"
				returnStr+="<==================================>\n"
				returnStr+="The entered directory/folder path contains certain files and folders\n"
				returnStr+="that are restricted to 'Root Access' only. This Path has been Discarded!\n"
				returnStr+="Proceeding further ...\n"
				returnStr+="Path Name :  ${pathsArray[$elem1]}\n\n\n"
			fi
		fi
	done

	if [ $problemfound -ne 1 ]; then
		returnStr="Everything seems dandy, again!\n\n\n"
	fi

}


# Parameter 1 - Similar Directory Action Mode
# Parameter 2 - Return Message String	[ REFERENCE ]
function_checksimilardir()
{
	local elem1=""
	local elem2=""
	local tmpStr0=""
	local problemfound=0

	local simdiractmode="$1"
	local -n returnStr="$2"
	returnStr=""

	tmpArray1=()
	tmpArray2=()

	for elem1 in ${!pathsArray[@]}
	do
		for elem2 in ${!pathsArray[@]}
		do
			if [ $elem1 -ne $elem2 ]; then
				if [[ "${pathsArray[$elem1]}" == *"${pathsArray[$elem2]}"* ]] || \
				[[ "${pathsArray[$elem2]}" == *"${pathsArray[$elem1]}"* ]]; then
					problemfound=1
					tmpArray1+=("${pathsArray[$elem1]}")
					tmpArray2+=("${pathsArray[$elem2]}")
					if [ $simdiractmode -eq 0 ]; then
						returnStr+="\n ERROR :: Flag = ±0 : PATHS N\n"
					elif [ $simdiractmode -eq -1 ]; then
						returnStr+="\n INFO :: Flag = -1 : PATHS N\n"
					else
						returnStr+="\n INFO :: Flag = -2 : PATHS N\n"
					fi
					returnStr+="<==================================>\n"
					returnStr+="Path $(($elem1+1)) and Path $(($elem2+1)) are similar.\n"
					if [ $simdiractmode -eq 0 ]; then
						returnStr+="Please keep either one and\n"
						returnStr+="discard the other. Cannot Proceed Further!\n"
					else
						if [ $simdiractmode -eq -1 ]; then
							tmpStr0="Child"
						else
							tmpStr0="Parent"
						fi
						returnStr+="The $tmpStr0 directory/folder will be discarded.\n"
						returnStr+="Proceeding further ...\n"
					fi
					returnStr+="Path-$(($elem1+1)) Name :  ${pathsArray[$elem1]}\n"
					returnStr+="Path-$(($elem2+1)) Name :  ${pathsArray[$elem2]}\n\n\n"
				fi
			fi
		done
	done

	if [ $problemfound -ne 1 ]; then
		returnStr="Everything seems dandy!\n\n\n"
	fi
	
}


# Parameter 1 - Return Message String	[ REFERENCE ]
function_clearsimilardir()
{
	local removeArr=()
	local tmpStr01=""
	local tmpStr02=""
	local tmpStr03=""
	local elem0=""
	local elem1=""
	local i=0

	local -n returnStr="$2"
	returnStr=""

	for i in ${!tmpArray1[@]}
	do
		tmpStr01="${argsArray[3]}"
		if [ ${#tmpArray1[$i]} -ge ${#tmpArray2[$i]} ]; then
			tmpStr02="${tmpArray1[$i]}"
			tmpStr03="${tmpArray2[$i]}"
		else
			tmpStr02="${tmpArray2[$i]}"
			tmpStr03="${tmpArray1[$i]}"
		fi
		if [[ "${tmpStr0:1:1}" == "1" ]]; then
			removeArr+=("$tmpStr03")
		else
			removeArr+=("$tmpStr02")
		fi
	done

	i=0
	returnStr+=" INFO :: PATHS N\n"
	returnStr+="<=====================>\n"

	for elem0 in ${removeArr[@]}
	do
		for elem1 in ${!pathsArray[@]}
		do
			if [[ "${pathsArray[$elem1]}" == "$elem0" ]]; then
				let "i = i + 1"
				returnStr+="$i. Path Name '${pathsArray[$elem1]}' has been discarded!\n"
				unset pathsArray[$elem1]
				break
			fi
		done
	done

	returnStr+="\n\n"
}


# Parameter 1 - Data String	[ REFERENCE ]
function_singularstring()
{
	local -n dataStr="$1"

	dataStr=$(echo -e $dataStr | tr -d '\t')
	dataStr=$(echo -e $dataStr | tr -d '\n')
	dataStr=$(echo -e $dataStr | tr -d ' ')
}




exitstatusglobal=""
destdirpath=""
transferopt=""

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
tmpArray1=()
tmpArray2=()

lineglobal=""
pathselem=""
errorFound=0
argsArray=()
pathsArray=()



# TO BE DISPLAYED  -  START

#echo -ne "\033]0;MFC Ubuntu Backup\007"


#resize -s 5 30


#clear
#clear
#echo
#echo " Please wait."
#echo -n " Backup in Progress ...  "
#while :
#do
#	printf "\b${MFC_SPINNER:i++%${#MFC_SPINNER}:1}"
#	sleep 0.1
#done

# TO BE DISPLAYED  -  END



tmpStr2+="\n\n--------------------------------------------------------------\n"
tmpStr2+=" DATA  BACKUP\n"
tmpStr2+=" A simple script by Melwyn  F. Carlo\n"
tmpStr2+=" `date`\n"
tmpStr2+="--------------------------------------------------------------\n\n\n"
echo -e "$tmpStr2" >> $DB_LITE_LOG



# Reading the Arguments File
echo -ne "Reading the Arguments File . . ." >> $DB_LITE_LOG
while read -rs lineglobal
do
	tmpStr1="$lineglobal"
	function_singularstring lineglobal
	if [[ "$lineglobal" != "" ]]; then
		argsArray+=("$tmpStr1")
	fi
done < $MFC_DBLITE_ARGUMENTS_FILE
echo -e " Done !\n" >> $DB_LITE_LOG



# Verifying the Input Arguments
echo -ne "Verifying the Input Arguments . . ." >> $DB_LITE_LOG
errorFound=0
tmpStr2="\n"
if [ ${#argsArray[@]} -eq $MFC_DBLITE_ARGUMENTS_NUM ]; then
	if [ -e "/media/`whoami`/${argsArray[0]}" ]; then
		if [ ! -d "/media/`whoami`/${argsArray[0]}" ]; then
			errorFound=1
			tmpStr2+=" ERROR :: ARGUMENT 1\n"
			tmpStr2+="<=====================>\n"
			tmpStr2+="The device name entered, '${argsArray[0]}', is NOT a VALID device that is suitable for backup.\n\n\n"
		fi
	else
		errorFound=1
		tmpStr2+=" ERROR :: ARGUMENT 1\n"
		tmpStr2+="<=====================>\n"
		tmpStr2+="The device name '${argsArray[0]}' does not exist in the '/media/`whoami`' directory/folder.\n\n\n"
	fi
	tmpStr3="${argsArray[1]}"
	function_singularstring tmpStr3
	if [[ "$tmpStr3" != "0" ]] && [[ "$tmpStr3" != "1" ]] && [[ "$tmpStr3" != "2" ]] && \
	[[ "${tmpStr3^^}" != "SIMPLE" ]] && [[ "${tmpStr3^^}" != "COMPRESS" ]] && [[ "${tmpStr3^^}" != "COMPRESSED" ]]; then
		errorFound=1
		tmpStr2+=" ERROR :: ARGUMENT 2\n"
		tmpStr2+="<=====================>\n"
		tmpStr2+="The transfer method options for backup should be : \n"
		tmpStr2+="Simple [0/1] / Compressed [2]\n\n\n"
	fi
	tmpStr3="${argsArray[2]}"
	function_singularstring tmpStr3
	if [[ "${argsArray[2]}" != "0" ]] && [[ "${argsArray[2]}" != "1" ]] && [[ "${argsArray[2]}" != "-1" ]] && \
	[[ "${tmpStr3^^}" != "TRUE" ]] && [[ "${tmpStr3^^}" != "FALSE" ]] && [[ "${tmpStr3^^}" != "DISCARD" ]]; then
		errorFound=1
		tmpStr2+=" ERROR :: ARGUMENT 3\n"
		tmpStr2+="<=====================>\n"
		tmpStr2+="The root access flag mode options should be : \n"
		tmpStr2+="True [1] / False [0] / Discard [-1]\n\n\n"
	fi
	tmpStr3="${argsArray[3]}"
	function_singularstring tmpStr3
	if [[ "${argsArray[3]}" != "0" ]] && [[ "${argsArray[3]}" != "1" ]] && [[ "${argsArray[3]}" != "-1" ]] && \
	[[ "${tmpStr3^^}" != "TRUE" ]] && [[ "${tmpStr3^^}" != "FALSE" ]] && [[ "${tmpStr3^^}" != "DISCARDCHILD" ]] && \
	[[ "${tmpStr3^^}" != "DISCARDPARENT" ]]; then
		errorFound=1
		tmpStr2+=" ERROR :: ARGUMENT 4\n"
		tmpStr2+="<=====================>\n"
		tmpStr2+="The similar directories/folders flag mode options should be : \n"
		tmpStr2+="True [1] / False [0] / Discard Child [-1] / Discard Parent [-2]\n\n\n"
	fi
else
	errorFound=1
	tmpStr2+=" ERROR :: ARGUMENTS N\n"
	tmpStr2+="<=====================>\n"
	tmpStr2+="There are ${#argsArray[@]} lines of arguments.\n"
	tmpStr2+="There must be EXACTLY $MFC_DBLITE_ARGUMENTS_NUM lines of arguments ONLY!\n"
	tmpStr2+="As Follows :  Argument 1 - Device name located in the '/media/`whoami`' directory/folder\n"
	tmpStr2+="              Argument 2 - Transfer method for backup ( Simple [0/1] / Compressed [2] )\n"
	tmpStr2+="              Argument 3 - Flag mode to proceed even if some contents require 'Root Access'\n"
	tmpStr2+="                           ( True [1] / False [0] / Discard [-1] )\n\n\n"
	tmpStr2+="              Argument 4 - Flag mode to proceed even if there are similar directories/folders\n"
	tmpStr2+="                           ( True [1] / False [0] / Discard Child [-1] / Discard Parent [-2] )\n\n\n"
fi
echo -e " Done !\n" >> $DB_LITE_LOG


if [ $errorFound -eq 1 ]; then
	echo -e "$tmpStr2" >> $DB_LITE_LOG
	function_end "1"
fi



# Checking external device connection
function_checkexterndevice "/media/`whoami`/${argsArray[0]}" "1"



# Simplifying the Arguments Array
echo -ne "Simplifying the Arguments Array . . ." >> $DB_LITE_LOG
tmpStr3="${argsArray[1]}"
function_singularstring tmpStr3
if [[ "$tmpStr3" == "0" ]] || [[ "$tmpStr3" == "1" ]] || [[ "${tmpStr3^^}" == "SIMPLE" ]]; then
	argsArray[1]="0"
else
	argsArray[1]="1"
fi
tmpStr3="${argsArray[2]}"
function_singularstring tmpStr3
if [[ "${argsArray[2]}" == "1" ]] || [[ "${tmpStr3^^}" == "TRUE" ]]; then
	argsArray[2]="1"
elif [[ "${argsArray[2]}" == "0" ]] || [[ "${tmpStr3^^}" == "FALSE" ]]; then
	argsArray[2]="0"
else
	argsArray[2]="-1"
fi
tmpStr3="${argsArray[3]}"
function_singularstring tmpStr3
if [[ "${argsArray[3]}" == "1" ]] || [[ "${tmpStr3^^}" == "TRUE" ]]; then
	argsArray[3]="1"
elif [[ "${argsArray[3]}" == "0" ]] || [[ "${tmpStr3^^}" == "FALSE" ]]; then
	argsArray[3]="0"
elif [[ "${argsArray[3]}" == "-1" ]] || [[ "${tmpStr3^^}" == "DISCARDCHILD" ]]; then
	argsArray[3]="-1"
else
	argsArray[3]="-2"
fi
echo -e " Done !\n" >> $DB_LITE_LOG



# Reading the contents of the Default Paths List
echo -ne "Reading the contents of the Default Paths List . . ." >> $DB_LITE_LOG
while read -rs lineglobal
do
	tmpStr1="$lineglobal"
	function_singularstring lineglobal
	if [[ "$lineglobal" != "" ]]; then
		pathsArray+=("$tmpStr1")
	fi
done < $DEFAULT_DATFILEPATH
echo -e " Done !\n" >> $DB_LITE_LOG



# Verifying the contents of the Default Paths List
echo -ne "Verifying the contents of the Default Paths List . . ." >> $DB_LITE_LOG
errorFound=0
tmpStr2="\n"
if [ ${#pathsArray[@]} -gt 0 ]; then
	for pathselem in ${!pathsArray[@]}
	do
		if [ -e "${pathsArray[$pathselem]}" ]; then
			if [ ! -d "${pathsArray[$pathselem]}" ]; then
				errorFound=1
				tmpStr2+=" ERROR :: PATH $(($pathselem+1))\n"
				tmpStr2+="<=====================>\n"
				tmpStr2+="You can NOT select a regular file.\nEnter paths of directories/folders only!\n"
				tmpStr2+="Path Name :  ${pathsArray[$pathselem]}\n\n\n"
			fi
		else
			errorFound=1
			tmpStr2+=" ERROR :: PATH $(($pathselem+1))\n"
			tmpStr2+="<=====================>\n"
			tmpStr2+="The entered filepath does NOT exist !\n"
			tmpStr2+="Path Name :  ${pathsArray[$pathselem]}\n\n\n"
		fi
	done
else
	errorFound=1
	tmpStr2+=" ERROR :: PATHS N\n"
	tmpStr2+="<=====================>\n"
	tmpStr2+="The Default Paths List File is EMPTY !\n"
	tmpStr2+="There are NO directory/folder paths in the Default Paths List.\n\n\n"
fi
echo -e " Done !\n" >> $DB_LITE_LOG


if [ $errorFound -eq 1 ]; then
	echo -e "$tmpStr2" >> $DB_LITE_LOG
	function_end "1"
else
	echo -e "\n\n" >> $DB_LITE_LOG
fi



# Checking the Paths List directories/folders for similar directories/folders
echo -ne "Checking the Paths List directories/folders for similar directories/folders . . ." >> $DB_LITE_LOG
tmpStr2=""
if [[ "${argsArray[2]}" == "1" ]]; then
	tmpStr2+="\n INFO :: Flag = +1 : PATHS N\n"
	tmpStr2+="<===============================>\n"
	tmpStr2+="Similar directories/folders will continue to be backed up.\n\n\n"
else
	function_checksimilardir "${argsArray[2]}" tmpStr2
	if [ ${#tmpArray1[@]} -ne 0 ]; then
		function_clearsimilardir tmpStr2
	fi
fi
echo -e " Done !\n" >> $DB_LITE_LOG


echo -e "$tmpStr2" >> $DB_LITE_LOG
if [ $errorFound -eq 1 ]; then
	function_end "1"
fi



# Checking the Paths List directories/folders for Root Access
echo -ne "Checking the Paths List directories/folders for Root Access . . ." >> $DB_LITE_LOG
errorFound=0
tmpStr2=""
if [[ "${argsArray[2]}" == "1" ]]; then
	tmpStr2+="\n INFO :: Flag = +1 : PATHS N\n"
	tmpStr2+="<===============================>\n"
	tmpStr2+="Directories/Folders with Root Access can still be attempted to backup.\n\n\n"
else
	function_checkdirroot tmpStr2
fi
echo -e " Done !\n" >> $DB_LITE_LOG


echo -e "$tmpStr2" >> $DB_LITE_LOG
if [ $errorFound -eq 1 ]; then
	function_end "1"
fi



# Checking external device connection, again
function_checkexterndevice "/media/`whoami`/${argsArray[0]}" "1"


# Main Backup Transfer Operation
function_begin_transfer "/media/`whoami`/${argsArray[0]}" "1" "${argsArray[1]}" "${pathsArray[@]}"


exec 2> "data/db.tmp"



tmpStr2="\n\n--------------------------------------------------------------\n"
tmpStr2+=" All Backed Up!\n"
tmpStr2+=" This program will successfully terminate now.\n"
tmpStr2+=" `date`"
tmpStr2+="\n--------------------------------------------------------------\n\n\n"
echo -e "$tmpStr2" >> $DB_LITE_LOG
sleep 1.5
echo "1" > "data/dbliteprocessdone"



