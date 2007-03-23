%define _unpackaged_files_terminate_build 0
Summary: perl-Cache-FastMmap 
Name: perl-Cache-FastMmap 
Version: 1.14 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Cache-FastMmap-1.14.tar.gz 
BuildRoot: /tmp/Cache-FastMmap
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no
Requires: perl(Storable)
Provides: perl(Cache::FastMmap::CImpl) perl(Cache::FastMmap)

%description
Distribution id = R/RO/ROBM/Cache-FastMmap-1.14.tar.gz
    CPAN_USERID  ROBM (Rob Mueller <cpan@robm.fastmail.fm>)
    CONTAINSMODS Cache::FastMmap::CImpl Cache::FastMmap
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Cache-FastMmap-1.14
    localfile    /root/.cpan/sources/authors/id/R/RO/ROBM/Cache-FastMmap-1.14.tar.gz
    unwrapped    YES



%prep
%setup -q -n Cache-FastMmap-1.14

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
  -type f -printf "/%%P\n" > Cache-FastMmap-filelist

if [ "$(cat Cache-FastMmap-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Cache-FastMmap-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
