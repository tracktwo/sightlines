@echo off
mkdir %1

copy %~dp0\Patches\UIUnitFlag.OnInit.txt %1\Sightlines.txt || (
    echo Failed to copy UIUnitFlag.OnInit.txt
    exit /b 1
    )

type %~dp0\Patches\UIUnitFlag.RealizeEKG.txt >> %1\Sightlines.txt
type %~dp0\Patches\XGAIPlayer_Animal.OnUnitEndMove.txt >> %1\Sightlines.txt
type %~dp0\Patches\XComTacticalController.ParsePath.txt >> %1\Sightlines.txt
type %~dp0\Patches\UITacticalHUD_Radar.UpdateBlips.txt >> %1\Sightlines.txt

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

