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
    echo "syntax: $0 enable | disable"
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

writeCfg() {
# write contents to config file.
cat << EOF > $1
# config
# Should be placed at ~/.ssh/config, make it if not exist. 
# or you should edit line at /etc/ssh/ssh_config
# 49 #   ProxyCommand ssh -q -W %h:%p gateway.example.com
Host *
    ProxyCommand netcat -x 127.0.0.1:8080 %h %p
EOF
}

disable() {
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

enable() {
    if [ -f ${cfgFilePath} ]; then
        echo "Found $cfgFile file, backup $cfgFile to ${cfgFile}.bak"
        cd ~/.ssh
        echo mv $cfgFile ${cfgFile}.bak
        mv $cfgFile ${cfgFile}.bak
        cd - &>/dev/null
        echo Backup Done!
    fi

    # pass parameter to the self-defined function.
    echo Writing Contents to config: $cfgFilePath
    writeCfg $cfgFilePath
    
    echo "cat ~/.ssh/$cfgFile"
    echo "--------------------------------------------------"
    cat ~/.ssh/$cfgFile
}

case $1 in
    'enable')
        enable
    ;;

    'disable')
        disable
    ;;
esac;

