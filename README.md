dcs-arduino-example
===================

**Note: This is an old example. I suggest using [DCS-BIOS](https://github.com/dcs-bios/dcs-bios) instead.**

An Arduino sketch and matching Export.lua file.

* Displays the contents of the CMSP on a 20x2 character LCD attached to the Arduino
* Turns the LED on pin 13 of the Arduino into a Master Warning Light
* Turns a push button on digital pin 10 into a Master Caution button

### How to use

If you don't have an `Export.lua` file, rename `CMSPExport.lua` to `Export.lua` and copy it to `%USERPROFILE%\Saved Games\DCS\Scripts`.

If you do have an existing `Export.lua`, copy `CMSPExport.lua` to `%USERPROFILE%\Saved Games\DCS\Scripts` and add the following line to the end of your existing `Export.lua`:

````lua
dofile(lfs.writedir()..[[Scripts\CMSPExport.lua]])
````
Edit `run-socat.cmd` to set the correct COM port and start it to transfer data between the serial port and DCS.

### Protocol

Each command is one line (terminated by `\n`). The line begins with the command name and a space; interpretation of the rest depends on the command.

Commands sent from DCS to the Arduino:

* `MC-LED <0|1>` Turn the Master Caution LED on or off
* `CMSP1 <some text>` Set line 1 of the display. The line is not cleared first, so to get an empty line, you have to send 20 spaces.
* `CMSP2 <some text>` Set line 2 of the display. The line is not cleared first, so to get an empty line, you have to send 20 spaces.

Commands sent from the Arduino to DCS:

* `MASTER-CAUTION-BTN <0|1>` Set the state of the Master Caution button (1 = pushed in).

### License

The code is released under the MIT license.
This repository includes a binary distribution of `socat` (GPLv2 and MIT, see `socat/README`).
