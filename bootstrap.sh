# Google Chrome sources
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'

# Sync Ubuntu packages
sudo apt-get update

# Install dependencies
sudo apt-get install -y xvfb git curl default-jre openjdk-7-jre google-chrome-stable firefox php5 php5-curl phantomjs

# Set vagrant user as owner over his home folder
sudo chown vagrant:vagrant -R /home/vagrant

# Setup autologin as the default vagrant user. @see http://ubuntuforums.org/showthread.php?t=2296757
# @fixme change this touch/chown/echo pattern to sed or a shorter version without setting chown
sudo touch /etc/systemd/system/getty.target.wants/getty\@tty1.service
sudo chown vagrant:vagrant /etc/systemd/system/getty.target.wants/getty\@tty1.service
echo -e "[Unit]\nDescription=Getty on %I\nDocumentation=man:agetty(8) man:systemd-getty-generator(8)\nDocumentation=http://0pointer.de/blog/projects/serial-console.html\nAfter=systemd-user-sessions.service plymouth-quit-wait.service\nAfter=rc-local.service\n# If additional gettys are spawned during boot then we should make\n# sure that this is synchronized before getty.target, even though\n# getty.target didn't actually pull it in.\nBefore=getty.target\nIgnoreOnIsolate=yes\n# On systems without virtual consoles, don't start any getty. Note\n# that serial gettys are covered by serial-getty@.service, not this\n# unit.\nConditionPathExists=/dev/tty0\n[Service]\n# the VT is cleared by TTYVTDisallocate\nExecStart=-/sbin/agetty --autologin vagrant --noclear %I 38400 linux\nType=idle\nRestart=always\nRestartSec=0\nUtmpIdentifier=%I\nTTYPath=/dev/%I\nTTYReset=yes\nTTYVHangup=yes\nTTYVTDisallocate=yes\nKillMode=process\nIgnoreSIGPIPE=no\nSendSIGHUP=yes\n# Unset locale for the console getty since the console has problems\n# displaying some internationalized messages.\nEnvironment=LANG= LANGUAGE= LC_CTYPE= LC_NUMERIC= LC_TIME= LC_COLLATE= LC_MONETARY= LC_MESSAGES= LC_PAPER= LC_NAME= LC_ADDRESS= LC_TELEPHONE= LC_MEASUREMENT= LC_IDENTIFICATION=\n[Install]\nWantedBy=getty.target\nDefaultInstance=tty1\n" > /etc/systemd/system/getty.target.wants/getty\@tty1.service

# allow vagrant to login without a password confirmation
sudo usermod -a -G nopasswdlogin vagrant

# install openbox. tried with xfce4, gnome-shell and i3 but couldn't get the session to start
sudo apt-get install -y xinit openbox lightdm xterm

# set default x sesion. This step will set the autologin user (as with getty service) and set the default session (as with bash_profile). @todo check for redundancy
# @see http://askubuntu.com/questions/51086/how-do-i-enable-auto-login-in-lightdm/51087#51087
# @fixme change this touch/chown/echo pattern to sudo sh -c echo or a shorter version without setting chown
sudo touch /etc/lightdm/lightdm.conf
sudo chown vagrant:vagrant /etc/lightdm/lightdm.conf
echo -e "[SeatDefaults]\nuser-session=openbox\nautologin-user-timeout=0\nautologin-user=vagrant\ngreeter-session=lightdm-gtk-greeter" > /etc/lightdm/lightdm.conf

# @fixme change this touch/chown/echo pattern to sudo sh -c echo or a shorter version without setting chown
sudo touch /home/vagrant/.xinitrc
sudo chown vagrant:vagrant /home/vagrant/.xinitrc
echo -e "openbox" > /home/vagrant/.xinitrc

# run virtual X server
export DISPLAY=:99.0
/sbin/start-stop-daemon --start --quiet --pidfile /tmp/custom_xvfb_99.pid --make-pidfile --background --exec /usr/bin/Xvfb -- :99 -ac -screen 0 1280x1024x16

# Assure that SSH Agent is running (used to add keys to the known_hosts in ~/.ssh)
eval `ssh-agent -s`

# Get phpunit-selenium-env repo
git clone https://github.com/bogdananton/Selenium-Setup
cd Selenium-Setup

# prepare build
wget https://getcomposer.org/composer.phar
php composer.phar update
php bin/selenium-setup.php start
