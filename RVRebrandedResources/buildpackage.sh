#
# RealityVision Client for iPhone
# Codesigns a rebranded RealityVision Client and packages it into an ipa for the App Store.
# 
# Usage: buildpackage.sh APP IDENTITY
#    APP is the application to sign (don't include the .app extension)
#    IDENTITY is the code signing identity to use
#

die() {
    echo "$*" >&2
    exit 1
}

appname="$1.app"
identity="$2"
curdir=`pwd`
ipaname="$1.ipa"
sdk="iphoneos4.3"

echo $0: Codesigning $appname for $identity

export CODESIGN_ALLOCATE=/Developer/Platforms/iPhoneOS.platform\
/Developer/usr/bin/codesign_allocate

codesign -f -s \""$identity"\" "$appname" | die codesign failed
xcrun -sdk $sdk PackageApplication "$appname" -o "$curdir/$ipaname"

