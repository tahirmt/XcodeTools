default:
	xcodebuild -configuration Release
	cp -rf build/Release/XcodeTools.app /Applications/XcodeTools.app