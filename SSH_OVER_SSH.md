# copyright by Peng, last edit 12-08 2017
# ssh login issue caused by through SSH -D dynamic tunnelling.
## scene
      step1:  ssh -vv -ND 8080 [Laptop_ip] -l [login_name on Laptop]
     ---------------------------------------------------------------->
VIRL                                                                    Laptop
     -----------------------------------------------------------------
now I want to login laptop through this socks5 proxy setup by step1 on VIRL.

> hostname
virl
> ssh -p 8080 localhost -l [login_name on Laptop]
ssh_exchange_identification: Connection closed by remote host

# begin of log
debug2: client_check_window_change: changed
debug2: client_check_window_change: changed
debug1: Connection to port 8080 forwarding to socks port 0 requested.
debug2: fd 6 setting TCP_NODELAY
debug2: fd 6 setting O_NONBLOCK
debug1: channel 2: new [dynamic-tcpip]
debug2: channel 2: pre_dynamic: have 0
debug2: channel 2: pre_dynamic: have 43
debug2: channel 2: zombie
debug2: channel 2: garbage collecting
debug1: channel 2: free: dynamic-tcpip, nchannels 3
# end of log

notice this line: debug1: Connection to port 8080 forwarding to socks port 0 requested.
forwarding to socks port 0, notice this port 0.

ssh use -p 8080 to connect proxy, but proxy did not which port to forward, 0 is now the default.

## solve this issue
# netcat is named as nc on some Linux.
> ssh -vv -o ProxyCommand='netcat -x 127.0.0.1:8080 %h %p' [Laptop_ip] -l [login_name on Laptop]

OpenSSH_6.6.1, OpenSSL 1.0.1f 6 Jan 2014
debug1: Reading configuration data /etc/ssh/ssh_config
debug1: /etc/ssh/ssh_config line 19: Applying options for *
debug1: Executing proxy command: exec netcat -x 127.0.0.1:8080 [Laptop_ip] 22
debug1: permanently_drop_suid: 1000
debug1: identity file /home/virl/.ssh/id_rsa type 1
debug1: identity file /home/virl/.ssh/id_rsa-cert type -1
debug1: identity file /home/virl/.ssh/id_dsa type -1
debug1: identity file /home/virl/.ssh/id_dsa-cert type -1
debug1: identity file /home/virl/.ssh/id_ecdsa type -1
debug1: identity file /home/virl/.ssh/id_ecdsa-cert type -1
debug1: identity file /home/virl/.ssh/id_ed25519 type -1
debug1: identity file /home/virl/.ssh/id_ed25519-cert type -1
debug1: Enabling compatibility mode for protocol 2.0
debug1: Local version string SSH-2.0-OpenSSH_6.6.1p1 Ubuntu-2ubuntu2.8
debug1: Remote protocol version 2.0, remote software version OpenSSH_6.9
debug1: match: OpenSSH_6.9 pat OpenSSH* compat 0x04000000
debug2: fd 5 setting O_NONBLOCK
debug2: fd 4 setting O_NONBLOCK
......

Password:

# begin of log
debug2: client_check_window_change: changed
debug1: Connection to port 8080 forwarding to socks port 0 requested.
debug2: fd 6 setting TCP_NODELAY
debug2: fd 6 setting O_NONBLOCK
debug1: channel 2: new [dynamic-tcpip]
debug2: channel 2: pre_dynamic: have 0
debug2: channel 2: pre_dynamic: have 3
debug2: channel 2: decode socks5
debug2: channel 2: socks5 auth done
debug2: channel 2: pre_dynamic: need more
debug2: channel 2: pre_dynamic: have 0
debug2: channel 2: pre_dynamic: have 10
debug2: channel 2: decode socks5
debug2: channel 2: socks5 post auth
debug2: channel 2: dynamic request: socks5 host [Laptop_ip] port 22 command 1
debug2: channel 2: open confirm rwindow 2097152 rmax 32768
debug2: client_check_window_change: changed
# end of log

Success Now.
