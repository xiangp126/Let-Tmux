#!/bin/bash
set -x

# this shell start dir, normally original path
startDir=`pwd`
# main work directory, usually ~/myGit
mainWd=$startDir

# common install directory
commInstdir=~/.usr
libeventInstDir=$commInstdir
ncursesInstDir=$commInstdir
# dynamic env global name
dynamicEnvName=dynamic.env
# make installation directory
mkdir -p $commInstdir

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
	$exeName [install | help]

_EOF
	logo
}

installLibEvent() {
    
    cat << "_EOF"
    
------------------------------------------------------
STEP 1: INSTALLING LIBEVENT ...
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
    cd $startDir
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
            echo [Error]: wget returns error, quiting now ...            exit
        fi
    fi

    tar -zxv -f libevent-2.1.8-stable.tar.gz
    cd $untarName
    # fix env problem for openssl in MAC OS
    export CPPFLAGS=-I/usr/local/opt/openssl/include
    export LDFLAGS=-L/usr/local/opt/openssl/lib
    # end fix
    ./configure --prefix=$libeventInstDir
    make -j
    make install

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
STEP 2: INSTALLING NCURSES ...
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
    untarName=ncurses-5.9

    # rename download package
    cd $startDir
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
            echo [Error]: wget returns error, quiting now ...            exit
        fi
    fi

    tar -zxv -f $tarName
    cd $untarName
    ./configure --prefix=$ncursesInstDir
    make -j
    make install

    # go back to start dir to make ncurses.pc
    cd $startDir
    ncursesPcName=ncurses.pc
    echo Making $ncursesPcName to due path ...

    cat > $ncursesPcName << _EOF
#ncurses pkg-config source file

prefix=$ncursesInstDir
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

    echo Copying $ncursesPcName to due path ...
    cp $ncursesPcName ${ncursesInstDir}/lib/pkgconfig/

    cat << _EOF
    
------------------------------------------------------
INSTALLING LIBEVENT DONE ...
libevent path = $libeventInstDir/bin/
------------------------------------------------------
_EOF
}

# make file, dynamic environment
makeDynEnv() {
    # enter into dir first
    cd $startDir
    envName=$dynamicEnvName
    # delete it if exists
    rm -rf $envName

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
STEP 3: INSTALLING TMUX ...
------------------------------------------------------
_EOF
    # make dynamic env before source it.
    makeDynEnv
    # source dynamic.env first
    source ${startDir}/$dynamicEnvName
    tmuxInstDir=$commInstdir
    repoLink=https://github.com/tmux
    repoName=tmux

    cd $startDir
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

    # master -> v2.6
    checkoutVersion=2.6
    cd $repoName
    git checkout $checkoutVersion
    sh autogen.sh
    ./configure --prefix=$tmuxInstDir
    make -j
    make install

    cat << _EOF
    
------------------------------------------------------
INSTALLING TMUX DONE ...
tmux -V = `$tmuxInstDir/bin/tmux -V`
tmux path = $tmuxInstDir/bin/
------------------------------------------------------
_EOF
}

install() {
    installLibEvent
    installNcurses
    makeDynEnv
    installTmux
}

case $1 in
    'install')
        install
    ;;

    *)
        set +x
        usage
    ;;
esac
