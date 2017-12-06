#!/bin/bash

#set -x
usage() {
    echo "git push using proxy, proxy socks5://127.0.0.0:8080 through SSH reverse tunnel."
    echo "ssh -vv -ND 8080 -l login_name midman_server"
    echo "syntax: $0 enable | disable"
}

proxyAddr="socks5://127.0.0.1:8080"

if [ $# -le 0 ]; then
    usage
    exit
fi

case $1 in
    'enable')
        echo "start enabling http.proxy ..."
        git config --global http.proxy ${proxyAddr}
        echo "start enabling https.proxy ..."
        git config --global https.proxy ${proxyAddr}
    ;;

    'disable')
        echo "start disabling http.proxy ..."
        git config --global --unset http.proxy
        echo "start disabling https.proxy ..."
        git config --global --unset https.proxy
    ;;
esac;

echo "using 'git config --global -l' to see if changed correctly."

