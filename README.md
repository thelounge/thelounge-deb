# Debian/Ubuntu package for The Lounge

<a href="https://travis-ci.org/thelounge/deb-lounge">
	<img
		alt="Travis CI Build Status"
		src="https://img.shields.io/travis/thelounge/deb-lounge/master.svg?style=flat-square">
</a>

This repository holds out the build scripts that generates our `.deb` precompiled packages and also tracks Debian-specific issues in relation to the packaging.


## Installation

If you are looking to simply install The Lounge, please use our pre-compiled binary .deb files available in the releases section of the main project. This section assumes you want to build a Debian package from sources.

```sh
# Clone the repository
git clone https://github.com/thelounge/deb-lounge.git
cd deb-lounge

# Call the build script
./build-package
```

After this, you should have a nice `.deb` file in the `deb/` output folder! This file can then be installed:

```
# dpkg -i deb/*.deb
```

### Configuration

The default system-wide documentation file is located at `/etc/lounge/config.js`. Please note that user profiles and their IRC passwords are also stored there, so the directory is only readable by the `lounge` user.


### Running

The Lounge provides both a system-wide and per-user systemd unit. If you installed the package, The Lounge should already be running and accessible on `http://127.0.0.1:9000`.


#### System

Simply enable the `lounge.service` unit, and your server should be up and running:

```sh
systemctl enable --now lounge.service
```


#### User

If you do not want to run the software system-wide, or host multiple users that wish to host their own instance of The Lounge, it can also be launched per user:

```sh
systemctl --user enable --now lounge.service
```

Please note that for The Lounge to start on boot in this scenario, you will also require to have [lingering](https://wiki.archlinux.org/index.php/Systemd/User#Automatic_start-up_of_systemd_user_instances) enabled for this user:

```sh
loginctl enable-linger $username
```
