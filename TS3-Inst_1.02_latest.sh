#!/bin/bash
#set -x
#set -v
#trap read debug

if [ ! $(cat /etc/issue | cut -d " " -f 1) = Ubuntu ]
then
        echo Please run this script only from an Ubuntu distribution
        exit 400
fi

declare -x TS3USER
declare -x TS3PATH
TS3USER=$(grep User /var/log/teamspeak/Details | cut -d "=" -f 2)
TS3PATH=$(grep Path /var/log/teamspeak/Details | cut -d "=" -f 2)
FirstRun=1

if [ $FirstRun = "1" ]
then
cp $BASH_SOURCE $BASH_SOURCE.FirstRun
sed -i -- '0,/FirstRun=1/s/FirstRun=1/FirstRun=0/g' $BASH_SOURCE
echo "**************************************************************************************"
echo "**                       PLEASE READ BEFORE YOU PROCEED                             **"
echo "**   This initial installation process will appear only now at the first execution  **"
echo "**                if you like to run the installation again                         **"
echo "**              you need run the following command and try again:                   **"
echo "**************************************************************************************"
echo "Run the command = #cp "$BASH_SOURCE".FirstRun "$BASH_SOURCE""
echo ""
echo "**************************************************************************************"
echo "** For security reasons Teamspeak3 must be installed under a uniqe and new username **"
echo "**   please specify why to be created (leave empty for the default ts3srv user)     **"
echo "**************************************************************************************"

read TS3USER
if [[ $TS3USER = "" ]]; then TS3USER=ts3srv; fi

echo "**************************************************************************************"
echo "**                  Where would you like to install the server                      **"
echo "**     please provide a path (leave empty for the default /opt/teamspeak3server)    **"
echo "**************************************************************************************"

read TS3PATH
if [[ $TS3PATH = "" ]]; then TS3PATH="/opt/teamspeak3server"; fi

fi

