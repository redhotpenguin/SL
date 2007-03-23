%define _unpackaged_files_terminate_build 0
Summary: perl-Test-Harness 
Name: perl-Test-Harness 
Version: 2.64 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Test-Harness-2.64.tar.gz 
BuildRoot: /tmp/Test-Harness
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no
Requires: perl(File::Spec) >= 0.6
Provides: perl(Test::Harness::Util) perl(Test::Harness) perl(Test::Harness::Iterator) perl(Test::Harness::Assert) perl(Test::Harness::Straps) perl(Test::Harness::Point) perl(Test::Harness::Results)

%description
Distribution id = P/PE/PETDANCE/Test-Harness-2.64.tar.gz
    CPAN_USERID  PETDANCE (Andy Lester <andy@petdance.com>)
    CONTAINSMODS Test::Harness::Util Test::Harness Test::Harness::Iterator Test::Harness::Assert Test::Harness::Straps Test::Harness::Point Test::Harness::Results
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Test-Harness-2.64
    localfile    /root/.cpan/sources/authors/id/P/PE/PETDANCE/Test-Harness-2.64.tar.gz
    unwrapped    YES



%prep
%setup -q -n Test-Harness-2.64

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
  -type f -printf "/%%P\n" > Test-Harness-filelist

if [ "$(cat Test-Harness-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Test-Harness-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
