SpeedPitch
==========

![SpeedPitch icon](images/appicon/speedpitch-1024.png|width=512)

Copyright (c) [Dan Wilcox](danomatika.com) 2021

BSD Simplified License.

For information on usage and redistribution, and for a DISCLAIMER OF ALL
WARRANTIES, see the file, "LICENSE.txt," in this distribution.

Description
-----------

_SpeedPitch_ is a simple augmented sonic reality experiment that alters music playback rate based on your actual GPS ground speed. The faster you go, the higher the pitch and sudden stops lead to dragging audio samples. Natural motion leads to unnatural sound.

http://danomatika.com/code/speedpitch

[SpeedPitch on the iOS App Store](https://itunes.apple.com/app/id1577262763)

User Guide
----------

### Usage

1. Select files from the Music app or Files browser using the buttons in the main screen, upper right
2. Start playback via pressing play or tapping a song in the playlist screen
3. Ride you bike or take a walk and see what happens...

### Speed

You can adjust the speed limit for the pitch processing to set the speed songs are played back at a normal rate: menu button, upper right -> Speed. The speed ranges approximate the type of movement you will be doing based on the vehicle.

### Quantization

The playback rate calculation from the live speed updates can be quantized. This basically changes the rate in discrete steps instead of a smooth range which makes matching speed between multiple people much easier.

### Keep Awake

Live speed calculations require navigation-level GPS updates which only ocurr when the device is in active use. If the screen turns off, GPS updates to SpeedPitch will be paused therefore, by default, the "Keep screen awake" SpeedPitch display setting is set to on.

### Minimal

Long-press on the current speed to hide or show the navigation bar and playback controls.

Developing
----------

### Release steps

1. Update version in Xcode project, AppInfo.txt, and changelog
2. Update changelog with relevant changes
3. Archive and distribute to App Store Connect
4. Tag version

Acknowledgments
---------------

This project has been developed as part of the Nix Wie Raus! Fahrrad Kunst Sommer exhibition at the BBK in Karlsruhe Germany 2021.

https://www.bbk-karlsruhe.de/fahrrad-kunst-sommer/
