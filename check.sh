#!/bin/sh

#this code is tested un fresh 2015-11-21-raspbian-jessie-lite Raspberry Pi image
#by default this script should be located in two subdirecotries under the home

#sudo apt-get update -y && sudo apt-get upgrade -y
#sudo apt-get install git -y
#mkdir -p /home/pi/detect && cd /home/pi/detect
#git clone https://github.com/catonrug/jre-detect.git && cd jre-detect && chmod +x check.sh && clear && ./check.sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  return
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in deeper directory
  return
fi

#set application name based on directory name
#this will be used for future temp directory, database name, google upload config, archiving
appname=$(pwd | sed "s/^.*\///g")

#set temp directory in variable based on application name
tmp=$(echo ../tmp/$appname)

#create temp directory
if [ ! -d "$tmp" ]; then
  mkdir -p "$tmp"
fi

#check if database directory has prepared 
if [ ! -d "../db" ]; then
  mkdir -p "../db"
fi

#set database variable
db=$(echo ../db/$appname.db)

#if database file do not exist then create one
if [ ! -f "$db" ]; then
  touch "$db"
fi

#check if google drive config directory has been made
#if the config file exists then use it to upload file in google drive
#if no config file is in the directory there no upload will happen
if [ ! -d "../gd" ]; then
  mkdir -p "../gd"
fi

#put all links that contains "BundleId" in array
linklist=$(wget --no-cookies --no-check-certificate https://www.java.com/en/download/manual.jsp -qO- | grep BundleId | sed "s/\d034/\n/g" | grep "^http" | sort | uniq | sed '$aend of file')

printf %s "$linklist" | while IFS= read -r url
do {
	#echo $url
	
	#take every link and look what kind of file it reports. do not download anything yet!
	wget $url -S --spider -o $tmp/outs.log -q
	
	#detect if there is any exe files in the link
	sed "s/http/\nhttp/g;s/exe/exe\n/g" $tmp/outs.log | grep "^http.*x64.exe$\|^http.*i586.exe$" | sort | uniq | grep "^http.*x64.exe$\|^http.*i586.exe$" > /dev/null
		if [ $? -eq 0 ]
			#if some exe file was found
			then
				#detect exact filename by striping down all content from left side and leaving only last part
				filename=$(sed "s/http/\nhttp/g;s/exe/exe\n/g" $tmp/outs.log | grep "^http.*x64.exe$\|^http.*i586.exe$" | sort | uniq | sed "s/^.*\///g")
				
				#check if this can of filename has already been downloaded
				cat $db | grep "$filename"
					if [ $? -ne 0 ]
						#if this file has never downloaded
						then
							echo Downloading $filename
							#downloading real file now!
							wget --no-cookies --no-check-certificate $url -O $tmp/$filename -q
							#creating some check sums
							md5=$(md5sum $tmp/$filename | sed "s/\s.*//g")
							echo $md5
							sha1=$(sha1sum $tmp/$filename | sed "s/\s.*//g")
							echo $sha1
							#lets put all signs about this file into the database
							echo "$url">>$db
							echo "$filename">> $db
							echo "$md5">> $db
							echo "$sha1">> $db
								#if google drive config exists then upload and delete file:
								if [ -f "../gd/$appname.cfg" ]
									then
										echo Uploading $filename to Google Drive..
										../uploader.py "../gd/$appname.cfg" "$tmp/$filename"
								fi
							#lets send emails to all people in "posting" file
							emails=$(cat ../posting | sed '$aend of file')
							printf %s "$emails" | while IFS= read -r onemail
							do {
								python ../send-email.py "$onemail" "$filename" "$url
$md5
$sha1"
							} done
							echo
					fi
		fi
} done

#clean and remove whole temp direcotry
rm $tmp -rf > /dev/null
