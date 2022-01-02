class X2EventListener_TemplarShield extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_ListenerTemplate());

	return Templates;
}

/*
'AbilityActivated', AbilityState, SourceUnitState, NewGameState
'PlayerTurnBegun', PlayerState, PlayerState, NewGameState
'PlayerTurnEnded', PlayerState, PlayerState, NewGameState
'UnitDied', UnitState, UnitState, NewGameState
'KillMail', UnitState, Killer, NewGameState
'UnitTakeEffectDamage', UnitState, UnitState, NewGameState
'OnUnitBeginPlay', UnitState, UnitState, NewGameState
'OnTacticalBeginPlay', X2TacticalGameRuleset, none, NewGameState
*/

static function CHEventListenerTemplate Create_ListenerTemplate()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'X2EventListener_TemplarShield');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = false;

	Template.AddCHEvent('OverrideHitEffects', OnOverrideHitEffects, ELD_Immediate, 50);
	Template.AddCHEvent('OverrideMetaHitEffect', OnOverrideMetaHitEffect, ELD_Immediate, 50);
	Template.AddCHEvent('AbilityActivated', OnAbilityActivated, ELD_Immediate, 50);

	return Template;
}

static private function EventListenerReturn OnOverrideHitEffects(Object EventData, Object EventSource, XComGameState NullGameState, Name Event, Object CallbackData)
{
    local XComUnitPawn			Pawn;
    local XComLWTuple			Tuple;
    local XComGameState_Unit	TargetUnit;

    Pawn = XComUnitPawn(EventSource);
	if (Pawn == none)
		return ELR_NoInterrupt;

    Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;
			
	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Pawn.ObjectID));
	`LOG(GetFuncName() @ TargetUnit.GetFullName() @ TargetUnit.ObjectID,, 'IRITEST');

	if (TargetUnit != none && TargetUnit.IsUnitAffectedByEffectName('IRI_PsionicShield_Effect')) // TODO: This check fails if the effect was removed by the attack
	{
		`LOG(GetFuncName() @ "overriding hit effect hit result",, 'IRITEST');
		Tuple.Data[0].b = false;
		Tuple.Data[7].i = eHit_Reflect; // HitResult - Using eHit_Reflect to make hit effects spawn on the left hand.
	}

    return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideMetaHitEffect(Object EventData, Object EventSource, XComGameState NullGameState, Name Event, Object CallbackData)
{
    local XComUnitPawn			Pawn;
    local XComLWTuple			Tuple;
    local XComGameState_Unit	TargetUnit;

    Pawn = XComUnitPawn(EventSource);
	if (Pawn == none)
		return ELR_NoInterrupt;

    Tuple = XComLWTuple(EventData);
	if (Tuple == none)
		return ELR_NoInterrupt;
			
	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Pawn.ObjectID));
	`LOG(GetFuncName() @ TargetUnit.GetFullName() @ TargetUnit.ObjectID @ "HP:" @ TargetUnit.GetCurrentStat(eStat_HP) @ "Shield HP:" @ TargetUnit.GetCurrentStat(eStat_ShieldHP),, 'IRITEST');

	if (TargetUnit != none && TargetUnit.IsUnitAffectedByEffectName('IRI_PsionicShield_Effect')) // TODO: This check fails if the effect was removed by the attack
	{
		`LOG(GetFuncName() @ "overriding hit effect hit result",, 'IRITEST');
		Tuple.Data[0].b = false;		// Setting to *not* override the Hit Effect, so it can play as we want. 
		Tuple.Data[5].i = eHit_Reflect; // HitResult - Using eHit_Reflect to make hit effects spawn on the left hand.
	}

	// Previous game state has same stats.
	//TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetPreviousGameStateForObject(TargetUnit));
	//`LOG("Previous HP:" @ TargetUnit.GetCurrentStat(eStat_HP) @ "Shield HP:" @ TargetUnit.GetCurrentStat(eStat_ShieldHP),, 'IRITEST');

    return ELR_NoInterrupt;
}

