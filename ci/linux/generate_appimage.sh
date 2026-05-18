#!/usr/bin/env bash

INSTALL_FOLDER=$1

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
	FILENAME="$(find $INSTALL_FOLDER/qtFRED/bin -iname 'qtfred_*' -type f -printf "%f\n").AppImage"
	appimagetool -n "$INSTALL_FOLDER/qtFRED" "$INSTALL_FOLDER/$FILENAME"
	chmod +x "$INSTALL_FOLDER/$FILENAME"
fi
fi

ls -al $INSTALL_FOLDER
