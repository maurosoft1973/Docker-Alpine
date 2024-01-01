# Alpine Linux in Docker with Multilanguage e Timezone support

[![Docker Automated build](https://img.shields.io/docker/automated/maurosoft1973/alpine.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/maurosoft1973/alpine/)
[![Docker Pulls](https://img.shields.io/docker/pulls/maurosoft1973/alpine.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/maurosoft1973/alpine/)
[![Docker Stars](https://img.shields.io/docker/stars/maurosoft1973/alpine.svg?style=for-the-badge&logo=docker)](https://hub.docker.com/r/maurosoft1973/alpine/)
[![Alpine Version](https://img.shields.io/badge/Alpine%20version-v3.19.0-green.svg?style=for-the-badge)](https://alpinelinux.org/)

This Docker image [(maurosoft1973/alpine)](https://hub.docker.com/r/maurosoft1973/alpine/) is based on the minimal [Alpine Linux](https://alpinelinux.org/).

##### Alpine Version 3.19.0 (Released Dec 07 2023)

This docker image is the base Alpine Linux. For more info on versions & support see [Releases](https://wiki.alpinelinux.org/wiki/Alpine_Linux:Releases)

----

## What is Alpine Linux?
Alpine Linux is a Linux distribution built around musl libc and BusyBox. The image is only 5 MB in size and has access to a package repository that is much more complete than other BusyBox based images. This makes Alpine Linux a great image base for utilities and even production applications. Read more about Alpine Linux here and you can see how their mantra fits in right at home with Docker images.

## Features

* Minimal size only, minimal layers
* Memory usage is minimal on a simple install
* Multilanguage support.
* Timezone Support

## Architectures

* ```:aarch64``` - 64 bit ARM
* ```:armhf```   - 32 bit ARM v6
* ```:armv7```   - 32 bit ARM v7
* ```:ppc64le``` - 64 bit PowerPC
* ```:x86```     - 32 bit Intel/AMD
* ```:x86_64```  - 64 bit Intel/AMD (x86_64/amd64)

## Tags

* ```:latest```         latest branch based (Automatic Architecture Selection)
* ```:aarch64```        latest 64 bit ARM
* ```:armhf```          latest 32 bit ARM v6
* ```:armv7```          latest 32 bit ARM v7
* ```:ppc64le```        latest 64 bit PowerPC
* ```:x86```            latest 32 bit Intel/AMD
* ```:x86_64```         latest 64 bit Intel/AMD
* ```:test```           test branch based (Automatic Architecture Selection)
* ```:test-aarch64```   test 64 bit ARM
* ```:test-armhf```     test 32 bit ARM v6
* ```:test-armv7```     test 32 bit ARM v7
* ```:test-ppc64le```   test 64 bit PowerPC
* ```:test-x86```       test 32 bit Intel/AMD
* ```:test-x86_64```    test 64 bit Intel/AMD
* ```:3.19.0``` 3.19.0 branch based (Automatic Architecture Selection)
* ```:3.19.0-aarch64```   3.19.0 64 bit ARM
* ```:3.19.0-armhf```     3.19.0 32 bit ARM v6
* ```:3.19.0-armv7```     3.19.0 32 bit ARM v7
* ```:3.19.0-ppc64le```   3.19.0 64 bit PowerPC
* ```:3.19.0-x86```       3.19.0 32 bit Intel/AMD
* ```:3.19.0-x86_64```    3.19.0 64 bit Intel/AMD


## Layers & Sizes

| Version                                                                               | Size                                                                                                                 |
|---------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| ![Version](https://img.shields.io/badge/version-amd64-blue.svg?style=for-the-badge)   | ![MicroBadger Size (tag)](https://img.shields.io/docker/image-size/maurosoft1973/alpine/latest?style=for-the-badge)  |
| ![Version](https://img.shields.io/badge/version-aarch64-blue.svg?style=for-the-badge) | ![MicroBadger Size (tag)](https://img.shields.io/docker/image-size/maurosoft1973/alpine/aarch64?style=for-the-badge) |
| ![Version](https://img.shields.io/badge/version-armv6-blue.svg?style=for-the-badge)   | ![MicroBadger Size (tag)](https://img.shields.io/docker/image-size/maurosoft1973/alpine/armhf?style=for-the-badge)   |
| ![Version](https://img.shields.io/badge/version-armv7-blue.svg?style=for-the-badge)   | ![MicroBadger Size (tag)](https://img.shields.io/docker/image-size/maurosoft1973/alpine/armv7?style=for-the-badge)   |
| ![Version](https://img.shields.io/badge/version-ppc64le-blue.svg?style=for-the-badge) | ![MicroBadger Size (tag)](https://img.shields.io/docker/image-size/maurosoft1973/alpine/ppc64le?style=for-the-badge) |
| ![Version](https://img.shields.io/badge/version-x86-blue.svg?style=for-the-badge)     | ![MicroBadger Size (tag)](https://img.shields.io/docker/image-size/maurosoft1973/alpine/x86?style=for-the-badge)     |


## Environment Variables:

### Main parameters:
* `LC_ALL`: default locale (en_GB.UTF-8)
* `TIMEZONE`: default timezone (Europe/Brussels)
* `SHELL_TERMINAL`: default shell (bin/sh)

#### List of locale Sets

When setting locale, also make sure to choose a locale otherwise it will be the default (en_GB.UTF-8).

```
+-----------------+
| Locale          |
+-----------------+
| fr_CH.UTF-8     |
| fr_FR.UTF-8     |
| de_CH.UTF-8     |
| de_DE.UTF-8     |
| en_GB.UTF-8     |
| en_US.UTF-8     |
| es_ES.UTF-8     |
| it_CH.UTF-8     |
| it_IT.UTF-8     |
| nb_NO.UTF-8     |
| nl_NL.UTF-8     |
| pt_PT.UTF-8     |
| pt_BR.UTF-8     |
| ru_RU.UTF-8     |
| sv_SE.UTF-8     |
+-----------------+
```

## Example of use

### 1.Creating an instance (default timezone and locale)

```console
docker run --rm -it --name alpine maurosoft1973/alpine
```

### 2.Creating an instance with locale it_IT

```console
docker run --rm -it --name alpine -e LC_ALL=it_IT.UTF-8 maurosoft1973/alpine
```

### 3.Creating an instance with locale it_IT and timezone Europe/Rome

```console
docker run --rm -it --name alpine -e LC_ALL=it_IT.UTF-8 -e TIMEZONE=Europe/Rome maurosoft1973/alpine
```

***
###### Last Update 01.01.2024 13:12:01
