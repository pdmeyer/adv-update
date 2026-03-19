# Saving Max for Live Device presets with a project

I ran some tests related to saving, bundling, and distributing Max for Live device presets with a project.

## Project structure:
```
Preset Bundling Test
├── Presets
│   ├── Drag1.adv 
│   ├── Save1.adv 
│   └── Save2.adv 
├── Project Bundling Test.als
└── Tessella.amxd
```

## Presets
Drag1.adv:
- Was saved from Tessella.amxd by dragging the device from the track onto the project in the file browser
- This created a RelativePathType of 3 and a RelativePath of "Tessella.amxd"
- This preset successfully loaded on another machine using this Project folder.
Save1.adv: 
- This created a RelativePathType of 3 and a RelativePath of "Presets/Drag1.adv"
- Was saved from Drag1.adv by modifying, renaming, and then saving Drag1 as Save1
- This preset successfully loaded on another machine using this Project folder.
Save2.adv: 
- Was saved from Tessella.amxd by modifying, renaming, and then saving Tessella.amxd as Save2.
- Saving this preset caused Live to duplicate Tessella.amxd to the root level of my user library.
- This created a RelativePathType of 6 and a RelativePath of "Tessella.amxd"
- This preset did not load on another machine using this Project folder.

# Project Bundling
I tried two methods for bundling the project:
1. Copying the Project contents to a separate folder, then zipping that folder with my OS's native zip tool.
2. Creating an ALP file using the packing workflow in Live.

Both methods resulted in the same results. Drag1 and Save1 worked, but Save2 did not.

# XML Snippets
## Drag1
```xml
<FileRef>
    <RelativePathType Value="3" />
    <RelativePath Value="Tessella.amxd" />
    <Path Value="/Users/philipmeyer/Documents/Max 9/Max for Live Devices/2025/Tessella/Sets/Preset Bundling Test/Tessella.amxd" />
    <Type Value="2" />
    <LivePackName Value="" />
    <LivePackId Value="" />
    <OriginalFileSize Value="1067029" />
    <OriginalCrc Value="6244" />
    <SourceHint Value="" />
</FileRef>
```
## Save1
```xml
<FileRef>
    <RelativePathType Value="3" />
    <RelativePath Value="Presets/Drag1.adv" />
    <Path Value="/Users/philipmeyer/Documents/Max 9/Max for Live Devices/2025/Tessella/Sets/Preset Bundling Test/Presets/Drag1.adv" />
    <Type Value="2" />
    <LivePackName Value="" />
    <LivePackId Value="" />
    <OriginalFileSize Value="0" />
    <OriginalCrc Value="0" />
    <SourceHint Value="" />
</FileRef>
```

## Save2
```xml
<FileRef>
    <RelativePathType Value="6" />
    <RelativePath Value="Tessella.amxd" />
    <Path Value="/Volumes/T7/Ableton/User Library/Tessella.amxd" />
    <Type Value="2" />
    <LivePackName Value="" />
    <LivePackId Value="" />
    <OriginalFileSize Value="1067029" />
    <OriginalCrc Value="6244" />
    <SourceHint Value="" />
</FileRef>
```

# Conclusions
## How to save presets
The most foolproof way to save presets is:
- Save the device to the project
- Save the preset by dragging the device from the track onto the project in the file browser.

This will allow prestes to reliably load on another machine as long as the project folder remains in tact. 

One caveat is that the ADV file will still contain some stray references to the original device's original path on the original machine, particularly in the <Path> tag.

An alternative method for saving presets is to save them however you want, then manually modfiy the XML, but this is a bit more risky. I have been able to successfully save presets using these steps:
* Change `<RelativePathType>` to `"3"`
* Change `<RelativePath>` to the name of the device

A script that automates the process of modifying the XML can be found at: https://github.com/pdmeyer/adv-update. This script also allows you to use `<RelativePathType Value= "1">`, which does not rely upon a project. With this method, you would typically not use a Live project and deliver the ADVs and the AMXD together in a single folder. 

## The role of packing
Packing and unpacking does not seem to have any influence upon the preset files. From what I can tell, packing is the same as simply zipping the project contents (aside from the prompt that Live creates when you open the ALP)
