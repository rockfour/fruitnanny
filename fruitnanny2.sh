#2
# install basic software
sudo apt-get update
sudo apt-get install vim git nano emacs libraspberrypi-dev autoconf automake libtool pkg-config alsa-base alsa-tools alsa-utils

#install nodejs
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -sudo apt install -y nodejs
#downloading tar file instead
cd
wget https://nodejs.org/dist/v10.15.1/node-v10.15.1-linux-armv6l.tar.xz
tar -xvf node-v10.15.1-linux-armv6l.tar.xz
cd node-v10.15.1-linux-armv6l
sudo cp -R * /usr/local/
sudo apt install -y nodejs

#cam config
sudo raspi-config

#upgrade raspberry firmware
sudo apt-get install rpi-update
sudo rpi-update

#setup wifi
sudo iw dev wlan0 set power_save off
#add line to interfaces
sudo nano /etc/network/interfaces
#add "wireless-power off"

#local access
sudo apt-get install avahi-daemon

#3
#download fruitnanny
cd /opt
sudo mkdir fruitnanny
sudo chown pi:pi fruitnanny
git clone https://github.com/ivadim/fruitnanny

#4
#audio video pipes
sudo apt-get install gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-alsa

#build  gstreamer plugin for rpicam
git clone https://github.com/thaytan/gst-rpicamsrc /tmp/gst-rpicamsrc
cd /tmp/gst-rpicamsrc
./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/
make
sudo make install
sudo make configs

#5 janus
# install prerequisites
sudo apt-get install libmicrohttpd-dev libjansson-dev libnice-dev \
    libssl-dev libsrtp-dev libsofia-sip-ua-dev libglib2.0-dev \
    libopus-dev libogg-dev pkg-config gengetopt libsrtp2-dev
    
# get Janus sources
git clone https://github.com/meetecho/janus-gateway /tmp/janus-gateway
cd /tmp/janus-gateway
git checkout v0.2.5

# build binaries
sh autogen.sh
./configure --disable-websockets --disable-data-channels --disable-rabbitmq --disable-mqtt
make
sudo make install
sudo make configs

#copy config files
sudo cp /opt/fruitnanny/configuration/janus/janus.cfg /usr/local/etc/janus
sudo cp /opt/fruitnanny/configuration/janus/janus.plugin.streaming.cfg /usr/local/etc/janus
sudo cp /opt/fruitnanny/configuration/janus/janus.transport.http.cfg /usr/local/etc/janus

#create ssl certs for janus and nignx
cd /usr/local/share/janus/certs
sudo openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
  -keyout mycert.key -out mycert.pem
  
#autostart everything
sudo cp /opt/fruitnanny/configuration/systemd/audio.service /etc/systemd/system/
sudo cp /opt/fruitnanny/configuration/systemd/video.service /etc/systemd/system/
sudo cp /opt/fruitnanny/configuration/systemd/janus.service /etc/systemd/system/
sudo cp /opt/fruitnanny/configuration/systemd/fruitnanny.service /etc/systemd/system/

#start everything
sudo systemctl enable audio
sudo systemctl start audio

sudo systemctl enable video
sudo systemctl start video

sudo systemctl enable janus
sudo systemctl start janus

sudo systemctl enable fruitnanny
sudo systemctl start fruitnanny

#install nginx

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

#add authentication
sudo sh -c "echo -n 'fruitnanny:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/.htpasswd"

#finish
