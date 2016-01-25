class SightlineMutator extends XComMutator;

var XGUnit kFriendlyDrone;
var vector vOldLocation;

function Mutate(String MutateString, PlayerController Sender)
{
    if (MutateString == "UpdateSightlines") {
        BuildSightlineMessage();
    }

    super.Mutate(MutateString, Sender);
}

function XGUnit SpawnAlien(EPawnType ePawn)
{
    local XGUnit kUnit;
    kUnit = XComTacticalCheatManager(GetALocalPlayerController().CheatManager).DropAlien(ePawn, false);
    return kUnit;
}

function ToggleOverwatchIndicators()
{
    local XGUnit kUnit;

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

    SetTimer(2.5, false, 'ToggleOverwatchIndicators');
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

    BuildSightlineMessage();
}

function BuildSightlineMessage()
{
    local XCom3DCursor kCursor;
    local Vector cursorLoc;
    local Vector2D vScreenLocation;
    local XComPlayerController controllerRef;
    local XComPresentationLayer pres;
    local XGUnit kActiveUnit;
    local XGUnit kEnemy;
    local int iVisible;
    local string msg;
    local string alienMsg;
    local array<XGUnit> arrEnemies;
    local XGUnit kFriendlyDrone;
    local int i;
    local bool found;
    local XGSquad kSquad;
    local XGUnit kUnit;
    local XComPathingPawn kPathPawn;
    local UnitDirectionInfo directionInfo;
    local array<XComInteractPoint> arrPoints;

    controllerRef = XComPlayerController(WorldInfo.GetALocalPlayerController());

    kActiveUnit = XComTacticalController(controllerRef).GetActiveUnit();
    if (kActiveUnit != none) {
        pres = XComPresentationLayer(controllerRef.m_Pres);
        //kCursor = XComTacticalController(controllerRef).GetCursor();
        //cursorLoc = kCursor.Location;
        //if (cursorLoc == vOldLocation) {
            //return;
        //}
        ClearTimer('ToggleOverwatchIndicators');
        //vOldLocation = cursorLoc;

        if (kFriendlyDrone == none) {
            foreach AllActors(class'XGUnit', kUnit) {
                if (kUnit.GetTeam() == eTeam_Neutral && kUnit.GetCharacter().m_eType == ePawnType_Sectoid) {
                    kFriendlyDrone = kUnit;
                    break;
                }
            }
        }

        if (kFriendlyDrone == none) {
            //kFriendlyDrone = SpawnAlien(ePawnType_Sectoid);
            kFriendlyDrone = XComTacticalCheatManager(GetALocalPlayerController().CheatManager).DropAlien(ePawnType_Sectoid, false);
            //kFriendlyDrone.SetVisible(false);
            //kFriendlyDrone.SetHiding(true);
            kSquad = kFriendlyDrone.GetSquad();
            XComTacticalGRI(class'Engine'.static.GetCurrentWorldInfo().GRI).m_kBattle.SwapTeams(kFriendlyDrone, false, eTeam_Neutral);
            kFriendlyDrone.SetvisibleToTeams(0);
       } 
       //
        
        kFriendlyDrone.GetPawn().SetCollision(false, false, false);
        kFriendlyDrone.GetPawn().bCollideWorld = false;
        kFriendlyDrone.GetPawn().SetPhysics(0);

        // Reset all units
        foreach AllActors(class'XGUnit', kEnemy) {
            if (kEnemy.GetTeam() != eTeam_Alien) {
                continue;
            }

            if ((kEnemy.m_iZombieMoraleLoss & 0x60000000) != 0) {
                kEnemy.m_iZombieMoraleLoss = kEnemy.m_iZombieMoraleLoss & ~0x60000000; 
            }
        }

        kPathPawn = kActiveUnit.GetPathingPawn();
        cursorLoc = kPathPawn.GetPathDestinationLimitedByCost();
        if (cursorLoc.X == 0 && cursorLoc.Y == 0 && cursorLoc.Z == 0) {
            cursorLoc = kActiveUnit.Location;
        }


        kFriendlyDrone.GetPawn().SetLocation(cursorLoc);
        kFriendlyDrone.ProcessNewPosition(false);

        /*
        kFriendlyDrone.SetVisible(false);
        kFriendlyDrone.SetHiding(true);
        kFriendlyDrone.SetHidden(true);
        kFriendlyDrone.GetPawn().SetHidden(true);
        kFriendlyDrone.GetPawn().HideMainPawnMesh();
        kFriendlyDrone.GetPawn().Weapon.Mesh.SetHidden(true);
        */
        //kActiveUnit.m_kPlayerNativeBase.m_kSightMgrBase.RecalculateVisible();
        //class'XComWorldData'.static.GetWorldData().UpdateVisibility();
        class'XComWorldData'.static.GetWorldData().ClearTileBlockedByUnitFlag(kFriendlyDrone);
        arrEnemies = kFriendlyDrone.GetVisibleEnemies();


        //if (cursorLoc == kActiveUnit.Location) {
        //    return;
       // }

        // Set visible aliens as visible
        foreach arrEnemies (kEnemy) {
            //if (kActiveUnit.CanSee(kEnemy)) {
                //`Log("Building icon for " $ string(kEnemy));
                //XComPresentationLayer(XComPlayerController(WorldInfo.GetALocalPlayerController()).m_Pres).GetWorldMessenger().Message((("<img src='" $ "Icon_OVERWATCH_HTML") $ "' align='baseline' vspace='-3'>") $ " - !!!", kEnemy.GetLocation(), 0, 1, "cursorHelp_SightlineMod");
                alienMsg $= ConstructAlienMessage(kEnemy);
                ++iVisible;
                kEnemy.m_iZombieMoraleLoss = kEnemy.m_iZombieMoraleLoss | 0x40000000;
            //}
        }

        SetTimer(2.5, false, 'ToggleOverwatchIndicators');

        XComPresentationLayer(XComPlayerController(WorldInfo.GetALocalPlayerController()).m_Pres).m_kUnitFlagManager.Update();

        // TODO Squadsight
        //if (iVisible > 0) {
            pres.isOnScreen(cursorLoc, vScreenLocation);
            msg = "Enemies in sight (" $ iVisible $ "): " $ alienMsg; //$ " S pos: " $ string(kFriendlyDrone.Location) $ " U pos: " $ string(kActiveUnit.Location);
            pres.GetWorldMessenger().Message(msg, cursorLoc, 0, 1, "cursorHelp_SightlinesMod",, true, vScreenLocation, 0.0);
        //} else {
            //pres.GetWorldMessenger().RemoveMessage("cursorHelp_SightlinesMod");
        //} 

        //kFriendlyDrone.GetPawn().SetLocation(kActiveUnit.Location);
        //kFriendlyDrone.ProcessNewPosition(false);
        //class'XComWorldData'.static.GetWorldData().UpdateVisibility();

/*
        kSquad.RemoveUnit(kFriendlyDrone);
        for (i = 0; i < kSquad.m_iNumPermanentUnits; ++i) {
            if (kSquad.m_arrPermanentMembers[i] == kFriendlyDrone) {
                found = true;
            } 

            if (found && i < (kSquad.m_iNumPermanentUnits -1)) {
                kSquad.m_arrPermanentMembers[i] = kSquad.m_arrPermanentMembers[i+1];
            } else {
                if (found) {
                    kSquad.m_arrPermanentMembers[i] = none;
                }
            }
        }
        kSquad.m_iNumPermanentUnits--;
        kFriendlyDrone.Uninit();
        kFriendlyDrone.Destroy();
        */
    }        
}

