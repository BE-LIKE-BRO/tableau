#!/bin/bash

### Variables 
path=$(pwd)
dir_name="test"
floor=0
today=$(date +'%Y%m%d' | tr -d '/') 

### if directory exists, move to the directory else create a new directory
echo "setting up working directory..."
if [ -d "$path/$dir_name/" ]
then 
    echo "directory exists, moving to directory"
    cd $path/$dir_name/
else
    mkdir $path/$dir_name/ && cd $path/$dir_name/
    echo "directory doesn't exist, setting up directory"
fi 

### clean up working directory to setup new files
echo "cleaning up directory"
rm -rf *.*

### List all licenses on this tableau server and put the output in text file
tsm licenses list > licenses.txt

### remove the headers of the output so only the list of licenses remain
sed '1,2d' licenses.txt > licenses_only.txt

### Filter the license list to show only expiry dates
cat licenses_only.txt | awk  '{print $8}' > expiry_dates.txt 

### create a text file to hold list of formatted expiry dates
touch formatted_dates.txt

### Format licence expiry dates and put then in a text file 
license_count=$(sed -n '$=' licenses_only.txt)

while [ $floor -lt $license_count ]
do 
    ((floor++))
    for expiry_date in `sed -n ${floor}p expiry_dates.txt`
    do 
        echo "setting up formatted dates"
        date -d "$expiry_date" +"%Y%m%d" >> formatted_dates.txt
    done

done &

while [ $floor -lt $license_count ]
do 
    ((floor++))
    formatted_date=$(sed -n ${floor}p formatted_dates.txt)
    echo "comparing dates"
    echo "$formatted_date"
    if [ $today -lt $formatted_date ]
    then 
        echo "still have some time left"
    else
        echo "expired"
    fi

done


# for formatted_date in `sed -n ${floor}p formatted_dates.txt`
#     # do 
        
#     #     fi 


# while [ $floor -lt $license_count ]
# do 
#     ((floor++))
#     echo "this loop works"

# done