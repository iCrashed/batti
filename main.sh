#!/bin/bash

WD="$(dirname $0)"
PRG="$(basename $0)"

SCHEDULE="$HOME/.cache/batti.sch"

function download {
    wget -c http://nea.org.np/loadshedding.html -O /tmp/nea.html
    link=($(sed -n '/supportive_docs/p' /tmp/nea.html | tr '<' '\n' | sed -n 's/.*\(http.*pdf\)">.*/\1/gp'))
    wget -c ${link[0]} -O /tmp/nea.pdf
}

function extract {
    rm -f $SCHEDULE
    pdftotext -f 1 -layout /tmp/nea.pdf /tmp/raw.txt
    sed -n '/;d"x÷af/,/;d"x–@/p' /tmp/raw.txt > /tmp/part.txt
    sed -i 's/\;d"x–.//; /M/!d; s/^ \+//' /tmp/part.txt
    $WD/2utf8/main.sh -f /tmp/part.txt > /tmp/uni.txt
    sed -i 's/०/0/g; s/१/1/g; s/२/2/g; s/३/3/g;
            s/४/4/g; s/५/5/g; s/६/6/g; s/७/7/g;
            s/८/8/g; s/९/9/g; s/–/-/g;' /tmp/uni.txt
    sed 's/ \+/\t/g' /tmp/uni.txt | head -2 > $SCHEDULE
    echo "Schedule Extracted"
    # cat $SCHEDULE
}

function get_color { # arg($1:color_code)
    # NOTE: cdef is always same
    if [ "$SGR" = "" ] ; then
	echo "\033[$1;$2m"
    fi
}

function rotate_field { # arg($1:group, $2:day)
    f=$(($1-$2))
    if [ $f -le 0 ]; then
	echo $((7+$f))
    else
	echo $f
    fi
}

function week_view { # arg($1:group)
    day=(Sun Mon Tue Wed Thr Fri Sat)
    color=$(get_color 1 32)

    for((i=0;i<7;i++)) {
	field=$(rotate_field $i $1)
	if [ $today == $i ]; then
	    color=$(get_color 1 32)
	    cdef=$(get_color 0 0)
	else
	    color=""
	    cdef=""
	fi

	echo -e ${color}${day[$i]} # $field
	time=($(cut -f$field $SCHEDULE))
	echo -e "\t${time[0]}"
	echo -e "\t${time[1]}$cdef"
    }
}

function xml_dump {
    day=(sunday monday tuesday wednesday thursday friday saturday)
    echo -e "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<routine>"
    for((g=1;g<=7;g++)) {
	echo -e "    <group name=\"$g\">"
	grp=$(($g-2))
	for((i=0;i<7;i++)) {
	    field=$(rotate_field $i $grp)
	    time=($(cut -f$field $SCHEDULE))

	    echo "      <day name=\"${day[$i]}\">"
	    echo "        <item>${time[0]}</item>"
	    echo "        <item>${time[1]}</item>"
	    echo "      </day>"
	}
	echo -e "    </group>"
    }
    echo "</routine>"
}

function all_sch {
    h1=$(get_color 1 32)
    cdef=$(get_color 0 0)

    sed 's/://g' $SCHEDULE > /tmp/batti.sch
    SCHEDULE=/tmp/batti.sch

    echo -en "          $h1"

    for day in Sun Mon Tue Wed Thr Fri Sat ; do
	printf "   %-7s" "$day"
    done
    echo

    today=(`date +%w`)
    for((g=1;g<=7;g++)) {
	echo -en "$h1 Group $g: $cdef"
	grp=$(($g-2))
	line2=""
	for((i=0;i<7;i++)) {
	    field=$(rotate_field $i $grp)
	    time=($(cut -f$field $SCHEDULE))
	    if [ $today == $i ]; then
		echo -en "$(get_color 1 34)${time[0]}$(get_color 0 0) "
		line2+=$(echo -en "$(get_color 1 34)${time[1]}$(get_color 0 0) ")
	    else
		echo -en "${time[0]} "
		line2+=$(echo -en "${time[1]} ")
	    fi
	}
	echo -e "\n          $line2"
    }
}

function today_view { # arg($1:group)
    field=$(rotate_field $today $1)
    time=($(cut -f$field $SCHEDULE))
    echo ${time[0]}, ${time[1]}
}

function update {
    local FILE="/tmp/nea.pdf"
    if [ ! -e $FILE ]; then
	download
    fi
    if [ -e $FILE ]; then
	extract
    fi
}

if [ ! -e $SCHEDULE ]; then
    update
fi

today=(`date +%w`)

#checking arguments
if [ $# -eq 0 ]; then
    all_sch
    exit 0;
fi

function Usage {
    echo -e "Usage: \tbatti -g [1-7] [OPTIONS]";
    echo -e "\t-a | --all\tShow All [default]"
    echo -e "\t-g | --group\tGroup number 1-7"
    echo -e "\t-t | --today\tShow today's schedule [uses with group no]"
    echo -e "\t-w | --week\tShow week's schedule"
    echo -e "\t-u | --update\tCheck for update [ignores extra options]"
    echo -e "\t-x | --xml\tDump to xml"
    echo -e "\t-h | --help\tDisplay this message"
    exit
}

TEMP=$(getopt  -o    g:awtuxh\
              --long all,group:,week,today,update,xml,help\
               -n    "batti" -- "$@")

if [ $? != "0" ]; then exit 1; fi

eval set -- "$TEMP"

dis=0 grp=0
while true; do
    case $1 in
	-a|--all)	 all_sch; exit;;
	-g|--group)	 grp=$2; shift 2;;
	-w|--week)	 dis=0; shift;;
	-t|--today)	 dis=1; shift;;
	-u|--update)	 update; exit;;
	-x|--xml)	 xml_dump; exit;;
	-h|--help)	 Usage; exit;;
	--)		 shift; break;;
    esac
done

if [ "$grp" == 0 ]; then Usage; fi
grp=$(($grp-2)) # for rotation
if [ $dis == "0" ]; then week_view grp;
else today_view grp; fi
