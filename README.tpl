# Alpine Linux in Docker with Multilanguage e Timezone support

This Docker image [(gitlab.welcomeitalia.it:5050/docker-images/alpine)](https://gitlab.welcomeitalia.it:5050/docker-images/alpine/) is based on the minimal [Alpine Linux](https://alpinelinux.org/).

##### Alpine Version %ALPINE_VERSION% (Released %ALPINE_VERSION_DATE%)

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
* ```:%ALPINE_VERSION%``` %ALPINE_VERSION% branch based (Automatic Architecture Selection)
* ```:%ALPINE_VERSION%-aarch64```   %ALPINE_VERSION% 64 bit ARM
* ```:%ALPINE_VERSION%-armhf```     %ALPINE_VERSION% 32 bit ARM v6
* ```:%ALPINE_VERSION%-armv7```     %ALPINE_VERSION% 32 bit ARM v7
* ```:%ALPINE_VERSION%-ppc64le```   %ALPINE_VERSION% 64 bit PowerPC
* ```:%ALPINE_VERSION%-x86```       %ALPINE_VERSION% 32 bit Intel/AMD
* ```:%ALPINE_VERSION%-x86_64```    %ALPINE_VERSION% 64 bit Intel/AMD

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

## Creating an instance (default timezone and locale)

```bash
docker run --rm -it --name alpine gitlab.welcomeitalia.it:5050/docker-images/alpine
```

## Creating an instance with locale it_IT

```bash
docker run --rm -it --name alpine -e LC_ALL=it_IT.UTF-8 gitlab.welcomeitalia.it:5050/docker-images/alpine
```

## Creating an instance with locale it_IT and timezone Europe/Rome

```bash
docker run --rm -it --name alpine -e LC_ALL=it_IT.UTF-8 -e TIMEZONE=Europe/Rome gitlab.welcomeitalia.it:5050/docker-images/alpine
```

## Creating an instance with locale it_IT, timezone Europe/Rome and shell bash

```bash
docker run --rm -it --name alpine -e LC_ALL=it_IT.UTF-8 -e TIMEZONE=Europe/Rome -e SHELL_TERMINAL=bin/bash gitlab.welcomeitalia.it:5050/docker-images/alpine
```

***
###### Last Update %LAST_UPDATE%
