class SightlineMutator extends XComMutator config(GameCore);

enum ESightIndicator
{
    eIndicator_Overwatch,
    eIndicator_Disc_Green,
    eIndicator_Disc_Orange,
    eIndicator_Disc_Gold
};

var XGUnit m_kFriendlyChryssalid;
var XGUnit m_kFriendlySectoid;
var float m_fTimeSinceLastTick;

// What type of indicator to use for visible enemies
var config ESightIndicator SightIndicator;

// How much time to wait between toggling the blue/red overwatch icon
var config float OVERWATCH_TOGGLE_DELAY; 

// How much time to wait between ticks before processing LoS
var config float SIGHTLINE_TICK_DELAY;


function Mutate(String MutateString, PlayerController Sender)
{
    if (MutateString == "XComTacticalController.ParsePath") {
        MoveHelperOutOfTheWay(m_kFriendlySectoid);
        MoveHelperOutOfTheWay(m_kFriendlyChryssalid);
    }
    super.Mutate(MutateString, Sender);
}

// Move the helper units somewhere safe. This is invoked from a mutator call before processing a move
// order as moving onto the same tile as a helper corrupts the tile blocking state such that the
// tile is considered unoccupied. This means other units can then walk right onto it. By moving the units
// out of the way first to a close, empty location, the tile remains blocked after the move order completes.
function MoveHelperOutOfTheWay(XGUnit kUnit)
{
    local vector vPosition;

    if (kUnit != none) {
        vPosition = class'XComWorldData'.static.GetWorldData().FindClosestValidLocation(kUnit.Location, false, false);
        MoveHelper(kUnit, vPosition);
    }
}

// Swap back and forth between overwatch "red" and "blue" indicators for overwatching enemies.
function ToggleOverwatchIndicators()
{
    local XGUnit kUnit;

    foreach AllActors(class'XGUnit', kUnit) {
        if (kUnit.m_aCurrentStats[eStat_Reaction] > 0) {
            if ((kUnit.m_iZombieMoraleLoss & 0x40000000) != 0) {
                // Enemy is on overwatch and is visible. Toggle their icon to normal by temporarily
                // removing the "visible" flag, and saving it in another bit.
                kUnit.m_iZombieMoraleLoss = kUnit.m_iZombieMoraleLoss & ~0x40000000;
                kUnit.m_iZombieMoraleLoss = kUnit.m_iZombieMoraleLoss | 0x20000000;
            } else if ((kUnit.m_iZombieMoraleLoss & 0x20000000) != 0) {
                // Enemy was toggled to the alternate view. Toggle them back.
                kUnit.m_iZombieMoraleLoss = kUnit.m_iZombieMoraleLoss & ~0x20000000;
                kUnit.m_iZombieMoraleLoss = kUnit.m_iZombieMoraleLoss | 0x40000000;
            }
        }
    }

    SetTimer(OVERWATCH_TOGGLE_DELAY, false, 'ToggleOverwatchIndicators');
}

// Visibilty updates are processed on tick intervals. The minimum time passed between updates
// is configurable via SIGHTLINE_TICK_DELAY.
simulated event Tick(float fDeltaTime)
{
    local XGUnit kActiveUnit;
    local XComPlayerController kController;
    kController = XComPlayerController(WorldInfo.GetALocalPlayerController());
    kActiveUnit = XComTacticalController(kController).GetActiveUnit();

    if (kActiveUnit == none || kActiveUnit.GetTeam() != eTeam_XCom || kActiveUnit.IsPerformingAction()) {
        RemoveAllVisibility();
        return;
    }

    m_fTimeSinceLastTick += fDeltaTime;
    if (m_fTimeSinceLastTick < SIGHTLINE_TICK_DELAY) {
        return;
    }

    m_fTimeSinceLastTick = 0.0;

    ProcessSightline(fDeltaTime);
}

// Initialize a helper - set them as invisible and non-interacting with the environment.
function InitializeHelper(XGUnit kHelper)
{
    kHelper.GetPawn().SetCollision(false, false, true);
    kHelper.GetPawn().bCollideWorld = false;
    kHelper.GetPawn().SetPhysics(0);

    // Make sure the helper is invisible
    kHelper.SetVisible(false);
    kHelper.SetHidden(true);
    kHelper.SetHiding(true);
    kHelper.GetPawn().SetHidden(true);
    kHelper.GetPawn().HideMainPawnMesh();
    kHelper.GetPawn().Weapon.Mesh.SetHidden(true);
}

// Move a helper unit to a new location.
function MoveHelper(XGUnit kHelper, vector cursorLoc)
{
    kHelper.GetPawn().SetLocation(cursorLoc);

    // Process the new position without evaluating the new stance or the pawn will interact 
    // with the environment in ways we don't want (e.g. splashing in water).
    kHelper.ProcessNewPosition(false);

    // Don't mark the tile occupied by the helper as blocked. E.g. if you're behind hard cover
    // and are peeking out around a corner and you move the cursor to the tile you peek out over,
    // you would otherwise lose vision as this unit is blocking the peek.
    class'XComWorldData'.static.GetWorldData().ClearTileBlockedByUnitFlag(kHelper);
}

