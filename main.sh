#!/bin/bash

WD="$(dirname $0)"
PRG="$(basename $0)"

SCHEDULE="$HOME/.cache/batti.sch"

function Usage {
    echo -e "Usage: \tbatti -g [1-7] [OPTIONS]";
    echo -e "\t-g | --group\tGroup number 1-7"
    echo -e "\t-t | --today\tShow today's schedule [uses with group no]"
    echo -e "\t-w | --week\tShow week's schedule [default]"
    echo -e "\t-u | --update\tCheck for update [ignores extra options]"
    echo -e "\t-h | --help\tDisplay this message"
    exit
}

function download {
    wget -c http://nea.org.np/loadshedding.html -O /tmp/nea.html
    link=$(egrep -o "http.*pdf" /tmp/nea.html)
    wget -c $link -O /tmp/nea.pdf
}

function getall { #all schedule
    pdftotext /tmp/nea.pdf /tmp/raw.txt
    sed -n '/;d"x÷af/,/cTolws/p' /tmp/raw.txt > /tmp/part.txt
    $WD/2utf8/main.sh -f /tmp/part.txt > /tmp/uni.txt
    sed -i '/2utf8/d' /tmp/uni.txt
}

function maketable {
    sed '/समूह/d; /मंगलबार/q' /tmp/uni.txt > /tmp/sunmon.txt
    echo -e "\nआईतबार" > /tmp/table.txt
    awk -F ' ' '/[०-९] / { print $1 }' /tmp/sunmon.txt >> /tmp/table.txt
    echo -e "\nसोमबार" >> /tmp/table.txt
    awk -F ' ' '/[०-९] / { print $2 }' /tmp/sunmon.txt >> /tmp/table.txt
    echo >> /tmp/table.txt
    sed -n '/मंगलबार/,/बुधबार/p' /tmp/uni.txt >> /tmp/table.txt
    sed -n '/बुधबार/,/शनिबार/p' /tmp/uni.txt > /tmp/wedfri.txt
    awk -F ' ' '/[०-९] / { print $1 }' /tmp/wedfri.txt >> /tmp/table.txt
    echo -e "\nबिहीबार" >> /tmp/table.txt
    awk -F ' ' '/[०-९] / { print $2 }' /tmp/wedfri.txt >> /tmp/table.txt
    echo -e "\nशुक्रबार" >> /tmp/table.txt
    awk -F ' ' '/[०-९] / { print $3 }' /tmp/wedfri.txt >> /tmp/table.txt
    echo >> /tmp/table.txt
    sed -n '/शनिबार/,+14p' /tmp/uni.txt >> /tmp/table.txt

    flag=-1
    while read i; do
    	if [ "$i" == "" ]; then
    	    echo -e $row1 >> $SCHEDULE
    	    echo -e $row2 >> $SCHEDULE
    	    row1=""
	    row2=""
	    flag=-1
    	    continue
	fi

	if [ $flag == 0 ]; then
	    row1="$row1$i\t"
	    flag=1
	elif [ $flag == 1 ]; then
	    row2="$row2$i\t"
	    flag=0
	else
	    flag=0
	fi
    done < /tmp/table.txt
    echo -e $row1 >> $SCHEDULE
    echo -e $row2 >> $SCHEDULE
}

function replace {
    sed -i 's/०/0/g; s/१/1/g; s/२/2/g; s/३/3/g;
            s/४/4/g; s/५/5/g; s/६/6/g; s/७/7/g;
            s/८/8/g; s/९/9/g; /^$/d' $SCHEDULE
}

function extract {
    rm -f $SCHEDULE
    getall
    maketable
    replace
}

function week {
    day=(Sun Mon Tue Wed Thr Fri Sat)
    for((i=0;i<7;i++)) {
	r1=$(($i*2))
	r2=$(($r1+1))
	if [ $today == $i ]; then
	    color="\033[1;32m"
	    cdef="\033[0m"
	else
	    color=""
	    cdef=""
	fi

	echo -e ${color}${day[$i]}
	echo -e "\t${time[$r1]}"
	echo -e "\t${time[$r2]}$cdef"
    }
}

function today {
    r1=$(($today*2))
    r2=$(($r1+1))
    echo ${time[r1]}, ${time[r2]}
}

function update {
    download
    extract
}

