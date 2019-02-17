sudo apt-get update
sudo apt-get upgrade

# Basic software
sudo apt-get install vim git libraspberrypi-dev autoconf automake libtool pkg-config alsa-base alsa-tools alsa-utils

# Nodejs
#curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
#downloading tar file instead
cd
wget https://nodejs.org/dist/v10.15.1/node-v10.15.1-linux-armv6l.tar.xz
tar -xvf node-v10.15.1-linux-armv6l.tar.xz
cd node-v10.15.1-linux-armv6l
sudo cp -R * /usr/local/
sudo apt install -y nodejs

# Install process manager for nodejs
sudo npm install pm2 -g
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u pi --hp /home/pi
pm2 save

# Enable Camera
sudo raspi-config

# Update rpi firmware
sudo apt-get install rpi-update
sudo rpi-update

# Turn off wireless-power
sudo iw dev wlan0 set power_save off
#doing this manually, add this line to this file
#vim /etc/network/interfaces
#wireless-power off

# Enable raspberrypi.local
sudo apt-get install avahi-daemon

# Setup Audio & Video
sudo apt-get install gstreamer1.0-tools gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-plugins-bad libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev gstreamer1.0-alsa

# Install gstreamer plugin for rpi camera module
git clone https://github.com/thaytan/gst-rpicamsrc /tmp/gst-rpicamsrc
cd /tmp/gst-rpicamsrc
./autogen.sh --prefix=/usr --libdir=/usr/lib/arm-linux-gnueabihf/
make
sudo make install

# Download fruitnanny source code
cd /opt
sudo mkdir fruitnanny
sudo chown pi:pi fruitnanny
git clone https://github.com/ivadim/fruitnanny
npm install
pm2 start server/app.js --name="fruitnanny"

# Install libsrtp
sudo apt-get install libmicrohttpd-dev libjansson-dev libnice-dev \
    libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
    libopus-dev libogg-dev pkg-config gengetopt
wget https://github.com/cisco/libsrtp/archive/v2.1.0.tar.gz
tar xfv v2.1.0.tar.gz
cd libsrtp-2.1.0
./configure --prefix=/usr --enable-openssl
make shared_library && sudo make install


# Install janus
git clone https://github.com/meetecho/janus-gateway /tmp/janus-gateway
cd /tmp/janus-gateway
git checkout v0.2.6
sh autogen.sh
./configure --disable-websockets --disable-data-channels --disable-rabbitmq --disable-mqtt
make
sudo make install
sudo make configs

# Configure janus
sudo cp /opt/fruitnanny/configuration/janus/janus.cfg /usr/local/etc/janus
sudo cp /opt/fruitnanny/configuration/janus/janus.plugin.streaming.cfg /usr/local/etc/janus
sudo cp /opt/fruitnanny/configuration/janus/janus.transport.http.cfg /usr/local/etc/janus

# Install nginx
sudo apt-get install nginx

sudo rm -f /etc/nginx/sites-enabled/default

sudo cp /opt/fruitnanny/configuration/nginx/fruitnanny_http /etc/nginx/sites-available/fruitnanny_http
sudo cp /opt/fruitnanny/configuration/nginx/fruitnanny_https /etc/nginx/sites-available/fruitnanny_https

sudo ln -s /etc/nginx/sites-available/fruitnanny_http /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/fruitnanny_https /etc/nginx/sites-enabled/

# Enable basic auth
sudo sh -c "echo -n 'fruitnanny:' >> /etc/nginx/.htpasswd"
sudo sh -c "openssl passwd -apr1 >> /etc/nginx/.htpasswd"

# Create cert for janus
cd /usr/local/share/janus/certs
sudo openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
  -keyout mycert.key -out mycert.pem

# Enable service
sudo cp /opt/fruitnanny/configuration/systemd/audio.service /etc/systemd/system/
sudo cp /opt/fruitnanny/configuration/systemd/video.service /etc/systemd/system/
sudo cp /opt/fruitnanny/configuration/systemd/janus.service /etc/systemd/system/

sudo systemctl enable audio
sudo systemctl start audio

sudo systemctl enable video
sudo systemctl start video

sudo systemctl enable janus
sudo systemctl start janus
