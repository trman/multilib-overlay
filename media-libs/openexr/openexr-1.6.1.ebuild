# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/openexr/openexr-1.6.1.ebuild,v 1.12 2009/02/28 16:59:42 armin76 Exp $

EAPI="2"

inherit libtool eutils multilib-native

DESCRIPTION="ILM's OpenEXR high dynamic-range image file format libraries"
HOMEPAGE="http://openexr.com/"
SRC_URI="http://download.savannah.nongnu.org/releases/openexr/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 -arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="doc examples"

RDEPEND="media-libs/ilmbase[lib32?]"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"

multilib-native_src_prepare_internal() {
	# Replace the temporary directory used for tests.
	sed -i -e 's:"/var/tmp/":"'${T}'":' "IlmImfTest/tmpDir.h"

	epatch "${FILESDIR}/${P}-gcc-4.3.patch"

	# Sane versioning on FreeBSD - please don't remove elibtoolize
	elibtoolize
}

multilib-native_src_configure_internal() {
	econf $(use_enable examples imfexamples)
}

multilib-native_src_install_internal() {
	emake DESTDIR="${D}" examplesdir="/usr/share/doc/${PF}/examples" install || \
		die "install failed"
	dodoc AUTHORS ChangeLog NEWS README

	if use doc ; then
		insinto "/usr/share/doc/${PF}"
		doins doc/*.pdf
	fi
	rm -frv "${D}usr/share/doc/OpenEXR"*

	if use examples ; then
		dobin "IlmImfExamples/imfexamples"
	else
		rm -fr "${D}usr/share/doc/${PF}/examples"
	fi
}

pkg_postinst() {
	elog "OpenEXR was divided into IlmBase, OpenEXR, and OpenEXR_Viewers."
	elog "Viewers are available in OpenEXR_Viewers package."
	elog "If you want them, run:"
	elog
	elog "emerge media-gfx/openexr_viewers"
	elog

	ewarn "OpenEXR may have had ABI changes."
	ewarn "Please run revdep-rebuild"
	ewarn "to rebuild programs using it"
	ewarn "(like KDELibs, KRita, ImageMagick, etc.)."
}
