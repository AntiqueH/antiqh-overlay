# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )

inherit meson python-any-r1 xdg

DESCRIPTION="A system designed to make installation and updates of packages easier"
HOMEPAGE="https://github.com/AntiqueH/PackageKit"

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/AntiqueH/${PN}.git"
	EGIT_BRANCH="dev"
else
	SRC_URI="https://github.com/AntiqueH/${PN}/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64"
fi

LICENSE="GPL-2+"
SLOT="0"
IUSE="introspection policykit bash-completion gtk-doc systemd test vala"

RESTRICT="!test? ( test )"

REQUIRED_USE="vala? ( introspection )"

RDEPEND="
	dev-libs/glib:2
	dev-db/sqlite:3
	sys-apps/portage
	policykit? ( sys-auth/polkit )
	introspection? ( dev-libs/gobject-introspection )
	bash-completion? ( app-shells/bash-completion )
"
DEPEND="${RDEPEND}"
BDEPEND="${PYTHON_DEPS}
	virtual/pkgconfig
	dev-util/intltool
	introspection? ( dev-lang/vala )
"

src_configure() {
	local emesonargs=(
		-Dpackaging_backend=portage
		-Dgstreamer_plugin=false
		-Dgtk_module=false
		-Dgtk_doc=$(usex gtk-doc true false)
		-Dcron=$(usex cron true false)
		-Dlegacy_tools=$(usex legacy true false)
		-Dsystemd=$(usex systemd true false)
		-Dgobject_introspection=$(usex introspection true false)
		-Ddaemon_tests=$(usex test true false)
	)

	meson_src_configure
}

src_install() {
	meson_src_install

	if use introspection; then
		dosym "vaapigen-${PV}" /usr/bin/vaapigen
	fi

	dodoc README.md AUTHORS NEWS
}
