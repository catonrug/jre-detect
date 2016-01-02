#!/bin/sh

#check if script is located in /home direcotry
pwd | grep "^/home/" > /dev/null
if [ $? -ne 0 ]; then
  echo script must be located in /home direcotry
  break
fi

#it is highly recommended to place this directory in another directory
deep=$(pwd | sed "s/\//\n/g" | grep -v "^$" | wc -l)
if [ $deep -lt 4 ]; then
  echo please place this script in another directory
  break
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
  break
fi

#check if Google Drive uploader program exists
if [ ! -f "../uploader.py" ]; then
  echo uploader.py not found. downloading now..
  wget https://github.com/catonrug/gduploader/raw/4d6414047d0f78e81b390f167a8e9d9e9441325a/uploader.py -O ../uploader.py -q
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
  break
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

#if database file do not exist then create one
if [ ! -f "../db/$appname.db" ]; then
  touch "../db/$appname.db"
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
  echo 7z support no installed. Please run:
  echo sudo apt-get install p7zip-full
fi


#clean and remove temp direcotry
rm $tmp -rf > /dev/null
