#!/bin/sh -e
#
# Copyright 2022, Roger Brown
#
# This file is part of rhubarb-geek-nz/svnkit.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#

VERSION=1.10.8
PKGNAME=svnkit
ZIPFILE="org.tmatesoft.svn_$VERSION.standalone.zip"
IDENTIFIER=nz.geek.rhubarb.svnkit

trap "rm -rf root $PKGNAME.pkg distribution.xml $ZIPFILE" 0

if test ! -f "$ZIPFILE"
then
	curl --silent --fail --location --output "$ZIPFILE" "https://www.svnkit.com/$ZIPFILE"
fi

mkdir -p root/share root/bin

(
	set -e

	cd root/share

	unzip "../../$ZIPFILE"

	mv "$PKGNAME-$VERSION" "$PKGNAME"

	rm -rf "$PKGNAME/src"

	cd "$PKGNAME/bin"
	rm *.bat *.openvms
)

cat > "root/bin/svn" <<EOF
#!/bin/sh -e
#
# Copyright 2022, Roger Brown
#
# This file is part of rhubarb-geek-nz/svnkit.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# See <http://www.gnu.org/licenses/>
#

JAVA_HOME=\$(/usr/libexec/java_home) exec /usr/local/share/$PKGNAME/bin/jsvn "\$@"
EOF

tail -1 "root/bin/svn" 

chmod +x "root/bin/svn" 

pkgbuild \
	--identifier $IDENTIFIER \
	--version "$VERSION" \
	--root root \
	--install-location /usr/local \
	--sign "Developer ID Installer: $APPLE_DEVELOPER" \
	"$PKGNAME.pkg"

cat > distribution.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <pkg-ref id="$IDENTIFIER"/>
    <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">$PKGNAME.pkg</pkg-ref>
    <title>SVNKit - $VERSION</title>
</installer-gui-script>
EOF

productbuild --distribution ./distribution.xml --package-path . ./$PKGNAME-$VERSION.pkg --sign "Developer ID Installer: $APPLE_DEVELOPER"
