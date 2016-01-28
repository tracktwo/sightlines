# LoS Indicator Mod for XCOM: Enemy Within / Long War

The LoS Indicator is a mod to bring the feature of XCOM2 back to XCOM EW/LW. With this mod 
enabled, while moving the cursor around to select a movement target tile enemies that will
be visible from that point are indicated graphically on the screen. 

The mod contains several configurable variables that may be of interest, see the configuration
section below.

## Installation

The installation steps are different depending on whether you are installing for Long War or
Vanilla EW. EU is not supported (but might work?)

### Installation with Long War 1.0

1. Apply the patch file Sightlines_LW.txt with PatcherGUI
2. Copy Sightlines.u to your XEW packages folder (e.g. C:\Program Files (x86)\Steam\SteamApps\Common\XCom Enemy Within\XEW\XComGame\CookedPCConsole)
3. Add the following line to the bottom of the DefaultMutatorLoader.ini file in your 
XEW Config folder:
    arrTacticalMutators="Sightlines.SightlineMutator"

### Installation for Enemy Within

Installation for Vanilla EW takes several steps, broken into three main sections. 

#### Enabling Modding

If you have never added any PatcherGUI based mods to your EW installation, you need to take a few steps to enable
modding at all:

1. Select "Enable INI loading" from the PatcherGUI "Tools" menu.
2. Select "Disable Phoning Home" from the PatcherGUI "Tools" menu. 

#### Enable Mutator support

Once modding is enabled, you need to enable mutators. This section is only needed if you have not installed any mutator
based EW mods. I am not aware of any others that don't require LW, so odds are good that if you are in doubt, you need to
do the steps in this section.
    
This section thanks to the efforts of Wasteland Ghost, without whose Mutator work most of my mods would not be possible. 
See https://github.com/wghost/XCom-Mutators, and the included file LICENSE-Mutators.txt for the licensing information
for this package.

1. Apply the patch file XComMutatorEnabler.txt with PatcherGUI
2. Copy DefaultMutatorLoader.ini to your XEW config folder (e.g. C:\Program Files (x86)\Steam\SteamApps\Common\XCom Enemy Within\XEW\XComGame\Config)
3. Add the following line to the [Engine.ScriptPackages] section of the DefaultEngine.ini file in your XEW Config folder (just after XComUIShell):
    +NonNativePackages=XComMutator
    
#### Enable the Sightlines Mod

Finally you're actually ready to install this mod. 

1. Apply the patch file Sightlines_EW.txt with PatcherGUI
2. Copy Sightlines.u to your XEW packages folder (e.g. C:\Program Files (x86)\Steam\SteamApps\Common\XCom Enemy Within\XEW\XComGame\CookedPCConsole)

If you skipped section 2 because you already had mutators enabled, you'll need to add Sightlines.SightlineMutator to your DefaultMutatorLoader.ini file
as per the instructions in the LW section. If you followed the steps to enable mutators this is already done for you in the file you copied over.

### Upgrading From an Earlier Version

1. Uninstall the old patch. In PatcherGUI, click "Show Log" and find the patch script you 
installed for the Loadout Manager in the list of installed mods. Highlight it and select 
"Load Uninstaller". Then click "Apply".

2. Reinstall as per a normal fresh installation. You may not need to alter the 
DefaultMutatorLoader.ini, but ensure the correct lines are already there.

## Configuration

The mod contains several configurable variables. These can be modified by adding the following
lines to the bottom of DefaultGameCore.ini:

    [Sightlines.SightlineMutator]
    OVERWATCH_TOGGLE_DELAY=1.2
    SIGHTLINE_TICK_DELAY=1.0
    SightIndicator=eIndicator_Disc_Green

OVERWATCH_TOGGLE_DELAY controls how long the mod waits when switching back and forth
between the red and blue overwatch icons on visible, overwatching enemies. At the default
setting of 1.2, the indicator will toggle state every 1.2 seconds.

SIGHTLINE_TICK_DELAY controls the refresh rate of the LoS information. Setting this to a
lower value will mean a lower lag time between moving the mouse and updated LoS being
displayed on-screen, but may increase CPU use. Conversely, setting this value higher can
improve performance at a cost of less frequent LoS updates.

SightIndicator controls how visible aliens are represented in the game. There are four
possible values:

eIndicator_Disc_Green
eIndicator_Disc_Orange
eIndicator_Disc_Gold
eIndicator_Overwatch  (Long War only!)

The first three (including the default, eIndicator_Disc_Green) use the unit selection
ring to indicate visible units, and the particular value determines the colour used
for the ring. 
    
eIndicator_Overwatch is only supported in Long War and uses the overwatch "eye" indicator 
to indicate visibility, similar to XCOM2's implementation.  The icon is shaded blue to 
differentiate it from overwatching enemies, and will toggle back and forth between red 
and blue for visible enemies that are currently on overwatch as a reminder.

