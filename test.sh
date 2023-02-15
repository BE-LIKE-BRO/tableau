#!/bin/bash

### Variables 
path=$(pwd)
dir_name="test"
floor=0
today=$(date +'%Y%m%d' | tr -d '/') 
expiry_sns_topic=""
degraded_sns_topic=""

### if directory exists, move to the directory else create a new directory
echo "setting up working directory..."
echo " "
if [ -d "$path/$dir_name/" ]
then 
    echo "directory exists, moving to directory..."
    echo " "
    cd $path/$dir_name/
else
    echo "directory doesn't exist, setting up directory..."
    echo " "
    mkdir $path/$dir_name/ && cd $path/$dir_name/
fi 

### clean up working directory to setup new files
echo "cleaning up directory..."
echo " "
rm -rf *.*

### Check server staus
touch status.txt
tsm status > status.txt
status=$(cat status.txt | awk  '{print $2}')

if [ $status == "DEGRADED" ]
then
    aws sns publish --topic-arn ${degraded_sns_topic} --message "TABLEAU SERVER IS DEGRADED!!!"
else
    ### create licenses text file
    touch licenses.txt

    ### List all licenses on this tableau server and put the output in text file
    tsm licenses list > licenses.txt

    ### remove the headers of the output so only the list of licenses remain
    sed '1,2d' licenses.txt > licenses_only.txt

    ### Filter the license list to show only expiry dates
    cat licenses_only.txt | awk  '{print $8}' > expiry_dates.txt 

    ###  Filter the license list to show only License ids
    cat licenses_only.txt | awk  '{print $1}' > license_ids.txt

    ### create a text file to hold list of formatted expiry dates
    touch formatted_dates.txt
    touch expired_license_ids.txt

    ### Format license expiry dates and put then in a text file 
    license_count=$(sed -n '$=' licenses_only.txt)

    ### Check if there are any licenses in the license list text file
    license_exist_check=$(sed -n '$=' licenses.txt)
    license_exist_check2=$(tsm licenses list)

    ### Go through the list of expiry dates and find the one(s) older that today, flag them as expired then notify specified email
    if [[ $license_exist_check == "" || $license_exist_check2 == "No licenses are currently activated." || $license_exist_check == 1 ]]
    then 
        echo "There are no licenses on this server..."
        echo "Wrapping up process..."
        echo "License checks DONE!"
    else
        while [ $floor -lt $license_count ]
        do 
            ((floor++))
            for expiry_date in `sed -n ${floor}p expiry_dates.txt`
            do 
                echo " "
                echo "formatting date..."
        # Change the license expiry date from mm/dd/yy to yy/mm/dd. This helps compare dates easily 
                date -d "$expiry_date" +"%Y%m%d" >> formatted_dates.txt
        # print the iterated expiry date and put it in a variable to compare with today
                formatted_date=$(sed -n ${floor}p formatted_dates.txt)
        # Compare dates and put expired dates in a file
                echo "comparing expiry date with today..."
                if [[ $today -lt $formatted_date ]]
                then 
                    active_license=$(sed -n ${floor}p license_ids.txt)
                    echo " "
                    echo "license '${active_license}' is still active"
                else
                    expired_license=$(sed -n ${floor}p license_ids.txt)
                    echo "${expired_license}" >> expired_license_ids.txt
                    expiration_date=$(sed -n ${floor}p expiry_dates.txt)
                    # aws sns publish --topic-arn ${expiry_sns_topic} --message "The tableau license '$expired_license' is no longer active since $expiration_date"
                fi
            done
    done
fi

expired_license_count=$(sed -n '$=' expired_license_ids.txt)

        if [[ $expired_license_count -ne 0 ]]
                then 
                    echo " "
                    echo "Found some expired licenses. Sending email alert..."
                    expired_licenses=$(cat expired_license_ids.txt)
                    aws sns publish --topic-arn ${expiry_sns_topic} --message "These tableau licenses are no longer active;
'${expired_licenses}' "
                else
                    echo " "
                    echo "All licenses are active!"
                fi
                
        echo "DONE!"
fi