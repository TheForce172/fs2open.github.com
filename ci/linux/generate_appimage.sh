#!/usr/bin/env bash
export LD_LIBRARY_PATH=$(pwd)/bin/lib:$LD_LIBRARY_PATH
INSTALL_FOLDER=$1
# safety check
if [ ! -d bin -o ! -f cmake_install.cmake ]; then
	echo "ERROR! This script must be run from within the build root!"
	exit 1
fi

if [ ! -x "$(which wget)" ]; then
	echo "ERROR! Required utility is not available: wget"
	exit 1
fi

# install newest appimagetool if it's not already available
if [ ! -x ./bin/linuxdeployqt ]; then
	APPIMAGE_TOOL_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$(uname -m).AppImage"
	PLUGIN_TOOL_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$(uname -m).AppImage"

	wget -O ./bin/linuxdeploy "$APPIMAGE_TOOL_URL" || { echo "ERROR! Failed to get linuxdeployqt!" && exit 1; }
	wget -O ./bin/linuxdeploy-plugin-qt "$PLUGIN_TOOL_URL" || { echo "ERROR! Failed to get linuxdeployqt!" && exit 1; }
	chmod +x ./bin/linuxdeploy
	chmod +x ./bin/linuxdeploy-plugin-qt

	
fi

# This shouldn't be needed with newer runtimes, but they still generate an
# error if fusermount is missing even though it works. So to skip error msg
# and have max compatibility with runtimes and containers we'll use it.
export APPIMAGE_EXTRACT_AND_RUN=1
# Install Freespace2 targets
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_FOLDER/Freespace2 -DCOMPONENT=Unspecified -P cmake_install.cmake
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_FOLDER/Freespace2 -DCOMPONENT=Freespace2 -P cmake_install.cmake

# We need to be a bit creative for determining the AppImage name since we don't want to hard-code the name
FILENAME="$(find $INSTALL_FOLDER/Freespace2/bin -name 'fs2_open_*' -type f -printf "%f\n").AppImage"
appimagetool -n "$INSTALL_FOLDER/Freespace2" "$INSTALL_FOLDER/$FILENAME"
chmod +x "$INSTALL_FOLDER/$FILENAME"

# Maybe install qtFRED targets
if [[ "$RUNNER_ARCH" != "ARM" && "$RUNNER_ARCH" != "ARM64" ]]; then
	if [ "$ENABLE_QTFRED" = "ON" ]; then
		cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_FOLDER/qtFRED -DCOMPONENT=Unspecified -P cmake_install.cmake
		cmake -DCMAKE_INSTALL_PREFIX=$INSTALL_FOLDER/qtFRED -DCOMPONENT=qtFRED -P cmake_install.cmake
		# We need to be a bit creative for determining the AppImage name since we don't want to hard-code the name
		export QT_QPA_PLATFORM=offscreen
		TARGET_DIR="$INSTALL_FOLDER/qtFRED/bin"
		DESKTOP_PATH=$(find "$INSTALL_FOLDER/qtFRED" -name "*.desktop" -type f -print -quit)
		BINARY_PATH=$(find "$TARGET_DIR" -type f -name "qtfred_*" -not -name "*help*" -print -quit)
		CLEANFILENAME=$(basename "$BINARY_PATH")
		FILENAME="${CLEANFILENAME}.AppImage"
		if [ -z "$BINARY_PATH" ] || [ ! -f "$BINARY_PATH" ]; then
    		echo "ERROR: linuxdeployqt target not found at $BINARY_PATH"
    		exit 1
		fi
		#FILENAME="$(find $INSTALL_FOLDER/qtFRED/bin -iname 'qtfred_*' ! -iname '*help*' -type f -printf "%f\n").AppImage"
		./bin/linuxdeploy --appdir "$INSTALL_FOLDER/qtFRED" --plugin qt --executable "$BINARY_PATHY"
		appimagetool -n "$INSTALL_FOLDER/qtFRED" "$INSTALL_FOLDER/$FILENAME"
		chmod +x "$INSTALL_FOLDER/$FILENAME"
	fi
fi

ls -al $INSTALL_FOLDER
