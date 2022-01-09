class X2TemplarShield extends Object abstract;

var privatewrite name ShieldEffectName;

static final function bool WasUnitFullyProtected(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	`LOG(GetFuncName() @ OldUnitState.GetFullName(),, 'IRITEST');
	`LOG("Old HP:" @ OldUnitState.GetCurrentStat(eStat_HP),, 'IRITEST');
	`LOG("New HP:" @ NewUnitState.GetCurrentStat(eStat_HP),, 'IRITEST');
	`LOG("Unit fully protected:" @ NewUnitState.GetCurrentStat(eStat_HP) >= OldUnitState.GetCurrentStat(eStat_HP),, 'IRITEST');
	return NewUnitState.GetCurrentStat(eStat_HP) >= OldUnitState.GetCurrentStat(eStat_HP);
}

static final function bool WasShieldFullyConsumed(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	`LOG(GetFuncName() @ OldUnitState.GetFullName(),, 'IRITEST');
	`LOG("Old shield HP:" @ OldUnitState.GetCurrentStat(eStat_ShieldHP),, 'IRITEST');
	`LOG("New shield HP:" @ NewUnitState.GetCurrentStat(eStat_ShieldHP),, 'IRITEST');
	`LOG("Shield fully consumed:" @ NewUnitState.GetCurrentStat(eStat_ShieldHP) <= 0,, 'IRITEST');
	return NewUnitState.GetCurrentStat(eStat_ShieldHP) <= 0;
}

defaultproperties
{
	ShieldEffectName = "IRI_PsionicShield_Effect"
}