function sparrow_update {
    #for group 1
     routine=$(curl -s http://loadshedding.sparrowsms.com |grep -Eo '<td>.*</td>'|sed -e's/Group - 2.*//g' -e 's/<[^>]\+>/ /g')
     sun1=`echo $routine| sed 's/.*SUN *\(.*\),.*MON.*/\1/p' -n`
     sun2=`echo $routine| sed 's/.*SUN.*, *\(.*\) *MON.*/\1/p' -n`
     mon1=`echo $routine| sed 's/.*MON *\(.*\),.*TUE.*/\1/p' -n`
     mon2=`echo $routine| sed 's/.*MON.*, *\(.*\) *TUE.*/\1/p' -n`
     tue1=`echo $routine| sed 's/.*TUE *\(.*\),.*WED.*/\1/p' -n`
     tue2=`echo $routine| sed 's/.*TUE.*, *\(.*\) *WED.*/\1/p' -n`
     wed1=`echo $routine| sed 's/.*WED *\(.*\),.*THU.*/\1/p' -n`
     wed2=`echo $routine| sed 's/.*WED.*, *\(.*\) *THU.*/\1/p' -n`
     thu1=`echo $routine| sed 's/.*THU *\(.*\),.*FRI.*/\1/p' -n`
     thu2=`echo $routine| sed 's/.*THU.*, *\(.*\) *FRI.*/\1/p' -n`
     fri1=`echo $routine| sed 's/.*FRI *\(.*\),.*SAT.*/\1/p' -n`
     fri2=`echo $routine| sed 's/.*FRI.*, *\(.*\) *SAT.*/\1/p' -n`
     sat1=`echo $routine| sed 's/.*SAT *\(.*\),.*/\1/p' -n`
     sat2=`echo $routine| sed 's/.*SAT.*, *\(.*\) */\1/p' -n`
     echo -e " $sun1\t$sat1\t$fri1\t$thu1\t$wed1\t$tue1\t$mon1" > $SCHEDULE
     echo -e " $sun2\t$sat2\t$fri2\t$thu2\t$wed2\t$tue2\t$mon2" >> $SCHEDULE
     echo -e " $mon1\t$sun1\t$sat1\t$fri1\t$thu1\t$wed1\t$tue1" >> $SCHEDULE
     echo -e " $mon2\t$sun2\t$sat2\t$fri2\t$thu2\t$wed2\t$tue2" >> $SCHEDULE
     echo -e " $tue1\t$mon1\t$sun1\t$sat1\t$fri1\t$thu1\t$wed1" >> $SCHEDULE
     echo -e " $tue2\t$mon2\t$sun2\t$sat2\t$fri2\t$thu2\t$wed2" >> $SCHEDULE
     echo -e " $wed1\t$tue1\t$mon1\t$sun1\t$sat1\t$fri1\t$thu1" >> $SCHEDULE
     echo -e " $wed2\t$tue2\t$mon2\t$sun2\t$sat2\t$fri2\t$thu2" >> $SCHEDULE
     echo -e " $thu1\t$wed1\t$tue1\t$mon1\t$sun1\t$sat1\t$fri1" >> $SCHEDULE
     echo -e " $thu2\t$wed2\t$tue2\t$mon2\t$sun2\t$sat2\t$fri2" >> $SCHEDULE
     echo -e " $fri1\t$thu1\t$wed1\t$tue1\t$mon1\t$sun1\t$sat1" >> $SCHEDULE
     echo -e " $fri2\t$thu2\t$wed2\t$tue2\t$mon2\t$sun2\t$sat2" >> $SCHEDULE
     echo -e " $sat1\t$fri1\t$thu1\t$wed1\t$tue1\t$mon1\t$sun1" >> $SCHEDULE
     echo -e " $sat2\t$fri2\t$thu2\t$wed2\t$tue2\t$mon2\t$sun2" >> $SCHEDULE
}

if [ ! -e $SCHEDULE ]; then
    update
fi

#checking arguments
if [ $# -eq 0 ]; then
    Usage;
    exit 1;
fi

TEMP=$(getopt  -o    g:wtuhs\
              --long group:,week,today,update,help,sparrow_update\
               -n    "batti" -- "$@")

if [ $? != "0" ]; then exit 1; fi

eval set -- "$TEMP"

dis=0 grp=0
while true; do
    case $1 in
	-g|--group) grp=$2; shift 2;;
 	-w|--week) dis=0; shift;;
	-t|--today) dis=1; shift;;
	-u|--update) update; exit;;
	-s|--sparrow_update) sparrow_update; exit;;
 	-h|--help) Usage; exit;;
	--) shift; break;;
    esac

done

if [ $grp == 0 ]; then Usage; fi
time=(`cut -f$grp $SCHEDULE`)
today=(`date +%w`)
if [ $dis == "0" ]; then week;
else today; fi
