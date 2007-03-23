%define _unpackaged_files_terminate_build 0
Summary: perl-Attribute-Handlers 
Name: perl-Attribute-Handlers 
Version: 0.78 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: Attribute-Handlers-0.78.tar.gz 
BuildRoot: /tmp/Attribute-Handlers
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no

Provides: perl(Attribute::Handlers)

%description
Distribution id = A/AB/ABERGMAN/Attribute-Handlers-0.78.tar.gz
    CPAN_USERID  ABERGMAN (Artur Bergman <abergman@cpan.org>)
    CONTAINSMODS Attribute::Handlers
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/Attribute-Handlers-0.78
    localfile    /root/.cpan/sources/authors/id/A/AB/ABERGMAN/Attribute-Handlers-0.78.tar.gz
    unwrapped    YES



%prep
%setup -q -n Attribute-Handlers-0.78

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
  -type f -printf "/%%P\n" > Attribute-Handlers-filelist

if [ "$(cat Attribute-Handlers-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f Attribute-Handlers-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
