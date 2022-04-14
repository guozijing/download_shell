#!/bin/env bash

Url="http://10.240.224.200/New_OS/bevo/pf9/v4.5/P9-offline-install/"
DownPath="/mnt/pf9/P9-offline-install/"
DownListFile="/tmp/downlist.txt"
DownListTmpFile="/tmp/tmplist.txt"
DownFileType=""
DownList=""
UrlBack="$Url"
Action="1"

while getopts "a:" OPTION; do
        case $OPTION in
                a)
                        Action=$OPTARG
                        ;;
                ?)
                        echo "Invalid option: -$OPTION."
                        ;;
                esac
done

if [[ $Action = "1" ]]; then
        [ ! -f $DownListFile ] && touch $DownListFile || echo > $DownListFile
        [ ! -f $DownListTmpFile ] && touch $DownListTmpFile || echo > $DownListTmpFile
fi

CURL_URLS(){
Urls=`curl $UrlBack |awk -F "a href=\"" '{printf "%s\n",$2}'|awk -F "\"" '{printf "%s\n",$1}'|grep -vE "^$|^\?|^http:\/\/"|sed 1d`
}
URL_LIST(){
        CURL_URLS
        for i in $Urls
        do
                echo "$UrlBack$i" >> $DownListTmpFile
        done
}
RECURSIVE_SEARCH_URL(){
UrlBackTmps=`cat $DownListTmpFile`
[[ "$UrlBackTmps" == "" ]] && exit 1
for j in $UrlBackTmps ;do
        if [[ "${j##*\/}" != "" ]] ;then
                echo "$j" >> $DownListFile
        else
                UrlBack="$j"
                URL_LIST
        fi
        UrlTmps=`grep -vE "$j$" $DownListTmpFile`
        echo "$UrlTmps" > $DownListTmpFile
        RECURSIVE_SEARCH_URL
done
}
DOWNLOAD_FILE(){
DownList=`grep -E "$DownFileType" $DownListFile`
for k in $DownList
do
        TFILE=`echo "$k" | awk -F $Url '{print $2}'`
        FilePath=$DownPath${TFILE#*\/\/}
        DIR=`dirname $FilePath`
        if [ ! -d $DIR ]; then
                 mkdir -p $DIR
        fi

        if [ ! -f $FilePath ]; then
                cd $DIR
                wget $k
        fi
done
}
if [[ $Action = "1" ]]; then
        URL_LIST $Urls
        RECURSIVE_SEARCH_URL
fi

if [[ $Action = "2" ]]; then
        DOWNLOAD_FILE
        rm -f $DownListFile
        rm -f $DownListTmpFile
fi

