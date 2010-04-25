# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/gnome-doc-utils/gnome-doc-utils-0.18.0.ebuild,v 1.2 2009/12/09 22:12:55 eva Exp $

EAPI="2"

inherit gnome2 python multilib-native

DESCRIPTION="A collection of documentation utilities for the Gnome project"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~x86-fbsd"
IUSE=""

RDEPEND=">=dev-libs/libxml2-2.6.12[python,lib32?]
	 >=dev-libs/libxslt-1.1.8[lib32?]
	 >=dev-lang/python-2.4[lib32?]"
DEPEND="${RDEPEND}
	sys-devel/gettext[lib32?]
	>=dev-util/intltool-0.35
	>=dev-util/pkgconfig-0.9[lib32?]
	~app-text/docbook-xml-dtd-4.4
	app-text/scrollkeeper-dtd"
# dev-libs/glib needed for eautofoo, bug #255114.

DOCS="AUTHORS ChangeLog NEWS README"

# FIXME: Highly broken with parallel make, see bug #286889
MAKEOPTS="${MAKEOPTS} -j1"

multilib-native_pkg_setup_internal() {
	G2CONF="${G2CONF} --disable-scrollkeeper"
}

# If there is a need to reintroduce eautomake or eautoreconf, make sure
# to AT_M4DIR="tools m4", bug #224609 (m4 removes glib build time dep)

multilib-native_pkg_postinst_internal() {
	python_need_rebuild
	python_mod_optimize $(python_get_sitedir)/xml2po
	gnome2_pkg_postinst
}

multilib-native_pkg_postrm_internal() {
	python_mod_cleanup /usr/$(get_libdir)/python*/site-packages/xml2po
	gnome2_pkg_postrm
}