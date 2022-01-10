class X2TemplarShield extends Object abstract;

var privatewrite name ShieldEffectName;

static final function bool WasUnitFullyProtected(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	//`LOG(GetFuncName() @ OldUnitState.GetFullName(),, 'TemplarParryRework');
	//`LOG("Old HP:" @ OldUnitState.GetCurrentStat(eStat_HP),, 'TemplarParryRework');
	//`LOG("New HP:" @ NewUnitState.GetCurrentStat(eStat_HP),, 'TemplarParryRework');
	//`LOG("Unit fully protected:" @ NewUnitState.GetCurrentStat(eStat_HP) >= OldUnitState.GetCurrentStat(eStat_HP),, 'TemplarParryRework');

	// Bleeding out check is required, because if the unit had 1 HP before the attack that made them start bleeding out, they will still have 1 HP while bleeding out.
	return NewUnitState.GetCurrentStat(eStat_HP) >= OldUnitState.GetCurrentStat(eStat_HP) && !NewUnitState.IsBleedingOut();
}

static final function bool WasShieldFullyConsumed(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	//`LOG(GetFuncName() @ OldUnitState.GetFullName(),, 'TemplarParryRework');
	//`LOG("Old shield HP:" @ OldUnitState.GetCurrentStat(eStat_ShieldHP),, 'TemplarParryRework');
	//`LOG("New shield HP:" @ NewUnitState.GetCurrentStat(eStat_ShieldHP),, 'TemplarParryRework');
	//`LOG("Shield fully consumed:" @ NewUnitState.GetCurrentStat(eStat_ShieldHP) <= 0,, 'TemplarParryRework');

	// Hacky, doesn't take into account Shield HP from other sources.
	return NewUnitState.GetCurrentStat(eStat_ShieldHP) <= 0;
}

defaultproperties
{
	ShieldEffectName = "IRI_TemplarShield_Effect"
}