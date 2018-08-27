## Illustrate
- This project aims to deploy tmux from source on Linux server by just one command
    - automatically generating dynamic env, no extra action need
    - [Giggle](https://github.com/xiangp126/Giggle) may call this repo to install tmux if needed
- Incremental install supported, safe to run consecutive times
- Two modes deploy selection

Mode Name | Annotate | Package Install Loc
:--- | :--- | :---
home mode | has root privilege | $HOME/.usr
root mode | has not root privilege | /usr/local


> Has checked on Ubuntu、CentOS, and brew install preferred on Mac

- [x] Ubuntu
- [x] CentOS
- [x] MacOs

> Current released version: *_2.6_*

## Contents
- [Quick Start](#start)
- [Compile libevent](#libevent)
    - [What is pkg-config?](#pkgconfig)
    - [What is pkg-config file?](#pcfile)
- [Compile ncurses](#ncurses)
    - [PKG_CONFIG_PATH for libevent](#pkgconfigpath)
    - [ncurses.pc for ncurses](#ncursespc)
- [Compile tmux](#tmux)
    - [LD_LIBRARY_PATH for libevent](#ldlibrarypath)
    - [env var for tmux](#envfortmux)
- [License](#license)

<a id = start></a>
## Quick Start
``` bash
sh oneKey.sh

[NAME]
    oneKey.sh -- setup tmux through one script from source

[SYNOPSIS]
    sh oneKey.sh [home | root | help]

[EXAMPLE]
    sh oneKey.sh
    sh oneKey.sh home

[DESCRIPTION]
    home -- install packages into $HOME/.usr/
    root -- install packages into /usr/local/
                          _
  ___ ___  _ __ ___  __ _(_)_ __
 / __/ _ \| '__/ __|/ _` | | '__|
| (_| (_) | |  \__ \ (_| | | |
 \___\___/|_|  |___/\__,_|_|_|

```
``` bash
sh oneKey.sh home
```
<a id = libevent></a>
## Compile libevent
> tmux needs libevent 2.x support, missing probility: % % %

``` bash
cd ~/.mytarball
wget https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
tar -zxv -f libevent-2.1.8-stable.tar.gz
cd libevent-2.1.8-stable
./configure --prefix=/home/pi/.usr/
make -j
make install
```
<a id = pkgconfig></a>
### what is pkg-config ?
> pkg-config is used in ./configure. used for founding environment variables for specified packages.

```bash
# for example
which pkg-config
/usr/bin/pkg-config

pwd
/home/pi/.usr/lib/pkgconfig
ll libevent.pc
-rw-r--r-- 1 pi pi 344 Dec 11 14:27 libevent.pc

# after PKG_CONFIG_PATH configured for current dir
# below commands can be excuted everywhere.
# only match the full name of the .pc file exclude the .pc postfix.
pkg-config --libs libevent.pc
-L/home/pi/.usr/lib -levent

pkg-config --cflags libevent.pc
-I/home/pi/.usr/include

pkg-config --libs --static --cflags libevent.pc
-I/home/pi/.usr/include  -L/home/pi/.usr/lib -levent -lcrypto -lrt

pkg-config --list-all
```

<a id = pcfile></a>
### what is .pc file ?
``` bash
pwd
/home/pi/.usr/lib/pkgconfig
# libevent.pc, exists after 'make install' in procedure 'compile libevent' under this dir.
cat libevent.pc
```
```bash
#libevent pkg-config source file

prefix=/home/pi/.usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: libevent
Description: libevent is an asynchronous notification event loop library
Version: 2.1.8-stable
Requires:
Conflicts:
Libs: -L${libdir} -levent
Libs.private: -lcrypto -lrt
Cflags: -I${includedir}

---------------------------------------------------------
ncurses did not generate .pc file after 'make'
so you have to add one as libevent.pc.
---------------------------------------------------------
```

<a id = ncurses></a>
## Compile ncurses
> tmux dependes on ncurses, missing probility: %<br>
> There is little chance missing ncurses for the platform, though self-compile it is a little complex.

```bash
apt-cache search ncurses5-dev
libncurses5-dev - developer's libraries for ncurses
----------------------------------------------------

cd ~/.mytarball
wget ftp://ftp.invisible-island.net/ncurses/ncurses.tar.gz
tar -zxv -f ncurses.tar.gz
./configure --prefix=/home/pi/.usr/
# you'd better just use 'make', not 'make -j' for the first time you compile.
# Or it'll end up with err: undefined reference to `leaveok'
make
make install
```

<a id = pkgconfigpath></a>
### set PKG_CONFIG_PATH for libevent
> must set this env first, or ./configure of tmux will not find libevent or ncurses.

``` bash
export PKG_CONFIG_PATH=/home/pi/.usr/lib/pkgconfig/:$PKG_CONFIG_PATH
```

<a id = ncursespc></a>
### make one ncurses.pc for ncurses packages
> packages ncurses-5.9 tar.gz, after 'make' had not generated *.pc files at all.<br>
> so for Tmux use, one must add such a file by himself. Use ncurses-config to determine what is needed.

```bash
pwd
/home/pi/.usr/bin
./ncurses5-config --libs
-L/home/pi/.usr/lib -lncurses
./ncurses5-config --includedir
home/pi/.usr/include

cat ncurses.pc
```
```bash
#ncurses pkg-config source file

prefix=/home/pi/.usr
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include/ncurses

Name: ncurses
Description: libncurses is a new free software emulation of curses.
Version: 5.9-stable
Requires:
Conflicts:
Libs: -L${libdir} -lncurses
# Libs.private: -lncurses
Cflags: -I${includedir}
```

> The name of the pc file must match what is used for checking in **`configure file`** of tmux. If not, ./configure of tmux will not detect the existence of the pc file.<br>
> By searching the log of `sh -x confgure --prefix=/home/pi/.usr &> pkg_config.log`
we found it used **ncurses** or **ncursesw** for detection, not libncurses assumed at first.

```bash
sh -x confgure --prefix=/home/pi/.usr &> pkg_config.log
vim pkg_config.log
# partial of pkg_config.log

++ /usr/bin/pkg-config --libs ncurses
+ pkg_cv_LIBNCURSES_LIBS='-L/home/pi/.usr/lib -lncurses  '
+ test x0 '!=' x0
+ test no = yes
+ test no = untried
+ LIBNCURSES_CFLAGS='-I/home/pi/.usr/include/ncurses  '
+ LIBNCURSES_LIBS='-L/home/pi/.usr/lib -lncurses  '
+ printf '%s\n' 'configure:5622: result: yes'
+ printf '%s\n' yes
yes
+ found_ncurses=yes
+ test xyes = xno
+ test xyes = xyes

......

We see it used '++ /usr/bin/pkg-config --libs ncurses'
so we name this pc file ncurses.pc, not libncurses.pc.
```

<a id = tmux></a>
## Compile tmux
``` bash
cd ~/.mytarball
git clone https://github.com/tmux/tmux
cd tmux
# checkout to latest stable version. default it was on master branch.
git tag
2.0
2.1
2.2
2.3
2.4
2.5
2.6

git checkout 2.6
HEAD is now at bd71cbb... 2.6.
sh autogen.sh
./configure --prefix=/home/pi/.usr/
make -j
make install

# Then
./tmux
./tmux: error while loading shared libraries: libevent-2.1.so.6: cannot open shared object file: No such file or directory
```

> It said that libevent-2.1 had not been loaded yet, and below shows that.

<a id = ldlibrarypath></a>
### set LD_LIBRARY_PATH for libevent
``` bash
pwd
/home/pi/.mytarball/tmux
ldd tmux
    linux-vdso.so.1 =>  (0x00007ffe0df9b000)
    libutil.so.1 => /lib64/libutil.so.1 (0x00000037b1200000)
    libtinfo.so.5 => /lib64/libtinfo.so.5 (0x00000037ad800000)
    libevent-2.1.so.6 => not found
    librt.so.1 => /lib64/librt.so.1 (0x00000037a1800000)
    libresolv.so.2 => /lib64/libresolv.so.2 (0x00000037a2c00000)
    libc.so.6 => /lib64/libc.so.6 (0x00000037a0c00000)
    libpthread.so.0 => /lib64/libpthread.so.0 (0x00000037a0800000)
    /lib64/ld-linux-x86-64.so.2 (0x00000037a0400000)

# and then
```
```bash
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/pi/.usr/lib
```
```bash
ldd tmux
    linux-vdso.so.1 =>  (0x00007ffec8b9d000)
            libutil.so.1 => /lib64/libutil.so.1 (0x00000037b1200000)
            libtinfo.so.5 => /lib64/libtinfo.so.5 (0x00000037ad800000)
            libevent-2.1.so.6 => /home/pi/.usr/lib/libevent-2.1.so.6 (0x00007fb351970000)
            librt.so.1 => /lib64/librt.so.1 (0x00000037a1800000)
            libresolv.so.2 => /lib64/libresolv.so.2 (0x00000037a2c00000)
            libc.so.6 => /lib64/libc.so.6 (0x00000037a0c00000)
            libcrypto.so.10 => /usr/lib64/libcrypto.so.10 (0x00000037ac000000)
            libpthread.so.0 => /lib64/libpthread.so.0 (0x00000037a0800000)
            /lib64/ld-linux-x86-64.so.2 (0x00000037a0400000)
            libdl.so.2 => /lib64/libdl.so.2 (0x00000037a1400000)
            libz.so.1 => /lib64/libz.so.1 (0x00000037a1c00000)

we can see libevent-2.1.so.6 => /home/pi/.usr/lib/libevent-2.1.so.6 (0x00007fb351970000).

./tmux -V
tmux 2.6
```

<a id = envfortmux></a>
### env var for tmux
```bash
vim ~/.bashrc
export PATH=/home/pi/.usr/bin:$PATH
export PKG_CONFIG_PATH=/home/pi/.usr/lib/pkgconfig/:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/home/pi/.usr/lib
```

<a id = license></a>
## License
The [MIT](./LICENSE.txt) License (MIT)
