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
    untarName=libevent-2.1.8-stable

> wget ncurses.tar.gz
> tar -zxv -f ncurses.tar.gz
> ./configure --prefix=/home/pi/.usr/
# you'd better just use 'make', not 'make -j' for the first time you compile.
# Or it'll end up with err: undefined reference to `leaveok'
> make 
> make install



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

makeTecEnv() {
    # enter into dir first
    cd $startDir
    envName=dynamic.env
    TOMCAT_HOME=${tomcatInstDir}
    CATALINA_HOME=$TOMCAT_HOME

    # parse value of $var
    cat > $envName << _EOF
#!/bin/bash
export COMMON_INSTALL_DIR=$commInstdir
export JAVA_HOME=${javaInstDir}
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export TOMCAT_USER=${tomcatUser}
export TOMCAT_HOME=${TOMCAT_HOME}
export CATALINA_HOME=${TOMCAT_HOME}
export CATALINA_BASE=${TOMCAT_HOME}
export CATALINA_TMPDIR=${TOMCAT_HOME}/temp
export OPENGROK_INSTANCE_BASE=${opengrokInstanceBase}
export OPENGROK_TOMCAT_BASE=$CATALINA_HOME
_EOF

    # do not parse value of $var
    cat >> $envName << "_EOF"
export PATH=${COMMON_INSTALL_DIR}/bin:${JAVA_HOME}/bin:$PATH
_EOF

    chmod +x $envName
    cd - &> /dev/null
    # as return value of this func
    echo $envName
}

# deploy OpenGrok
installOpenGrok() {
    cat << "_EOF"
    
------------------------------------------------------
STEP 4: INSTALLING OPENGROK ...
------------------------------------------------------
_EOF

    wgetLink="https://github.com/oracle/opengrok/releases/download/1.1-rc18"
    tarName="opengrok-1.1-rc18.tar.gz"
    untarName="opengrok-1.1-rc18"

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
            echo [Error]: wget returns error, quiting now ...
            exit
        fi
    fi
    tar -zxv -f $tarName 

    echo ------------------------------------------------------
    echo BEGIN TO MAKE ENV FILE FOR SOURCE ...
    echo ------------------------------------------------------
    # env name is the return value of func makeTecEnv
    makeTecEnv
    envName=$dynamicEnvName

    # source ./$envName
    # enter into opengrok dir
    cd $untarName/bin
    chmod +w OpenGrok

    # add source command at top of script OpenGrok
    sed -i "2a source ${startDir}/${envName}" OpenGrok
    ln -sf "`pwd`"/OpenGrok ${commInstdir}/bin/openGrok 
    # and then can run deploy well
    sudo ./OpenGrok deploy

    cd - &> /dev/null

    cat << "_EOF"
    
------------------------------------------------------
STEP 4: INSTALLING OPENGROK DONE ...
------------------------------------------------------
_EOF
}

summaryInstall() {
    set +x
    logo

    cat << _EOF

******************************************************
*                  UNIVERSAL CTAGS                   *
******************************************************
_EOF
echo export PATH=${commInstdir}:'$PATH'

    cat << _EOF

******************************************************
*                  JAVA JAVA JAVA 8                  *
******************************************************

******************************************************
*                  TOMCAT TOMCAT 8                   *
******************************************************
# start tomcat
sudo sh ./daemon.sh run &> /dev/null &
# stop tomcat
sudo sh ./daemon.sh stop

******************************************************
*                  OPENGROK 1.1-RC18                 *
******************************************************
# deploy OpenGrok
sudo sh ./OpenGrok deploy
# make index of source
sudo sh ./OpenGrok index /usr/local/src/coreutils-8.21
------------------------------------------------------

_EOF
}

install() {
    installLibEvent
    installNcurses
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
