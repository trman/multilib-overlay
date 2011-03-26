# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/xorg-2.eclass,v 1.39 2011/03/19 15:02:47 scarabeus Exp $
#
# @ECLASS: xorg-2.eclass
# @MAINTAINER:
# x11@gentoo.org
# @BLURB: Reduces code duplication in the modularized X11 ebuilds.
# @DESCRIPTION:
# This eclass makes trivial X ebuilds possible for apps, fonts, drivers,
# and more. Many things that would normally be done in various functions
# can be accessed by setting variables instead, such as patching,
# running eautoreconf, passing options to configure and installing docs.
#
# All you need to do in a basic ebuild is inherit this eclass and set
# DESCRIPTION, KEYWORDS and RDEPEND/DEPEND. If your package is hosted
# with the other X packages, you don't need to set SRC_URI. Pretty much
# everything else should be automatic.

# Author: Tomáš Chvátal <scarabeus@gentoo.org>
# Author: Donnie Berkholz <dberkholz@gentoo.org>

MULTILIB_EXT_SOURCE_BUILD=yes

GIT_ECLASS=""
if [[ ${PV} == *9999* ]]; then
	GIT_ECLASS="git"
	XORG_EAUTORECONF="yes"
fi

# If we're a font package, but not the font.alias one
FONT_ECLASS=""
if [[ ${PN} == font* \
	&& ${CATEGORY} = media-fonts \
	&& ${PN} != font-alias \
	&& ${PN} != font-util ]]; then
	# Activate font code in the rest of the eclass
	FONT="yes"
	FONT_ECLASS="font"
fi

inherit autotools-utils eutils libtool multilib toolchain-funcs flag-o-matic autotools \
	${FONT_ECLASS} ${GIT_ECLASS}

EXPORTED_FUNCTIONS="src_unpack src_compile src_install pkg_postinst pkg_postrm"
case "${EAPI:-0}" in
	3|4) EXPORTED_FUNCTIONS="${EXPORTED_FUNCTIONS} src_prepare src_configure" ;;
	*) die "EAPI=${EAPI} is not supported" ;;
esac

# exports must be ALWAYS after inherit
EXPORT_FUNCTIONS ${EXPORTED_FUNCTIONS}

IUSE=""
HOMEPAGE="http://xorg.freedesktop.org/"

# @ECLASS-VARIABLE: XORG_EAUTORECONF
# @DESCRIPTION:
# If set to 'yes' and configure.ac exists, eautoreconf will run. Set
# before inheriting this eclass.
: ${XORG_EAUTORECONF:="no"}

# @ECLASS-VARIABLE: XORG_BASE_INDIVIDUAL_URI
# @DESCRIPTION:
# Set up SRC_URI for individual modular releases. If set to an empty
# string, no SRC_URI will be provided by the eclass.
: ${XORG_BASE_INDIVIDUAL_URI="http://xorg.freedesktop.org/releases/individual"}

# @ECLASS-VARIABLE: XORG_MODULE
# @DESCRIPTION:
# The subdirectory to download source from. Possible settings are app,
# doc, data, util, driver, font, lib, proto, xserver. Set above the
# inherit to override the default autoconfigured module.
if [[ -z ${XORG_MODULE} ]]; then
	case ${CATEGORY} in
		app-doc)             XORG_MODULE=doc/     ;;
		media-fonts)         XORG_MODULE=font/    ;;
		x11-apps|x11-wm)     XORG_MODULE=app/     ;;
		x11-misc|x11-themes) XORG_MODULE=util/    ;;
		x11-base)            XORG_MODULE=xserver/ ;;
		x11-drivers)         XORG_MODULE=driver/  ;;
		x11-proto)           XORG_MODULE=proto/   ;;
		x11-libs)            XORG_MODULE=lib/     ;;
		*)                   XORG_MODULE=         ;;
	esac
fi

# backcompat, remove when everything in main tree fixed
[[ -n ${MODULE} ]] && XORG_MODULE=${MODULE} && ewarn "$CATEGORY/$P is using MODULE variable, please migrate to XORG_MODULE to preserve namespace."

