@echo off
mkdir %1

copy %~dp0\Patches\UIUnitFlag.OnInit.txt %1\Sightlines_EW.txt || (
    echo Failed to copy UIUnitFlag.OnInit.txt
    exit /b 1
    )

type %~dp0\Patches\UIUnitFlag.RealizeEKG.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XGAIPlayer_Animal.OnUnitEndMove.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XGUnit.UpdateInteractClaim.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XGUnit.ShowMouseOverDisc.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XGUnit.OnEnterPoison.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\UIUnitFlag.Update.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XComTacticalHUD.GetMousePickActor.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XGUnit.OnUpdatedVisibility.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XGUnitNativeBase.SetBETemplate.txt >> %1\Sightlines_EW.txt
type %~dp0\Patches\XComTacticalCheatManager.marketing.txt >> %1\Sightlines_EW.txt

copy %1\Sightlines_EW.txt %1\Sightlines_LW.txt

type %~dp0\Patches\XComTacticalController.ParsePath_LW.txt >> %1\Sightlines_LW.txt
type %~dp0\Patches\XComTacticalController.ParsePath_EW.txt >> %1\Sightlines_EW.txt

type %~dp0\Patches\UITacticalHUD_Radar.UpdateBlips.txt >> %1\Sightlines_LW.txt

copy D:\XCom-Mutators\UPK-Patches\XComMutatorEnabler.txt %1\XComMutatorEnabler.txt
copy D:\XCom-Mutators\LICENSE %1\LICENSE-Mutators.txt

copy %~dp0\config\DefaultMutatorLoader.ini %1\DefaultMutatorLoader.ini

copy %~dp0\README.md %1\README.md || (
    echo "Failed to copy README.md
    exit /b 1
    )

copy %~dp0\CHANGELOG.txt %1 || (
    echo Failed to copy CHANGELOG.txt
    exit /b 1
    )

copy D:\UDK\UDKGame\CookedPC\Sightlines.u %1 || (
    echo Failed to copy Sightlines.u
    exit /b 1
    )

copy D:\UDK\UDKGame\CookedPC\XcomMutator.u %1 || (
    echo Failed to copy XComMutator.u
    exit /b 1
    )

copy %~dp0\config\DefaultSightlines.ini %1\DefaultSightlines.ini || (
    echo Failed to copy DefaultSightlines.ini
    exit /b 1
    )

