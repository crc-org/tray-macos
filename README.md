## CodeReady Container: OpenShift 4 on you laptop

This is a companion app for CodeReady Containers, it works only on macOS
For the CRC project head over to: https://github.com/code-ready/crc

[![Build Status](https://travis-ci.org/anjannath/crc-macos-tray.svg?branch=master)](https://travis-ci.org/anjannath/crc-macos-tray)

### How to use

1. You need the latest CRC binary first. Download it from https://github.com/code-ready/crc/releases
2. Download the precompiled tray app from releases page of this repository
3. run `crc daemon`
4. Launch the tray app you downloaded and you should see the OCP logo on the menubar

### Screenshots

<img src="https://i.imgur.com/XFAc9OB.png" alt="shot2" width="250" height="250"/>
<img src="https://i.imgur.com/RslQlpW.png" alt="shot3" width="268" height="250"/>
<img src="https://i.imgur.com/bMBqHUq.png" alt="shot1" width="250" height="250"/>

### Steps to build

**Note: CodeReady Containers tray needs minimum Xcode version 10.3. You might be able to build it with older versions of Xcode but that has not been tested.**

1. Clone this repository `git clone https://github.com/code-ready/crc-macos-tray.git`.
2. Change to the `crc-macos-tray` directory. 
3. Run the build script `./build.sh` which will create *_CodeReady Containers.app_* inside `crc-macos-tray/out` directory.
