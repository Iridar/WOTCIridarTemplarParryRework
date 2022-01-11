class X2Effect_TemplarShield extends X2Effect_EnergyShield;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		m_aStatChanges.Length = 0;
		AddPersistentStatChange(eStat_ShieldHP, GetShieldStrength(UnitState, NewGameState));
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

private function OnShieldRemoved_BuildVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayAnimation		PlayAnimation;
	local XGUnit						Unit;
	local XComUnitPawn					UnitPawn;

	// Exit if the effect did not expire naturally.
	// We don't want the animation to play here if the effect was removed by damage, visualization for that is handled elsewhere.
	if (XComGameStateContext_TickEffect(VisualizeGameState.GetContext()) == none)
		return;

	Unit = XGUnit(ActionMetadata.VisualizeActor);
	if (Unit != none && Unit.IsAlive())
	{
		UnitPawn = Unit.GetPawn();
		if (UnitPawn != none && UnitPawn.GetAnimTreeController().CanPlayAnimation('HL_Shield_Fold'))
		{
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			PlayAnimation.Params.AnimName = 'HL_Shield_Fold';
			PlayAnimation.Params.BlendTime = 0.3f;
		}
	}
}

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

static final function int GetShieldStrength(const XComGameState_Unit UnitState, XComGameState CheckGameState)
{
	local XComGameState_Item	ItemState;
	local X2WeaponTemplate		WeaponTemplate;
	local int					Index;

	ItemState = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState);
	if (ItemState == none)
		return 0;

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	if (WeaponTemplate == none)
		return 0;

	Index = WeaponTemplate.ExtraDamage.Find('Tag', 'TemplarShield');
	if (Index == INDEX_NONE)
		return 0;

	return WeaponTemplate.ExtraDamage[Index].Damage;
}

defaultproperties
{
	EffectName = "IRI_TemplarShield_Effect"
	EffectRemovedVisualizationFn = OnShieldRemoved_BuildVisualization
}