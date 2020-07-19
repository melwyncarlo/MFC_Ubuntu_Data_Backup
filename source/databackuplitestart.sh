#!/bin/bash



readonly MFC_SPINNER="/-\|"


i=1
readline=""
procstat="0"
dblitemd51="0"
dblitemd52="0"
dblitemessage1=""
dblitemessage2=" Preparing for Backup ...  "


echo "0" > "data/dbliteprocessdone"
echo "0" > "data/dblitemsgmd5"
echo "$dblitemessage1" > "data/dblitemsg"



# TO BE DISPLAYED  -  START

echo -ne "\033]0;MFC Ubuntu Backup\007"


resize -s 6 35

clear
clear
echo
echo -n " Please wait ...  "


source databackuplite.sh &
while [[ "$procstat" == "0" ]]
do
	if [[ "$dblitemd52" != "$dblitemd51" ]] && [[ "$dblitemessage2" != "" ]]; then
		dblitemd51="$dblitemd52"
		dblitemessage1="$dblitemessage2"
		clear
		clear
		echo
		echo " Please wait."
		echo -ne "$dblitemessage2"
	fi
	printf "\b${MFC_SPINNER:i++%${#MFC_SPINNER}:1}"
	sleep 0.1
	procstat=`cat "data/dbliteprocessdone"`
	dblitemd52=`cat "data/dblitemsgmd5"`
	dblitemessage2=`cat "data/dblitemsg"`
	if [ ${#dblitemessage2} -gt 0 ]; then
		dblitemessage2=$(echo -e $dblitemessage2 | tr '#' ' ')
	fi
done
clear
clear
echo
if [[ "$procstat" == "1" ]]; then
	echo -e " Backup Completed !\n"
else
	echo -e " Backup Failed !\n"
fi

# TO BE DISPLAYED  -  END



sleep 1.5
exit 0



