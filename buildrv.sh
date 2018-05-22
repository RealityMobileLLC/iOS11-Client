#
# RealityVision Client for iPhone
# Build script
#
# There are three version numbers associated with an iOS build:
# 
#   Build number (aka Project version, aka Bundle version)
#     A monotonically increased integer that increments with every QA build.
#     This is only used internally by iTunes Connect to differentiate builds submitted to the App Store.
#     It is not displayed to the user in either the App Store or the RealityVision app.
#   
#   Marketing version (aka Release version, aka Bundle short version string)
#     Three period-separated integers uniquely identifying a released build.
#     It is derived from the first three integers in the RealityVision About version.
#     This is the version number displayed on the App Store.
#     
#   RealityVision About version
#     Four period-separated integers uniquely identifying an internal build.
#     This is the version number displayed on the About view of the app.
#
# Usage: buildrv.sh [setvers RV_VERSION [BUILD_NUMBER]]
# 
# Options:
#
#    setvers RV_VERSION [BUILD_NUMBER]
#      
#      Sets the RealityVision About version to RV_VERSION and sets the Marketing
#      version to the first three integers in RV_VERSION.
#      
#      If the optional BUILD_NUMBER is provided, it sets the Build number to the
#      given value.  Otherwise, the Build number is incremented.
#      
#      The "servers" option should be used only for QA builds.
#

die() {
    echo "$*" >&2
    exit 1
}

usage() {
    die "$0: Usage: $0 [setvers RV_VERSION [BUILD_NUMBER]]"
}

appname='RealityVision'
sdk='iphoneos6.1'
project_dir=$(pwd)
builddate=$(date -u +%Y%m%d%H%M%S)
projectfiles='RealityVision-Info.plist RealityVision.xcodeproj/project.pbxproj'

# if there are multiple versions of Xcode installed, use the next line to point to the desired one
#export DEVELOPER_DIR=/Developer

if [ "$#" -eq 1 -o "$#" -gt 3 ]; then
    # invalid number of parameters
    usage $0
fi

if [ "$#" -gt 1 ]; then
    if [ "$1" = "setvers" ]; then
        echo $0: Setting $appname version number to $2
        chmod +w $projectfiles
        export RV_ABOUT_VERSION="$2"
        mversion=`expr "$RV_ABOUT_VERSION" : '\([0-9]*\.[0-9]*\.[0-9]*\)'`
        agvtool new-marketing-version "$mversion"
        if [ "$#" = "3" ]; then
            echo $0: Setting build number to $3
            agvtool new-version -all "$3"
        else
            echo $0: Incrementing build number
            agvtool bump -all
        fi
    else
        # unrecognized option
        usage $0
    fi
else
    export RV_ABOUT_VERSION="$(agvtool mvers -terse1)"
fi

buildnum="$(agvtool vers -terse)"
fullversion="$RV_ABOUT_VERSION-$buildnum"
echo $0: Building $appname version $fullversion

#./buildrvforconfig.sh $appname 'Distribution Ad Hoc' $sdk "$appname.$fullversion.$builddate-adhoc.ipa" || die "$0: Failed to build Ad Hoc configuration"
#./buildrvforconfig.sh $appname 'Distribution App Store' $sdk "$appname.$fullversion.$builddate-appstore.ipa" || die "$0: Failed to build App Store configuration"
./buildrvscheme.sh $appname 'RealityVision Ad Hoc' $sdk "$appname.$fullversion.$builddate-adhoc.ipa" || die "$0: Failed to build Ad Hoc configuration"
./buildrvscheme.sh $appname 'RealityVision App Store' $sdk "$appname.$fullversion.$builddate-appstore.ipa" || die "$0: Failed to build Ad Hoc configuration"

if [ "$1" = "setvers" ]; then
    echo $0: Promoting changed project files
    cd "$project_dir"
    accurev login cm turtle123
    accurev keep -c "Auto-promote: Updated version to $fullversion" $projectfiles || die "$0: Keep before promote failed"
    accurev promote -c "Auto-promote: Updated version to $fullversion" -K $projectfiles || die "$0: Promote failed"
fi

echo $0: $appname built successfully
