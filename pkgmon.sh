#!/bin/bash
case $1 in
"installed")
    for i in `ls Packages`
    do
        lastin=`grep ' installed ' ./Packages/$i/ops.txt | tail -1`
        lastrem=`grep ' remove ' ./Packages/$i/ops.txt | tail -1`
        readarray -d " " -t arrlastin <<< $lastin
        readarray -d " " -t arrlastrem <<< $lastrem
        if [[ "${arrlastin[0]} ${arrlastin[1]}" > "${arrlastrem[0]} ${arrlastrem[1]}" ]]
        then
            echo "${i} : ${lastin}"
        fi
    done
    ;;
"removed")
    for i in `ls Packages`
    do
        lastin=`grep ' installed ' ./Packages/$i/ops.txt | tail -1`
        lastrem=`grep ' remove ' ./Packages/$i/ops.txt | tail -1`
        readarray -d " " -t arrlastin <<< $lastin
        readarray -d " " -t arrlastrem <<< $lastrem
        if [[ "${arrlastin[0]} ${arrlastin[1]}" < "${arrlastrem[0]} ${arrlastrem[1]}"  || "${arrlastin[0]} ${arrlastin[1]}" == "${arrlastrem[0]} ${arrlastrem[1]}" ]]
        then
            echo "${i} : ${lastrem}"
        fi
    done
    ;;
"history")
    if [ ./Packages/$2/ops.txt ]
    then
        cat ./Packages/$2/ops.txt
    else
        echo "Package not found"
    fi
    ;;
"date")

*)
    echo "Ivalid argument"

esac