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



"lst10days")
    limit=$(date -d "10 days ago" "+%Y-%m-%d %H:%M:%S")
    for ops in Packages/*/ops.txt; do
        pkg=$(basename "$(dirname "$ops")")
        awk -v limit="$limit" -v pkg="$pkg" '
            ($0 ~ /status (installed|uninstalled)/) && (substr($0,1,19) >= limit) {
                print pkg " -> " $0
            }
        ' "$ops"
    done
    ;;

"size")
    dpkg-query -W -f='${Installed-Size} KB\n' "$2" 2>/dev/null || echo "Pachetul nu este instalat."
    ;;

"total-size")
    echo "Calculare dimensiune totală (vă rugăm așteptați)..."
    total=0
    for pkg in $(ls Packages); do
        lastin=$(grep ' installed ' "./Packages/$pkg/ops.txt" | tail -1)
        lastrem=$(grep ' remove ' "./Packages/$pkg/ops.txt" | tail -1)
        if [[ "$lastin" > "$lastrem" ]]; then
            size=$(dpkg-query -W -f='${Installed-Size}' "$pkg" 2>/dev/null || echo 0)
            total=$((total + size))
        fi
    done
    echo "Suma dimensiunilor instalate: $total KB" | tee total_size.db
    ;;

"undo")
    echo " Undo Cache (LRU) "
    cat Cache.txt
    ;;

"is-first-installed")
    if grep -q " remove " "./Packages/$2/ops.txt"; then
            echo "Pachetul $2 a mai fost instalat și șters anterior."
    else
        if grep -q " installed " "./Packages/$2/ops.txt"; then
            echo "Pachetul $2 este la prima instalare în sistem."
        else
            echo "Pachetul $2 nu este instalat sau complet"
        fi
    fi
    ;;
*)
    echo "Ivalid argument"

esac
