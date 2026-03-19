# ADV preset path updater

Updates Ableton Live `.adv` device preset files so they reference a Max for Live device (`.amxd`) by a relative instead of absolute path.

This is useful when distributing Max for Live devices with presets. Normally, presets are linked to the Max for Live device using an absolute path to the device file. However, it is possible to link Live to connect the preset to the device via a relative reference by editing the `.adv` file, which is in XML format. Once the `.adv` file is updated, the preset will be linked to the device via a relative reference. This allows the user to move the device and presets (together, but not separately!) to a different location without breaking the link.

Thanks to Mattijs Kneppers for documenting this process. To learn more, see his [post on the Cycling '74 Forum](https://cycling74.com/forums/embedding-adv-presets-with-a-max-for-live-amxd-or-how-to-send-device-to-someone-else-with-presets#reply-61113ecf7c499450d12c2469).

## Usage
Grant execute permissions to the script. (You only need to do this once.)
```bash
chmod +x adv_update.sh
```

Run the script.
```bash
./adv_update.sh <path> <device.amxd> [1|3]
```

- **path**: Absolute path to a single `.adv` file or a folder of `.adv` files.
- **device.amxd**: Device filename only. Same device is applied to all presets when path is a folder.
- **RelativePathType** (optional): `1` or `3`. Default `3`. Use `1` to link the ADV file to the AMXD file in the same folder. Use `3` to link the ADV file to an AMXD in the same Project folder. 

### Examples

```bash
# Single preset
./adv_update.sh "/path/to/Preset Name.adv" "MyDevice.amxd"

# All presets in a folder
./adv_update.sh "/path/to/Presets/" "MyDevice.amxd"

# Use RelativePathType 1
./adv_update.sh "/path/to/Presets/" "MyDevice.amxd" 1
```

## What it does
1. Decompresses the file if it is gzipped (in place).
2. In the ADV XML: 
    - sets `RelativePathType` to the given value (default 3)
    - sets `RelativePath` to the device filename
    - removes `<Path Value="..." />` and `<Type Value="..." />` lines.
3. Scans the XML for stray absolute paths (lines containing `<Path Value="/Users` or `<BrowserContentPath Value=".../Users`) and prints a warning with line numbers if found. The script still exits 0; this is informational.