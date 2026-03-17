# ADV preset path updater

Updates Ableton Live `.adv` device preset files so they reference a device (`.amxd`) by relative path instead of absolute, and optionally checks for remaining absolute paths.

## Usage
Grant execute permissions to the script.
```bash
chmod +x adv_update.sh
```

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
2. In the ADV XML: sets `RelativePathType` to the given value (default 3), sets `RelativePath` to the device filename, and removes `<Path Value="..." />` and `<Type Value="..." />` lines.
3. Scans the file for stray absolute paths (lines containing `<Path Value="/Users` or `<BrowserContentPath Value=".../Users`) and prints a warning with line numbers if found. The script still exits 0; this is informational.