#include "script_component.hpp"
/*
 * Author: PabstMirror
 * Applies a loadout to a vehicle
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Default loadout type <STRING>
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [cursorTarget] call potato_assignGear_fnc_assignGearVehicle;
 *
 * Public: Yes
 */

params ["_theVehicle", "_defaultLoadout"];
TRACE_2("assignGearVehicle",_theVehicle,_defaultLoadout);

private _typeOf = typeOf _theVehicle;
private _loadout = _theVehicle getVariable ["F_Gear", _typeOf];
private _faction = toLower faction _theVehicle;

TRACE_2("",GVAR(setVehicleLoadouts),_loadout);

//Leave default gear when "F_Gear" is "Default" or GVAR(setVehicleLoadouts) is 0
if ((GVAR(setVehicleLoadouts) == 0) || {_loadout == "Default"}) exitWith {
    if (GVAR(alwaysAddToolkits)) then { _theVehicle addItemCargoGlobal ["Toolkit", 1]; };
};

//Clean out starting inventory when "F_Gear" is "Empty" or GVAR(setVehicleLoadouts) is -1
if ((GVAR(setVehicleLoadouts) == -1) || {_loadout == "Empty"}) exitWith {
    clearWeaponCargoGlobal _theVehicle;
    clearMagazineCargoGlobal _theVehicle;
    clearItemCargoGlobal _theVehicle;
    clearBackpackCargoGlobal _theVehicle;
    //Add a Toolkit
    if (GVAR(alwaysAddToolkits)) then { _theVehicle addItemCargoGlobal ["Toolkit", 1]; };
};

private _vehConfigSide = [_theVehicle, true] call BIS_fnc_objectSide;
private _vehConfigFactions = switch (_vehConfigSide) do {
    case (west): { [_faction, "potato_w", "blu_f"] };
    case (east): { [_faction, "potato_e", "opf_f", "potato_msv"] }; // potato_msv is depcrecated but kept for BWC for now
    case (independent): { [_faction, "potato_i", "ind_f"] };
    default { [_faction, "civ_f"] };
};

private _path = configNull;
{
    private _break = false;
    private _loadoutToCheck = _x;

    {   
        private _faction = _x;
        private _factionPath = missionConfigFile >> "CfgLoadouts" >> _faction;
        private _staticLoadoutName = getText (_factionPath >> "using"); // refernce to a static potato loadout
        if (_staticLoadoutName != "") then {
            _factionPath = configFile >> "potato_loadouts" >> _faction >> _staticLoadoutName;
            if (!isClass _factionPath) then { ERROR_2("_faction %1 using bad _staticLoadoutName %2",_faction,_staticLoadoutName); };
        };
        _path = _factionPath >> _loadoutToCheck;
        if (isClass _path) exitWith { _break = true; };
    } forEach _vehConfigFactions;

    if (_break) exitWith {};
} forEach [_loadout, _defaultLoadout];

if (!isClass _path) exitWith {
    diag_log text format ["[POTATO-assignGear] - No loadout found for %1 (typeOf %2) (kindOf %3) (defaultLoadout: %4)", _theVehicle, typeof _theVehicle, _loadout, _defaultLoadout];
};

//Clean out starting inventory (even if there is no class)
clearWeaponCargoGlobal _theVehicle;
clearMagazineCargoGlobal _theVehicle;
clearItemCargoGlobal _theVehicle;
clearBackpackCargoGlobal _theVehicle;
//Add a Toolkit
if (GVAR(alwaysAddToolkits)) then { _theVehicle addItemCargoGlobal ["Toolkit", 1]; };

private _transportMagazines = getArray(_path >> "TransportMagazines");
private _transportItems = getArray(_path >> "TransportItems");
private _transportWeapons = getArray(_path >> "TransportWeapons");
private _transportBackpacks = getArray(_path >> "TransportBackpacks");

// transportMagazines
{
    (_x splitString ":") params ["_classname", ["_amount", "1", [""]]];
    _theVehicle addMagazineCargoGlobal [_classname, parseNumber _amount];
    nil
} count _transportMagazines; // count used here for speed, make sure nil is above this line

// transportItems
{
    (_x splitString ":") params ["_classname", ["_amount", "1", [""]]];
    _theVehicle addItemCargoGlobal [_classname, parseNumber _amount];
    nil
} count _transportItems; // count used here for speed, make sure nil is above this line

// transportWeapons
{
    (_x splitString ":") params ["_classname", ["_amount", "1", [""]]];
    _theVehicle addWeaponCargoGlobal [_classname, parseNumber _amount];
    nil
} count _transportWeapons; // count used here for speed, make sure nil is above this line

// transportBackpacks
{
    (_x splitString ":") params ["_classname", ["_amount", "1", [""]]];
    _theVehicle addBackpackCargoGlobal [_classname, parseNumber _amount];
    nil
} count _transportBackpacks; // count used here for speed, make sure nil is above this line
