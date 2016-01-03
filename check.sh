#!/bin/sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  return
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in another directory
  return
fi

#check if email sender exists
if [ ! -f "../send-email.py" ]; then
  echo send-email.py not found. downloading now..
  wget https://gist.githubusercontent.com/superdaigo/3754055/raw/e28b4b65110b790e4c3e4891ea36b39cd8fcf8e0/zabbix-alert-smtp.sh -O ../send-email.py -q
fi

#check if email sender is configured
grep "your.account@gmail.com" ../send-email.py > /dev/null
if [ $? -eq 0 ]; then
  echo username is not configured in ../send-email.py please look at the line:
  grep -in "your.account@gmail.com" ../send-email.py
  echo sed -i \"s/your.account@gmail.com//\" ../send-email.py
  echo
fi

#check if email password is configured
grep "your mail password" ../send-email.py > /dev/null
if [ $? -eq 0 ]; then
  echo password is not configured in ../send-email.py please look at line:
  grep -in "your mail password" ../send-email.py
  echo sed -i \"s/your mail password//\" ../send-email.py
  return
fi

#check for file where all emails will be used to send messages
if [ ! -f "../posting" ]; then
  echo posting email address not configured. all changes will be submited to all email adresies in this file
  echo echo your.email@gmail.com\> ../posting
  echo
fi

#make sure the maintenance email is configured
if [ ! -f "../maintenance" ]; then
  echo maintenance email address not configured. this will be used to check if the page even still exist.
  echo echo your.email@gmail.com\> ../maintenance
  echo
  return
fi

#check for javascript html downloader
if [ ! -f "../html-downloader.py" ]; then
  echo html-downloader.py not found. downloading now..
  wget https://github.com/catonrug/html-downloader/raw/3c3fc6a5b551c94a5b528af3674ddddb5b60fec1/html-downloader.py -O ../html-downloader.py -q
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

#check if 7z command is installed
sudo dpkg -l | grep p7zip-full > /dev/null
if [ $? -ne 0 ]
then
  echo Installing 7z support
  sudo apt-get install p7zip-full
  echo
fi


#if client_secrets.json not exist then google upload will not work
if [ ! -f "/home/pi/client_secrets.json" ]
  then
    echo /home/pi/client_secrets.json not found. Upload to Google Drive will be impossible
    echo
  else
    #if client_secrets.json exist the check for additional libraries to work with upload
    sudo dpkg -l | grep python-pip > /dev/null
    if [ $? -ne 0 ]
      then
        echo alternative Python package installer [pip] is not installed. please run:
        echo sudo apt-get install python-pip -y
        return
      else
        pip freeze | grep "google-api-python-client" > /dev/null
        if [ $? -ne 0 ]
          then
		    echo google-api-python-client python module not installed. Installing now..
            sudo pip install --upgrade google-api-python-client
          fi
    fi
fi

#if all necesary modules are installed to work with google uploder then download upload script:
pip freeze | grep "google-api-python-client" > /dev/null
if [ $? -eq 0 ]
  then
    if [ ! -f "../uploader.py" ]
	  then
        echo uploader.py not found. downloading now..
        wget https://github.com/jerbly/motion-uploader/blob/04de61ce2c379955acac6a2bee676159882d9a86/uploader.py -O ../uploader.py -q
    fi
fi


linklist=$(wget --no-cookies --no-check-certificate https://www.java.com/en/download/manual.jsp -qO- | grep BundleId | sed "s/\d034/\n/g" | grep "^http" | sort | uniq | sed '$aend of file')
printf %s "$linklist" | while IFS= read -r url
do {
echo $url
wget $url -S --spider -o $tmp/outs.log -q
sed "s/http/\nhttp/g;s/exe/exe\n/g" $tmp/outs.log | grep "^http.*x64.exe$\|^http.*i586.exe$" | sort | uniq | grep "^http.*x64.exe$\|^http.*i586.exe$"
if [ $? -eq 0 ]
then
filename=$(sed "s/http/\nhttp/g;s/exe/exe\n/g" $tmp/outs.log | grep "^http.*x64.exe$\|^http.*i586.exe$" | sort | uniq | sed "s/^.*\///g")
echo $filename
cat $db | grep "$filename"
if [ $? -ne 0 ]; then
echo downloading $filename
wget --no-cookies --no-check-certificate $url -O $tmp/$filename -q
md5=$(md5sum $tmp/$filename | sed "s/\s.*//g")
echo $md5
sha1=$(sha1sum $tmp/$filename | sed "s/\s.*//g")
echo $sha1
echo "$url">>$db
echo "$filename">> $db
echo "$md5">> $db
echo "$sha1">> $db
emails=$(cat ../posting | sed '$aend of file')
printf %s "$emails" | while IFS= read -r onemail
do {
python ../send-email.py "$onemail" "$filename" "$url
$md5
$sha1"
} done
fi
fi
} done


#clean and remove temp direcotry
rm $tmp -rf > /dev/null
