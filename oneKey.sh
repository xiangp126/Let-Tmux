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

    libeventNeedCompile=true
    # libevent libevent - libevent is an asynchronous notification event loop library
   whereIsLibevent=`pkg-config --list-all | grep -i '^libevent\b'` 
   if [[ "$whereIsLibevent" != "" ]]; then
       echo [Warning]: system already has libevent installed, omitting it ...
       libeventNeedCompile=false
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
STEP 1: INSTALLING NCURSES ...
------------------------------------------------------

_EOF
    ncursesInstDir=$commInstdir
    wgetLink=ftp://ftp.invisible-island.net/ncurses
    tarName=ncurses.tar.gz
    untarName=

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
