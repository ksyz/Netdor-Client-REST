Name:           perl-Netdot-Client-REST
Version:        1.03
Release:        1%{?dist}
Summary:        RESTful API for Netdot
License:        GPL+ or Artistic
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/Netdot-Client-REST/
Source0:        http://www.cpan.org/authors/id/C/CV/CVICENTE/Netdot-Client-REST-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  perl(Data::Dumper)
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(LWP)
BuildRequires:  perl(Module::Build)
BuildRequires:  perl(XML::Simple)
Requires:       perl(Data::Dumper)
Requires:       perl(LWP)
Requires:       perl(XML::Simple)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
Netdot::Client::REST can be used in Perl scripts that need access to the
Netdot application database. Communication occurs over HTTP/HTTPS, thus
avoiding the need to open SQL access on the machine running Netdot.

%prep
%setup -q -n Netdot-Client-REST-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%check
./Build test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc META.json
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Fri Nov 13 2015 Michal Ingeli <mi@v3.sk> 1.03-1
- Specfile autogenerated by cpanspec 1.78.
