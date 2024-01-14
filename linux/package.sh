#!/bin/sh -e
#
#  Copyright 2022, Roger Brown
#
#  This file is part of rhubarb-geek-nz/svnkit.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

VERSION=1.10.8
PKGNAME=svnkit
ZIPFILE="org.tmatesoft.svn_$VERSION.standalone.zip"
INTDIR="$(pwd)"
SPECFILE="$INTDIR/rpm.spec"
TGTPATH="$INTDIR/rpm.dir"
BASEDIR="$INTDIR/root"
PKGROOT="usr/share/$PKGNAME"
RPMBUILD=rpm
RELEASE=$(git log --oneline "$0" | wc -l)

trap "chmod -R +w root ; rm -rf root $SPECFILE $TGTPATH $BASEDIR $ZIPFILE" 0

if test ! -f "$ZIPFILE"
then
	curl --silent --fail --location --output "$ZIPFILE" "https://www.svnkit.com/$ZIPFILE"
fi

mkdir -p "$TGTPATH" $(dirname "$BASEDIR/$PKGROOT") "$BASEDIR/usr/bin"

unzip "$ZIPFILE"

mv "$PKGNAME-$VERSION" "$BASEDIR/$PKGROOT"

rm -rf *.rpm

(
	set -e

	cd "$BASEDIR/$PKGROOT"

	rm -rf src

	cd bin

	rm *.bat *.openvms
)

cat > "$BASEDIR/usr/bin/svn" << EOF
#!/bin/sh -e
#
#  Copyright 2022, Roger Brown
#
#  This file is part of rhubarb-geek-nz/svnkit.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#

exec /$PKGROOT/bin/jsvn "\$@"
EOF

chmod +x "$BASEDIR/usr/bin/svn"

if rpmbuild --help >/dev/null
then
    RPMBUILD=rpmbuild
fi

(
	cat << EOF
Summary: SVNKit $VERSION
Name: $PKGNAME
Version: $VERSION
BuildArch: noarch
Release: $RELEASE
Group: Development/Tools
Conflicts: subversion
License: TMate
Prefix: /

%description
Subversion is a leading and fast growing Open Source version control system. SVNKit brings Subversion closer to the Java world! SVNKit is a pure Java toolkit - it implements all Subversion features and provides APIs to work with Subversion working copies, access and manipulate Subversion repositories - everything within your Java application.

EOF

	echo "%files"
	echo "%defattr(-,root,root)"
	cd "$BASEDIR"

	find "$PKGROOT" usr/bin/* | while read N
	do
		if test -L "$N"
		then
			echo "/$N"
		else
			if test -d "$N"
			then
				echo "%dir %attr(555,root,root) /$N"
			else
				if test -f "$N"
				then
					if test -x "$N"
					then
						echo "%attr(555,root,root) /$N"
					else
						echo "%attr(444,root,root) /$N"	
					fi
				fi
			fi
		fi
	done

	echo
	echo "%clean"
	echo echo clean "$\@"
	echo
) >$SPECFILE

"$RPMBUILD" --buildroot "$BASEDIR" --define "_build_id_links none" --define "_rpmdir $TGTPATH" -bb "$SPECFILE"

find  "$TGTPATH" -type f -name "*.rpm" | while read N
do
	mv "$N" .
done
