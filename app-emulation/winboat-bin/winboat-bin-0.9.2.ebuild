# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

CHROMIUM_LANGS="
	af am ar bg bn ca cs da de el en-GB en-US es es-419 et fa fi fil fr gu he hi
	hr hu id it ja kn ko lt lv ml mr ms nb nl pl pt-BR pt-PT ro ru sk sl sr sv
	sw ta te th tr uk ur vi zh-CN zh-TW
"

inherit chromium-2 desktop optfeature pax-utils xdg

MY_PN="${PN%-bin}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Run Windows applications on Linux with seamless desktop integration"
HOMEPAGE="https://www.winboat.app/
	https://github.com/TibixDev/winboat/"
SRC_URI="
	https://github.com/TibixDev/winboat/releases/download/v${PV}/${MY_P}-x64.tar.gz
	https://raw.githubusercontent.com/TibixDev/winboat/v${PV}/icons/winboat_logo.svg
		-> ${MY_P}.svg
"
S="${WORKDIR}/${MY_P}-x64"

LICENSE="MIT"
LICENSE+=" Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 Base64 Boost-1.0 CC-BY-3.0 CC-BY-4.0 Clear-BSD FFT2D FTL"
LICENSE+=" IJG ISC LGPL-2 LGPL-2.1 MIT MPL-1.1 MPL-2.0 Ms-PL PSF-2 SGI-B-2.0 SSLeay SunSoft Unicode-3.0"
LICENSE+=" Unicode-DFS-2015 Unlicense UoI-NCSA ZLIB libtiff openssl"
LICENSE+=" Apache-1.1 BlueOak-1.0.0"
LICENSE+=" CC0-1.0 public-domain"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="+docker podman smartcard"
REQUIRED_USE="|| ( docker podman )"
RESTRICT="strip"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-misc/freerdp:3[client,X]
	net-print/cups
	sys-apps/dbus
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	|| (
		net-misc/freerdp:3[alsa]
		net-misc/freerdp:3[pulseaudio]
	)
	docker? (
		app-containers/docker
		app-containers/docker-cli
		app-containers/docker-compose
	)
	podman? (
		app-containers/podman
		app-containers/podman-compose
	)
	smartcard? ( net-misc/freerdp:3[smartcard] )
"

CONFIG_CHECK="~KVM ~TUN"
ERROR_KVM="CONFIG_KVM is required to run the Windows virtual machine"
ERROR_TUN="CONFIG_TUN is required for the virtual machine's networking"

QA_PREBUILT="opt/${MY_PN}/*"

src_configure() {
	default

	chromium_suid_sandbox_check_kernel_config
}

src_prepare() {
	default

	cd locales || die
	chromium_remove_language_paks
	cd "${S}" || die

	local moddir prebuilds
	for moddir in resources/app.asar.unpacked/node_modules/*; do
		prebuilds="${moddir}/prebuilds"
		[[ -d ${prebuilds} ]] || continue

		find "${prebuilds}" -mindepth 1 -maxdepth 1 -type d \
			! -name 'linux-x64' -exec rm -r {} + || die
	done
}

src_install() {
	local app_root="/opt/${MY_PN}"

	dodoc LICENSE.electron.txt LICENSES.chromium.html
	rm LICENSE.electron.txt LICENSES.chromium.html || die

	insinto "${app_root}"
	doins -r .

	fperms +x "${app_root}"/${MY_PN}
	fperms +x "${app_root}"/chrome_crashpad_handler
	fperms 4711 "${app_root}"/chrome-sandbox

	pax-mark m "${ED}${app_root}"/${MY_PN}

	dosym -r "${app_root}"/${MY_PN} /usr/bin/${MY_PN}

	domenu "${FILESDIR}"/${MY_PN}.desktop
	newicon -s scalable "${DISTDIR}"/${MY_P}.svg ${MY_PN}.svg
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "WinBoat runs Windows in a container, so your user needs access to"
	elog "the container runtime:"
	if use docker; then
		elog "  Docker: add your user to the 'docker' group and enable the service"
	fi
	if use podman; then
		elog "  Podman: USB passthrough is currently unsupported on Podman"
	fi
	elog
	elog "FreeRDP 3.x with sound support is required and pulled in as a"
	elog "dependency. WinBoat looks for 'xfreerdp3' and then 'xfreerdp'."
	elog
	elog "Loading the iptables/nftables kernel modules can improve the VM's"
	elog "network performance, but is not required."

	optfeature "sharing host smartcards with the Windows guest" \
		"net-misc/freerdp:3[smartcard]"
}