Start_Install() {
cd $TS3PATH

TS_New_Version=$(curl -s https://www.teamspeak.com/en/downloads.html#server | grep teamspeak3-server_linux_amd64- | grep -m 1 -o -P '(?<=amd64-).*(?=.tar.bz2)')
TS_Current_Version=$(cat /var/log/teamspeak/CurrentTSversion)

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

sudo systemctl stop ts3server
tar xvf teamspeak3-server_linux_amd64-$TS_New_Version.tar.bz2
chown -R $TS3USER:$TS3USER $TS3PATH
sudo systemctl start ts3server

echo "TeamSpeak 3 server started, for details please view the log file"
echo $(date) "<===> INFO: TeamSpeak 3 server started, for details please view the log file" >> /var/log/teamspeak/TS3.log
}

if [ ! -d $TS3PATH ] && [ $(whoami) = root ]
    then
            mkdir -p $TS3PATH
			if [ ! $(which curl) ]; then apt install curl -y; fi
            if [ ! $(which wget) ]; then apt install wget -y; fi
            if [ ! $(which tar) ]; then apt install tar -y; fi
            if [ ! $(which bzip2) ]; then apt install bzip2 -y; fi
            echo "Running TS3 installation for the first time"
            echo "$TS3USER ALL=(ALL) NOPASSWD:/bin/systemctl stop ts3server" >> /etc/sudoers
            echo "$TS3USER ALL=(ALL) NOPASSWD:/bin/systemctl start ts3server" >> /etc/sudoers
            systemctl restart ssh
            echo "Creating system user $TS3USER"
            adduser \
            --system \
            --shell /bin/bash \
            --group \
            --disabled-password \
            --home /home/$TS3USER \
            $TS3USER
            mkdir /var/log/teamspeak
            sleep 2
            echo " " > /var/log/teamspeak/TS3.log
            echo "User=$TS3USER" > /var/log/teamspeak/Details
            echo "Path=$TS3PATH" >> /var/log/teamspeak/Details
            chmod -R 777 /var/log/teamspeak/
            echo "0 4 * * 0,3 $TS3PATH/TS3-Upgrade.sh" > /tmp/crontab.tmp
            #chmod 2755 /usr/bin/crontab
            su -c 'crontab /tmp/crontab.tmp' $TS3USER
            rm -rf /tmp/crontab.tmp
            cp $BASH_SOURCE $TS3PATH/TS3-Upgrade.sh
            echo $BASH_SOURCE
            chmod +x $TS3PATH/TS3-Upgrade.sh
            chown $TS3USER:$TS3USER $TS3PATH/TS3-Upgrade.sh
            cd $TS3PATH
            cat <<EOF > /lib/systemd/system/ts3server.service
[Unit]
Description=TeamSpeak 3 Server
After=network.target

[Service]
User=$TS3USER
UMask=0027
WorkingDirectory=$TS3PATH/teamspeak3-server_linux_amd64
ExecStart=$TS3PATH/teamspeak3-server_linux_amd64/ts3server_minimal_runscript.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
            systemctl enable ts3server
            Start_Install
            if [ ! -f /var/log/teamspeak/CurrentTSversion ]
            then
            echo "$TS_New_Version" > /var/log/teamspeak/CurrentTSversion
            chmod 777 /var/log/teamspeak/CurrentTSversion
            echo "$TS_New_Version" > /var/log/teamspeak/CurrentTSversion
            echo $(date) "<===> INFO: *********************************************************************************************************" >> /var/log/teamspeak/TS3.log
            echo $(date) "<===> INFO: TeamSpeak 3 server is starting for the first time" >> /var/log/teamspeak/TS3.log
            echo $(date) "<===> INFO: Alternatively, you may check the log files in $TS3PATH/teamspeak3-server_linux_amd64/logs/" >> /var/log/teamspeak/TS3.log
            echo $(date) "<===> INFO: *********************************************************************************************************" >> /var/log/teamspeak/TS3.log
            echo "*********************************************************************************************************"
            echo "TeamSpeak 3 server is starting for the first time, please wait to get your admin privilege key...."
            echo "Alternatively, you may check the log files either in $TS3PATH/teamspeak3-server_linux_amd64/logs/"
            echo "or in, /var/log/teamspeak/TS3.log"
            echo "*********************************************************************************************************"
            COUNTER=0
            while ! [ $(grep -o token= $TS3PATH/teamspeak3-server_linux_amd64/logs/ts3server_*) ]
            do
                                let COUNTER=COUNTER+1
                                echo "Checking if server is up "$COUNTER"s/120s (Seconds)"
                                if [ $COUNTER -eq 120 ]
                                        then
                                                echo "For some reason starting the ts3server is taking more than expected"
                                                echo "Please check the logs under $TS3PATH/teamspeak3-server_linux_amd64/logs/"
                                                echo $(date) "<===> INFO: For some reason starting the ts3server is taking more than expected" >> /var/log/teamspeak/TS3.log
                                                echo $(date) "<===> INFO: Please check the logs under $TS3PATH/teamspeak3-server_linux_amd64/logs/" >> /var/log/teamspeak/TS3.log
                                                exit
                                        fi
                                sleep 1
                        done
                        tail -n 4 $TS3PATH/teamspeak3-server_linux_amd64/logs/ts3server_*
                        echo $(date) "<===> INFO: Your admin privilege key is "$(tail -n 2 $TS3PATH/teamspeak3-server_linux_amd64/logs/ts3server_* | grep -o -P '(?<=token=).*') >> /var/log/teamspeak/TS3.log
                        fi
                        exit
elif [ ! -d $TS3PATH ]
        then
                echo "It seems that you dont have Teamspeak installed under the path $TS3PATH"
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

if [ $(whoami) = $TS3USER ]
        then
                echo "Checking latest version ...."
                echo $(date) "<===> INFO: Checking latest version" >> /var/log/teamspeak/TS3.log
        else
                echo "Please log into account $TS3USER and run the script again"
                echo $(date) "<===> ERROR: User $(whoami) tried to tun the script" >> /var/log/teamspeak/TS3.log
                echo $(date) "<===> ERROR: Please log into account $TS3USER and run the script again" >> /var/log/teamspeak/TS3.log
                exit 400
fi

Start_Install
echo "$TS_New_Version" > /var/log/teamspeak/CurrentTSversion
exit 200