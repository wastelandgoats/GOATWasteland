/* ===============================================================================================================
  Simple Vehicle Respawn Script v1.82 for Arma 3
  by Tophe of Östgöta Ops [OOPS]
  Updated by SPJESTER & modded by AgentRev
  
  vehicle.sqf is an example of the name of the file, name it whatever you would like
  
  Put this in the vehicles init line:
  veh = [this] execVM "vehicle.sqf"
  _______
  Options
  ¯¯¯¯¯¯¯
  There are some optional settings. The format for these are:
  veh = [object, Delay, Deserted timer, Respawns, Effect, Dynamic, Init commands] execVM "vehicle.sqf"
  
  Delay: Default respawn delay is 30 seconds, to set a custom respawn delay time, put that in the init as well. 

  Deserted timer: Default respawn time when vehicle is deserted, but not destroyed is 120 seconds. To set a custom timer for this 
                  first set respawn delay, then the deserted vehicle timer. (0 = disabled) 
  
  Respawns: By default the number of respawns is infinite. To set a limit first set preceding values then the number of respawns you want (0 = infinite).

  Effect: Set this value to TRUE to add a special explosion effect to the wreck when respawning.
          Default value is FALSE, which will simply have the wreck disappear.
  
  Static: By default the vehicle will respawn at the position where it was destroyed (dynamic).
          This can be changed to static. Then the vehicle will respawn at the specified position (static).
          First set all preceding values then set a respawn position for static, or FALSE for dynamic.
  
  Example with all parameters:
  veh = [this, 15, 10, 5, TRUE, getPosASL this] execVM "vehicle.sqf"
  
  Default values of all settings are:
  veh = [this, 30, 120, 0, FALSE, FALSE] execVM "vehicle.sqf"
  
	
Contact & Bugreport: cwadensten@gmail.com
Ported for new update "call compile" by SPJESTER: mhowell34@gmail.com
Converted to server-side, junk removed, and modded for 404 Wasteland by AgentRev: agentrevo@gmail.com

NOTE: Some parameters have changed since the previous release, especially static/dynamic respawning, and removal of init commands.
	  Please ajust your vehicle spawn scripts accordingly if you plan to use this respawn scripts as-is.
================================================================================================================== */
  
if (!isServer) exitWith {};

// Define variables
_unit = _this select 0;
_delay = if (count _this > 1) then {_this select 1} else {30};
_deserted = if (count _this > 2) then {_this select 2} else {120};
_respawns = if (count _this > 3) then {_this select 3} else {0};
_explode = if (count _this > 4) then {_this select 4} else {false};
_static = if (count _this > 5) then {_this select 5} else {false};

_run = true;

if (_delay < 0) then {_delay = 0};
if (_deserted < 0) then {_deserted = 0};

sleep 1;

_dir = getDir _unit;
_position = getPosASL _unit;
_type = typeOf _unit;
_dead = false;
_nodelay = false;
				
// Start monitoring the vehicle
while {_run} do 
{	
	sleep 10;
	
    if (getDammage _unit > 0.8 && {alive _unit} count crew _unit == 0) then {
		_dead = true;
	};
	
	// Check if the vehicle is deserted.
	if (_deserted > 0) then
	{
		if (getPosASL _unit distance _position > 10 && {alive _unit} count crew _unit == 0) then 
		{
			diag_log format ["Crew: %1", {alive _unit} count crew _unit];
			
			_timeout = time + _deserted;
			sleep 0.1;
			
			while { _timeout > time && alive _unit && {alive _unit} count crew _unit == 0 } do
			{
				sleep 5;
				
				// R3F HELL YEA
				if (!isNull (_unit getVariable ["R3F_LOG_est_transporte_par", objNull]) || {!isNull (_unit getVariable ["R3F_LOG_est_deplace_par", objNull])}) then
				{
					_timeout = time + _deserted;
				};
			};
			
			if ({alive _unit} count crew _unit > 0) then
			{
				_dead = false;
			}
			else
			{
				_dead = true;
				if (alive _unit) then { _nodelay = true } else { _nodelay = false };
			};
		};
	};
	
	// Respawn vehicle
    if (_dead) then 
	{
		// Clean-up if vehicle is towing via R3F
		
		_towedUnit = _unit getVariable ["R3F_LOG_remorque", objNull];
		
		if (!isNull _towedUnit) then
		{
			detach _towedUnit;
			_towedUnit setVariable ["R3F_LOG_est_transporte_par", objNull, true];
			_unit setVariable ["R3F_LOG_remorque", objNull, true];
			
			_pos = getPosATL _towedUnit;
			
			if (_pos select 2 < 1) then {
				_towedUnit setPosATL [_pos select 0, _pos select 1, 1];
			};
			_towedUnit setVelocity [0,0,0];
		};
		
		if (_nodelay) then {sleep 0.1; _nodelay = false;} else {sleep _delay;};
		
		if (typename _static == "ARRAY") then { _position = _static; }
		else { _position = getPosASL _unit; _dir = getDir _unit; };
		
		if (_explode) then {_effect = "M_AT" createVehicle getPosASL _unit; _effect setPosASL getPosASL _unit;};
		
		sleep 0.1;
		_carType = typeOf _unit;
		deleteVehicle _unit;
		sleep 0.1;
		
		// 404 Wasteland vehicle spawn script
		[_position, _carType] call vehicleCreation;
		
		sleep 0.1;		
		_run = false;
	};
};
