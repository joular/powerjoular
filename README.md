# [![Joular Project](https://gitlab.com/uploads/-/system/group/avatar/10668049/joular.png?width=64)](https://www.noureddine.org/research/joular/) PowerJoular :zap:

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue)](https://www.gnu.org/licenses/gpl-3.0)
[![Ada](https://img.shields.io/badge/Made%20with-Ada-blue)](https://www.adaic.org)

PowerJoular is a command line software to monitor, in real time, the power consumption of software and hardware components.

## :rocket: Features

- Monitor power consumption of CPU and GPU of PC/servers
- Monitor power consumption of individual processes in GNU/Linux
- Expose power consumption to the terminal and CSV files
- Provides a systemd service (daemon) to continuously monitor power of devices
- Low overhead (written in Ada and compiled to native code)

## :satellite: Supported platforms

PowerJoular monitors the following platforms:
- :computer: PC/Servers using a RAPL supported Intel processor (since Sandy Bridge), and optionally an Nvidia graphic card

In all platforms, PowerJoular works currently only on GNU/Linux.

On PC/Servers, PowerJoular uses powercap Linux interface to read Intel RAPL (Running Average Power Limit) energy consumption.

PowerJoular supports RAPL package domain (core, including integrated graphics, and dram), and for more recent processors, we support Psys package (which covers the energy consumption of the entire SoC).

## :package: Installation

Easy-to-use installation scripts are available in the ```installer``` folder.
Just open the installer folder and run the appropriate file to build and/or install or uninstall the program and systemd service.

- ```install-bin.sh```: install the already compiled binaries of the program and systemd service. The script will detect the device architecture (x86_64) and install the appropriate binary.
- ```build-install.sh```: will build (using ```gprbuild```) and install the program binary to ```/usr/bin``` and systemd service. It requires having installed GNAT, gprbuild and GNATColl (see [Compilation](#floppy_disk-compilation)).
- ```uninstall.sh```: deletes the program binary and systemd service.

## :bulb: Usage

To use PowerJoular, just run the command ```powerjoular```.
On PC/servers, PowerJoular uses Intel's RAPL through the Linux powercap sysfs, and therefore requires root/sudo access on the latest Linux kernels (5.10 and newer): ```sudo powerjoular```.

By default, the software will show the power consumption of the CPU and its utilization.
The difference (increase or decrease) of power consumption from last metric will also be shown.

The following options are available:
- ```-h```: show the help message
- ```-p pid```: specifiy a particular PID to monitor
- ```-f filename```: save monitoring data to the given filename path
- ```-o filename```: save only last monitoring data to the given filename path (file overwritten with only latest power measures)
- ```-t```: print data to the terminal
 
You can mix options, i.e., ```powerjoular -tp 144``` will monitor PID 144 and will print to the terminal.

## :floppy_disk: Compilation

PowerJoular is written with Ada (revision 2012), and requires an Ada compiler, such as GNAT, and uses gprbuild.

PowerJoular is released under the GNU GPL 3 license, so you can use AdaCore GNAT Community Edition, or use the FSF GNAT which includes the GCC Runtime Library Exception.

PowerJoular depends on the following additional Ada libraries:
- [GNATColl-core (GNAT Components Collection – Core packages)](https://github.com/AdaCore/gnatcoll-core). Either build it or install the package from your distro (```libgnatcoll17-dev``` or ```gnatcoll```).

PowerJoular depends on the following commands and libraries for certain of its functions, but can function without them:
- nvidia-smi: for monitoring power consumption of Nvidia graphic cards
- Linux powercap with Intel RAPL support: for monitoring power consumption of Intel processors and SoC

On latest Fedora, install gnat, gprbuild and GNATColl:
```
sudo dnf install fedora-gnat-project-common gprbuild gnatcoll
```

On Debian 10, install gnat, gprbuild and GNATColl (on Ubuntu 20.04 use libgnatcoll18-dev instead):
```
sudo apt install gnat gprbuild libgnatcoll17-dev
```

To compile the project, use ```gprbuild``` on ```powerjoular.gpr``` file.

```
git clone https://gitlab.com/joular/powerjoular.git
cd powerjoular
mkdir -p obj
gprbuild
```

The PowerJoular binary will be created in the ```obj/``` folder.

By default, the project will statically link the required libraries.
To build with dynamic linking, remove or comment the static switch in the ```powerjoular.gpr``` file, in particular these lines:

```
package Binder is
    for Switches ("Ada") use ("-static");
end Binder;
```

## :hourglass: Systemd service

A systemd service is provided and can be installed (by copying ```powerjoular.service``` in ```systemd``` folder to ```/etc/systemd/system/```).
The service will run the program with the ```-o``` option (which only saves the latest power data) and saves data to ```/tmp/powerjoular-service.csv```.
The service can be enabled to run automatically on boot.

The systemd service is automatically installed when installing PowerJoular using the GNU/Linux provided packages.

## :newspaper: License

PowerJoular is licensed under the GNU GPL 3 license only (GPL-3.0-only).

Copyright (c) 2020-2021, Adel Noureddine, Université de Pau et des Pays de l'Adour.
All rights reserved. This program and the accompanying materials are made available under the terms of the GNU General Public License v3.0 only (GPL-3.0-only) which accompanies this distribution, and is available at: https://www.gnu.org/licenses/gpl-3.0.en.html

Author : Adel Noureddine
