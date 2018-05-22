#
# RealityVision Client for iPhone
# Builds a specific XCode configuration
#
# Usage: buildrvforconfig.sh app-name config sdk ipa-name
#    Where
#       app-name is the name of the app to build
#       config is the name of the XCode configuration to build
#         (i.e., 'Distribution Ad Hoc' or 'Distribution App Store')
#       sdk is the name of the iOS SDK to build against
#       ipa-name is the name of the ipa output file
#

die() {
    echo "$*" >&2
    exit 1
}

appname=$1
config=$2
sdk=$3
ipaname=$4
project_dir=$(pwd)
build_dir="$project_dir/build/$config-iphoneos"

echo $0: Building configuration $config

security unlock-keychain -p turtlepower /Users/cm/Library/Keychains/login.keychain || die "$0: Failed to unlock keychain"
xcodebuild -configuration "$config" -sdk $sdk build || die "$0: Build failed"

echo $0: Packaging ipa
xcrun -sdk $sdk PackageApplication -v "$build_dir/$appname.app" -o "$build_dir/$ipaname"

echo $0: Finished building $ipaname
