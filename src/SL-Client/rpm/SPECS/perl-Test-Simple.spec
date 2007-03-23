%define _unpackaged_files_terminate_build 0
Summary: perl-Test-Simple 
Name: perl-Test-Simple 
Version: 0.70 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Test-Simple-0.70.tar.gz 
BuildRoot: /tmp/Test-Simple
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no
Requires: perl(Test::Harness) >= 2.03
Provides: perl(Test::More) perl(Test::Builder) perl(Test::Simple) perl(Test::Builder::Tester::Color) perl(Test::Builder::Tester) perl(Test::Builder::Module)

%description
Distribution id = M/MS/MSCHWERN/Test-Simple-0.70.tar.gz
    CPAN_USERID  MSCHWERN (Michael G Schwern <mschwern@cpan.org>)
    CONTAINSMODS Test::More Test::Builder Test::Simple Test::Builder::Tester::Color Test::Builder::Tester Test::Builder::Module
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Test-Simple-0.70
    localfile    /root/.cpan/sources/authors/id/M/MS/MSCHWERN/Test-Simple-0.70.tar.gz
    unwrapped    YES



%prep
%setup -q -n Test-Simple-0.70

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
  -type f -printf "/%%P\n" > Test-Simple-filelist

if [ "$(cat Test-Simple-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Test-Simple-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
