# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )
inherit cmake flag-o-matic python-single-r1 shell-completion

DESCRIPTION="Bounded Model Checker for C and C++ programs"
HOMEPAGE="https://www.cprover.org/cbmc/
	https://github.com/diffblue/cbmc"
SRC_URI="https://github.com/diffblue/cbmc/archive/refs/tags/${P}.tar.gz"
S="${WORKDIR}"/${PN}-${P}

LICENSE="BSD-4"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+memory-analyzer test"
RESTRICT="!test? ( test )"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	sci-mathematics/minisat
	memory-analyzer? ( dev-debug/gdb )
"
DEPEND="
	${RDEPEND}
	>=sci-mathematics/minisat-2.2.1-r2[static-libs]
"
BDEPEND="
	sys-devel/bison
	sys-devel/flex
	test? ( dev-lang/perl )
"

PATCHES=(
	"${FILESDIR}"/${P}-respect-flags.patch
)

pkg_setup() {
	python-single-r1_pkg_setup
}

src_configure() {
	filter-lto

	local mycmakeargs=(
		-DBUILD_SHARED_LIBS=OFF
		-Dsat_impl=system-minisat2
		-DWITH_JBMC=OFF
		-DWITH_MEMORY_ANALYZER=$(usex memory-analyzer)
		-Denable_cbmc_tests=$(usex test)
		-DCCACHE_PROGRAM=CCACHE_PROGRAM-NOTFOUND
	)

	cmake_src_configure
}

src_install() {
	cmake_src_install
	python_fix_shebang "${ED}"/usr/bin/ls_parse.py

	newbashcomp "${ED}"/usr/etc/bash_completion.d/cbmc cbmc
	rm -r "${ED}"/usr/etc || die
}
