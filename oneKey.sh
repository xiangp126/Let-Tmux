#!/bin/bash
# where is shell executed
startDir=`pwd`
# main work directory, not influenced by start dir
mainWd=$(cd $(dirname $0); pwd)
# common install dir for home | root mode
homeInstDir=~/.usr
rootInstDir=/usr/local
# default is home mode
commInstdir=$homeInstDir
execPrefix=""
# libevent & ncurses
libeventInstDir=$commInstdir
ncursesInstDir=$commInstdir
# dynamic env global name
dynamicEnvName=dynamic.env
# how many cpus os has, used for make -j
osCpus=1
# store all downloaded packages here
downloadPath=$mainWd/downloads
# store packages that was slow to download
pkgPath=$mainWd/packages

logo() {
    cat << "_EOF"
 _      _
| | ___| |_ _ __ ___  _   ___  __
| |/ _ \ __| '_ ` _ \| | | \ \/ /
| |  __/ |_| | | | | | |_| |>  <
|_|\___|\__|_| |_| |_|\__,_/_/\_\

_EOF
}

usage() {
    exeName=${0##*/}
    cat << _EOF
[NAME]
    $exeName -- setup tmux through one script from source

[SYNOPSIS]
    sh $exeName [home | root | help]

[EXAMPLE]
    sh $exeName
    sh $exeName home

[DESCRIPTION]
    home -- install packages into $homeInstDir/
    root -- install packages into $rootInstDir/
_EOF
    logo
}

installLibEvent() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING LIBEVENT ...
------------------------------------------------------
_EOF
    # libevent libevent - libevent is an asynchronous notification event loop library
    whereIsLibevent=`pkg-config --list-all | grep -i '^libevent\b'`
    if [[ "$whereIsLibevent" != "" ]]; then
        echo [Warning]: system already has libevent installed, omitting it ...
        return
    fi
    libeventInstDir=$commInstdir
    wgetLink=https://github.com/libevent/libevent/releases/download/release-2.1.8-stable
    tarName=libevent-2.1.8-stable.tar.gz
    untarName=libevent-2.1.8-stable

    # rename download package
    cd $downloadPath
    # check if already has this tar ball.
    if [[ -f $tarName ]]; then
        echo [Warning]: Tar Ball $tarName already exists, Omitting wget ...
    else
        wget --no-cookies \
             --no-check-certificate \
             --header "Cookie: oraclelicense=accept-securebackup-cookie" \
             "${wgetLink}/${tarName}" \
             -O $tarName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi

    if [[ ! -d $untarName ]]; then
        tar -zxv -f $tarName
    fi
    cd $untarName
    # fix env problem for openssl in MAC OS
    export CPPFLAGS=-I/usr/local/opt/openssl/include
    export LDFLAGS=-L/usr/local/opt/openssl/lib
    # end fix
    ./configure --prefix=$libeventInstDir
    make -j

    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quiting now ...
        exit
    fi
    $execPrefix make install

    cat << _EOF
------------------------------------------------------
INSTALLING LIBEVENT DONE ...
libevent path = $libeventInstDir/bin/
------------------------------------------------------
_EOF
}

installNcurses() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING NCURSES ...
------------------------------------------------------
_EOF
    # ncurses: libncurses is a new free software emulation of curses.
    whereIsNcurses=`pkg-config --list-all | grep -i '^ncurses\b'`
    if [[ "$whereIsNcurses" != "" ]]; then
        echo [Warning]: system already has ncurses installed, omitting it ...
        return
    fi

    ncursesInstDir=$commInstdir
    # wgetLink=ftp://ftp.invisible-island.net/ncurses
    tarName=ncurses.tar.gz
    untarName=ncurses-latest

    cd $downloadPath
    # check if already has this tar ball.
    # if [[ -f $tarName ]]; then
    #     echo [Warning]: Tar Ball $tarName already exists, Omitting wget ...
    # else
    #     wget --no-cookies \
    #          --no-check-certificate \
    #          --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    #          "${wgetLink}/${tarName}" \
    #          -O $tarName
    #     # check if wget returns successfully
    #     if [[ $? != 0 ]]; then
    #         echo [Error]: wget returns error, quiting now ...
    #         exit
    #     fi
    # fi

    if [[ ! -d $untarName ]]; then
        mkdir -p $untarName
        tar -zxv -f $pkgPath/$tarName --strip-components=1 -C $untarName
    fi
    cd $untarName
    # fix issue for lib_gen.c
    export CPPFLAGS="-P"
    ./configure --prefix=$ncursesInstDir --with-shared
    make -j
    # check if make returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quiting now ...
        exit
    fi
    $execPrefix make install
    cat << "_EOF"
