# sshfs-watchdog
A series of bash script to monitor and manage sshfs connections by regular users. It helps to address 2 major problems with remote file systems:
  * it automatically mounts and unmounts remote sshfs after exceeding predefined thesholds (positive / negative)
  * it brings interaction with sshfs to gui. Once connection is set there is no need to open console for it anymore.

This piece of code is for you if:
* you are going to mount remote file systems with help of sshfs
* you are ok to connect to remote side with help of user login and password (ssh keys are not supported by now)
* you are ok with storing credentials (login/password) in a gnome keychain
* your ssh server responds on ICMP pings and it is acceptable to you to check its health by pinging it

## install dependencies
Run install_prerequisites.sh to install required dependencies. You need to be root at this stage.

## setup watchdog autostart
Run sshfs-wd-create-autostart.sh to create startup shortcut for your desktop environment system. A file sshfs-wd-autostart.desktop will be created. Next time you login to DE it should be executed and all the watchdogs launched.

## create / modify a connection
Run sshfs-wd-set-connection.sh to create a connection configuration for your remote ssh server. You can modify config files manually by modifying them in your ~/.config/sshfs-wd/ folder. Please see sampleConfig.conf for more info

## delete a connection
Run sshfs-wd-remove-connection.sh <connection_name>. It will basically delete corresponding config file from ~/.config/sshfs-wd/ and delete credentials from a keyring.


