%define _unpackaged_files_terminate_build 0
Summary: perl-SL-Client
Name: perl-SL-Client
Version: 0.2
Release: 1
License: Perl/Artistic License
Group: Applications/CPAN
Source: SL-Client-0.2.tar.gz 
BuildRoot: /tmp/SL-Client-0.2
Packager: fred@redhotpenguin.com 

%define __find_provides /usr/lib/rpm/find-provides.perl
%define __find_requires /usr/lib/rpm/find-requires.perl

%define _sl_conf_dir /usr/local/sl/conf

%description
Silver Lining Client

%prep
%setup -q -n SL-Client-0.2

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

mkdir -p %{buildroot}/usr/local/sl/conf
echo "current dir is " `pwd`
cp `pwd`/t/conf/proxy_list.txt %{buildroot}/%{_sl_conf_dir}
cp `pwd`/t/conf/ua_blacklist.txt %{buildroot}/%{_sl_conf_dir}
cp `pwd`/t/conf/ext_blacklist.txt %{buildroot}/%{_sl_conf_dir}
cp `pwd`/t/conf/url_blacklist.txt %{buildroot}/%{_sl_conf_dir}

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find ${RPM_BUILD_ROOT} \
  \( -path '*/perllocal.pod' -o -path '*/.packlist' -o -path '*.bs' \) -a -prune -o \
  -type f -printf "/%%P\n" > SL-Client-filelist

if [ "$(cat SL-Client-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f SL-Client-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