------------------------------------------------------
GENERATING NCURSES.PC FOR PKG-CONFIG ...
------------------------------------------------------
_EOF
    # go back to mainWd to make ncurses.pc
    cd $mainWd
    ncursesPcName=ncurses.pc

    cat > $ncursesPcName << _EOF
# ncurses pkg-config source file

prefix=$ncursesInstDir
_EOF

    cat >> $ncursesPcName << "_EOF"
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include/ncurses

Name: ncurses
Description: ncurses(libncurses) is new emulation of curses.
Version: 5.9-stable
Requires:
Conflicts:
Libs: -L${libdir} -lncurses
# Libs.private: -lncurses
Cflags: -I${includedir}
_EOF
    $execPrefix cp $ncursesPcName ${ncursesInstDir}/lib/pkgconfig/
    cat << _EOF
------------------------------------------------------
INSTALLING LIBEVENT DONE ...
libevent path = $libeventInstDir/bin/
------------------------------------------------------
_EOF
}

# make file, dynamic environment
makeDynEnv() {
    cat << "_EOF"
------------------------------------------------------
GENERATING DYNAMIC ENV TXT ...
------------------------------------------------------
_EOF
    #enter into mainWd
    cd $mainWd
    envName=$dynamicEnvName
    LIBEVENT_INSTALL_DIR=$commInstdir
    # parse value of $var
    cat > $envName << _EOF
#!/bin/bash
export LIBEVENT_INSTALL_DIR=$LIBEVENT_INSTALL_DIR
export LIBEVENT_PKG_DIR=${LIBEVENT_INSTALL_DIR}/lib/pkgconfig
_EOF
    # do not parse value of $var
    cat >> $envName << "_EOF"
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${LIBEVENT_INSTALL_DIR}/lib
export PKG_CONFIG_PATH=${LIBEVENT_PKG_DIR}:$PKG_CONFIG_PATH
_EOF
    chmod +x $envName
    cd - &> /dev/null
    # as return value of this func
}

installTmux() {
    # make dynamic env before source it.
    makeDynEnv
    # source dynamic.env first
    source $mainWd/$dynamicEnvName

    cat << "_EOF"
------------------------------------------------------
INSTALLING TMUX ...
------------------------------------------------------
_EOF
    tmuxInstDir=$commInstdir
    $execPrefix mkdir -p $tmuxInstDir
    # comm attribute for getting source tmux
    repoLink=https://github.com/tmux
    repoName=tmux

    cd $downloadPath
    # check if already has this tar ball.
    if [[ -d $repoName ]]; then
        echo [Warning]: Github repository $repoName already exists, Omitting clone ...
    else
        git clone $repoLink/$repoName
        # check if wget returns successfully
        if [[ $? != 0 ]]; then
            echo [Error]: git clone returns error, quiting now ...
            exit
        fi
    fi

    cd $repoName
    # checkout to latest released tag
    git pull
    latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    if [[ "$latestTag" != "" ]]; then
        git checkout $latestTag
    fi

    # fix issue
    # tmux -V for tag 2.7 shows master, which not compatible with tmux-resurrect
    # so go back to version 2.6. Seems beed fixed after 2018/05/03
    git checkout 2.6

    # begin to build
    sh autogen.sh
    # check if autogen returns successfully
    if [[ $? != 0 ]]; then
        echo [Error]: install automake first, quiting now ...
        exit
    fi
    ./configure --prefix=$tmuxInstDir
    make -j

    if [[ $? != 0 ]]; then
        echo [Error]: make returns error, quiting now ...
        exit
    fi
    $execPrefix make install
    if [[ $? != 0 ]]; then
        echo [Error]: make install returns error, quiting now ...
        exit
    fi

    cat << _EOF
------------------------------------------------------
INSTALLING TMUX DONE ...
tmux -V = `$tmuxInstDir/bin/tmux -V`
tmux path = $tmuxInstDir/bin/
dynamic env txt = $dynamicEnvName
------------------------------------------------------
_EOF
}

