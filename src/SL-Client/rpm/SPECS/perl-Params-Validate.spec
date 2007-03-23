%define _unpackaged_files_terminate_build 0
Summary: perl-Params-Validate 
Name: perl-Params-Validate 
Version: 0.88 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Params-Validate-0.88.tar.gz 
BuildRoot: /tmp/Params-Validate
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no
Requires: perl(Scalar::Util) perl(Test::More) perl(Attribute::Handlers)
Provides: perl(Attribute::Params::Validate) perl(Params::Validate)

%description
Distribution id = D/DR/DROLSKY/Params-Validate-0.88.tar.gz
    CPAN_USERID  DROLSKY (Dave Rolsky <autarch@urth.org>)
    CONTAINSMODS Attribute::Params::Validate Params::Validate
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Params-Validate-0.88
    localfile    /root/.cpan/sources/authors/id/D/DR/DROLSKY/Params-Validate-0.88.tar.gz
    unwrapped    YES



%prep
%setup -q -n Params-Validate-0.88

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
  -type f -printf "/%%P\n" > Params-Validate-filelist

if [ "$(cat Params-Validate-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Params-Validate-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
