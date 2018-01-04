#!/bin/bash

Start_Install() {
cd /home/ts3srv

TS_New_Version=$(curl -s https://www.teamspeak.com/en/downloads.html#server | grep teamspeak3-server_linux_amd64- | grep -m 1 -o -P '(?<=amd64-).*(?=.tar.bz2)')
TS_Current_Version=$(cat /tmp/CurrentTSversion)

echo $(date) "<===> INFO: Current version is $TS_Current_Version" >> /var/log/teamspeak/TS3.log
echo $(date) "<===> INFO: Latest version is $TS_New_Version" >> /var/log/teamspeak/TS3.log

if [ $TS_New_Version = $TS_Current_Version ]
        then
                echo "You already have the latest version of $TS_Current_Version"
                echo $(date) "<===> INFO: You already have the latest version of $TS_Current_Version" >> /var/log/teamspeak/TS3.log
                exit 400
fi

echo "Install/Upgrade to version $TS_New_Version started"
echo $(date) "<===> INFO: Install/Upgrade to version $TS_New_Version started" >> /var/log/teamspeak/TS3.log

wget http://teamspeak.gameserver.gamed.de/ts3/releases/$TS_New_Version/teamspeak3-server_linux_amd64-$TS_New_Version.tar.bz2
cp /scripts/teamspeak3-server_linux_amd64-3.0.13.8.tar.bz2 /home/ts3srv/

#/home/ts3srv/teamspeak3-server_linux_amd64/ts3server_startscript.sh stop
sudo systemctl stop ts3server
pwd
tar xvf teamspeak3-server_linux_amd64-$TS_New_Version.tar.bz2
sudo systemctl start ts3server
#/home/ts3srv/teamspeak3-server_linux_amd64/ts3server_startscript.sh start
echo "TeamSpeak 3 server started, for details please view the log file"
echo $(date) "<===> INFO: TeamSpeak 3 server started, for details please view the log file" >> /var/log/teamspeak/TS3.log
}

if [ ! $(cat /etc/issue | cut -d " " -f 1) = Ubuntu ]
then
        echo Please run this script only from an Ubuntu distribution
        exit 400
fi

if [ ! -d /home/ts3srv ] && [ $(whoami) = root ]
    then
            if [ ! $(which curl) ]; then apt install curl -y; fi
            if [ ! $(which wget) ]; then apt install wget -y; fi
            if [ ! $(which tar) ]; then apt install tar -y; fi
            if [ ! $(which bzip2) ]; then apt install bzip2 -y; fi
            echo "Running TS3 installation for the first time"
            echo "ts3srv ALL=(ALL) NOPASSWD:/bin/systemctl stop ts3server" >> /etc/sudoers
            echo "ts3srv ALL=(ALL) NOPASSWD:/bin/systemctl start ts3server" >> /etc/sudoers
            systemctl restart ssh
            echo "Creating system user ts3srv"
            adduser \
            --system \
            --shell /bin/bash \
            --group \
            --disabled-password \
            --home /home/ts3srv \
            ts3srv
            mkdir /var/log/teamspeak
            sleep 2
            echo " " > /var/log/teamspeak/TS3.log
            chmod 777 /var/log/teamspeak/TS3.log
            echo "0 4 * * 0,3 /home/ts3srv/TS3-Upgrade.sh" > /tmp/crontab.tmp
            #chmod 2755 /usr/bin/crontab
            su -c 'crontab /tmp/crontab.tmp' ts3srv
            rm -rf /tmp/crontab.tmp
            cp $BASH_SOURCE /home/ts3srv/TS3-Upgrade.sh
            echo $BASH_SOURCE
            chmod +x /home/ts3srv/TS3-Upgrade.sh
            chown ts3srv:ts3srv /home/ts3srv/TS3-Upgrade.sh
            cd /home/ts3srv
            cat <<EOF > /lib/systemd/system/ts3server.service
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
User=ts3srv
UMask=0027
WorkingDirectory=/home/ts3srv/teamspeak3-server_linux_amd64
ExecStart=/home/ts3srv/teamspeak3-server_linux_amd64/ts3server_minimal_runscript.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
            systemctl enable ts3server
            Start_Install
            if [ ! -f /tmp/CurrentTSversion ]
            then
            echo "$TS_New_Version" > /tmp/CurrentTSversion
            chmod 777 /tmp/CurrentTSversion
            chown -R ts3srv:ts3srv /home/ts3srv/
            echo "$TS_New_Version" > /tmp/CurrentTSversion
            echo $(date) "<===> INFO: *********************************************************************************************************" >> /var/log/teamspeak/TS3.log
            echo $(date) "<===> INFO: TeamSpeak 3 server is starting for the first time" >> /var/log/teamspeak/TS3.log
            echo $(date) "<===> INFO: Alternatively, you may check the log files in /home/ts3srv/teamspeak3-server_linux_amd64/logs/" >> /var/log/teamspeak/TS3.log
            echo $(date) "<===> INFO: *********************************************************************************************************" >> /var/log/teamspeak/TS3.log
            echo "*********************************************************************************************************"
            echo "TeamSpeak 3 server is starting for the first time, please wait to get your admin privilege key...."
            echo "Alternatively, you may check the log files either in /home/ts3srv/teamspeak3-server_linux_amd64/logs/"
            echo "or in, /var/log/teamspeak/TS3.log"
            echo "*********************************************************************************************************"
            COUNTER=0
            while ! [ $(grep -o token= /home/ts3srv/teamspeak3-server_linux_amd64/logs/ts3server_*) ]
            do
                                let COUNTER=COUNTER+1
                                echo "Checking if server is up "$COUNTER"s/120s (Seconds)"
                                if [ $COUNTER -eq 120 ]
                                        then
                                                echo "For some reason starting the ts3server is taking more than expected"
                                                echo "Please check the logs under /home/ts3srv/teamspeak3-server_linux_amd64/logs/"
                                                echo $(date) "<===> INFO: For some reason starting the ts3server is taking more than expected" >> /var/log/teamspeak/TS3.log
                                                echo $(date) "<===> INFO: Please check the logs under /home/ts3srv/teamspeak3-server_linux_amd64/logs/" >> /var/log/teamspeak/TS3.log
                                                exit
                                        fi
                                sleep 1
                        done
                        tail -n 4 /home/ts3srv/teamspeak3-server_linux_amd64/logs/ts3server_*
                        echo $(date) "<===> INFO: Your admin privilege key is "$(tail -n 2 /home/ts3srv/teamspeak3-server_linux_amd64/logs/ts3server_* | grep -o -P '(?<=token=).*') >> /var/log/teamspeak/TS3.log
                        fi
                        exit
elif [ ! -d /home/ts3srv ]
        then
                echo "It seems that you dont have Teamspeak installed under ts3srv username"
                echo "Please execute this installation script as root only in order to install for the first time"
        exit
echo "TeamSpeak 3 server started, for details please view the log file"
exit 200
fi

actualsize=$(wc -c</var/log/teamspeak/TS3.log)
if [ $actualsize -ge 20480000 ]
        then
                LogLocationold=$LogLocation.old
                mv $LogLocation $LogLocationold
                echo " " > $LogLocation
fi

if [ $(whoami) = ts3srv ]
        then
                echo "Checking latest version ...."
                echo $(date) "<===> INFO: Checking latest version" >> /var/log/teamspeak/TS3.log
        else
                echo "Please log into account ts3srv and run the script, try adduser ts3srv and then install it under home folder"
                echo $(date) "<===> ERROR: User $(whoami) tried to tun the script" >> /var/log/teamspeak/TS3.log
                echo $(date) "<===> ERROR: Please log into account ts3srv and run the script, try adduser ts3srv and then install it under home folder" >> /var/log/teamspeak/TS3.log
                exit 400
fi

Start_Install
echo "$TS_New_Version" > /tmp/CurrentTSversion
exit 200