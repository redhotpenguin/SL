%define _unpackaged_files_terminate_build 0
Summary: perl-Test 
Name: perl-Test 
Version: 1.25 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Test-1.25.tar.gz 
BuildRoot: /tmp/Test
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no
Requires: perl(Test::Harness) >= 1.1601 perl(File::Spec)
Provides: perl(Test)

%description
Distribution id = S/SB/SBURKE/Test-1.25.tar.gz
    CPAN_USERID  SBURKE (Sean M. Burke <sburke@cpan.org>)
    CONTAINSMODS Test
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Test-1.25
    localfile    /root/.cpan/sources/authors/id/S/SB/SBURKE/Test-1.25.tar.gz
    unwrapped    YES



%prep
%setup -q -n Test-1.25

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
  -type f -printf "/%%P\n" > Test-filelist

if [ "$(cat Test-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Test-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
