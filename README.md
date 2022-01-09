[![logo](https://raw.githubusercontent.com/ich777/docker-templates/master/ich777/images/openvpn-client.png)](https://openvpn.net/)

# OpenVPN

This is an OpenVPN client docker container. It makes routing containers'
traffic through OpenVPN easy.

This container is forked from: https://github.com/dperson/openvpn-client

# What is OpenVPN?

OpenVPN is an open-source software application that implements virtual private
network (VPN) techniques for creating secure point-to-point or site-to-site
connections in routed or bridged configurations and remote access facilities.
It uses a custom security protocol that utilizes SSL/TLS for key exchange. It is
capable of traversing network address translators (NATs) and firewalls.

# How to use this image

This OpenVPN container was designed to be started first to provide a connection
to other containers (using `--net=container:OpenVPN-Client`, see below *Starting an OpenVPN
client instance*).

**NOTE**: More than the basic privileges are needed for OpenVPN. With Docker 1.2
or newer you can use the `--cap-add=NET_ADMIN` and `--device /dev/net/tun`
options. Earlier versions, or with fig, and you'll have to run it in privileged
mode.

**NOTE 2**: If you have connectivity issues, please see the DNS instructions
below, also please note IPv6 is disabled by default for unRAID.

**NOTE 3**: If you need access to other non HTTP proxy-able ports, please see
the Routing instructions below.

**NOTE 4**: If you have a VPN service that allows making local services
available, you'll need to reuse the VPN container's network stack with the
`--net=container:OpenVPN-Client` (replacing 'OpenVPN-Client' with what you named your instance of this
container) when you launch the service in its container.

**NOTE 5**: If you need IPv6, or the errors really bother you add a
`--sysctl net.ipv6.conf.all.disable_ipv6=0` to the docker run command (disabled by default for unRAID).

## Starting an OpenVPN client instance

    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                -v /path/to/vpn:/vpn -d ich777/openvpn-client \
                -v 'vpn.server.name;username;password'
    docker restart OpenVPN-Client

Once it's up other containers can be started using its network connection:

    docker run -ti --net=container:OpenVPN-Client -d some/docker-container

## Local Network access to services connecting to the internet through the VPN.

However to access them from your normal network (off the 'local' docker bridge),
you'll also need to run a web proxy, like so:

    docker run -ti --name web -p 80:80 -p 443:443 \
                --link OpenVPN-Client:<service_name> -d binhex/arch-nginx \
                -w "http://<service_name>:<PORT>/<URI>;/<PATH>"

Which will start a Nginx web server on local ports 80 and 443, and proxy any
requests under `/<PATH>` to the to `http://<service_name>:<PORT>/<URI>`. To use
a concrete example:

    docker run -ti --name bit --net=container:OpenVPN-Client -d binhex/arch-delugevpn
    docker run -ti --name web -p 80:80 -p 443:443 --link OpenVPN-Client:bit \
                -d binhex/arch-nginx -w "http://bit:9091/transmission;/transmission"

For multiple services (non-existant 'foo' used as an example):

    docker run -ti --name bit --net=container:OpenVPN-Client -d binhex/arch-delugevpn
    docker run -ti --name foo --net=container:OpenVPN-Client -d ich777/foo
    docker run -ti --name web -p 80:80 -p 443:443 --link OpenVPN-Client:bit \
                --link vpn:foo -d binhex/arch-nginx \
                -w "http://bit:9091/transmission;/transmission" \
                -w "http://foo:8000/foo;/foo"

## Routing for local access to non HTTP proxy-able ports

The argument to the `-r` (route) command line argument must be your local
network that you would connect to the server running the docker containers on.
Running the following on your docker host should give you the correct network:
`ip route | awk '!/ (docker0|br-)/ && /src/ {print $1}'`

    cp /path/to/vpn/vpn.crt /some/path/vpn-ca.crt
    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                -v /path/to/vpn:/vpn -d ich777/openvpn-client \
                -r 192.168.1.0/24 -v 'vpn.server.name;username;password'

**NOTE**: if you have a port you want to make available, you have to add the
docker `-p` option to the VPN container. The network stack will be reused by
the second container (that's what `--net=container:OpenVPN-Client` does).

## Configuration

    docker run -ti --rm ich777/openvpn-client -h

    Usage: start-server.sh [-opt] [command]
    Options (fields in '[]' are optional, '<>' are required):
        -h          This help
        -c '<passwd>' Configure an authentication password to open the cert
                    required arg: '<passwd>'
                    <passwd> password to access the certificate file
        -a '<user;password>' Configure authentication username and password
        -D          Don't use the connection as the default route
        -d          Use the VPN provider's DNS resolvers
        -f '[port]' Firewall rules so that only the VPN and DNS are allowed to
                    send internet traffic (IE if VPN is down it's offline)
                    optional arg: [port] to use, instead of default
        -m '<mss>'  Maximum Segment Size <mss>
                    required arg: '<mss>'
        -o '<args>' Allow to pass any arguments directly to openvpn
            required arg: '<args>'
            <args> could be any string matching openvpn arguments
            i.e '--arg1 value --arg2 value'
        -p '<port>[;protocol]' Forward port <port>
                    required arg: '<port>'
                    optional arg: [protocol] to use instead of default (tcp)
        -R '<network>' CIDR IPv6 network (IE fe00:d34d:b33f::/64)
                    required arg: '<network>'
                    <network> add a route to (allows replies once the VPN is up)
        -r '<network>' CIDR network (IE 192.168.1.0/24)
                    required arg: '<network>'
                    <network> add a route to (allows replies once the VPN is up)
        -v '<server;user;password[;port]>' Configure OpenVPN
                    required arg: '<server>;<user>;<password>'
                    <server> to connect to (multiple servers are separated by :)
                    <user> to authenticate as
                    <password> to authenticate with
                    optional args:
                    [port] to use, instead of default
                    [proto] to use, instead of udp (IE, tcp)

    The 'command' (if provided and valid) will be run instead of openvpn

ENVIRONMENT VARIABLES

 * `CERT_AUTH` - As above (-c) provide authentication to access certificate
 * `DNS` - As above (-d) use the VPN provider's DNS resolvers
 * `DEFAULT_GATEWAY` - As above (-D) if set to 'false', don't use default route
 * `FIREWALL` - As above (-f) setup firewall to disallow net access w/o the VPN
 * `CIPHER` - Set openvpn cipher option when generating conf file with -v
 * `AUTH` - Set openvpn auth option when generating conf file with -v
 * `MSS` - As above (-m) set Maximum Segment Size
 * `OTHER_ARGS` - As above (-o) pass arguments directly to openvpn
 * `ROUTE6` - As above (-R) add a route to allow replies to your private network
 * `ROUTE` - As above (-r) add a route to allow replies to your private network
 * `TZ` - Set a timezone, IE `EST5EDT`
 * `VPN_FILES` - specify the '<corfig>[;cert]' files to use (relative to `/vpn`)
 * `VPN` - As above (-v) setup a VPN connection
 * `VPN_AUTH` - As above (-a) provide authentication to vpn server
 * `VPNPORT` - As above (-p) setup port forwarding (See NOTE below)
 * `GROUPID` - Set the GID for the vpn

 **NOTE**: optionally supports additional variables starting with the same name,
 IE `VPNPORT` also will work for `VPNPORT_2`, `VPNPORT_3`... `VPNPORT_x`, etc.

 **NOTE2**: if you are using `-d` or `DNS` and set the container as read-only,
you will get errors as it tries to write to `/etc/resolv.conf`, the 2 are
incompatible.

## Examples

Any of the commands can be run at creation with `docker run` or later with
`docker exec -ti OpenVPN-Client /opt/scripts/start-server.sh` (as of version 1.3 of docker).

### Setting the Timezone

    cp /path/to/vpn/vpn.crt /some/path/vpn-ca.crt
    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                -v /path/to/vpn:/vpn -e TZ=EST5EDT -d ich777/openvpn-client \
                -v 'vpn.server.name;username;password'

### VPN configuration

**NOTE**: When using `-v` (`VPN` variable) a vpn configuration is generated.

**NOTE2**: See the `-a` (`VPN_AUTH` variable) to just provide user / password
authentication to an existing configuration.

**NOTE3**: If the auto detect isn't picking the correct configuration, you can
use the `VPN_FILES` environment variable. All files must still be in `/vpn`, and
will only be looked for there. IE, you could use the following to specify the
`vpn.conf` configuration and `vpn.crt` certificate files:
`-e VPN_FILES="vpn.conf;vpn.crt`

In order to work you must provide VPN configuration and the certificate. You can
use external storage for `/vpn`:

    cp /path/to/vpn/vpn.crt /some/path/vpn-ca.crt
    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                -v /path/to/vpn:/vpn -d ich777/openvpn-client \
                -v 'vpn.server.name;username;password'

Or you can store it in the container:

    cat /path/to/vpn/vpn.crt | docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 \
                --device /dev/net/tun --name OpenVPN-Client -d ich777/openvpn-client \
                -v 'vpn.server.name;username;password' tee /vpn/vpn-ca.crt \
                >/dev/null
    docker restart OpenVPN-Client

### Firewall

It's just a simple command line argument (`-f ""`) to turn on the firewall, and
block all outbound traffic if the VPN is down.

    cp /path/to/vpn/vpn.crt /some/path/vpn-ca.crt
    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                -v /path/to/vpn:/vpn -d ich777/openvpn-client -f "" \
                -v 'vpn.server.name;username;password'

### DNS Issues (May Look Like You Can't Connect To Anything)

Often local DNS and/or your ISP won't be accessable from the new IP address you
get from your VPN. You'll need to add the `--dns` command line option to the
`docker run` statement. Here's an example of doing so, with a Google DNS server:

    cp /path/to/vpn.crt /some/path/vpn-ca.crt
    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                --dns 8.8.4.4 -v /path/to/vpn:/vpn -d ich777/openvpn-client \
                -v 'vpn.server.name;username;password'

### Run with client certificates

In case you want to use client certificates you just copy them into the /vpn
directory.

    cp /path/to/vpn/vpn.crt /some/path/vpn-ca.crt
    cp /path/to/vpn/client.crt /some/path/client.crt
    cp /path/to/vpn/client.key /some/path/client.key
    cp /path/to/vpn/vpn.conf /some/path/vpn.conf
    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
                -v /some/path:/vpn -d ich777/openvpn-client

The vpn.conf should look like this:

    client
    dev tun
    port 1194
    proto udp

    remote vpn.server.name 1194
    nobind

    ca /vpn/vpn-ca.crt
    cert /vpn/client.crt
    key /vpn/client.key

    persist-key
    persist-tun

### Run with openvpn client configuration and provided auth

In case you want to use your client configuration in /vpn named vpn.conf
but adding your vpn user and password by command line

    docker run -ti --cap-add=NET_ADMIN --sysctl net.ipv6.conf.all.disable_ipv6=0 --device /dev/net/tun --name OpenVPN-Client \
            -v /path/to/vpn:/vpn -d ich777/openvpn-client -a 'username;password'

# User Feedback

## Issues

If you have any problems with or questions about this image, please contact me
through a GitHub issue.