class SightlineMutator extends XComMutator config(GameCore);

var XGUnit m_kFriendlySquid;
var XGUnit m_kFriendlySectoid;
var vector m_vOldLocation;
var float m_fTimeInOldLocation;
var float m_fTimeSinceLastTick;

// How much time to wait between toggling the blue/red overwatch icon
var config float OVERWATCH_TOGGLE_DELAY; 

/*
// How much time to wait between ticks before processing LoS
var config float SIGHTLINE_TICK_DELAY;
*/

function Mutate(String MutateString, PlayerController Sender)
{
    super.Mutate(MutateString, Sender);
}

function ToggleOverwatchIndicators()
{
    local XGUnit kUnit;
    `Log("Timer fired");
    foreach AllActors(class 'XGUnit', kUnit) {
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

simulated event Tick(float fDeltaTime)
{
    local XGUnit kActiveUnit;
    local XComPlayerController kController;
    kController = XComPlayerController(WorldInfo.GetALocalPlayerController());
    kActiveUnit = XComTacticalController(kController).GetActiveUnit();

    if (kActiveUnit == none || kActiveUnit.GetTeam() != eTeam_XCom || kActiveUnit.IsPerformingAction()) {
        return;
    }
/*
    m_fTimeSinceLastTick += fDeltaTime;
    if (m_fTimeSinceLastTick < SIGHTLINE_TICK_DELAY) {
        return;
    }

    m_fTimeSinceLastTick = 0.0;
*/
    `Log("Delta = " $ fDeltaTime);
    ProcessSightline(fDeltaTime);
}

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

function ProcessVisibleUnits(XGUnit kHelper)
{
    local array<XGUnit> arrEnemies;
    local XGUnit kEnemy;

    // Gather up all the enemies the helper can see
    arrEnemies = kHelper.GetVisibleEnemies();

    // Reset all units in the game to not visible.
    foreach AllActors(class'XGUnit', kEnemy) {
        if (kEnemy.GetTeam() != eTeam_Alien) {
            continue;
        }

        if ((kEnemy.m_iZombieMoraleLoss & 0x60000000) != 0) {
            kEnemy.m_iZombieMoraleLoss = kEnemy.m_iZombieMoraleLoss & ~0x60000000; 
        }
    }

    // Mark each alien the helper can see as visible
    foreach arrEnemies (kEnemy) {
        kEnemy.m_iZombieMoraleLoss = kEnemy.m_iZombieMoraleLoss | 0x40000000;
    }
}

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

    controllerRef = XComPlayerController(WorldInfo.GetALocalPlayerController());

    kActiveUnit = XComTacticalController(controllerRef).GetActiveUnit();

    if (m_kFriendlySquid == none) {
        foreach AllActors(class'XGUnit', kUnit) {
            if (kUnit.GetTeam() == eTeam_Neutral && kUnit.GetCharacter().m_eType == ePawnType_Seeker) {
                m_kFriendlySquid = kUnit;
                InitializeHelper(m_kFriendlySquid);
                break;
            }

            if (kUnit.GetTeam() == eTeam_Neutral && kUnit.GetCharacter().m_eType == ePawnType_Sectoid) {
                m_kFriendlySectoid = kUnit; 
                InitializeHelper(m_kFriendlySectoid);
                break;
            }
        }
    }

    if (m_kFriendlySquid == none) {
//        m_kFriendlySquid = XComTacticalCheatManager(GetALocalPlayerController().CheatManager).DropAlien(ePawnType_Seeker, true);
 //       XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.SwapTeams(m_kFriendlySquid, false, eTeam_Neutral);
        m_kFriendlySquid = CreateHelper(ePawnType_Seeker);
        m_kFriendlySquid.SetvisibleToTeams(0);
        InitializeHelper(m_kFriendlySquid);
    } 

    if (m_kFriendlySectoid == none) {
        //m_kFriendlySectoid = XComTacticalCheatManager(GetALocalPlayerController().CheatManager).DropAlien(ePawnType_Sectoid, true);
        //XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.SwapTeams(m_kFriendlySectoid, false, eTeam_Neutral);
        m_kFriendlySectoid = CreateHelper(ePawnType_Sectoid);
        m_kFriendlySectoid.SetvisibleToTeams(0);
        InitializeHelper(m_kFriendlySectoid);
    }
    
    kPathPawn = kActiveUnit.GetPathingPawn();
    cursorLoc = kPathPawn.GetPathDestinationLimitedByCost();
    if (cursorLoc.X == 0 && cursorLoc.Y == 0 && cursorLoc.Z == 0) {
        cursorLoc = kActiveUnit.Location;
    }


    m_fTimeInOldLocation += fDeltaTime;
    // If the cursor hasn't moved, just return without refreshing the LoS indicators.
    // This lets the overwatch timer toggle things correctly.
    if (cursorLoc == m_vOldLocation && m_fTimeInOldLocation > 0.2) {
        return;
    }

    // Cursor has moved: cache the new position and proceed.
    m_vOldLocation = cursorLoc;

    if (m_fTimeInOldLocation > 0.2) {
        m_fTimeInOldLocation = 0.0;
        // Reset the old timer.
        ClearTimer('ToggleOverwatchIndicators');
        SetTimer(OVERWATCH_TOGGLE_DELAY, false, 'ToggleOverwatchIndicators');
        `Log("Cleared timer");
    }


    // Set the helper to the new path position. 
    MoveHelper(m_kFriendlySquid, cursorLoc);
    MoveHelper(m_kFriendlySectoid, cursorLoc);

    InitializeHelper(m_kFriendlySquid);
    InitializeHelper(m_kFriendlySectoid);

    if (kActiveUnit.CanUseCover()) {
        ProcessVisibleUnits(m_kFriendlySectoid);
    } else {
        ProcessVisibleUnits(m_kFriendlySquid);
    }

//    XComPresentationLayer(XComPlayerController(WorldInfo.GetALocalPlayerController()).m_Pres).m_kUnitFlagManager.Update();
}

