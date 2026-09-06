# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs autotools

DESCRIPTION="Small and fast Portage helper tools written in C (qmerge binhost fork)"
HOMEPAGE="https://github.com/AntiqueH/portage-utils"

CURL_PV="8.20.0"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/AntiqueH/${PN}.git"
	EGIT_BRANCH="dev"
	SRC_URI="internal-libs? ( https://curl.se/download/curl-${CURL_PV}.tar.xz )"
else
	SRC_URI="https://github.com/AntiqueH/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz
		internal-libs? ( https://curl.se/download/curl-${CURL_PV}.tar.xz )"
	KEYWORDS="~amd64"
fi

LICENSE="GPL-2 internal-libs? ( curl )"
SLOT="0"
IUSE="+gpg +gpkg +gtree internal-libs openmp +qmanifest static libxml2"

REQUIRED_USE="
	qmanifest? ( gpg )
	gtree? ( gpg )
	libxml2? ( static )
"

COMMON_DEPEND="
	!static? (
		app-arch/libarchive:=
		virtual/zlib:=
		!internal-libs? ( >=net-misc/curl-7.85.0:= )
		internal-libs? ( dev-libs/openssl:= )
		gpg? ( app-crypt/gpgme:= )
		gtree? ( app-arch/libarchive:=[zstd] )
		qmanifest? ( app-crypt/libb2:= )
	)
	openmp? ( || (
		sys-devel/gcc:*[openmp]
		llvm-runtimes/openmp
	) )
"
RDEPEND="${COMMON_DEPEND}
	gpg? ( sys-apps/util-linux )
"

DEPEND="${COMMON_DEPEND}
	static? (
		app-arch/bzip2[static-libs]
		app-arch/xz-utils[static-libs]
		app-arch/zstd[static-libs]
		sys-apps/acl[static-libs]
		virtual/zlib[static-libs]
		!internal-libs? (
			>=net-misc/curl-7.85.0[static-libs]
			dev-libs/openssl[static-libs]
			dev-libs/libunistring[static-libs]
			net-dns/c-ares[static-libs]
			net-dns/libidn2[static-libs]
			net-libs/libpsl[static-libs]
			net-libs/nghttp2[static-libs]
			net-libs/nghttp3[static-libs]
			net-libs/ngtcp2[openssl,ssl,static-libs]
		)
		internal-libs? ( dev-libs/openssl[static-libs] )
		gpg? (
			app-crypt/gpgme[static-libs]
			dev-libs/libgpg-error[static-libs]
			>=dev-libs/libassuan-3.0.0-r3[static-libs]
		)
		gtree? ( app-arch/libarchive[static-libs,zstd] )
		qmanifest? ( app-crypt/libb2[static-libs] )
		!libxml2? (
			app-arch/libarchive[static-libs,expat]
			dev-libs/expat[static-libs]
		)
		libxml2? (
			app-arch/libarchive[static-libs,-expat]
			dev-libs/libxml2[static-libs]
			dev-libs/icu[static-libs]
		)
	)
"
BDEPEND="virtual/pkgconfig"

QA_CONFIG_IMPL_DECL_SKIP=(
	"MIN"
	"unreachable"
	"alignof"
	"static_assert"
)

pkg_setup() {
	[[ ${MERGE_TYPE} != binary ]] && use openmp && tc-check-openmp
}

src_prepare() {
	default
	if use internal-libs && [[ ! -f ${S}/src/curl/configure ]]; then
		rm -rf "${S}/src/curl" || die
		mv "${WORKDIR}/curl-${CURL_PV}" "${S}/src/curl" || die
	fi
}

src_configure() {
	econf \
		--disable-maintainer-mode \
		--with-eprefix="${EPREFIX}" \
		$(use_enable static) \
		$(use_enable gpg) \
		$(use_enable gpkg) \
		$(use_enable gtree) \
		$(use_enable qmanifest) \
		$(use_enable openmp) \
		$(use_enable internal-libs)
}
