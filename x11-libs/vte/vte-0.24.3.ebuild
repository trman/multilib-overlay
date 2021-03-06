# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/vte/vte-0.24.3.ebuild,v 1.7 2010/10/17 14:52:29 armin76 Exp $

EAPI="2"

inherit gnome2 eutils multilib-native

DESCRIPTION="Gnome terminal widget"
HOMEPAGE="http://www.gnome.org/"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ~hppa ia64 ppc ppc64 sh sparc x86 ~x86-fbsd"
IUSE="debug doc glade python"

RDEPEND=">=dev-libs/glib-2.22.0[lib32?]
	>=x11-libs/gtk+-2.14.0[lib32?]
	>=x11-libs/pango-1.22.0[lib32?]
	sys-libs/ncurses[lib32?]
	glade? ( dev-util/glade:3 )
	python? ( >=dev-python/pygtk-2.4[lib32?] )
	x11-libs/libX11[lib32?]
	x11-libs/libXft[lib32?]"
DEPEND="${RDEPEND}
	doc? ( >=dev-util/gtk-doc-1.13 )
	>=dev-util/intltool-0.35
	>=dev-util/pkgconfig-0.9[lib32?]
	sys-devel/gettext[lib32?]"

DOCS="AUTHORS ChangeLog HACKING NEWS README"

multilib-native_pkg_setup_internal() {
	G2CONF="${G2CONF}
		--disable-deprecation
		--disable-static
		$(use_enable debug)
		$(use_enable glade glade-catalogue)
		$(use_enable python)
		--with-html-dir=/usr/share/doc/${PF}/html"
}

multilib-native_src_prepare_internal() {
	gnome2_src_prepare

	# Fix ugly artifacts with upstream patches from bgo#618749
	# FIXME: Second patch needs to be skipped since it causes problems with
	# x11-terms/terminal, see bug #324631. If this is not solved by upstream,
	# the problem could reappear with >=x11-libs/vte-0.25.2
	epatch "${FILESDIR}/${PN}-0.24.1-background-color.patch"
#	epatch "${FILESDIR}/${PN}-0.24.1-background-color2.patch"
	epatch "${FILESDIR}/${PN}-0.24.1-cleanup-background.patch"

	# Prevent cursor from become invisible, bgo#602596
	# FIXME: The following patches cannot be applied until bug #323443 is solved.
#	epatch "${FILESDIR}/${PN}-0.24.2-invisible-cursor.patch"
#	epatch "${FILESDIR}/${PN}-0.24.2-invisible-cursor2.patch"
}
