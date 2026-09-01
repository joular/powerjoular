# <a href="https://www.noureddine.org/research/joular/"><img src="https://raw.githubusercontent.com/joular/.github/main/profile/joular.png" alt="Joular Project" width="64" /></a> PowerJoular :zap:

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue)](https://www.gnu.org/licenses/gpl-3.0)
[![Ada](https://img.shields.io/badge/Made%20with-Ada-blue)](https://www.adaic.org)

![PowerJoular Logo](powerjoular.png)

PowerJoular is a command line tool that monitors, in real time, the power consumption of the machine and of the software running on it.

Detailed documentation (including user and reference guides) is available at: [https://joular.github.io/powerjoular/](https://joular.github.io/powerjoular/).

## :rocket: Features

- Monitor the power consumption of the CPU and the GPU of PCs and servers
- Monitor the power consumption of Raspberry Pi and Asus Tinker Board devices
- Monitor the power consumption of one process, or of one application and every process of it
- Monitor the power consumption from inside a virtual machine
- Export the power data to the terminal, to CSV files, and to a shared memory ring buffer
- Ships with a systemd service (daemon) to monitor the machine continuously
- Low overhead: written in Ada, compiled to native code, one binary with nothing to install alongside it

## :satellite: Supported platforms

PowerJoular runs on **GNU/Linux and Windows**, on PCs, servers, and single-board computers.

| Component | Hardware | OS | Method | 
|---|---|---|---|
| CPU | Intel (since Sandy Bridge), AMD (Ryzen, EPYC) | Linux | RAPL through the powercap sysfs |
| CPU | Intel, AMD | Windows | RAPL MSR through [Hubblo's RAPL driver](https://github.com/hubblo-org/windows-rapl-driver) |
| CPU | Raspberry Pi, Asus Tinker Board | Linux | Research-based regression power models |
| GPU | Nvidia cards | Linux, Windows | NVML, installed with the Nvidia driver |
| GPU | AMD cards | Linux | amdgpu hwmon sysfs |
| GPU | AMD cards | Windows | ADLX, installed with the AMD driver |
| Whole machine | Any of the above, from inside a virtual machine | Linux, Windows | A file the host writes the power to |

The supported single-board computers are the Raspberry Pi models 5B, 400, 4B, 3B+, 3B, 2B, 1B+, 1B and Zero W, and the Asus Tinker Board (S). Every revision of each model is supported, though the power model was trained on one particular revision, on which the accuracy is at its best.

PowerJoular does the energy and CPU usage measuring through two Ada libraries we developed:

- [Joular Core](https://github.com/joular/joularcore): for CPU and GPU energy and power consumption.
- [CPU Load](https://github.com/joular/cpuload): for CPU usage for the whole system, a specific PID, and a specific application (all its PIDs).

### Required privileges

- **Linux, PC or server**: reading RAPL files needs elevated on the recent kernels (5.10 and newer), so run `sudo powerjoular`, or giving read rights to the files. See [this issue](https://github.com/joular/powerjoular/issues/1).
- **Windows**: install [Hubblo's RAPL driver](https://github.com/hubblo-org/windows-rapl-driver). The easiest way to get a signed version installed is through the [Scaphandre installer](https://github.com/hubblo-org/scaphandre/releases).
- **Raspberry Pi and GPU readings**: no special privileges needed.

## :bulb: Usage

Run `powerjoular`. With no option, it prints the power of the machine on the terminal, once a second, until Ctrl+C.

```bash
sudo powerjoular
```

The following options are available:

| Option | What it does |
|---|---|
| `-h` | Show the help message |
| `-v` | Show the version number |
| `-t` | Print the power data on the terminal |
| `-d` | Print what the machine offers on start up |
| `-p pid` | Monitor the process with this number |
| `-a appName` | Monitor this application, and every process of it |
| `-f filename` | Add the power data to this file |
| `-o filename` | Keep only the latest power data in this file (the file is overwritten every second) |
| `-r` | Write the power data to a shared memory ring buffer |
| `-m filename` | Read the power of this machine from the file the host writes, when running inside a virtual machine |
| `-s format` | Format of that file, either `powerjoular` or `watts` |

Options can be mixed, i.e., `powerjoular -tp 144` monitors the process 144 and prints it on the terminal.

Monitoring a process or an application writes **two** CSV files: the given filename for the whole system, and the same name with the process number or the application name added to it for the process or the application.

### Exporting to CSV

`-f` adds a row every second and starts the file with a header:

```
Timestamp,CPU Usage,Total Power,CPU Power,GPU Power
1756681930,0.2460,18.4500,15.2000,3.2500
```

The file of a monitored process or application holds the load and the power of that process or application:

```
Timestamp,CPU Usage,CPU Power
1756681930,0.0310,1.8400
```

`-o` writes the latest measurement only: the file is rewritten every second and carries no header, which is a good option for another program polling it for the current value.

The time of the measurement is a Unix timestamp.

### Exporting to a shared memory ring buffer

`-r` writes every measurement to a shared memory ring buffer, that any program on the same machine can read with low latency.

| OS | Where the area lives |
|---|---|
| Linux | `/dev/shm/joularcorering` |
| Windows | `Local\JoularCoreRing` |
| Other | `/tmp/joularcorering` |

The area is 248 bytes, in the byte order of the machine: a counter of 8 bytes, then 5 entries of 48 bytes each.

| Field | Type | Meaning |
|---|---|---|
| `timestamp` | unsigned, 8 bytes | Unix time in seconds |
| `cpu_power` | IEEE double | CPU power in watts |
| `gpu_power` | IEEE double | GPU power in watts |
| `total_power` | IEEE double | CPU plus GPU power in watts |
| `cpu_usage` | IEEE double | Load of the machine, from 0.0 to 1.0 |
| `pid_app_power` | IEEE double | Power of the monitored process or application in watts, zero when none is monitored |

A measurement goes in the entry the counter points at (`counter mod 5`), and the counter is raised afterwards. A reader follows the counter to know when a new measurement has landed, and the timestamps to know how old each entry is.

### Monitoring inside a virtual machine

The hardware cannot be measured from inside a virtual machine, so the power value has to come from the host, with these steps:

- On the host, monitor power consumption of the virtual machine itself, and write its power to a file shared with the guest. You can use any program to monitor the VM's power consumption, but also PowerJoular.
- In the guest, run PowerJoular with `-m` pointing at the file the host writes and `-s` indicating the file format.

The two formats `-s` takes:

- `powerjoular`: the three column CSV that `-o` writes for a monitored process, timestamp, CPU load and power, where the power is the third column.
- `watts`: a file holding the power in watts and nothing else.

`-s` says what is inside the file, so it goes together with the program the host runs.

**With PowerJoular on the host.** Monitor the specific process of the virtual machine, and not the whole system:

```bash
powerjoular -p 1234 -o /shared/vm-power.csv
```

This writes two files, and the one to share is the one carrying the process number: it alone holds the power of the virtual machine, while the other one holds the power of the whole host.

```bash
powerjoular -m /shared/vm-power.csv-1234.csv -s powerjoular -t
```

**With another program on the host.** Have it write the power in watts and nothing else, then read that file with the `watts` format:

```bash
powerjoular -m /shared/vm-power.txt -s watts -t
```

## :package: Installation

PowerJoular is one binary that can be copied to any machine of the same architecture and run as it is.

Ready-made packages, and easy-to-use installation scripts in the `installer` folder:

- `installer/bash-installer/build-install.sh`: builds the program and installs the binary in `/usr/bin` along with the systemd service.
- `installer/bash-installer/uninstall.sh`: removes both again.

## :floppy_disk: Compilation

PowerJoular is written in Ada and needs a modern Ada compiler such as GNAT, together with the [Joular Core](https://github.com/joular/joularcore) and [CPU Load](https://github.com/joular/cpuload) libraries.

### With Alire

[Alire](https://alire.ada.dev/) fetches the two libraries on its own, so this is the shortest way:

```bash
alr build
```

The binary lands in `bin/powerjoular`.

### With GNAT and GPRBuild

Check out the two libraries next to this repository, then point GPRBuild at them:

```bash
gprbuild -P powerjoular.gpr -aP../joularcore -aP../cpuload -p
```

To build for another OS than the one you are on, set `PJ_OS`:

```bash
gprbuild -P powerjoular.gpr -aP../joularcore -aP../cpuload -XPJ_OS=windows -p
```

### A binary with no dependencies at all

By default the Ada runtime and libgcc are carried inside the binary, which is enough to copy it to another machine of the same architecture and run it there. To leave nothing at all outside it, including the C library:

```bash
gprbuild -P powerjoular.gpr -aP../joularcore -aP../cpuload -XPOWERJOULAR_LINKING=full -p
```

On GNU/Linux, a fully static binary cannot load a library while it runs, so the Nvidia and AMD graphic card readings, which do exactly that, are lost with this option. The processor readings are not affected, and PowerJoular carries on without the GPU rather than failing.

### Cross-compilation and package generation

`release-version.sh` cross-compiles PowerJoular for several architectures (x86_64 and aarch64 for now, and it can be extended), then builds the RPM and DEB packages for them. It needs an x86_64 and an aarch64 GNAT compiler, Alire, and the `dpkg` and `rpm` packaging tools. On Ubuntu:

```bash
sudo apt install gnat gnat-12-aarch64-linux-gnu dpkg rpm
```

## :hourglass: Systemd service

A systemd service is provided in the `systemd` folder, and is installed by the GNU/Linux packages. It runs PowerJoular with `-o`, writing the latest power data to `/run/powerjoular/powerjoular-service.csv`. The folder is made by systemd when the service starts and removed when it stops, and anyone can read the file in it.

```bash
sudo systemctl start powerjoular.service
sudo systemctl enable powerjoular.service
```

## :sparkles: What changed in version 2

Version 2 does the measuring using the [Joular Core](https://github.com/joular/joularcore) and [CPU Load](https://github.com/joular/cpuload) libraries instead of its own code, which also include Windows support.

- **New**: `-r` writes the power data to a shared memory ring buffer.
- **Removed**: `-k`, which measured a process from its threads. It was experimental, and the process readings no longer need it.
- **Removed**: `-l`, which picked the linear power models of the single-board computers, has been removed. The default and only models used now are the polynomial models, which are much more accurate and their overhead is minimal.

Other main differences:

- The CSV files hold four digits after the dot instead of the fourteen. The columns and the header are have been renamed, with Timestamp and CPU Usage.
- The energy a RAPL processor reports is divided by how long the cycle actually took, rather than assumed to be exactly one second. On a machine running late, the watts reported are now the watts drawn.
- A file that cannot be written to, a power source that stops answering, or a ring buffer that cannot be opened is reported once and the monitoring continues.

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

Copyright (c) 2020-2026, Adel Noureddine.
All rights reserved. This program and the accompanying materials are made available under the terms of the GNU General Public License v3.0 only (GPL-3.0-only) which accompanies this distribution, and is available at: https://www.gnu.org/licenses/gpl-3.0.en.html

Author : Prof. Adel Noureddine
