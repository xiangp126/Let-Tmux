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

logo() {
    cat << "_EOF"
 _____ __  __ _   ___  __
|_   _|  \/  | | | \ \/ /
  | | | |\/| | | | |\  /
  | | | |  | | |_| |/  \
  |_| |_|  |_|\___//_/\_\

_EOF
}

usage() {
    exeName=${0##*/}
    cat << _EOF
[NAME]
    $exeName -- setup Tmux through one script

[USAGE]
    sh $exeName [home | root | help]

[DESCRIPTION]
    home -- install to $homeInstDir/
    root -- install to $rootInstDir/
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
    wgetLink=ftp://ftp.invisible-island.net/ncurses
    tarName=ncurses.tar.gz
    untarName=ncurses-latest

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
        mkdir -p $untarName
        tar -zxv -f $tarName --strip-components=1 -C $untarName
    fi
    cd $untarName
    # fix issue for lib_gen.c
    export CPPFLAGS="-P"
    ./configure --prefix=$ncursesInstDir
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
    cat << "_EOF"
------------------------------------------------------
INSTALLING TMUX ...
------------------------------------------------------
_EOF
    # make dynamic env before source it.
    makeDynEnv
    # source dynamic.env first
    source $mainWd/$dynamicEnvName

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

    cat << _EOF
------------------------------------------------------
INSTALLING TMUX DONE ...
tmux -V = `$tmuxInstDir/bin/tmux -V`
tmux path = $tmuxInstDir/bin/
dynamic env txt = $dynamicEnvName
------------------------------------------------------
_EOF
}

install() {
    mkdir -p $downloadPath
    installLibEvent
    installNcurses
    installTmux
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
        commInstdir=$rootInstDir
        execPrefix=sudo
        install
        ;;

    *)
        set +x
        usage
        ;;
esac
