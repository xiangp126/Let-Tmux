# cc_tmux

Guide for how to build tmux on Linux in case that I did not have root privilege.

# file list

* _.tmux.conf: tmux config files with good behaviour.
* sshproxy.sh: a small script used to setup http & https socks5 proxy useful for 'git clone'.
* httproxy.sh: a small script used to setup ssh config used for 'git push'.
* _config: sample ssh config file - proxycommand.
* GIT_PROXY_ISSUE.md: solution of key ssh over ssh communication issue.
* Compiliation guide: guide for compile tmux (written in this Readme.md).

# compilation guide
``` bash
> cd ~
# .usr to install packages.
> mkdir .usr
# .mytarball to store downloaded tarballs.
> mkdir .mytarball
```
## [optional 1] compile libevent 
tmux needs libevent 2.x support

``` bash
> cd ~/.mytarball
> wget https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
> tar -zxv -f libevent-2.1.8-stable.tar.gz
> cd libevent-2.1.8-stable
> ./configure --prefix=/users/penxiang/.usr/
> make -j
> make install
```

## [optional 2] compile ncurses
tmux dependes on ncurses.
```bash
> cd ~/.mytarball
> wget ftp://ftp.invisible-island.net/ncurses/ncurses.tar.gz
> tar -zxv -f ncurses.tar.gz
> ./configure --prefix=/users/penxiang/.usr/
> make -j
> make install
```

## what is .pc file
``` bash
> cd ~/.usr/lib/pkgconfig
> pwd
/users/penxiang/.usr/lib/pkgconfig
> cat /users/penxiang/.usr/lib/pkgconfig/libevent.pc

prefix=/users/penxiang/.usr
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

> pkg-config --libs pkgconfig/libevent.pc
-L/users/penxiang/.usr/lib -levent

> pkg-config --libs --static libevent.pc
-L/users/penxiang/.usr/lib -levent -lcrypto -lrt
```

## compile tmux

### set PKG_CONFIG_PATH for libevent
must set this env first, or configure of tmux cannot find libevent. 

``` bash
> export PKG_CONFIG_PATH=/users/penxiang/.usr/lib/pkgconfig/:$PKG_CONFIG_PATH
```
``` bash
> cd ~/.mytarball
> git clone https://github.com/tmux/tmux
> cd tmux
# checkout to latest stable version. default it was on master branch.
> git tag
2.0
2.1
2.2
2.3
2.4
2.5
2.6
> git checkout 2.6
HEAD is now at bd71cbb... 2.6.
> sh autogen.sh
> ./configure --prefix=/users/penxiang/.usr/
> make -j
> make install

Then
> ./tmux
./tmux: error while loading shared libraries: libevent-2.1.so.6: cannot open shared object file: No such file or directory

It said that libevent-2.1 had not been loaded yet, and below shows that.
```

### set LD_LIBRARY_PATH for libevent
``` bash
> pwd
/users/penxiang/.mytarball/tmux
> ldd tmux
    linux-vdso.so.1 =>  (0x00007ffe0df9b000)
    libutil.so.1 => /lib64/libutil.so.1 (0x00000037b1200000)
    libtinfo.so.5 => /lib64/libtinfo.so.5 (0x00000037ad800000)
    libevent-2.1.so.6 => not found
    librt.so.1 => /lib64/librt.so.1 (0x00000037a1800000)
    libresolv.so.2 => /lib64/libresolv.so.2 (0x00000037a2c00000)
    libc.so.6 => /lib64/libc.so.6 (0x00000037a0c00000)
    libpthread.so.0 => /lib64/libpthread.so.0 (0x00000037a0800000)
    /lib64/ld-linux-x86-64.so.2 (0x00000037a0400000)

and then
```
```bash
> export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/users/penxiang/.usr/lib
```
```bash
> ldd tmux
    linux-vdso.so.1 =>  (0x00007ffec8b9d000)
            libutil.so.1 => /lib64/libutil.so.1 (0x00000037b1200000)
            libtinfo.so.5 => /lib64/libtinfo.so.5 (0x00000037ad800000)
            libevent-2.1.so.6 => /users/penxiang/.usr/lib/libevent-2.1.so.6 (0x00007fb351970000)
            librt.so.1 => /lib64/librt.so.1 (0x00000037a1800000)
            libresolv.so.2 => /lib64/libresolv.so.2 (0x00000037a2c00000)
            libc.so.6 => /lib64/libc.so.6 (0x00000037a0c00000)
            libcrypto.so.10 => /usr/lib64/libcrypto.so.10 (0x00000037ac000000)
            libpthread.so.0 => /lib64/libpthread.so.0 (0x00000037a0800000)
            /lib64/ld-linux-x86-64.so.2 (0x00000037a0400000)
            libdl.so.2 => /lib64/libdl.so.2 (0x00000037a1400000)
            libz.so.1 => /lib64/libz.so.1 (0x00000037a1c00000)

we can see libevent-2.1.so.6 => /users/penxiang/.usr/lib/libevent-2.1.so.6 (0x00007fb351970000).

> ./tmux -V
tmux 2.6
```

### set env for using tmux
```bash
> vim ~/.bashrc
export PATH=/users/penxiang/.usr/bin:$PATH
export PKG_CONFIG_PATH=/users/penxiang/.usr/lib/pkgconfig/:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/users/penxiang/.usr/lib
```

### copy config file
``` bash
> mv ~/.tmux.conf ~/.tmux.conf.bak
> cp _.tmux.conf ~/.tmux.conf
```

# Reference

[pkg-config-guide](https://people.freedesktop.org/~dbn/pkg-config-guide.html)

[PKG_CONFIG_PATH detail explanation](http://blog.csdn.net/newchenxf/article/details/51750239)

[LD_LIBRARY_PATH refer](http://blog.csdn.net/wangeen/article/details/8159500)

