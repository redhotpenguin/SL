%define _unpackaged_files_terminate_build 0
Summary: perl-DBI 
Name: perl-DBI 
Version: 1.54 
Release: 1
License: Perl/Artistic License?
Group: Applications/CPAN
Source: DBI-1.54.tar.gz 
BuildRoot: /tmp/DBI
Packager: fred@redhotpenguin.com 
AutoReq: no
AutoReqProv: no

Provides: perl(DBI::SQL::Nano) perl(DBI::Gofer::Transport::stream) perl(DBD::ExampleP) perl(DBI::Util::_accessor) perl(DBI::Gofer::Response) perl(DBD::DBM) perl(DBI::Gofer::Execute) perl(DBD::Proxy) perl(DBD::Gofer::Policy::pedantic) perl(DBD::Gofer::Policy::Base) perl(DBI) perl(DBD::Sponge) perl(DBI::Profile) perl(DBD::Gofer) perl(DBI::Gofer::Transport::pipeone) perl(DBD::Gofer::Policy::classic) perl(DBD::Gofer::Transport::null) perl(DBI::ProfileDumper) perl(DBD::NullP) perl(DBD::Gofer::Transport::stream) perl(DBI::ProfileData) perl(DBI::ProfileDumper::Apache) perl(DBI::Const::GetInfoType) perl(DBI::Const::GetInfo::ODBC) perl(DBD::Gofer::Policy::rush) perl(DBI::Const::GetInfoReturn) perl(DBI::ProfileSubs) perl(DBD::Gofer::Transport::pipeone) perl(DBI::ProxyServer) perl(DBD::Gofer::Transport::http) perl(DBI::Const::GetInfo::ANSI) perl(DBD::File) perl(DBD::Gofer::Transport::Base) perl(DBI::Gofer::Transport::mod_perl) perl(DBI::Gofer::Request) perl(DBI::FAQ) perl(DBI::DBD) perl(DBI::Gofer::Transport::Base) perl(DBI::DBD::Metadata)

%description
Distribution id = T/TI/TIMB/DBI-1.54.tar.gz
    CPAN_USERID  TIMB (Tim Bunce <dbi-users@perl.org>)
    CONTAINSMODS DBI::SQL::Nano DBI::Gofer::Transport::stream DBD::ExampleP DBI::Util::_accessor DBI::Gofer::Response DBD::DBM DBI::Gofer::Execute DBD::Proxy DBD::Gofer::Policy::pedantic DBD::Gofer::Policy::Base DBI DBD::Sponge DBI::Profile DBD::Gofer DBI::Gofer::Transport::pipeone DBD::Gofer::Policy::classic DBD::Gofer::Transport::null DBI::ProfileDumper DBD::NullP DBD::Gofer::Transport::stream DBI::ProfileData DBI::ProfileDumper::Apache DBI::Const::GetInfoType DBI::Const::GetInfo::ODBC DBD::Gofer::Policy::rush DBI::Const::GetInfoReturn DBI::ProfileSubs DBD::Gofer::Transport::pipeone DBI::ProxyServer DBD::Gofer::Transport::http DBI::Const::GetInfo::ANSI DBD::File DBD::Gofer::Transport::Base DBI::Gofer::Transport::mod_perl DBI::Gofer::Request DBI::FAQ DBI::DBD DBI::Gofer::Transport::Base DBI::DBD::Metadata
    MD5_STATUS   OK
    archived     tar
    build_dir    /root/.cpan/build/DBI-1.54
    localfile    /root/.cpan/sources/authors/id/T/TI/TIMB/DBI-1.54.tar.gz
    unwrapped    YES



%prep
%setup -q -n DBI-1.54

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
  -type f -printf "/%%P\n" > DBI-filelist

if [ "$(cat DBI-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f DBI-filelist
%defattr(-,root,root)

%changelog
* Wed Mar 21 2007 fred@redhotpenguin.com 
- Initial build
