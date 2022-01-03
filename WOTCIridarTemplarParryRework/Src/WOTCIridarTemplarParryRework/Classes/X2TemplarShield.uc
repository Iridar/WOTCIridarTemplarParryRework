class X2TemplarShield extends Object abstract;

var privatewrite name ShieldEffectName;

static final function bool WasUnitFullyProtected(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	return NewUnitState.GetCurrentStat(eStat_HP) >= OldUnitState.GetCurrentStat(eStat_HP);
}

static final function bool WasShieldFullyConsumed(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	return NewUnitState.GetCurrentStat(eStat_ShieldHP) <= 0;
}

defaultproperties
{
	ShieldEffectName = "IRI_PsionicShield_Effect"
}