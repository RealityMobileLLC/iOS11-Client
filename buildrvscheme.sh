#
# RealityVision Client for iPhone
# Builds a specific XCode scheme
#
# Usage: buildrvscheme.sh app-name scheme sdk ipa-name
#    Where
#       app-name is the name of the app to build
#       config is the name of the XCode scheme to build
#         (i.e., 'RealityVision Ad Hoc' or 'RealityVision App Store')
#       sdk is the name of the iOS SDK to build against
#       ipa-name is the name of the ipa output file
#

die() {
    echo "$*" >&2
    exit 1
}

appname=$1
scheme=$2
sdk=$3
ipaname=$4
project_dir=$(pwd)
build_dir="$project_dir/build/$scheme"

echo $0: Building scheme $scheme

security unlock-keychain -p turtlepower /Users/cm/Library/Keychains/login.keychain || die "$0: Failed to unlock keychain"
xcodebuild -workspace RealityVision.xcworkspace -scheme "$scheme" -sdk $sdk build TARGET_BUILD_DIR="$build_dir" || die "$0: Build failed"

echo $0: Packaging ipa
xcrun -sdk $sdk PackageApplication -v "$build_dir/$appname.app" -o "$build_dir/$ipaname"

echo $0: Finished building $ipaname
