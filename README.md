# sshfs-watchdog
A series of bash script to monitor and manage sshfs connections by regular users

This piece of code is for you if:
* you are going to mount remote file systems with help of sshfs
* you are ok to connect to remote side with help of user login and password (ssh keys are not supported by now)
* you are ok with storing credentials (login/password) in a gnome keychain

## setup watchdog autostart
Run sshfs-wd-create-autostart.sh to create startup shortcut for your desktop environment system. A file sshfs-wd-autostart.desktop will be created. Next time you login to DE it should be executed and all the watchdogs launched.

## create / modify a connection
Run sshfs-wd-set-connection.sh to create a connection configuration for your remote ssh server. You can modify config files manually by modifying them in your ~/.config/sshfs-wd/ folder. Please see sampleConfig.conf for more info

## 
