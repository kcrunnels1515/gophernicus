# Maintainer: Kelly Runnels <kcrunnels15@gmail.com>
pkgname=gophernicus
pkgver=1.0
pkgrel=1
pkgdesc="The Gophernicus gopher server, with edited, usable Makefile."
arch=(x86_64)
url="http://github.com/kcrunnels1515/gophernicus.git"
license=('MIT')
groups=()
depends=()
makedepends=(git)
checkdepends=()
optdepends=()
provides=(in.gophernicus)
conflicts=()
replaces=()
backup=()
options=()
install=
changelog=
source=("git+$url")
noextract=()
md5sums=('SKIP')
validpgpkeys=()

build() {
	cd gophernicus 
	make
}

package() {
	cd gophernicus
	make DESTDIR="$pkgdir/" install
}
