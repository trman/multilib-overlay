# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libnotify/libnotify-0.7.1.ebuild,v 1.8 2011/03/13 11:50:46 ssuominen Exp $

EAPI=3
inherit autotools eutils gnome.org multilib-native

DESCRIPTION="Notifications library"
HOMEPAGE="http://www.galago-project.org/"
SRC_URI="${SRC_URI}
	mirror://gentoo/introspection-20110205.m4.tar.bz2"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE="doc +introspection test"

RDEPEND=">=dev-libs/glib-2.26:2[lib32?]
	x11-libs/gdk-pixbuf:2[lib32?]
	introspection? ( >=dev-libs/gobject-introspection-0.9.12 )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig[lib32?]
	dev-util/gtk-doc-am
	doc? ( >=dev-util/gtk-doc-1.14 )
	test? ( >=x11-libs/gtk+-2.90:3[lib32?] )"
PDEPEND="|| (
	x11-misc/notification-daemon
	xfce-extra/xfce4-notifyd
	x11-misc/notify-osd
	>=x11-wm/awesome-3.4.4
	kde-base/knotify
)"

multilib-native_src_unpack_internal() {
	# If gobject-introspection is installed, we don't need the extra .m4
	if has_version "dev-libs/gobject-introspection"; then
		unpack ${P}.tar.bz2
	else
		unpack ${A}
	fi
}

multilib-native_src_prepare_internal() {
	# Add configure switch for gtk+:3 based tests
	# and make tests build only when needed
	epatch "${FILESDIR}"/${PN}-0.7.1-gtk3-tests.patch

	AT_M4DIR=${WORKDIR} eautoreconf
}

multilib-native_src_configure_internal() {
	econf \
		--disable-static \
		--disable-dependency-tracking \
		$(use_enable introspection) \
		$(use_enable test tests)
}

multilib-native_src_install_internal() {
	emake install DESTDIR="${D}" || die
	dodoc AUTHORS ChangeLog NEWS || die

	find "${ED}" -name '*.la' -exec rm -f '{}' +
}

multilib-native_pkg_preinst_internal() {
	preserve_old_lib /usr/$(get_libdir)/libnotify.so.1
}

multilib-native_pkg_postinst_internal() {
	preserve_old_lib_notify /usr/$(get_libdir)/libnotify.so.1
}
