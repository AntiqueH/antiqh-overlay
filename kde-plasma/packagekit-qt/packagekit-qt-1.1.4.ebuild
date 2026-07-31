# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Qt bindings for PackageKit"
HOMEPAGE="https://github.com/PackageKit/PackageKit-Qt"

if [[ ${PV} == *9999* ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/PackageKit/PackageKit-Qt.git"
else
	SRC_URI="https://github.com/PackageKit/PackageKit-Qt/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="amd64"
	S="${WORKDIR}/PackageKit-Qt-${PV}"
fi

LICENSE="LGPL-2.1+"
SLOT="6"
IUSE="+qt6 test"

DEPEND="
	app-admin/PackageKit
	qt6? (
		>=dev-qt/qtbase-6.2:6=[dbus]
	)
"
RDEPEND="
	${DEPEND}
"
BDEPEND="
	virtual/pkgconfig
"

RESTRICT="!test? ( test )"

src_configure() {
	local mycmakeargs=(
		-DMAINTAINER=OFF
	)

	if use qt6; then
		mycmakeargs+=(
			-DQT_VERSION_MAJOR=6
			-DBUILD_WITH_QT6=ON
		)
	elif use qt5; then
		mycmakeargs+=(
			-DQT_VERSION_MAJOR=5
			-DBUILD_WITH_QT6=OFF
		)
	fi

	cmake_src_configure
}

src_install() {
	cmake_src_install

	dodoc README.md NEWS AUTHORS MAINTAINERS TODO
}