# @ECLASS-VARIABLE: XORG_PACKAGE_NAME
# @DESCRIPTION:
# For git checkout the git repository might differ from package name.
# This variable can be used for proper directory specification
: ${XORG_PACKAGE_NAME:=${PN}}

if [[ -n ${GIT_ECLASS} ]]; then
	: ${EGIT_REPO_URI:="git://anongit.freedesktop.org/git/xorg/${XORG_MODULE}${XORG_PACKAGE_NAME}"}
elif [[ -n ${XORG_BASE_INDIVIDUAL_URI} ]]; then
	SRC_URI="${XORG_BASE_INDIVIDUAL_URI}/${XORG_MODULE}${P}.tar.bz2"
fi

: ${SLOT:=0}

# Set the license for the package. This can be overridden by setting
# LICENSE after the inherit. Nearly all FreeDesktop-hosted X packages
# are under the MIT license. (This is what Red Hat does in their rpms)
: ${LICENSE:=MIT}

# Set up autotools shared dependencies
# Remember that all versions here MUST be stable
XORG_EAUTORECONF_ARCHES="x86-interix ppc-aix x86-winnt"
EAUTORECONF_DEPEND+="
	>=sys-devel/libtool-2.2.6a
	sys-devel/m4"
if [[ ${PN} != util-macros ]] ; then
	EAUTORECONF_DEPEND+=" >=x11-misc/util-macros-1.12.0"
	# Required even by xorg-server
	[[ ${PN} == "font-util" ]] || EAUTORECONF_DEPEND+=" >=media-fonts/font-util-1.2.0"
fi
WANT_AUTOCONF="latest"
WANT_AUTOMAKE="latest"
for arch in ${XORG_EAUTORECONF_ARCHES}; do
	EAUTORECONF_DEPENDS+=" ${arch}? ( ${EAUTORECONF_DEPEND} )"
done
DEPEND+=" ${EAUTORECONF_DEPENDS}"
[[ ${XORG_EAUTORECONF} != no ]] && DEPEND+=" ${EAUTORECONF_DEPEND}"
unset EAUTORECONF_DEPENDS
unset EAUTORECONF_DEPEND

