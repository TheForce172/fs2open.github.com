#!/usr/bin/env bash

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
	APPIMAGE_TOOL_URL="https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-$(uname -m).AppImage"

	wget -O ./bin/linuxdeployqt "$APPIMAGE_TOOL_URL" || { echo "ERROR! Failed to get linuxdeployqt!" && exit 1; }
	chmod +x ./bin/linuxdeployqt
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
	CLEANFILENAME="$(find $INSTALL_FOLDER/qtFRED/bin -iname 'qtfred_*' ! -iname '*help*' -type f -printf "%f\n")"
	FILENAME="$(find $INSTALL_FOLDER/qtFRED/bin -iname 'qtfred_*' ! -iname '*help*' -type f -printf "%f\n").AppImage"
	./bin/linuxdeployqt "$INSTALL_FOLDER/qtFRED/bin/$CLEANFILENAME"
	appimagetool -n "$INSTALL_FOLDER/qtFRED" "$INSTALL_FOLDER/$FILENAME"
	chmod +x "$INSTALL_FOLDER/$FILENAME"
fi
fi

ls -al $INSTALL_FOLDER
