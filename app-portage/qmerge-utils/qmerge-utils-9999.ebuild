# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic toolchain-funcs autotools

DESCRIPTION="Small and fast Portage helper tools written in C (qmerge binhost fork)"
HOMEPAGE="https://github.com/AntiqueH/qmerge-utils"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/AntiqueH/${PN}.git"
	EGIT_BRANCH="dev"
else
	SRC_URI="https://github.com/AntiqueH/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="+gpg +gpkg +gtree openmp +qmanifest static system-libcurl"

REQUIRED_USE="
	qmanifest? ( gpg )
	gtree? ( gpg )
"

RDEPEND="
	!static? (
		app-arch/libarchive:=
		virtual/zlib:=
		system-libcurl? ( net-misc/curl:= )
		!system-libcurl? ( dev-libs/openssl:= )
		gpg? ( app-crypt/gpgme:= )
		gtree? ( app-arch/libarchive:=[zstd] )
		qmanifest? ( app-crypt/libb2:= )
	)
	openmp? ( || (
		sys-devel/gcc:*[openmp]
		llvm-runtimes/openmp
	) )
	!!app-portage/portage-utils
"
DEPEND="${RDEPEND}
	static? (
		app-arch/libarchive[static-libs]
		virtual/zlib[static-libs]
		system-libcurl? ( net-misc/curl[static-libs] )
		!system-libcurl? ( dev-libs/openssl[static-libs] )
		gpg? ( app-crypt/gpgme[static-libs] )
		gtree? ( app-arch/libarchive[static-libs,zstd] )
		qmanifest? ( app-crypt/libb2[static-libs] )
	)
"
BDEPEND="virtual/pkgconfig
	dev-python/pyyaml"

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
	eautoreconf
}

src_configure() {
	use static && append-ldflags -static

	econf \
		--disable-maintainer-mode \
		--with-eprefix="${EPREFIX}" \
		$(use_enable gpg) \
		$(use_enable gpkg) \
		$(use_enable gtree) \
		$(use_enable qmanifest) \
		$(use_enable openmp) \
		$(use_with system-libcurl)
}