if [[ ${FONT} == yes ]]; then
	RDEPEND+=" media-fonts/encodings
		x11-apps/mkfontscale
		x11-apps/mkfontdir"
	PDEPEND+=" media-fonts/font-alias"
	DEPEND+=" >=media-fonts/font-util-1.2.0"

	# @ECLASS-VARIABLE: FONT_DIR
	# @DESCRIPTION:
	# If you're creating a font package and the suffix of PN is not equal to
	# the subdirectory of /usr/share/fonts/ it should install into, set
	# FONT_DIR to that directory or directories. Set before inheriting this
	# eclass.
	[[ -z ${FONT_DIR} ]] && FONT_DIR=${PN##*-}

	# Fix case of font directories
	FONT_DIR=${FONT_DIR/ttf/TTF}
	FONT_DIR=${FONT_DIR/otf/OTF}
	FONT_DIR=${FONT_DIR/type1/Type1}
	FONT_DIR=${FONT_DIR/speedo/Speedo}

	# Set up configure options, wrapped so ebuilds can override if need be
	[[ -z ${FONT_OPTIONS} ]] && FONT_OPTIONS="--with-fontdir=\"${EPREFIX}/usr/share/fonts/${FONT_DIR}\""

	[[ ${PN##*-} = misc || ${PN##*-} = 75dpi || ${PN##*-} = 100dpi || ${PN##*-} = cyrillic ]] && IUSE+=" nls"
fi

# If we're a driver package, then enable DRIVER case
[[ ${PN} == xf86-video-* || ${PN} == xf86-input-* ]] && DRIVER="yes"

# @ECLASS-VARIABLE: XORG_STATIC
# @DESCRIPTION:
# Enables static-libs useflag. Set to no, if your package gets:
#
# QA: configure: WARNING: unrecognized options: --disable-static
: ${XORG_STATIC:="yes"}

# Add static-libs useflag where usefull.
if [[ ${XORG_STATIC} == yes \
		&& ${FONT} != yes \
		&& ${CATEGORY} != app-doc \
		&& ${CATEGORY} != x11-apps \
		&& ${CATEGORY} != x11-proto \
		&& ${CATEGORY} != x11-drivers \
		&& ${CATEGORY} != media-fonts \
		&& ${PN} != util-macros \
		&& ${PN} != xbitmaps \
		&& ${PN} != xorg-cf-files \
		&& ${PN/xcursor} = ${PN} ]]; then
	IUSE+=" static-libs"
fi

DEPEND+=" >=dev-util/pkgconfig-0.23"

# @ECLASS-VARIABLE: XORG_DRI
# @DESCRIPTION:
# Possible values are "always" or the value of the useflag DRI capabilities
# are required for. Default value is "no"
#
# Eg. XORG_DRI="opengl" will pull all dri dependant deps for opengl useflag
: ${XORG_DRI:="no"}

DRI_COMMON_DEPEND="
	x11-base/xorg-server[-minimal]
	x11-libs/libdrm[lib32?]
"
DRI_DEPEND="
	x11-proto/xf86driproto
	x11-proto/glproto
	x11-proto/dri2proto[lib32?]
"
case ${XORG_DRI} in
	no)
		;;
	always)
		COMMON_DEPEND+=" ${DRI_COMMON_DEPEND}"
		DEPEND+=" ${DRI_DEPEND}"
		;;
	*)
		COMMON_DEPEND+=" ${XORG_DRI}? ( ${DRI_COMMON_DEPEND} )"
		DEPEND+=" ${XORG_DRI}? ( ${DRI_DEPEND} )"
		IUSE+=" ${XORG_DRI}"
		;;
esac
unset DRI_DEPEND
unset DRI_COMMONDEPEND

if [[ -n "${DRIVER}" ]]; then
	COMMON_DEPEND+="
		x11-base/xorg-server[xorg]
	"
fi
if [[ -n "${DRIVER}" && ${PN} == xf86-video-* ]]; then
	COMMON_DEPEND+="
		x11-libs/libpciaccess
	"
	# we also needs some protos and libs in all cases
	DEPEND+="
		x11-proto/fontsproto
		x11-proto/randrproto
		x11-proto/renderproto
		x11-proto/videoproto
		x11-proto/xextproto
		x11-proto/xineramaproto
		x11-proto/xproto
	"
fi

# @ECLASS-VARIABLE: XORG_DOC
# @DESCRIPTION:
# Possible values are "always" or the value of the useflag doc packages
# are required for. Default value is "no"
#
# Eg. XORG_DOC="manual" will pull all doc dependant deps for manual useflag
: ${XORG_DOC:="no"}

DOC_DEPEND="
	doc? (
		app-text/asciidoc
		app-text/xmlto
		app-doc/doxygen
		app-text/docbook-xml-dtd:4.1.2
		app-text/docbook-xml-dtd:4.2
		app-text/docbook-xml-dtd:4.3
	)
"
case ${XORG_DOC} in
	no)
		;;
	always)
		DEPEND+=" ${DOC_DEPEND}"
		;;
	*)
		DEPEND+=" ${XORG_DOC}? ( ${DOC_DEPEND} )"
		IUSE+=" ${XORG_DOC}"
		;;
esac
unset DOC_DEPEND

DEPEND+=" ${COMMON_DEPEND}"
RDEPEND+=" ${COMMON_DEPEND}"
unset COMMON_DEPEND

debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: DEPEND=${DEPEND}"
debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: RDEPEND=${RDEPEND}"
debug-print "${LINENO} ${ECLASS} ${FUNCNAME}: PDEPEND=${PDEPEND}"

# @FUNCTION: xorg-2_pkg_setup
# @DESCRIPTION:
# Setup prefix compat
xorg-2_pkg_setup() {
	debug-print-function ${FUNCNAME} "$@"

	[[ ${FONT} == yes ]] && font_pkg_setup "$@"
}

