@echo off
set UDK=D:\UDK\binaries\win32\udk
%UDK% Make
%UDK% CookPackages -platform=PC
copy D:\UDK\UDKGame\cookedPC\Sightlines.u X:\CookedPCConsole\Sightlines.u
