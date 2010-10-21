# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-assistant/qt-assistant-4.7.0.ebuild,v 1.6 2010/10/20 13:19:58 ranger Exp $

EAPI="3"
inherit qt4-build multilib-native

DESCRIPTION="The assistant help module for the Qt toolkit"
SLOT="4"
KEYWORDS="~amd64 ~arm ~ia64 ~ppc ~x86"
IUSE="compat doc +glib trace"
SRC_URI+=" compat? ( ftp://ftp.qt.nokia.com/qt/source/${PN}-qassistantclient-library-compat-src-4.6.3.tar.gz )"

DEPEND="~x11-libs/qt-gui-${PV}[aqua=,glib=,trace?,lib32?]
	~x11-libs/qt-sql-${PV}[aqua=,sqlite,lib32?]
	~x11-libs/qt-webkit-${PV}[aqua=,lib32?]
	~x11-libs/qt-declarative-${PV}"
RDEPEND="${DEPEND}"

multilib-native_pkg_setup_internal() {
	# Pixeltool isn't really assistant related, but it relies on
	# the assistant libraries. doc/qch/
	QT4_TARGET_DIRECTORIES="
		tools/assistant
		tools/pixeltool
		tools/qdoc3"
	QT4_EXTRACT_DIRECTORIES="
		tools/
		demos/
		examples/
		src/
		include/
		doc/"

	use trace && QT4_TARGET_DIRECTORIES="${QT4_TARGET_DIRECTORIES}
		tools/qttracereplay"
	QT4_EXTRACT_DIRECTORIES="${QT4_TARGET_DIRECTORIES}
		${QT4_EXTRACT_DIRECTORIES}"
	qt4-build_pkg_setup
}

multilib-native_src_unpack_internal() {
	qt4-build_src_unpack
	# compat version
	# http://labs.qt.nokia.com/2010/06/22/qt-assistant-compat-version-available-as-extra-source-package/
	if use compat; then
		unpack "${PN}"-qassistantclient-library-compat-src-4.6.3.tar.gz
		mv "${WORKDIR}"/"${PN}"-qassistantclient-library-compat-version-4.6.3 \
			"${S}"/tools/assistant/compat ||
				die "moving compat to the right place failed"
		tar xzf "${FILESDIR}"/"${PN}"-4.7-include.tar.gz -C "${S}"/include/ ||
			die "unpacking the include files failed"
	fi
}

multilib-native_src_prepare_internal() {
	qt4-build_src_prepare
	if use compat; then
		epatch "${FILESDIR}"/"${PN}"-4.7-fix-compat.patch
	fi
}

multilib-native_src_configure_internal() {
	myconf="${myconf} -no-xkb -no-fontconfig -no-xrender -no-xrandr
		-no-xfixes -no-xcursor -no-xinerama -no-xshape -no-sm -no-opengl
		-no-nas-sound -no-dbus -iconv -no-cups -no-nis -no-gif -no-libpng
		-no-libmng -no-libjpeg -no-openssl -system-zlib -no-phonon
		-no-xmlpatterns -no-freetype -no-libtiff -no-accessibility
		-no-fontconfig -no-multimedia -no-qt3support -no-svg"
	! use glib && myconf="${myconf} -no-glib"
	qt4-build_src_configure
}

multilib-native_src_compile_internal() {
	# help libQtHelp find freshly built libQtCLucene (bug #289811)
	export LD_LIBRARY_PATH="${S}/lib:${QTLIBDIR}"
	export DYLD_LIBRARY_PATH="${S}/lib:${S}/lib/QtHelp.framework"

	qt4-build_src_compile

	# ugly hack to build docs
	cd "${S}"
	qmake "LIBS+=-L${QTLIBDIR}" "CONFIG+=nostrip" projects.pro || die
	emake qch_docs || die "emake qch_docs failed"
	if use doc; then
		emake docs || die "emake docs failed"
	fi
	qmake "LIBS+=-L${QTLIBDIR}" "CONFIG+=nostrip" projects.pro || die
}

multilib-native_src_install_internal() {
	qt4-build_src_install
	cd "${S}"
	emake INSTALL_ROOT="${D}" install_qchdocs \
		|| die "failed to install qch docs"
	if use doc; then
		emake INSTALL_ROOT="${D}" install_htmldocs \
			|| die "failed to install htmldocs"
	fi
	dobin "${S}"/bin/qdoc3 || die "Failed to install qdoc3"
	# install correct assistant icon, bug 241208
	dodir /usr/share/pixmaps/ || die "dodir failed"
	insinto /usr/share/pixmaps/
	doins tools/assistant/tools/assistant/images/assistant.png ||
		die "doins failed"
	# Note: absolute image path required here!
	make_desktop_entry "${EPREFIX}"/usr/bin/assistant Assistant \
		"${EPREFIX}"/usr/share/pixmaps/assistant.png 'Qt;Development;GUIDesigner' ||
			die "make_desktop_entry failed"

	if use compat; then
		insinto /usr/share/qt4/mkspecs/features || die "insinto failed"
		doins tools/assistant/compat/features/assistant.prf || die "doins failed"
	fi
}
