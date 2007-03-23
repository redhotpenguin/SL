%define _unpackaged_files_terminate_build 0
Summary: perl-PathTools 
Name: perl-PathTools 
Version: 3.24 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: PathTools-3.24.tar.gz 
BuildRoot: /tmp/PathTools
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no
Requires: perl(Scalar::Util) perl(Test) perl(File::Path) perl(File::Basename) perl(Carp)
Provides: perl(File::Spec::Win32) perl(File::Spec::Epoc) perl(File::Spec) perl(File::Spec::Unix) perl(File::Spec::OS2) perl(File::Spec::VMS) perl(File::Spec::Functions) perl(File::Spec::Cygwin) perl(File::Spec::Mac) perl(Cwd)

%description
Distribution id = K/KW/KWILLIAMS/PathTools-3.24.tar.gz
    CPAN_USERID  KWILLIAMS (Ken Williams <ken@mathforum.org>)
    CONTAINSMODS File::Spec::Win32 File::Spec::Epoc File::Spec File::Spec::Unix File::Spec::OS2 File::Spec::VMS File::Spec::Functions File::Spec::Cygwin File::Spec::Mac Cwd
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/PathTools-3.24
    localfile    /root/.cpan/sources/authors/id/K/KW/KWILLIAMS/PathTools-3.24.tar.gz
    unwrapped    YES



%prep
%setup -q -n PathTools-3.24

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
  -type f -printf "/%%P\n" > PathTools-filelist

if [ "$(cat PathTools-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f PathTools-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
