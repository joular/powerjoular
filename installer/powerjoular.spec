Name:           powerjoular
Version:        0.7.3
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
* Thu Jun 20 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 0.8.0-1
- Version 0.8.0
* Thu Jun 06 2024 Adel Noureddine <adel.noureddine@univ-pau.fr> - 0.7.3-1
- First RPM build
