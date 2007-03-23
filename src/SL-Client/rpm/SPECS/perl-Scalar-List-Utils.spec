%define _unpackaged_files_terminate_build 0
Summary: perl-Scalar-List-Utils 
Name: perl-Scalar-List-Utils 
Version: 1.19 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Scalar-List-Utils-1.19.tar.gz 
BuildRoot: /tmp/Scalar-List-Utils
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no

Provides: perl(List::Util) perl(Scalar::Util)

%description
Distribution id = G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz
    CPAN_USERID  GBARR (Graham Barr <gbarr@pobox.com>)
    CONTAINSMODS List::Util Scalar::Util
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Scalar-List-Utils-1.19
    localfile    /root/.cpan/sources/authors/id/G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz
    unwrapped    YES



%prep
%setup -q -n Scalar-List-Utils-1.19

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
  -type f -printf "/%%P\n" > Scalar-List-Utils-filelist

if [ "$(cat Scalar-List-Utils-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Scalar-List-Utils-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
