#include "script_component.hpp"
TRACE_1("params",_this);

params ["_unit"];

[_unit getVariable [VQGVAR(disabledUnit),false], isPlayer _unit];
