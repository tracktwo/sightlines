# LoS Indicator Mod for Long War

The LoS Indicator is a mod to bring the feature of XCOM2 back to Long War. With this mod 
enabled, icons will be visible on each visible enemy while moving the cursor around to select
a path. These icons indicate whether or not they will be able to see that enemy should they
move to that location.

The overwatch "eye" symbol added to each currently visible enemy is added to each unit that
will be visible from the target location. The icon is shaded blue to differentiate it
from overwatching enemies, and will toggle back and forth between red and blue for visible
enemies that are currently on overwatch as a reminder.

The mod contains two configurable variables that may be of interest, see the configuration
section below.

## Installation

1. Apply the patch file Sightlines.txt with PatcherGUI
2. Copy Sightlines.u to your XEW packages folder (e.g. C:\Program Files (x86)\Steam\SteamApps\Common\XCom Enemy Within\XEW\XComGame\CookedPCConsole)
3. Add the following line to the bottom of the DefaultMutatorLoader.ini file in your 
XEW Config folder:
    arrTacticalMutators="Sightlines.SightlineMutator"

### Upgrading From an Earlier Version

1. Uninstall the old patch. In PatcherGUI, click "Show Log" and find the patch script you 
installed for the Loadout Manager in the list of installed mods. Highlight it and select 
"Load Uninstaller". Then click "Apply".

2. Reinstall as per a normal fresh installation. You may not need to alter the 
DefaultMutatorLoader.ini, but ensure the correct lines are already there.

## Configuration

The mod contains two configurable variables. These can be modified by adding the following
lines to the bottom of DefaultGameCore.ini:

[Sightlines.SightlineMutator]
OVERWATCH_TOGGLE_DELAY=1.2
SIGHTLINE_TICK_DELAY=1.0

OVERWATCH_TOGGLE_DELAY controls how long the mod waits when switching back and forth
between the red and blue overwatch icons on visible, overwatching enemies. At the default
setting of 1.2, the indicator will toggle state every 1.2 seconds.

SIGHTLINE_TICK_DELAY controls the refresh rate of the LoS information. Setting this to a
lower value will mean a lower lag time between moving the mouse and updated LoS being
displayed on-screen, but may increase CPU use. Conversely, setting this value higher can
improve performance at a cost of less frequent LoS updates.

