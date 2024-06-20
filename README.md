# <a href="https://www.noureddine.org/research/joular/"><img src="https://raw.githubusercontent.com/joular/.github/main/profile/joular.png" alt="Joular Project" width="64" /></a> PowerJoular :zap:

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue)](https://www.gnu.org/licenses/gpl-3.0)
[![Ada](https://img.shields.io/badge/Made%20with-Ada-blue)](https://www.adaic.org)

![PowerJoular Logo](powerjoular.png)

PowerJoular is a command line software to monitor, in real time, the power consumption of software and hardware components.

Detailed documentation (including user and reference guides) are available at: [https://joular.github.io/powerjoular/](https://joular.github.io/powerjoular/).

## :rocket: Features

- Monitor power consumption of CPU and GPU of PC/servers
- Monitor power consumption inside virtual machines
- Monitor power consumption of individual processes in GNU/Linux
- Expose power consumption to the terminal and CSV files
- Provides a systemd service (daemon) to continuously monitor power of devices
- Low overhead (written in Ada and compiled to native code)

## :satellite: Supported platforms

PowerJoular monitors the following platforms:
- :computer: PC/Servers using a RAPL supported Intel processor (since Sandy Bridge) or a RAPL supported AMD processor (Ryzen or EPYC), and optionally an Nvidia graphic card.
- :radio: Raspberry Pi devices (multiple models) and Asus Tinker Board.
- :computer: Inside virtual machines in all supported host platforms.

In all platforms, PowerJoular works currently only on GNU/Linux.

On PC/Servers, PowerJoular uses powercap Linux interface to read Intel RAPL (Running Average Power Limit) energy consumption.

PowerJoular supports RAPL package domain (core, including integrated graphics, and dram), and for more recent processors, we support Psys package (which covers the energy consumption of the entire SoC).

On virtual machines, PowerJoular requires two steps:
- Installing PowerJoular itself or another power monitoring tool in the host machine.
Then monitoring the virtual machine power consumption every second and writing it to a file (to be shared with the guest VM).
- Installing PowerJoular in the guest VM, then running PowerJoular while specifying the path of the power file shared with the host and its format.

On Raspberry Pi and Asus Tinker Board, PowerJoular uses its own research-based empirical regression models to estimate the power consumption of the ARM processor.

The supported list of Raspberry Pi and Asus Tinker Board models are listed below.
We support all revisions of each model lineup. However, the model is generated and trained on a specific revision (listed between brackets), and the accuracy is best on this particular revision.

We currently support the following Raspberry Pi and Asus Tinker Board models:
- Model Zero W (rev 1.1), for 32 bits OS
- Model 1 B (rev 2), for 32 bits OS
- Model 1 B+ (rev 1.2), for 32 bits OS
- Model 2 B (rev 1.1), for 32 bits OS
- Model 3 B (rev 1.2), for 32 bits OS
- Model 3 B+ (rev 1.3), for 32 bits OS
- Model 4 B (rev 1.1, and rev 1.2), for both 32 bits and 64 bits OS
- Model 400 (rev 1.0), for 64 bits OS
- Model 5 B (rev 1.0), for 64 bits OS
- Asus Tinker Board (S)

## :package: Installation

PowerJoular is written in Ada and can be easily compiled, and its unique binary added to your system PATH.

Easy-to-use installation scripts are available in the ```installer``` folder.
Just open the installer folder and run the appropriate file to build and/or install or uninstall the program and systemd service.

- ```build-install.sh```: will build (using ```gprbuild```) and install the program binary to ```/usr/bin``` and systemd service. It requires having installed GNAT and gprbuild (see [Compilation](#floppy_disk-compilation)).
- ```uninstall.sh```: deletes the program binary and systemd service.

## :bulb: Usage

To use PowerJoular, just run the command ```powerjoular```.
On PC/servers, PowerJoular uses Intel's RAPL through the Linux powercap sysfs, and therefore requires root/sudo access on the latest Linux kernels (5.10 and newer): ```sudo powerjoular```.

By default, the software will show the power consumption of the CPU and its utilization.
The difference (increase or decrease) of power consumption from last metric will also be shown.

The following options are available:
- ```-h```: show the help message
- ```-v```: show version number
- ```-p pid```: specifiy a particular PID to monitor
- ```-a appName```: specifiy a particular application name to monitor (will monitor all PIDs of the application)
- ```-f filename```: save monitoring data to the given filename path
- ```-o filename```: save only last monitoring data to the given filename path (file overwritten with only latest power measures)
- ```-t```: print energy data to the terminal
- ```-d```: print debug info to the terminal
- ```-l```: use linear regression models (less accurate than the default polynomial models) for Raspberry Pi energy models
- ```-m```: specify a filename for the power consumption of the virtual machine
- ```-s```: specify the format of the VM power, either ```powerjoular``` format (generated with the ```-o``` option: 3 columns csv file with the 3rd containing the power consumption the VM), or ```watts``` format (1 column containing just the power consumption of the VM)
 
You can mix options, i.e., ```powerjoular -tp 144``` will monitor PID 144 and will print to the terminal.

## :floppy_disk: Compilation

PowerJoular is written with Ada, and requires a modern Ada compiler, such as GNAT.

PowerJoular depends on the following commands and libraries for certain of its functions, but can function without them:
- nvidia-smi: for monitoring power consumption of Nvidia graphic cards
- Linux powercap with Intel RAPL support: for monitoring power consumption of Intel processors and SoC

On a modern GNU/Linux distribution, just install the GNAT compiler (and GPRBuild), usually available from the distribution's repositories:

```
Fedora:
sudo dnf install fedora-gnat-project-common gprbuild gcc-gnat

Debian, Ubuntu or Raspberry Pi OS:
sudo apt install gnat gprbuild
```

For other distributions, use their package manager to download the compiler, or check [this article for easy instruction for various distributions](https://www.noureddine.org/articles/ada-on-windows-and-linux-an-installation-guide), including RHEL and its clones which does not ship with Ada support in GCC.

### Compilation with the GNAT compiler and GPRBuild

To compile the project, just type ```gprbuild``` if using the latest GPRBuild versions.

Or, on older versions, create the ```/obj``` folder first, then type ```gprbuild powerjoular.gpr```.

The PowerJoular binary will be created in the ```obj/``` folder.

By default, the project will statically link the required libraries, and therefore the PowerJoular binary can be copied to any compatible system and used as-is.

To build with dynamic linking, remove or comment the static switch in the ```powerjoular.gpr``` file, in particular these lines:

```
package Binder is
    for Switches ("Ada") use ("-static");
end Binder;
```

### Compilation with the GNAT compiler only

You can also compile PowerJoular with the GNAT compiler only (without the need for GPRBuild).

Just compile using gnatmake. For example, to compile from ```obj/``` folder (so .o and .ali files are generated there), type the following:

```
mkdir -p obj
cd obj
gnatmake ../src/powerjoular.adb
```

### Compilation with Alire

If you have [Alire](https://alire.ada.dev/) installed, you can use it to build PowerJoular with:

```
alr build
```

### Cross-compilation and package generation

The ```release-version.sh``` script cross-compiles PowerJoular to multiple platforms (for now x86_64 and aarch64, but can be tweak to add other platforms).
The script then generates RPM and DEB binary installation packages for these plateforms.

The script needs a x86_64 and an aarch64 gnat compiler, along with deb and rpm packaging tools.

Install them according to your distribution. For example, in Ubuntu 22.04 x86_64 :

```
sudo apt install gnat gnat-12-aarch64-linux-gnu dpkg rpm
```

## :hourglass: Systemd service

A systemd service is provided and can be installed (by copying ```powerjoular.service``` in ```systemd``` folder to ```/etc/systemd/system/```).
The service will run the program with the ```-o``` option (which only saves the latest power data) and saves data to ```/tmp/powerjoular-service.csv```.
The service can be enabled to run automatically on boot.

The systemd service is automatically installed when installing PowerJoular using the GNU/Linux provided packages.

## :bookmark_tabs: Cite this work

To cite our work in a research paper, please cite our paper in the 18th International Conference on Intelligent Environments (IE2022).

- **PowerJoular and JoularJX: Multi-Platform Software Power Monitoring Tools**. Adel Noureddine. In the 18th International Conference on Intelligent Environments (IE2022). Biarritz, France, 2022.

```
@inproceedings{noureddine-ie-2022,
  title = {PowerJoular and JoularJX: Multi-Platform Software Power Monitoring Tools},
  author = {Noureddine, Adel},
  booktitle = {18th International Conference on Intelligent Environments (IE2022)},
  address = {Biarritz, France},
  year = {2022},
  month = {Jun},
  keywords = {Power Monitoring; Measurement; Power Consumption; Energy Analysis}
}
```

## :newspaper: License

PowerJoular is licensed under the GNU GPL 3 license only (GPL-3.0-only).

Copyright (c) 2020-2024, Adel Noureddine, Université de Pau et des Pays de l'Adour.
All rights reserved. This program and the accompanying materials are made available under the terms of the GNU General Public License v3.0 only (GPL-3.0-only) which accompanies this distribution, and is available at: https://www.gnu.org/licenses/gpl-3.0.en.html

Author : Adel Noureddine
