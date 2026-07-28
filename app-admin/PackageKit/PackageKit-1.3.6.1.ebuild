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
IUSE="+qmerge-backend portage-backend introspection policykit bash-completion gtk-doc systemd test vala"

RESTRICT="!test? ( test )"

REQUIRED_USE="
	^^ ( qmerge-backend portage-backend )
	vala? ( introspection )
"

# we recommend our portage-utils from app-portage
RDEPEND="
	dev-libs/glib:2
	dev-db/sqlite:3
	qmerge-backend? (
		app-portage/portage-utils
		app-arch/libarchive:=
		app-crypt/gpgme:=
		app-crypt/libb2:=
		net-misc/curl:=
		virtual/zlib:=
	)
	portage-backend? ( sys-apps/portage )
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
		-Dpackaging_backend=$(usex qmerge-backend qmerge portage)
		-Dgstreamer_plugin=false
		-Dgtk_module=false
		-Dgtk_doc=$(usex gtk-doc true false)
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
