# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libX11/libX11-1.4.2.ebuild,v 1.2 2011/03/21 14:05:45 flameeyes Exp $

EAPI=4

XORG_DOC=doc
inherit xorg-2 toolchain-funcs flag-o-matic multilib-native

DESCRIPTION="X.Org X11 library"

KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~ppc-aix ~x86-fbsd ~x64-freebsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="ipv6 test"

RDEPEND=">=x11-libs/libxcb-1.1.92[lib32?]
	x11-libs/xtrans[lib32?]
	>=x11-proto/xproto-7.0.13
	x11-proto/xf86bigfontproto
	x11-proto/inputproto
	x11-proto/kbproto
	x11-proto/xextproto"
DEPEND="${RDEPEND}
	test? ( dev-lang/perl[lib32?] )"

PATCHES=(
	"${FILESDIR}"/${PN}-1.1.4-aix-pthread.patch
	"${FILESDIR}"/${PN}-1.1.5-winnt-private.patch
	"${FILESDIR}"/${PN}-1.1.5-solaris.patch
)

multilib-native_pkg_setup_internal() {
	xorg-2_pkg_setup
	CONFIGURE_OPTIONS="
		$(use_with doc xmlto)
		$(use_enable doc specs)
		$(use_enable ipv6)
		--without-fop
	"
}

multilib-native_src_configure_internal() {
	[[ ${CHOST} == *-interix* ]] && export ac_cv_func_poll=no
	xorg-2_src_configure
}

multilib-native_src_compile_internal() {
	# [Cross-Compile Love] Disable {C,LD}FLAGS and redefine CC= for 'makekeys'
	if tc-is-cross-compiler; then
		(
			filter-flags -m*
			emake -C "${AUTOTOOLS_BUILD_DIR}"/src/util CC=$(tc-getBUILD_CC) CFLAGS="${CFLAGS}" LDFLAGS="" clean all || die
		)
	fi
	xorg-2_src_compile
}
