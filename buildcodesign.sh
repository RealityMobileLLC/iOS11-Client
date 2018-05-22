#
# RealityVision Client for iPhone
# Codesign script
#
# Usage: buildcodesign.sh APP IDENTITY
#    APP is the application to sign (don't include the .app extension)
#    IDENTITY is the code signing identity to use
#

die() {
    echo "$*" >&2
    exit 1
}

appname=$1
identity=$2

echo $0: Codesigning $appname for $identity

export CODESIGN_ALLOCATE=/Developer/Platforms/iPhoneOS.platform\
/Developer/usr/bin/codesign_allocate

codesign -f -s $identity $1.app | die codesign failed