installTPM() {
    cat << "_EOF"
------------------------------------------------------
INSTALLING MANAGER FOR TMUX PLUGINS
------------------------------------------------------
_EOF
    cd $mainWd
    tmuxConfPath=$HOME/.tmux.conf
    tmuxConfTempPath=./template/tmux.conf
    if [[ ! -f "$tmuxConfPath" ]]; then
        cp $tmuxConfTempPath $tmuxConfPath
        if [[ $? != 0 ]]; then
            echo [Error]: cp tmux config error, quiting now ...
            exit
        fi
    fi

    gitClonePath=https://github.com/tmux-plugins/tpm
    clonedName=$HOME/.tmux/plugins/tpm
    # check if target directory already exists
    if [[ -d $clonedName ]]; then
        echo [Warning]: target $clonedName already exists
    else
        git clone $gitClonePath $clonedName
        # check if git returns successfully
        if [[ $? != 0 ]]; then
            echo "[Error]: git returns error, quitting now "
            exit
        fi
    fi
    tmuxInstallScript=$HOME/.tmux/plugins/tpm/bin/install_plugins
    if [[ -f $tmuxInstallScript ]]; then
        sh -x $tmuxInstallScript
    fi
}

installSummary() {
    cat << _EOF
------------------------------------------------- Summary -----
# export key variables if needed
export PKG_CONFIG_PATH=$HOME/.usr/lib/pkgconfig:/usr/local/lib/pkgconfig
export LD_LIBRARY_PATH=$HOME/.usr/lib:$HOME/.usr/lib64:/usr/local/lib:/usr/local/lib64
---------------------------------------------------------------
_EOF
}

install() {
    mkdir -p $downloadPath
    installLibEvent
    installNcurses
    installTmux
    # always install tmux plugin manager
    if [[ 1 == 1 || "$execPrefix" != "sudo" ]]; then
        installTPM
    fi
    installSummary
}

fixDepends() {
    arch=$(uname -s)
    case $arch in
        Darwin)
            # echo "Platform is MacOS"
            platOsType=macos
            ;;
        Linux)
            linuxType=`sed -n '1p' /etc/issue | tr -s " " | cut -d " " -f 1`
            if [[ "$linuxType" == "Ubuntu" ]]; then
                # echo "Platform is Ubuntu"
                platOsType=ubuntu
                sudo apt-get install libevent-dev libncurses5 libncurses5-dev \
                    libncursesw5 libncursesw5-dev -y
            elif [[ "$linuxType" == "CentOS" || "$linuxType" == "\S" || "$linuxType" == "Red" ]]; then
                # echo "Platform is CentOS" \S => CentOS 7
                platOsType=centos
                sudo yum install libevent-devel ncurses* --skip-broken -y
            else
                echo "Sorry, We did not support your platform, pls check it first"
                exit
            fi
            ;;
        *)
            cat << "_EOF"
------------------------------------------------------
WE ONLY SUPPORT LINUX AND MACOS SO FAR
------------------------------------------------------
_EOF
            exit
            ;;
    esac
}

case $1 in
    'home')
        set -x
        commInstdir=$homeInstDir
        execPrefix=""
        install
        ;;

    'root')
        set -x
        fixDepends
        commInstdir=$rootInstDir
        execPrefix=sudo
        install
        ;;

    *)
        set +x
        usage
        ;;
esac