// Process all units in the game and update their visibility flags. Return true if any unit changed
// from not visible to visible or vice versa.
function bool ProcessVisibleUnits(XGUnit kHelper)
{
    local array<XGUnit> arrEnemies;
    local XGUnit kEnemy;
    local bool bAnyChange;

    // Gather up all the enemies the helper can see
    arrEnemies = kHelper.GetVisibleEnemies();

    // Reset all units in the game to not visible.
    foreach AllActors(class'XGUnit', kEnemy) {
        if (kEnemy.GetTeam() != eTeam_Alien) {
            continue;
        }

        if (arrEnemies.Find(kEnemy) != -1) {
            // Enemy is visible. Set the flag if it isn't already set.
            if ((kEnemy.m_iZombieMoraleLoss & 0x60000000) == 0) {
                kEnemy.m_iZombieMoraleLoss = kEnemy.m_iZombieMoraleLoss | 0x40000000;
                bAnyChange = true;
            } 

            // All visible enemies should have their discs updated if necessary, regardless
            // if they're coming into sight or not.
            switch(SightIndicator) {
                case eIndicator_Disc_Green:
                    kEnemy.SetDiscState(6);
                    kEnemy.m_kDiscMesh.SetMaterial(0, kEnemy.UnitCursor_UnitSelect_Green);
                    break;
                case eIndicator_Disc_Orange:
                    kEnemy.SetDiscState(6);
                    break;
                case eIndicator_Disc_Gold:
                    kEnemy.SetDiscState(6);
                    kEnemy.m_kDiscMesh.SetMaterial(0, kEnemy.UnitCursor_UnitSelect_Gold);
                    break;
                default:
            }
        } else {
            // Enemy is not visible. Strip all flags.
            if ((kEnemy.m_iZombieMoraleLoss & 0x60000000) != 0) {
                kEnemy.m_iZombieMoraleLoss = kEnemy.m_iZombieMoraleLoss & ~0x60000000;
                bAnyChange = true;
            }

            // Reset disc state if necessary.
            if (SightIndicator != eIndicator_Overwatch) {
                kEnemy.SetDiscState(0);
            }
        }
    }

    return bAnyChange;
}

// Strip the visibility bits from all enemies.
function RemoveAllVisibility()
{
    local XGUnit kUnit;

    foreach AllActors(class'XGUnit', kUnit) {
        kUnit.m_iZombieMoraleLoss = kUnit.m_iZombieMoraleLoss & ~0x60000000;
        if (SightIndicator != eIndicator_Overwatch) {
            kUnit.SetDiscState(0);
        }
    }
}

// Create a helper unit of the given type.
function XGUnit CreateHelper(EPawnType ePawnType)
{
    local XComSpawnPoint_Alien kSpawnPt;
    local XGPlayer kPlayer;
    local XGUnit kUnit;

    kSpawnPt = Spawn(class'XComSpawnPoint_Alien');
    kPlayer = XGBattle_SP(XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle).GetAnimalPlayer();
    kUnit = kPlayer.SpawnAlien(ePawnType, kSpawnPt,,, false);
    return kUnit;
}

function ProcessSightline(float fDeltaTime)
{
    local Vector cursorLoc;
    local XComPlayerController controllerRef;
    local XGUnit kActiveUnit;
    local XGUnit kUnit;
    local XComPathingPawn kPathPawn;
    local bool bAnyChange;

    controllerRef = XComPlayerController(WorldInfo.GetALocalPlayerController());

    kActiveUnit = XComTacticalController(controllerRef).GetActiveUnit();

    // Try to find our helpers. They may have been loaded from a saved game.
    if (m_kFriendlyChryssalid == none) {
        foreach AllActors(class'XGUnit', kUnit) {
            if (kUnit.GetTeam() == eTeam_Neutral && kUnit.GetCharacter().m_eType == ePawnType_Chryssalid) {
                m_kFriendlyChryssalid = kUnit;
                InitializeHelper(m_kFriendlyChryssalid);
                break;
            }
        }
    }

    if (m_kFriendlySectoid == none) {
        foreach AllActors(class'XGUnit', kUnit) {
            if (kUnit.GetTeam() == eTeam_Neutral && kUnit.GetCharacter().m_eType == ePawnType_Sectoid) {
                m_kFriendlySectoid = kUnit; 
                InitializeHelper(m_kFriendlySectoid);
                break;
            }
        }
    }

    // Spawn the helpers, if necessary.
    if (m_kFriendlyChryssalid == none) {
        m_kFriendlyChryssalid = CreateHelper(ePawnType_Chryssalid);
        m_kFriendlyChryssalid.SetvisibleToTeams(0);
        InitializeHelper(m_kFriendlyChryssalid);
    } 

    if (m_kFriendlySectoid == none) {
        m_kFriendlySectoid = CreateHelper(ePawnType_Sectoid);
        m_kFriendlySectoid.SetvisibleToTeams(0);
        InitializeHelper(m_kFriendlySectoid);
    }
    
    kPathPawn = kActiveUnit.GetPathingPawn();
    cursorLoc = kPathPawn.GetPathDestinationLimitedByCost();
    if (cursorLoc.X == 0 && cursorLoc.Y == 0 && cursorLoc.Z == 0) {

        // The path is invalid. Remove visibility
        RemoveAllVisibility();
    }
    else {
        // The path is valid. Move the helpers to the target location and test their visibility.
        MoveHelper(m_kFriendlyChryssalid, cursorLoc);
        MoveHelper(m_kFriendlySectoid, cursorLoc);

        InitializeHelper(m_kFriendlyChryssalid);
        InitializeHelper(m_kFriendlySectoid);

        if (kActiveUnit.CanUseCover()) {
            bAnyChange = ProcessVisibleUnits(m_kFriendlySectoid);
        } else {
            bAnyChange = ProcessVisibleUnits(m_kFriendlyChryssalid);
        }
    }

    // If we're using overwatch indication, set up the timer toggle to swap 
    // between red and blue for overwatching enemies.
    if (bAnyChange && SightIndicator == eIndicator_Overwatch) {
        ClearTimer('ToggleOverwatchIndicators');
        SetTimer(OVERWATCH_TOGGLE_DELAY, false, 'ToggleOverwatchIndicators');
    }
}

