# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-libs/db/db-4.6.21_p4.ebuild,v 1.11 2010/05/03 23:21:52 robbat2 Exp $

EAPI="2"

inherit eutils db flag-o-matic java-pkg-opt-2 autotools libtool multilib-native

#Number of official patches
#PATCHNO=`echo ${PV}|sed -e "s,\(.*_p\)\([0-9]*\),\2,"`
PATCHNO=${PV/*.*.*_p}
if [[ ${PATCHNO} == "${PV}" ]] ; then
	MY_PV=${PV}
	MY_P=${P}
	PATCHNO=0
else
	MY_PV=${PV/_p${PATCHNO}}
	MY_P=${PN}-${MY_PV}
fi

S="${WORKDIR}/${MY_P}/build_unix"
DESCRIPTION="Oracle Berkeley DB"
HOMEPAGE="http://www.oracle.com/technology/software/products/berkeley-db/index.html"
SRC_URI="http://download.oracle.com/berkeley-db/${MY_P}.tar.gz"
for (( i=1 ; i<=${PATCHNO} ; i++ )) ; do
	export SRC_URI="${SRC_URI} http://www.oracle.com/technology/products/berkeley-db/db/update/${MY_PV}/patch.${MY_PV}.${i}"
done

LICENSE="OracleDB"
SLOT="4.6"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~sparc-fbsd ~x86-fbsd"
IUSE="tcl java doc nocxx"

DEPEND="tcl? ( >=dev-lang/tcl-8.4[lib32?] )
	java? ( >=virtual/jdk-1.4 )
	>=sys-devel/binutils-2.16.1"
RDEPEND="tcl? ( dev-lang/tcl[lib32?] )
	java? ( >=virtual/jre-1.4 )"

multilib-native_src_prepare_internal() {
	cd "${S}"/..
	for (( i=1 ; i<=${PATCHNO} ; i++ ))
	do
		epatch "${DISTDIR}"/patch."${MY_PV}"."${i}"
	done
	epatch "${FILESDIR}"/"${PN}"-"${SLOT}"-libtool.patch

	# use the includes from the prefix
	epatch "${FILESDIR}"/"${PN}"-"${SLOT}"-jni-check-prefix-first.patch
	epatch "${FILESDIR}"/"${PN}"-4.3-listen-to-java-options.patch

	sed -e "/^DB_RELEASE_DATE=/s/%B %e, %Y/%Y-%m-%d/" -i dist/RELEASE

	# Include the SLOT for Java JAR files
	# This supersedes the unused jarlocation patches.
	sed -r -i \
		-e '/jarfile=.*\.jar$/s,(.jar$),-$(LIBVERSION)\1,g' \
		"${S}"/../dist/Makefile.in

	cd "${S}"/../dist
	rm -f aclocal/libtool.m4
	sed -i \
		-e '/AC_PROG_LIBTOOL$/aLT_OUTPUT' \
		configure.ac
	sed -i \
		-e '/^AC_PATH_TOOL/s/ sh, none/ bash, none/' \
		aclocal/programs.m4
	AT_M4DIR="aclocal aclocal_java" eautoreconf
	# Upstream sucks - they do autoconf and THEN replace the version variables.
	. ./RELEASE
	sed -i \
		-e "s/__EDIT_DB_VERSION_MAJOR__/$DB_VERSION_MAJOR/g" \
		-e "s/__EDIT_DB_VERSION_MINOR__/$DB_VERSION_MINOR/g" \
		-e "s/__EDIT_DB_VERSION_PATCH__/$DB_VERSION_PATCH/g" \
		-e "s/__EDIT_DB_VERSION_STRING__/$DB_VERSION_STRING/g" \
		-e "s/__EDIT_DB_VERSION_UNIQUE_NAME__/$DB_VERSION_UNIQUE_NAME/g" \
		-e "s/__EDIT_DB_VERSION__/$DB_VERSION/g" configure
}

multilib-native_src_configure_internal() {
	# compilation with -O0 fails on amd64, see bug #171231
	if use amd64 && [ ${ABI} = "amd64" ]; then
		replace-flags -O0 -O2
		is-flagq -O[s123] || append-flags -O2
	fi

	local myconf=""

	use amd64 && [ ${ABI} = "amd64" ] && myconf="${myconf} --with-mutex=x86/gcc-assembly"

	myconf="${myconf} $(use_enable !nocxx cxx)"

	use tcl \
		&& myconf="${myconf} --enable-tcl --with-tcl=/usr/$(get_libdir)" \
		|| myconf="${myconf} --disable-tcl"

	myconf="${myconf} $(use_enable java)"
	if use java; then
		myconf="${myconf} --with-java-prefix=${JAVA_HOME}"
		# Can't get this working any other way, since it returns spaces, and
		# bash doesn't seem to want to pass correctly in any way i try
		local javaconf="-with-javac-flags=$(java-pkg_javac-args)"
	fi

	[[ -n ${CBUILD} ]] && myconf="${myconf} --build=${CBUILD}"

	# the entire testsuite needs the TCL functionality
	if use tcl && use test ; then
		myconf="${myconf} --enable-test"
	else
		myconf="${myconf} --disable-test"
	fi

	# Add linker versions to the symbols. Easier to do, and safer than header file
	# mumbo jumbo.
	if use userland_GNU; then
		append-ldflags -Wl,--default-symver
	fi

	cd "${S}" && ECONF_SOURCE="${S}"/../dist econf \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--datadir=/usr/share \
		--sysconfdir=/etc \
		--localstatedir=/var/lib \
		--libdir=/usr/"$(get_libdir)" \
		--enable-compat185 \
		--enable-o_direct \
		--without-uniquename \
		--enable-rpc \
		--host="${CHOST}" \
		${myconf}  "${javaconf}" || die "configure failed"

	sed -e "s,\(^STRIP *=\).*,\1\"true\"," Makefile > Makefile.cpy \
	    && mv Makefile.cpy Makefile
}

multilib-native_src_install_internal() {
	einstall libdir="${D}/usr/$(get_libdir)" STRIP="true" || die

	db_src_install_usrbinslot

	db_src_install_headerslot

	db_src_install_doc

	db_src_install_usrlibcleanup

	dodir /usr/sbin
	# This file is not always built, and no longer exists as of db-4.8
	[[ -f "${D}"/usr/bin/berkeley_db_svc ]] && \
	mv "${D}"/usr/bin/berkeley_db_svc "${D}"/usr/sbin/berkeley_db"${SLOT/./}"_svc

	if use java; then
		java-pkg_regso "${D}"/usr/"$(get_libdir)"/libdb_java*.so
		java-pkg_dojar "${D}"/usr/"$(get_libdir)"/*.jar
		rm -f "${D}"/usr/"$(get_libdir)"/*.jar
	fi
}

multilib-native_pkg_postinst_internal() {
	db_fix_so
}

multilib-native_pkg_postrm_internal() {
	db_fix_so
}
