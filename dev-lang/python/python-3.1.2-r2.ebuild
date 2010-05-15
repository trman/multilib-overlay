# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-lang/python/python-3.1.2-r2.ebuild,v 1.1 2010/04/11 21:22:49 arfrever Exp $

EAPI="2"

inherit autotools eutils flag-o-matic multilib pax-utils python toolchain-funcs multilib-native

MY_P="Python-${PV}"
S="${WORKDIR}/${MY_P}"

PATCHSET_REVISION="3"

DESCRIPTION="Python is an interpreted, interactive, object-oriented programming language."
HOMEPAGE="http://www.python.org/"
SRC_URI="http://www.python.org/ftp/python/${PV}/${MY_P}.tar.bz2
	mirror://gentoo/python-gentoo-patches-${PV}$([[ "${PATCHSET_REVISION}" != "0" ]] && echo "-r${PATCHSET_REVISION}").tar.bz2"

LICENSE="PSF-2.2"
SLOT="3.1"
PYTHON_ABI="${SLOT}"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~sparc-fbsd ~x86-fbsd"
IUSE="build doc elibc_uclibc examples gdbm ipv6 +ncurses +readline sqlite ssl +threads tk +wide-unicode wininst +xml"

RDEPEND=">=app-admin/eselect-python-20090606
		>=sys-libs/zlib-1.1.3[lib32?]
		virtual/libffi
		virtual/libintl
		!build? (
			doc? ( dev-python/python-docs:${SLOT} )
			gdbm? ( sys-libs/gdbm[lib32?] )
			ncurses? (
				>=sys-libs/ncurses-5.2[lib32?]
				readline? ( >=sys-libs/readline-4.1[lib32?] )
			)
			sqlite? ( >=dev-db/sqlite-3[lib32?] )
			ssl? ( dev-libs/openssl[lib32?] )
			tk? ( >=dev-lang/tk-8.0[lib32?] )
			xml? ( >=dev-libs/expat-2[lib32?] )
		)"
DEPEND="${RDEPEND}
		dev-util/pkgconfig
		!sys-devel/gcc[libffi]"
RDEPEND+=" !build? ( app-misc/mime-types )"
PDEPEND="app-admin/python-updater
		|| ( dev-lang/python:2.7 dev-lang/python:2.6 )"

PROVIDE="virtual/python"

