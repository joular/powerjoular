Name:           powerjoular
Version:        1.0.5
Release:        1%{?dist}
Summary:        PowerJoular allows monitoring power consumption of multiple platforms and processes.

License:        GPL-3.0-only
Source0:        %{_sourcedir}/obj/powerjoular
Source1:        %{_sourcedir}/powerjoular.service

%description
PowerJoular allows monitoring power consumption of multiple platforms and processes.

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_bindir}
mkdir -p $RPM_BUILD_ROOT/%{_sysconfdir}/systemd/system/
install -m 755 %{SOURCE0} $RPM_BUILD_ROOT/%{_bindir}/%{name}
install -m 644 %{SOURCE1} $RPM_BUILD_ROOT/%{_sysconfdir}/systemd/system/%{name}.service

%files
%{_bindir}/%{name}
%{_sysconfdir}/systemd/system/%{name}.service

%changelog
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
