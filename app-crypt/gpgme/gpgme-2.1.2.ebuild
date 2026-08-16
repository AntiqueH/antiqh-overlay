# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

VERIFY_SIG_OPENPGP_KEY_PATH=/usr/share/openpgp-keys/gnupg.asc
inherit flag-o-matic libtool multilib-minimal verify-sig

DESCRIPTION="GnuPG Made Easy is a library for making GnuPG easier to use"
HOMEPAGE="https://www.gnupg.org/related_software/gpgme"
SRC_URI="
	mirror://gnupg/gpgme/${P}.tar.bz2
	verify-sig? ( mirror://gnupg/gpgme/${P}.tar.bz2.sig )
"

LICENSE="GPL-2 LGPL-2.1"
# Please check ABI on each bump, even if SONAMEs didn't change: bug #833355
# Subslot: SONAME of each: <libgpgme.FUDGE>
SLOT="1/45.0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~arm64-macos ~x64-macos ~x64-solaris"
IUSE="common-lisp static-libs test"
RESTRICT="!test? ( test )"

RDEPEND="
	|| (
		app-alternatives/gpg[reference]
		app-alternatives/gpg[freepg(-)]
	)
	>=dev-libs/libassuan-2.5.3:=[${MULTILIB_USEDEP}]
	>=dev-libs/libgpg-error-1.46-r1:=[${MULTILIB_USEDEP}]
"
DEPEND="${RDEPEND}"
BDEPEND="
	verify-sig? ( sec-keys/openpgp-keys-gnupg )
"

MULTILIB_WRAPPED_HEADERS=(
	/usr/include/gpgme.h
)

MULTILIB_CHOST_TOOLS=(
	/usr/bin/gpgme-config
)

PATCHES=(
	"${FILESDIR}"/${PN}-2.1.0-tests-start-stop-agent-use-command-v.patch
)

src_prepare() {
	default

	elibtoolize

	# bug #697456
	addpredict /run/user/$(id -u)/gnupg

	local MAX_WORKDIR=66
	if use test && [[ "${#WORKDIR}" -gt "${MAX_WORKDIR}" ]]; then
		eerror "Unable to run tests as WORKDIR='${WORKDIR}' is longer than ${MAX_WORKDIR} which causes failure!"
		die "Could not run tests as requested with too-long WORKDIR."
	fi

	# Make best effort to allow longer PORTAGE_TMPDIR as usock limitation
	# fails build/tests.
	ln -s "${P}" "${WORKDIR}/b" || die
	S="${WORKDIR}/b"
}

multilib_src_configure() {
	# bug #847955
	append-lfs-flags

	local languages=()
	if multilib_is_native_abi; then
		languages+=( $(usev common-lisp 'cl') )
	fi

	local myeconfargs=(
		--enable-languages="${languages[*]}"
		$(use_enable static-libs static)
		GPGRT_CONFIG="${ESYSROOT}/usr/bin/${CHOST}-gpgrt-config"
	)

	if multilib_is_native_abi && use test; then
		myeconfargs+=(
			--enable-gpgconf-test
			--enable-gpg-test
			--enable-gpgsm-test
			--enable-g13-test
		)
	else
		myeconfargs+=(
			--disable-gpgconf-test
			--disable-gpg-test
			--disable-gpgsm-test
			--disable-g13-test
		)
	fi

	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_test() {
	if multilib_is_native_abi; then
		emake check
	fi
}

multilib_src_install() {
	emake DESTDIR="${D}" install

	if ! multilib_is_native_abi; then
		rm -f "${ED}"/usr/bin/gpgme-tool \
			"${ED}"/usr/bin/gpgme-json \
			"${ED}"/usr/bin/gnupg-key-manage || die
	fi
}

multilib_src_install_all() {
	einstalldocs
	find "${ED}" -type f -name '*.la' -delete || die
}