multilib-native_src_prepare_internal() {
	# Ensure that internal copies of expat and libffi aren't used.
	rm -fr Modules/expat
	rm -fr Modules/_ctypes/libffi*

	if ! tc-is-cross-compiler; then
		rm "${WORKDIR}/${PV}"/*_all_crosscompile.patch
	fi

	EPATCH_SUFFIX="patch" epatch "${WORKDIR}/${PV}"

	sed -i -e "s:@@GENTOO_LIBDIR@@:$(get_libdir):g" \
		Lib/distutils/command/install.py \
		Lib/distutils/sysconfig.py \
		Lib/site.py \
		Makefile.pre.in \
		Modules/Setup.dist \
		Modules/getpath.c \
		setup.py || die "sed failed to replace @@GENTOO_LIBDIR@@"

	# Fix os.utime() on hppa. utimes it not supported but unfortunately reported as working - gmsoft (22 May 04)
	# PLEASE LEAVE THIS FIX FOR NEXT VERSIONS AS IT'S A CRITICAL FIX !!!
	[[ "${ARCH}" == "hppa" ]] && sed -e "s/utimes //" -i "${S}/configure"

	if ! use wininst; then
		# Remove Microsoft Windows executables.
		rm Lib/distutils/command/wininst-*.exe
	fi

	# Fix OtherFileTests.testStdin() not to assume
	# that stdin is a tty for bug #248081.
	sed -e "s:'osf1V5':'osf1V5' and sys.stdin.isatty():" -i Lib/test/test_file.py || die "sed failed"

	eautoreconf
}

multilib-native_src_configure_internal() {
	# Disable extraneous modules with extra dependencies.
	if use build; then
		export PYTHON_DISABLE_MODULES="gdbm _curses _curses_panel readline _sqlite3 _tkinter _elementtree pyexpat"
		export PYTHON_DISABLE_SSL="1"
	else
		local disable
		use gdbm     || disable+=" gdbm"
		use ncurses  || disable+=" _curses _curses_panel"
		use readline || disable+=" readline"
		use sqlite   || disable+=" _sqlite3"
		use ssl      || export PYTHON_DISABLE_SSL="1"
		use tk       || disable+=" _tkinter"
		use xml      || disable+=" _elementtree pyexpat" # _elementtree uses pyexpat.
		export PYTHON_DISABLE_MODULES="${disable}"

		if ! use xml; then
			ewarn "You have configured Python without XML support."
			ewarn "This is NOT a recommended configuration as you"
			ewarn "may face problems parsing any XML documents."
		fi
	fi

	if [[ -n "${PYTHON_DISABLE_MODULES}" ]]; then
		einfo "Disabled modules: ${PYTHON_DISABLE_MODULES}"
	fi

	filter-flags -malign-double

	[[ "${ARCH}" == "alpha" ]] && append-flags -fPIC

	# https://bugs.gentoo.org/show_bug.cgi?id=50309
	if is-flag -O3; then
		is-flag -fstack-protector-all && replace-flags -O3 -O2
		use hardened && replace-flags -O3 -O2
	fi

	if tc-is-cross-compiler; then
		OPT="-O1" CFLAGS="" LDFLAGS="" CC="" \
		./configure --{build,host}=${CBUILD} || die "cross-configure failed"
		emake python Parser/pgen || die "cross-make failed"
		mv python hostpython
		mv Parser/pgen Parser/hostpgen
		make distclean
		sed -i \
			-e "/^HOSTPYTHON/s:=.*:=./hostpython:" \
			-e "/^HOSTPGEN/s:=.*:=./Parser/hostpgen:" \
			Makefile.pre.in || die "sed failed"
	fi

	# Export CXX so it ends up in /usr/lib/python3.X/config/Makefile.
	tc-export CXX

	# Set LDFLAGS so we link modules with -lpython3.1 correctly.
	# Needed on FreeBSD unless Python 3.1 is already installed.
	# Please query BSD team before removing this!
	append-ldflags "-L."

	local dbmliborder
	if use gdbm; then
		dbmliborder+="${dbmliborder:+:}gdbm"
	fi

	OPT="" econf \
		--with-fpectl \
		--enable-shared \
		$(use_enable ipv6) \
		$(use_with threads) \
		$(use_with wide-unicode) \
		--infodir='${prefix}'/share/info \
		--mandir='${prefix}'/share/man \
		--with-computed-gotos \
		--with-dbmliborder=${dbmliborder} \
		--with-libc='' \
		--with-system-ffi
}

multilib-native_src_compile_internal() {
	emake EXTRA_CFLAGS="${CFLAGS}" || die "emake failed"
}

multilib-native_src_test_internal() {
	# Tests won't work when cross compiling.
	if tc-is-cross-compiler; then
		elog "Disabling tests due to crosscompiling."
		return
	fi

	# Byte compiling should be enabled here.
	# Otherwise test_import fails.
	python_enable_pyc

	# Skip all tests that fail during emerge but pass without emerge:
	# (See bug #67970)
	local skip_tests="distutils"

	# test_ctypes fails with PAX kernel (bug #234498).
	host-is-pax && skip_tests+=" ctypes"

	for test in ${skip_tests}; do
		mv "${S}/Lib/test/test_${test}.py" "${T}"
	done

	# Rerun failed tests in verbose mode (regrtest -w).
	EXTRATESTOPTS="-w" make test || die "make test failed"

	for test in ${skip_tests}; do
		mv "${T}/test_${test}.py" "${S}/Lib/test/test_${test}.py"
	done

	elog "The following tests have been skipped:"
	for test in ${skip_tests}; do
		elog "test_${test}.py"
	done

	elog "If you'd like to run them, you may:"
	elog "cd $(python_get_libdir)/test"
	elog "and run the tests separately."

	python_disable_pyc
}

multilib-native_src_install_internal() {
	emake DESTDIR="${D}" altinstall || die "emake altinstall failed"

	mv "${D}usr/bin/python${SLOT}-config" "${D}usr/bin/python-config-${SLOT}"

	# Fix collisions between different slots of Python.
	mv "${D}usr/bin/2to3" "${D}usr/bin/2to3-${SLOT}"
	mv "${D}usr/bin/pydoc3" "${D}usr/bin/pydoc${SLOT}"
	mv "${D}usr/bin/idle3" "${D}usr/bin/idle${SLOT}"
	rm -f "${D}usr/bin/smtpd.py"

	if use build; then
		rm -fr "${D}$(python_get_libdir)/"{email,sqlite3,test,tkinter}
	else
		use elibc_uclibc && rm -fr "${D}$(python_get_libdir)/test"
		use sqlite || rm -fr "${D}$(python_get_libdir)/"{sqlite3,test/test_sqlite*}
		use tk || rm -fr "${D}$(python_get_libdir)/"{tkinter,test/test_tk*}
	fi

	use threads || rm -fr "${D}$(python_get_libdir)/multiprocessing"

	prep_ml_includes $(python_get_includedir)

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins -r "${S}/Tools" || die "doins failed"
	fi

	newinitd "${FILESDIR}/pydoc.init" pydoc-${SLOT}
	newconfd "${FILESDIR}/pydoc.conf" pydoc-${SLOT}

	prep_ml_binaries usr/bin/python${SLOT} usr/bin/python-config-${SLOT}
}

multilib-native_pkg_preinst_internal() {
	if has_version "<${CATEGORY}/${PN}-${SLOT}" && ! has_version ">=${CATEGORY}/${PN}-${SLOT}_alpha"; then
		python_updater_warning="1"
	fi
}

eselect_python_update() {
	local ignored_python_slots_options=
	[[ "$(eselect python show)" == "python2."* ]] && ignored_python_slots_options="--ignore 3.0 --ignore 3.1 --ignore 3.2"

	# Create python3 symlink.
	eselect python update > /dev/null

	eselect python update ${ignored_python_slots_options}
}

multilib-native_pkg_postinst_internal() {
	eselect_python_update

	python_mod_optimize -x "(site-packages|test)" $(python_get_libdir)

	if [[ "$(eselect python show)" == "python2."* ]]; then
		ewarn
		ewarn "WARNING!"
		ewarn "Many Python modules haven't been ported yet to Python 3.*."
		ewarn "Python 3 hasn't been activated and Python wrapper is still configured to use Python 2."
		ewarn "You can manually activate Python ${SLOT} using \`eselect python set python${SLOT}\`."
		ewarn "It is recommended to currently have Python wrapper configured to use Python 2."
		ewarn "Having Python wrapper configured to use Python 3 is unsupported."
		ewarn
		ebeep 6
	fi

	if [[ "${python_updater_warning}" == "1" ]]; then
		ewarn
		ewarn "\e[1;31m************************************************************************\e[0m"
		ewarn
		ewarn "You have just upgraded from an older version of Python."
		ewarn "You should run 'python-updater \${options}' to rebuild Python modules."
		ewarn
		ewarn "\e[1;31m************************************************************************\e[0m"
		ewarn
		ebeep 12
	fi
}

pkg_postrm() {
	eselect_python_update

	python_mod_cleanup $(python_get_libdir)
}