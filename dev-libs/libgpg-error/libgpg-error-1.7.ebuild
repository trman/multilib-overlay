# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/libgpg-error/libgpg-error-1.7.ebuild,v 1.10 2009/12/12 21:49:05 arfrever Exp $

EAPI="2"

inherit eutils libtool multilib-native

DESCRIPTION="Contains error handling functions used by GnuPG software"
HOMEPAGE="http://www.gnupg.org/related_software/libgpg-error"
SRC_URI="mirror://gnupg/${PN}/${P}.tar.bz2"

LICENSE="GPL-2 LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="common-lisp nls"

RDEPEND="nls? ( virtual/libintl )"
DEPEND="nls? ( sys-devel/gettext[lib32?] )"

multilib-native_src_prepare_internal() {
	epunt_cxx
	# for BSD?
	elibtoolize
}

multilib-native_src_configure_internal() {
	econf $(use_enable nls)
}

multilib-native_src_install_internal() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc AUTHORS ChangeLog NEWS README

	if ! use common-lisp; then
		rm -fr "${D}usr/share/common-lisp"
	fi

	prep_ml_binaries /usr/bin/gpg-error-config
}
