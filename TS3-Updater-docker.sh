#!/bin/bash
INSTCOMM="apt"
if ! command -v curl &> /dev/null ; then sudo $INSTCOMM install curl -y; fi
TS_New_Version=$(curl -s https://www.teamspeak.com/en/downloads/#server | grep teamspeak3-server_linux_amd64- | grep -m 1 -o -P '(?<=amd64-).*(?=.tar.bz2)')
TS_Current_Version=$(sudo docker exec centos-ts3 cat /var/log/teamspeak/CurrentTSversion)
echo "Cloud Version = $TS_New_Version"
echo "Current installed version $TS_Current_Version"
if [ $TS_New_Version = $TS_Current_Version ]
	then
		echo "You already have the latest version of $TS_Current_Version , nothing to do"
        exit 0
	else
		if ! command -v wget &> /dev/null ; then sudo $INSTCOMM install wget -y; fi
		if ! command -v tar &> /dev/null ; then sudo $INSTCOMM install tar -y; fi
		if ! command -v bzip2 &> /dev/null ; then sudo $INSTCOMM install bzip2 -y; fi
		echo "Downloading version $TS_New_Version"
		wget --no-check-certificate https://files.teamspeak-services.com/releases/server/$TS_New_Version/teamspeak3-server_linux_amd64-$TS_New_Version.tar.bz2
		TS3CONTAINER="centos-ts3"
		TS3USER=$(sudo docker exec $TS3CONTAINER grep User /var/log/teamspeak/Details | cut -d "=" -f 2)
		TS3PATH=$(sudo docker exec $TS3CONTAINER grep Path /var/log/teamspeak/Details | cut -d "=" -f 2)
		echo $TS3USER;echo $TS3PATH
		tar xvf teamspeak3-server_linux_amd64-$TS_New_Version.tar.bz2
		echo "Stopping container $TS3CONTAINER"
		sudo docker stop $TS3CONTAINER
		sudo docker cp ./teamspeak3-server_linux_amd64 $TS3CONTAINER:/opt/teamspeak3server/
		echo "Starting container $TS3CONTAINER"
		sudo docker start $TS3CONTAINER
		sleep 1
		sudo docker exec $TS3CONTAINER chown -R $TS3USER: $TS3PATH
		echo $TS_New_Version > CurrentTSversion
		sudo docker cp CurrentTSversion $TS3CONTAINER:/var/log/teamspeak/CurrentTSversion
		sudo docker exec $TS3CONTAINER kill -9 1
		exit 0
fi
exit 255
