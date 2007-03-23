%define _unpackaged_files_terminate_build 0
Summary: perl-Storable 
Name: perl-Storable 
Version: 2.15 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Storable-2.15.tar.gz 
BuildRoot: /tmp/Storable
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no

Provides: perl(Storable)

%description
Distribution id = A/AM/AMS/Storable-2.15.tar.gz
    CPAN_USERID  AMS (Abhijit Menon-Sen <ams@wiw.org>)
    CONTAINSMODS Storable
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Storable-2.15
    localfile    /root/.cpan/sources/authors/id/A/AM/AMS/Storable-2.15.tar.gz
    unwrapped    YES



%prep
%setup -q -n Storable-2.15

%build
CFLAGS="$RPM_OPT_FLAGS $CFLAGS" perl Makefile.PL 
make

%clean 
if [ "%{buildroot}" != "/" ]; then
  rm -rf %{buildroot} 
fi


%install

make PREFIX=%{_prefix} \
     DESTDIR=%{buildroot} \
     INSTALLDIRS=site \
     install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find ${RPM_BUILD_ROOT} \
  \( -path '*/perllocal.pod' -o -path '*/.packlist' -o -path '*.bs' \) -a -prune -o \
  -type f -printf "/%%P\n" > Storable-filelist

if [ "$(cat Storable-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Storable-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
