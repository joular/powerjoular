Name:           powerjoular
Version:        2.0.0
Release:        1%{?dist}
Summary:        Monitor the power consumption of platforms, processes and applications

License:        GPL-3.0-only
URL:            https://github.com/joular/powerjoular
Source0:        %{_sourcedir}/powerjoular
Source1:        %{_sourcedir}/powerjoular.service

%{!?_unitdir: %global _unitdir %{_prefix}/lib/systemd/system}

%description
PowerJoular monitors, in real time, the power consumption of hardware components (CPU, GPU), processes and applications, on Linux, macOS, Windows and FreeBSD.
It follows one process or one whole application, and exports power values to the terminal, to CSV files, and to a shared memory ring buffer.

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
mkdir -p $RPM_BUILD_ROOT/%{_unitdir}
install -m 755 %{SOURCE0} $RPM_BUILD_ROOT/%{_bindir}/%{name}
install -m 644 %{SOURCE1} $RPM_BUILD_ROOT/%{_unitdir}/%{name}.service

# systemd learns about the unit on install and forgets it on removal
%post
if [ -d /run/systemd/system ]; then systemctl daemon-reload > /dev/null 2>&1 || :; fi

%postun
if [ -d /run/systemd/system ]; then systemctl daemon-reload > /dev/null 2>&1 || :; fi

%files
%{_bindir}/%{name}
%{_unitdir}/%{name}.service

%changelog
* Wed Sep 30 2026 Adel Noureddine <adel.noureddine@outlook.com> - 2.0.0-1
- Measure through the Joular Core and CPU Load libraries
- Add Windows, macOS and FreeBSD support
- Add the shared memory ring buffer export (-r)
- Remove the experimental -k option
- Remove the -l option: the polynomial power models are now the only ones used
- The systemd service writes to /run/powerjoular/powerjoular-service.csv instead of /tmp, and runs with reduced privileges
- The systemd service is installed in /usr/lib/systemd/system
* Fri Sep 19 2025 Adel Noureddine <adel.noureddine@parisnanterre.fr> - 1.1.1-1
- Fix Incorrect CPU power value after specific domain wrapping.
* Sat Mar 29 2025 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.1.0-1
- Add option to write timestamps in milliseconds instead of just seconds
- Write error messages to stderr
- Fix incorrect power value when multiple Nvidia GPUs are present
- Better way to handle mixed OS line ending (LF and CRLF)
* Tue Nov 19 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.0.5-1
- Hotfix: don't exit when DRAM energy can't be read
* Wed Jul 11 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.0.4-1
- Hotfix for error in updating PID list for monitoring an application by name
* Thu Jul 08 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.0.3-1
- Hotfix for handle exceptions for invalid command line arguments
* Thu Jul 08 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.0.2-1
- Handle exceptions for invalid command line arguments
- Add doc for VM in -h command
* Thu Jul 04 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.0.1-1
- Fix RPi 5 detection
* Thu Jun 20 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 1.0.0-1
- Version 1.0.0
* Thu Jun 06 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 0.7.3-1
- First RPM build
