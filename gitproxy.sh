#!/bin/bash
# config
# Should be placed at ~/.ssh/config, make it if not exist. 
# or you should edit line at /etc/ssh/ssh_config
# 49 #   ProxyCommand ssh -q -W %h:%p gateway.example.com
# Host *
#   ProxyCommand netcat -x 127.0.0.1:8080 %h %p

usage() {
    echo "git push using proxy, proxy socks5://127.0.0.0:8080 through SSH reverse tunnel."
    echo "pls ensure first: ssh -vv -ND 8080 -l [logName] [midmanServer]"
    echo "syntax: $0 install | uninstall"
}

# proxycommand use by ssh command.
pxyCmd='netcat -x 127.0.0.1:8080 %h %p'

if [ $# -le 0 ]; then
    usage
    exit
fi

# config file name.
cfgFile=config
cfgFilePath=~/.ssh/$cfgFile

uninstall() {
    if [ -f $cfgFilePath ]; then
        echo "Found $cfgFile file, Moving $cfgFile to ${cfgFile}.bak"
        cd ~/.ssh
        mv $cfgFile ${cfgFile}.bak
        cd - &>/dev/null
        echo Move Done!
    else 
        echo "Already has no $cfgFilePath, Quiting Now ..."
        exit
    fi
}

install() {
    if [ -f ${cfgFilePath} ]; then
        echo "Found $cfgFile file, backup $cfgFile to ${cfgFile}.bak"
        cd ~/.ssh
        echo mv $cfgFile ${cfgFile}.bak
        mv $cfgFile ${cfgFile}.bak
        cd - &>/dev/null
        echo Backup Done!
    fi
    # writing comments part to config.
    echo writing comments part to config ...
    echo "# config"                                                   >> $cfgFilePath
    echo "# Should be placed at ~/.ssh/config, make it if not exist." >> $cfgFilePath
    echo "# or you should edit line at /etc/ssh/ssh_config."          >> $cfgFilePath
    echo "# 49 #   ProxyCommand ssh -q -W %h:%p gateway.example.com." >> $cfgFilePath
    
    # writing main part to config
    echo writing main part to config ...
    echo "Host *"                                                   >> $cfgFilePath
    echo "  ProxyCommand netcat -x 127.0.0.1:8080 %h %p"            >> $cfgFilePath
    
    echo "cat ~/.ssh/$cfgFile"
    cat ~/.ssh/$cfgFile
}

case $1 in
    'install')
        install
    ;;

    'uninstall')
        uninstall
    ;;
esac;

