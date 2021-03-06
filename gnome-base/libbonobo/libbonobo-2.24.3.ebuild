# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/libbonobo/libbonobo-2.24.3.ebuild,v 1.10 2010/10/07 22:19:32 ssuominen Exp $

EAPI="2"
inherit gnome2 multilib-native

DESCRIPTION="GNOME CORBA framework"
HOMEPAGE="http://www.gnome.org/"

LICENSE="LGPL-2.1 GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ia64 ~mips ppc ppc64 sh sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~sparc-solaris ~x86-solaris"
IUSE="debug doc examples test"

RDEPEND=">=dev-libs/glib-2.14[lib32?]
	>=gnome-base/orbit-2.14.0[lib32?]
	>=dev-libs/libxml2-2.4.20[lib32?]
	>=sys-apps/dbus-1.0.0[lib32?]
	>=dev-libs/dbus-glib-0.74[lib32?]
	>=dev-libs/popt-1.5[lib32?]
	!gnome-base/bonobo-activation"
DEPEND="${RDEPEND}
	sys-devel/flex[lib32?]
	x11-apps/xrdb
	>=dev-util/pkgconfig-0.9[lib32?]
	>=dev-util/intltool-0.35
	doc? ( >=dev-util/gtk-doc-1 )"

DOCS="AUTHORS ChangeLog NEWS README TODO"

# Tests are broken in several ways as reported in bug #288689 and upstream
# doesn't take care since libbonobo is deprecated.
RESTRICT="test"

multilib-native_pkg_setup_internal() {
	G2CONF="${G2CONF} $(use_enable debug bonobo-activation-debug)"
}

multilib-native_src_prepare_internal() {
	gnome2_src_prepare

	# Fix intltoolize broken file, see upstream #577133
	sed "s:'\^\$\$lang\$\$':\^\$\$lang\$\$:g" -i po/Makefile.in.in || die

	if ! use test; then
		# don't waste time building tests, bug #226223
		sed 's/tests//' -i Makefile.am Makefile.in || die
	fi

	if ! use examples; then
		sed 's/samples//' -i Makefile.am Makefile.in || die
	fi
}

src_test() {
	# Pass tests with FEATURES userpriv, see bug #288689
	unset ORBIT_SOCKETDIR
	emake check || die
}