function String ConstructAlienMessage(XGUnit kEnemy)
{
    switch(kEnemy.GetCharType()) {
    case eChar_Sectoid: return "s";
    case eChar_Floater: return "f";
    case eChar_Thinman: return "t";
    case eChar_Muton: return "m";
    case eChar_Cyberdisc: return "C";
    case eChar_SectoidCommander: return "S";
    case eChar_FloaterHeavy: return "F";
    case eChar_MutonElite: return "e";
    case eChar_Ethereal: return "E";
    case eChar_Chryssalid: return "c";
    case eChar_Zombie: return "z";
    case eChar_MutonBerserker: return "B";
    case eChar_Sectopod: return "P";
    case eChar_Drone: return "d";
    case eChar_Outsider: return "o";
    case eChar_EtherealUber: return "E";
    case eChar_Mechtoid: return "M";
    case eChar_Mechtoid_Alt: return "M";
    case eChar_Seeker: return "k";
    case eChar_ExaltOperative: return "x";
    case eChar_ExaltSniper: return "n";
    case eChar_ExaltHeavy: return "h";
    case eChar_ExaltMedic: return "i";
    case eChar_ExaltEliteOperative: return "X";
    case eChar_ExaltEliteSniper: return "N";
    case eChar_ExaltEliteHeavy: return "H";
    case eChar_ExaltEliteMedic: return "I";
    default: 
        `Log("ConstructAlienMessage: unknown type " $ kEnemy.GetCharType());
        return "?";
    }
}
