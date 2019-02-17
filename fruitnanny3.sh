cd

#basics
sudo apt-get update
sudo apt-get install vim git nano emacs libraspberrypi-dev autoconf automake libtool pkg-config alsa-base alsa-tools alsa-utils

#nodeJS
#loading tar file instead curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
cd
wget https://nodejs.org/dist/v10.15.1/node-v10.15.1-linux-armv6l.tar.xz
tar -xvf node-v10.15.1-linux-armv6l.tar.xz
cd node-v10.15.1-linux-armv6l
sudo cp -R * /usr/local/

sudo apt install -y nodejs

#enable cam 5 1
sudo raspi-config

#upgrade raspi firmware
sudo apt-get install rpi-update
sudo rpi-update

#download fruitnanny
cd /opt
sudo mkdir fruitnanny
sudo chown pi:pi fruitnanny
git clone https://github.com/ivadim/fruitnanny

#install gstreamer

sudo apt-get install gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly 
  gstreamer1.0-plugins-bad libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-alsa
  
#install janus
# install prerequisites
sudo apt-get install libmicrohttpd-dev libjansson-dev libnice-dev    libssl-dev libsrtp-dev libsofia-sip-ua-dev libglib2.0-dev    libopus-dev libogg-dev pkg-config gengetopt libsrtp2-dev
    
# get Janus sources
git clone https://github.com/meetecho/janus-gateway /tmp/janus-gateway
cd /tmp/janus-gateway
git checkout

# build binaries
sh autogen.sh
./configure --disable-websockets --disable-data-channels --disable-rabbitmq --disable-mqtt
make
make install
make configs

#copy janus configs
sudo cp /opt/fruitnanny/configuration/janus/janus.cfg usr/local/etc/janus
sudo cp /opt/fruitnanny/configuration/janus/janus.plugin.streaming.cfg usr/local/etc/janus
sudo cp /opt/fruitnanny/configuration/janus/janus.transport.http.cfg /usr/local/etc/janus

#install phyton libs
git clone https://github.com/adafruit/Adafruit_Python_DHT /tmp/Adafruit_Python_DHT
cd /tmp/Adafruit_Python_DHT
sudo apt-get install build-essential python-dev python-pip
sudo python setup.py install

#make autostarts
sudo systemctl enable audio
sudo systemctl start audio

sudo systemctl enable video
sudo systemctl start video

sudo systemctl enable janus
sudo systemctl start janus

#make autostart node server
sudo npm install pm2 -g
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u pi --hp /home/pi
pm2 save

#start fruitnanny
cd /opt/fruitnanny
npm install
pm2 start server/app.js --name="fruitnanny"

#install and configure nginx
# install nginx
sudo apt-get install nginx
# remove default site
sudo rm -f /etc/nginx/sites-enabled/default
# copy fruitnanny configs
sudo cp /opt/fruitnanny/configuration/nginx/fruitnanny_http /etc/nginx/sites-available/fruitnanny_http
sudo cp /opt/fruitnanny/configuration/nginx/fruitnanny_https /etc/nginx/sites-available/fruitnanny_https
# enable new configs
sudo ln -s /etc/nginx/sites-available/fruitnanny_http /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/fruitnanny_https /etc/nginx/sites-enabled/

#add security credintials
sudo sh -c "echo -n 'winnie:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/.htpasswd"

#finish
