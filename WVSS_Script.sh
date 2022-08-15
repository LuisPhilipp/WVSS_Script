#!/bin/bash
cat << "EOF"

 __      ______   _____________ _________
/  \    /  \   \ /   /   _____//   _____/
\   \/\/   /\   Y   /\_____  \ \_____  \ 
 \        /  \     / /        \/        \
  \__/\  /    \___/ /_______  /_______  /
       \/                   \/        \/ 
                                                      
EOF
PS3='Please enter a Task: '
options=("network config wvss" "install mosquitto" "install Node-RED + InfluxDB" "install grafana" "install apache + TLS + Homepage" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "network config wvss")
            echo “Statische IP für WVSS vergeben”
echo “Beispiel IP: 10.16.RAUM.200+PC”
echo “Welche IP soll vergeben werden?”
read IP
cat > /etc/network/interfaces << EOF

# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto enp0s3
iface enp0s3 inet static
address $IP
netmask 255.0.0.0
gateway 10.16.1.245

EOF
cat > /etc/resolv.conf << EOF

domain wvss-mannheim.de
search wvss-mannheim.de
nameserver 10.16.1.253

EOF
sudo /etc/init.d/networking restart
echo "done"

            ;;
        "install mosquitto")
            apt install mosquitto mosquitto-clients
	    echo "listener 1883 0.0.0.0" > /etc/mosquitto/mosquitto.conf
	    echo "allow_anonymous true" >> /etc/mosquitto/conf.d/default.conf
	    systemctl enable mosquitto.service
    	    echo "done"
            ;;
        "install Node-RED + InfluxDB")
            apt install -y npm
	    npm install -g --unsafe-perm node-red
	    npm install -g pm2
	    pm2 start /usr/local/bin/node-red
	    pm2 save
	    pm2 startup
	    wget https://dl.influxdata.com/influxdb/releases/influxdb_1.8.10_amd64.deb
	    apt install curl
	     sudo dpkg -i influxdb_1.8.10_amd64.deb
	    systemctl start influxdb
                          influx
	     read DATABASENAME
                          create database “$DATABASENAME”
	     echo "done"
            ;;
	"install grafana")
	   sudo apt-get install -y apt-transport-https
	   sudo apt-get install -y software-properties-common wget
	   wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
	   echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	   sudo apt-get update
	   sudo apt-get install grafana
	   /bin/systemctl start grafana-server
	   echo "done"
            ;;
	"install apache + TLS + Homepage")
	   apt install apache2
	   echo "Website headline:"
	   read TEXT
	   echo "<H1>$TEXT</H1>" > /var/www/html/index.html
	   a2enmod ssl
	   systemctl restart apache2
	   /etc/init.d/apache2 restart
	   apt-get install openssl
	   mkdir /etc/apache2/ssl
	   openssl req -new -x509 -days 365 -nodes -out /etc/apache2/ssl/apache.pem -keyout /etc/apache2/ssl/apache.pem
	   chmod 600 /etc/apache2/ssl/apache.pem
	  echo “Bitte FQDN Angeben nslookup IP”
  read FQDN

cat > /etc/apache2/sites-available/ssl.conf << EOF
<VirtualHost *:443>
ServerName $FQDN
SSLEngine ON
SSLCertificateFile /etc/apache2/ssl/apache.pem
DocumentRoot /var/www/html
</VirtualHost>
EOF
  a2ensite ssl
	   /etc/init.d/apache2 restart
	   echo "done"
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done