# @FUNCTION: xorg-2_src_unpack
# @DESCRIPTION:
# Simply unpack source code.
xorg-2_src_unpack() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ -n ${GIT_ECLASS} ]]; then
		git_src_unpack
	else
		unpack ${A}
	fi

	[[ -n ${FONT_OPTIONS} ]] && einfo "Detected font directory: ${FONT_DIR}"
}

# @FUNCTION: xorg-2_patch_source
# @DESCRIPTION:
# Apply all patches
xorg-2_patch_source() {
	debug-print-function ${FUNCNAME} "$@"

	# Use standardized names and locations with bulk patching
	# Patch directory is ${WORKDIR}/patch
	# See epatch() in eutils.eclass for more documentation
	EPATCH_SUFFIX=${EPATCH_SUFFIX:=patch}

	[[ -d "${EPATCH_SOURCE}" ]] && epatch
	autotools-utils_src_prepare "$@"
}

# @FUNCTION: xorg-2_reconf_source
# @DESCRIPTION:
# Run eautoreconf if necessary, and run elibtoolize.
xorg-2_reconf_source() {
	debug-print-function ${FUNCNAME} "$@"

	case ${CHOST} in
		*-interix* | *-aix* | *-winnt*)
			# some hosts need full eautoreconf
			[[ -e "./configure.ac" || -e "./configure.in" ]] && eautoreconf || ewarn "Unable to autoreconf the configure script. Things may fail."
			;;
		*)
			# elibtoolize required for BSD
			[[ ${XORG_EAUTORECONF} != no && ( -e "./configure.ac" || -e "./configure.in" ) ]] && eautoreconf || elibtoolize
			;;
	esac
}

# @FUNCTION: xorg-2_src_prepare
# @DESCRIPTION:
# Prepare a package after unpacking, performing all X-related tasks.
xorg-2_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${GIT_ECLASS} ]] && git_src_prepare
	xorg-2_patch_source
	xorg-2_reconf_source
}

# @FUNCTION: xorg-2_font_configure
# @DESCRIPTION:
# If a font package, perform any necessary configuration steps
xorg-2_font_configure() {
	debug-print-function ${FUNCNAME} "$@"

	if has nls ${IUSE//+} && ! use nls; then
		if grep -q -s "disable-all-encodings" ${ECONF_SOURCE:-.}/configure; then
			FONT_OPTIONS+="
				--disable-all-encodings"
		else
			FONT_OPTIONS+="
				--disable-iso8859-2
				--disable-iso8859-3
				--disable-iso8859-4
				--disable-iso8859-5
				--disable-iso8859-6
				--disable-iso8859-7
				--disable-iso8859-8
				--disable-iso8859-9
				--disable-iso8859-10
				--disable-iso8859-11
				--disable-iso8859-12
				--disable-iso8859-13
				--disable-iso8859-14
				--disable-iso8859-15
				--disable-iso8859-16
				--disable-jisx0201
				--disable-koi8-r"
		fi
	fi
}

# @FUNCTION: xorg-2_flags_setup
# @DESCRIPTION:
# Set up CFLAGS for a debug build
xorg-2_flags_setup() {
	debug-print-function ${FUNCNAME} "$@"

	# Win32 require special define
	[[ ${CHOST} == *-winnt* ]] && append-cppflags -DWIN32 -D__STDC__
	# hardened ldflags
	[[ ${PN} = xorg-server || -n ${DRIVER} ]] && append-ldflags -Wl,-z,lazy

	# Quite few libraries fail on runtime without these:
	if has static-libs ${IUSE//+}; then
		filter-flags -Wl,-Bdirect
		filter-ldflags -Bdirect
		filter-ldflags -Wl,-Bdirect
	fi
}

# @FUNCTION: xorg-2_src_configure
# @DESCRIPTION:
# Perform any necessary pre-configuration steps, then run configure
xorg-2_src_configure() {
	debug-print-function ${FUNCNAME} "$@"

	xorg-2_flags_setup

	# @VARIABLE: CONFIGURE_OPTIONS
	# @DESCRIPTION:
	# Any options to pass to configure
	# @DEFAULT_UNSET
	CONFIGURE_OPTIONS=${CONFIGURE_OPTIONS:=""}

	[[ -n "${FONT}" ]] && xorg-2_font_configure
	local myeconfargs=(
		--disable-dependency-tracking
		${CONFIGURE_OPTIONS}
		${FONT_OPTIONS}
	)

	autotools-utils_src_configure "$@"
}

# @FUNCTION: xorg-2_src_compile
# @DESCRIPTION:
# Compile a package, performing all X-related tasks.
xorg-2_src_compile() {
	debug-print-function ${FUNCNAME} "$@"

	autotools-utils_src_compile "$@"
}

# @FUNCTION: xorg-2_src_install
# @DESCRIPTION:
# Install a built package to ${D}, performing any necessary steps.
# Creates a ChangeLog from git if using live ebuilds.
xorg-2_src_install() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${CATEGORY} == x11-proto ]]; then
		autotools-utils_src_install \
			${PN/proto/}docdir="${EPREFIX}/usr/share/doc/${PF}" \
			docdir="${EPREFIX}/usr/share/doc/${PF}"
	else
		autotools-utils_src_install \
			docdir="${EPREFIX}/usr/share/doc/${PF}"
	fi

	if [[ -n ${GIT_ECLASS} ]]; then
		pushd "${EGIT_STORE_DIR}/${EGIT_CLONE_DIR}" > /dev/null
		git log ${EGIT_COMMIT} > "${S}"/ChangeLog
		popd > /dev/null
	fi

	if [[ -e "${S}"/ChangeLog ]]; then
		dodoc "${S}"/ChangeLog || die "dodoc failed"
	fi

	# Don't install libtool archives (even with static-libs)
	remove_libtool_files all

	[[ -n ${FONT} ]] && remove_font_metadata
}

