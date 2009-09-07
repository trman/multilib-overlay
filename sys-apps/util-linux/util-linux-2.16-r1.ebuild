# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/util-linux/util-linux-2.16-r1.ebuild,v 1.2 2009/08/31 08:16:05 vapier Exp $

EAPI="2"

EGIT_REPO_URI="git://git.kernel.org/pub/scm/utils/util-linux-ng/util-linux-ng.git"
inherit eutils toolchain-funcs multilib-native
[[ ${PV} == "9999" ]] && inherit git autotools

MY_PV=${PV/_/-}
MY_P=${PN}-ng-${MY_PV}
S=${WORKDIR}/${MY_P}

DESCRIPTION="Various useful Linux utilities"
HOMEPAGE="http://www.kernel.org/pub/linux/utils/util-linux-ng/"
if [[ ${PV} == "9999" ]] ; then
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://kernel/linux/utils/util-linux-ng/v${PV:0:4}/${MY_P}.tar.bz2
		loop-aes? ( http://loop-aes.sourceforge.net/updates/util-linux-ng-2.16-20090725.diff.bz2 )"
	KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="crypt loop-aes nls old-linux selinux slang uclibc unicode"

RDEPEND="!sys-process/schedutils
	!sys-apps/setarch
	>=sys-libs/ncurses-5.2-r2[lib32?]
	!<sys-libs/e2fsprogs-libs-1.41.8
	!<sys-fs/e2fsprogs-1.41.8
	selinux? ( sys-libs/libselinux[lib32?] )
	slang? ( sys-libs/slang[lib32?] )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext[lib32?] )
	virtual/os-headers"

multilib-native_src_prepare_internal() {
	if [[ ${PV} == "9999" ]] ; then
		autopoint --force
		eautoreconf
	else
		epatch "${FILESDIR}"/0001-libblkid-fix-ext2-detection-on-systems-with-ext4-onl.patch #279054
		use loop-aes && epatch "${WORKDIR}"/util-linux-ng-*.diff
	fi
	use uclibc && sed -i -e s/versionsort/alphasort/g -e s/strverscmp.h/dirent.h/g mount/lomount.c
}

multilib-native_src_configure_internal() {
	econf \
		$(use_enable nls) \
		--enable-agetty \
		--enable-cramfs \
		$(use_enable old-linux elvtune) \
		--disable-init \
		--disable-kill \
		--disable-last \
		--disable-mesg \
		--enable-partx \
		--enable-raw \
		--enable-rdev \
		--enable-rename \
		--disable-reset \
		--disable-login-utils \
		--enable-schedutils \
		--disable-wall \
		--enable-write \
		--without-pam \
		$(use unicode || echo --with-ncurses) \
		$(use_with selinux) \
		$(use_with slang)
}

multilib-native_src_install_internal() {
	emake install DESTDIR="${D}" || die "install failed"
	dodoc AUTHORS NEWS README* TODO docs/*

	# need the libs in /
	gen_usr_ldscript -a blkid uuid
	# e2fsprogs-libs didnt install .la files, and .pc work fine
	rm -f "${D}"/usr/$(get_libdir)/*.la

	if use crypt ; then
		newinitd "${FILESDIR}"/crypto-loop.initd crypto-loop || die
		newconfd "${FILESDIR}"/crypto-loop.confd crypto-loop || die
	fi
}
