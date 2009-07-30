# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/qt-assistant/qt-assistant-4.4.2-r1.ebuild,v 1.10 2009/03/16 00:48:06 zmedico Exp $

EAPI="2"
inherit qt4-build multilib-native

DESCRIPTION="The assistant help module for the Qt toolkit"
HOMEPAGE="http://www.trolltech.com/"

LICENSE="|| ( GPL-3 GPL-2 )"
SLOT="4"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="+webkit"

DEPEND="~x11-libs/qt-gui-${PV}[lib32?]
	~x11-libs/qt-sql-${PV}[lib32?]
	webkit? ( ~x11-libs/qt-webkit-${PV}[lib32?] )"
RDEPEND="${DEPEND} !<x11-libs/qt-4.4.0:4"

# Pixeltool isn't really assistant related, but it relies on
# the assistant libraries.
QT4_TARGET_DIRECTORIES="tools/assistant tools/pixeltool"
QT4_EXTRACT_DIRECTORIES="${QT4_TARGET_DIRECTORIES}
doc/qch/
src/3rdparty/clucene/
tools/shared/fontpanel"

multilib-native_pkg_setup_internal() {
	qt4-build_pkg_setup

	if ! built_with_use x11-libs/qt-sql sqlite; then
		die "You must first emerge x11-libs/qt-sql with the \"sqlite\" use flag in order to use qt-assistant"
	fi
}

multilib-native_src_configure_internal() {
	local myconf
	myconf="${myconf} -no-xkb -no-tablet -no-fontconfig -no-xrender -no-xrandr
		-no-xfixes -no-xcursor -no-xinerama -no-xshape -no-sm -no-opengl
		-no-nas-sound -no-dbus -iconv -no-cups -no-nis -no-gif -no-libpng
		-no-libmng -no-libjpeg -no-openssl -system-zlib -no-phonon
		-no-xmlpatterns -no-freetype -no-libtiff -no-accessibility
		-no-fontconfig -no-glib -no-opengl -no-qt3support -no-svg"
	if use webkit; then
		myconf="$myconf -assistant-webkit"
	else
		myconf="$myconf -no-webkit"
	fi

	qt4-build_src_configure
}

multilib-native_src_install_internal() {
	qt4-build_src_install

	# install correct assistant icon, bug 241208
	dodir /usr/share/pixmaps/ || die "dodir failed"
	insinto /usr/share/pixmaps/ || die "insinto failed"
	doins tools/assistant/tools/assistant/images/assistant.png \
		|| die "doins failed"
	# Note: absolute image path required here!
	make_desktop_entry /usr/bin/assistant Assistant \
		/usr/share/pixmaps/assistant.png 'Qt;Development;GUIDesigner' \
		|| die "make_desktop_entry failed"

	insinto ${QTDOCDIR}
	doins -r doc/qch/ || die 'Installing qch files failed'
}