# @FUNCTION: xorg-2_pkg_postinst
# @DESCRIPTION:
# Run X-specific post-installation tasks on the live filesystem. The
# only task right now is some setup for font packages.
xorg-2_pkg_postinst() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${FONT} ]] && setup_fonts "$@"
}

# @FUNCTION: xorg-2_pkg_postrm
# @DESCRIPTION:
# Run X-specific post-removal tasks on the live filesystem. The only
# task right now is some cleanup for font packages.
xorg-2_pkg_postrm() {
	debug-print-function ${FUNCNAME} "$@"

	[[ -n ${FONT} ]] && font_pkg_postrm "$@"
}

# @FUNCTION: setup_fonts
# @DESCRIPTION:
# Generates needed files for fonts and fixes font permissions
setup_fonts() {
	debug-print-function ${FUNCNAME} "$@"

	create_fonts_scale
	create_fonts_dir
	font_pkg_postinst
}

# @FUNCTION: remove_font_metadata
# @DESCRIPTION:
# Don't let the package install generated font files that may overlap
# with other packages. Instead, they're generated in pkg_postinst().
remove_font_metadata() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${FONT_DIR} != Speedo && ${FONT_DIR} != CID ]]; then
		einfo "Removing font metadata"
		rm -rf "${ED}"/usr/share/fonts/${FONT_DIR}/fonts.{scale,dir,cache-1}
	fi
}

# @FUNCTION: create_fonts_scale
# @DESCRIPTION:
# Create fonts.scale file, used by the old server-side fonts subsystem.
create_fonts_scale() {
	debug-print-function ${FUNCNAME} "$@"

	if [[ ${FONT_DIR} != Speedo && ${FONT_DIR} != CID ]]; then
		ebegin "Generating font.scale"
			mkfontscale \
				-a "${EROOT}/usr/share/fonts/encodings/encodings.dir" \
				-- "${EROOT}/usr/share/fonts/${FONT_DIR}"
		eend $?
	fi
}

# @FUNCTION: create_fonts_dir
# @DESCRIPTION:
# Create fonts.dir file, used by the old server-side fonts subsystem.
create_fonts_dir() {
	debug-print-function ${FUNCNAME} "$@"

	ebegin "Generating fonts.dir"
			mkfontdir \
				-e "${EROOT}"/usr/share/fonts/encodings \
				-e "${EROOT}"/usr/share/fonts/encodings/large \
				-- "${EROOT}/usr/share/fonts/${FONT_DIR}"
	eend $?
}