static private function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameState_Unit			TargetUnit;
	local StateObjectReference			UnitRef;
	local XComGameStateHistory			History;

	if (NewGameState == none || NewGameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;
		
	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext == none)
		return ELR_NoInterrupt;

	// Insert a Post Build Vis delegate whenever an ability targets a unit affected by Templar Shield

	History = `XCOMHISTORY;

	TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit != none && TargetUnit.IsUnitAffectedByEffectName('IRI_PsionicShield_Effect'))
	{
		if (AbilityContext.PostBuildVisualizationFn.Find(ReplaceHitAnimation_PostBuildVis) == INDEX_NONE)
		{
			AbilityContext.PostBuildVisualizationFn.AddItem(ReplaceHitAnimation_PostBuildVis);
		}
	}
	else
	{
		foreach AbilityContext.InputContext.MultiTargets(UnitRef)
		{
			TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (TargetUnit != none && TargetUnit.IsUnitAffectedByEffectName('IRI_PsionicShield_Effect'))
			{
				if (AbilityContext.PostBuildVisualizationFn.Find(ReplaceHitAnimation_PostBuildVis) == INDEX_NONE)
				{
					AbilityContext.PostBuildVisualizationFn.AddItem(ReplaceHitAnimation_PostBuildVis);
				}
				break;
			}
		}
	}
		
	return ELR_NoInterrupt;
}

static private function ReplaceHitAnimation_PostBuildVis(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability	AbilityContext;
	local XComGameStateVisualizationMgr	VisMgr;
	local array<X2Action>				FindActions;
	local X2Action						FindAction;
	local X2Action						ChildAction;
	local VisualizationActionMetadata	ActionMetadata;
	local XComGameState_Unit								OldUnitState;
	local XComGameState_Unit								NewUnitState;
	local X2Action_ApplyWeaponDamageToUnit					DamageAction;
	local X2Action_ApplyWeaponDamageToUnit_TemplarShield	AdditionalAction;
	local X2Action_ApplyWeaponDamageToUnit_TemplarShield	ReplaceAction;
	local X2Action_MarkerNamed								EmptyAction;
	local X2Action											ParentAction;
	local X2Action											ParentParentAction;
	local array<X2Action>									ParentActions;
	local X2Action_PlayAnimation							ConsumeShieldAnim;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	VisMgr = `XCOMVISUALIZATIONMGR;

	// Replace Damage Unit actions that were created for all units affected by the Templar Shield effect.
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', FindActions);
	foreach FindActions(FindAction)
	{
		ActionMetadata = FindAction.Metadata;
		OldUnitState = XComGameState_Unit(FindAction.Metadata.StateObject_OldState);
		if (OldUnitState == none || !OldUnitState.IsUnitAffectedByEffectName('IRI_PsionicShield_Effect')) // TODO: This may need to be adjusted
			continue;

		// TODO: This may need to be adjusted depending on if grazes count as hit or miss
		`LOG("Graze is hit :" @ AbilityContext.IsHitResultHit(eHit_Graze),, 'IRITEST'); // true
		`LOG("Graze is miss:" @ AbilityContext.IsHitResultMiss(eHit_Graze),, 'IRITEST');// false
		
		// We don't care about misses
		if (!WasUnitHit(AbilityContext, OldUnitState.ObjectID))
			continue;		

		DamageAction = X2Action_ApplyWeaponDamageToUnit(FindAction);
		`LOG(GetFuncName() @ OldUnitState.GetFullName() @ XComGameState_Unit(ActionMetadata.StateObject_OldState).GetCurrentStat(eStat_ShieldHP) @ "->" @ XComGameState_Unit(ActionMetadata.StateObject_NewState).GetCurrentStat(eStat_ShieldHP),, 'IRITEST'); // 5 -> 1

		// #1. Insert an additional Damage Unit action. It will be responsible for playing the "unit shields themselves from the attack" animation.
		// This action needs to be parented not to the Fire Action, but to the parents of the Fire Action, so they can begin playing simultaneously,
		// so the starts reacting before getting hit with the first projectile.
		// This essentially mimics the base game visulization for Parry.

		// Gather parents of parents of the Damage Unit action.
		// The parent of the Damage Unit action should be the Fire Action,
		// so parent of the Fire Action should be Exit Cover action.
		ParentActions.Length = 0;
		foreach DamageAction.ParentActions(ParentAction)
		{
			foreach ParentAction.ParentActions(ParentParentAction)
			{
				ParentActions.AddItem(ParentParentAction);
			}
		}

		AdditionalAction = X2Action_ApplyWeaponDamageToUnit_TemplarShield(class'X2Action_ApplyWeaponDamageToUnit_TemplarShield'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, ParentActions));
		CopyActionProperties(AdditionalAction, DamageAction);
		AdditionalAction.bShowFlyovers = false;

		// Make child actions of the original Damage Unit action become children of the replacement action.
		foreach DamageAction.ChildActions(ChildAction)
		{
			VisMgr.ConnectAction(ChildAction, VisMgr.BuildVisTree, false, AdditionalAction);
		}

		// #2. Replace the original Damage Unit action that would have played "unit hit" animation,
		// but only if the shield fully absorbed all damage.
		NewUnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
		if (NewUnitState == none)
			continue;

		if (WasUnitFullyProtected(OldUnitState, NewUnitState))
		{
			// Since we now have a separate action for playing the "unit gets hit" animation, 
			// we replace the original Damage Unit action with a custom version that can be set to skip playing any animations.
			// We keep it in the tree so we still have a Damage Unit action as a child of the Fire Action so it can show the damage flyover when the unit gets hit.
			ReplaceAction = X2Action_ApplyWeaponDamageToUnit_TemplarShield(class'X2Action_ApplyWeaponDamageToUnit_TemplarShield'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, DamageAction.ParentActions));
			CopyActionProperties(ReplaceAction, DamageAction);
			ReplaceAction.bSkipAnimation = true;

			foreach DamageAction.ChildActions(ChildAction)
			{
				VisMgr.ConnectAction(ChildAction, VisMgr.BuildVisTree, false, ReplaceAction);
			}

			// Nuke the original action out of the tree.
			EmptyAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', DamageAction.StateChangeContext));
			EmptyAction.SetName("ReplaceDamageUnitAction");
			VisMgr.ReplaceNode(EmptyAction, DamageAction);
		}
		
		if (WasShieldFullyConsumed(OldUnitState, NewUnitState))
		{
			// If shield was fully depleted by the attack, play an additive animation with particle effects of the shield blowing up at the same time as the unit being hit.
			ConsumeShieldAnim = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, DamageAction.ParentActions));
			ConsumeShieldAnim.InputEventIDs = DamageAction.InputEventIDs;
			ConsumeShieldAnim.Params.AnimName = 'ADD_DestroyShield';
			ConsumeShieldAnim.Params.Additive = true;
		}
		
	}
}

// X2Action::Init() runs right before action starts playing, so we can't get this info from the action itself.
private static function bool WasUnitHit(const XComGameStateContext_Ability AbilityContext, const int ObjectID)
{
	local int Index;

	if (AbilityContext.InputContext.PrimaryTarget.ObjectID == ObjectID)
	{
		return AbilityContext.IsResultContextHit();
	}

	Index = AbilityContext.InputContext.MultiTargets.Find('ObjectID', ObjectID);
	if (Index != INDEX_NONE)
	{
		return AbilityContext.IsResultContextMultiHit(Index);
	}
	return false;
}

private static function CopyActionProperties(out X2Action_ApplyWeaponDamageToUnit_TemplarShield ReplaceAction, out X2Action_ApplyWeaponDamageToUnit DamageAction)
{
	ReplaceAction.AbilityTemplate = DamageAction.AbilityTemplate;
	ReplaceAction.DamageDealer = DamageAction.DamageDealer;
	ReplaceAction.SourceUnitState = DamageAction.SourceUnitState;
	ReplaceAction.m_iDamage = DamageAction.m_iDamage;
	ReplaceAction.m_iMitigated = DamageAction.m_iMitigated;
	ReplaceAction.m_iShielded = DamageAction.m_iShielded;
	ReplaceAction.m_iShredded = DamageAction.m_iShredded;
	ReplaceAction.DamageResults = DamageAction.DamageResults;
	ReplaceAction.HitResults = DamageAction.HitResults;
	ReplaceAction.DamageTypeName = DamageAction.DamageTypeName;
	ReplaceAction.m_vHitLocation = DamageAction.m_vHitLocation;
	ReplaceAction.m_vMomentum = DamageAction.m_vMomentum;
	ReplaceAction.bGoingToDeathOrKnockback = DamageAction.bGoingToDeathOrKnockback;
	ReplaceAction.bWasHit = DamageAction.bWasHit;
	ReplaceAction.bWasCounterAttack = DamageAction.bWasCounterAttack;
	ReplaceAction.bCounterAttackAnim = DamageAction.bCounterAttackAnim;
	ReplaceAction.AbilityContext = DamageAction.AbilityContext;
	ReplaceAction.AnimParams = DamageAction.AnimParams;
	ReplaceAction.HitResult = DamageAction.HitResult;
	ReplaceAction.TickContext = DamageAction.TickContext;
	ReplaceAction.AreaDamageContext = DamageAction.AreaDamageContext;
	ReplaceAction.FallingContext = DamageAction.FallingContext;
	ReplaceAction.WorldEffectsContext = DamageAction.WorldEffectsContext;
	ReplaceAction.TickIndex = DamageAction.TickIndex;
	ReplaceAction.PlayingSequence = DamageAction.PlayingSequence;
	ReplaceAction.OriginatingEffect = DamageAction.OriginatingEffect;
	ReplaceAction.AncestorEffect = DamageAction.AncestorEffect;
	ReplaceAction.bHiddenAction = DamageAction.bHiddenAction;
	ReplaceAction.CounterAttackTargetRef = DamageAction.CounterAttackTargetRef;
	ReplaceAction.bDoOverrideAnim = DamageAction.bDoOverrideAnim;
	ReplaceAction.OverrideOldUnitState = DamageAction.OverrideOldUnitState;
	ReplaceAction.OverridePersistentEffectTemplate = DamageAction.OverridePersistentEffectTemplate;
	ReplaceAction.OverrideAnimEffectString = DamageAction.OverrideAnimEffectString;
	ReplaceAction.bPlayDamageAnim = DamageAction.bPlayDamageAnim;
	ReplaceAction.bIsUnitRuptured = DamageAction.bIsUnitRuptured;
	ReplaceAction.bShouldContinueAnim = DamageAction.bShouldContinueAnim;
	ReplaceAction.bMoving = DamageAction.bMoving;
	ReplaceAction.bSkipWaitForAnim = DamageAction.bSkipWaitForAnim;
	ReplaceAction.RunningAction = DamageAction.RunningAction;
	ReplaceAction.HitReactDelayTimeToDeath = DamageAction.HitReactDelayTimeToDeath;
	ReplaceAction.UnitState = DamageAction.UnitState;
	ReplaceAction.GroupState = DamageAction.GroupState;
	ReplaceAction.ScanGroup = DamageAction.ScanGroup;
	ReplaceAction.ScanUnit = DamageAction.ScanUnit;
	ReplaceAction.kPerkContent = DamageAction.kPerkContent;
	ReplaceAction.TargetAdditiveAnims = DamageAction.TargetAdditiveAnims;
	ReplaceAction.bShowFlyovers = DamageAction.bShowFlyovers;
	ReplaceAction.bCombineFlyovers = DamageAction.bCombineFlyovers;
	ReplaceAction.EffectHitEffectsOverride = DamageAction.EffectHitEffectsOverride;
	ReplaceAction.CounterattackedAction = DamageAction.CounterattackedAction;
}

static final function bool WasUnitFullyProtected(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	return NewUnitState.GetCurrentStat(eStat_HP) >= OldUnitState.GetCurrentStat(eStat_HP);
}

static final function bool WasShieldFullyConsumed(const XComGameState_Unit OldUnitState, const XComGameState_Unit NewUnitState)
{
	return NewUnitState.GetCurrentStat(eStat_ShieldHP) <= 0;
}
