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
	local XComGameState_Unit								UnitState;
	local X2Action_ApplyWeaponDamageToUnit					DamageAction;
	local X2Action_ApplyWeaponDamageToUnit_TemplarShield	ReplaceAction;
	local X2Action_MarkerNamed								EmptyAction;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	VisMgr = `XCOMVISUALIZATIONMGR;

	// Replace Damage Unit actions that were created for all units affected by the Templar Shield effect.
	// The replacement action is largely the same, but it plays different animations depending on incoming damage.
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', FindActions);
	foreach FindActions(FindAction)
	{
		ActionMetadata = FindAction.Metadata;
		UnitState = XComGameState_Unit(FindAction.Metadata.StateObject_OldState);
		if (UnitState == none || !UnitState.IsUnitAffectedByEffectName('IRI_PsionicShield_Effect'))
			continue;

		DamageAction = X2Action_ApplyWeaponDamageToUnit(FindAction);
		ReplaceAction = X2Action_ApplyWeaponDamageToUnit_TemplarShield(class'X2Action_ApplyWeaponDamageToUnit_TemplarShield'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, DamageAction.ParentActions));//auto-parent to damage initiating action

		// Copy all of the action's properties
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

		// Make child actions of the original Damage Unit action become children of the replacement action.
		foreach DamageAction.ChildActions(ChildAction)
		{
			VisMgr.ConnectAction(ChildAction, VisMgr.BuildVisTree, false, ReplaceAction);
		}

		// Kill the original Damage Unit action.
		EmptyAction = X2Action_MarkerNamed(class'X2Action'.static.CreateVisualizationActionClass(class'X2Action_MarkerNamed', DamageAction.StateChangeContext));
		EmptyAction.SetName("ReplaceUnitAction");
		VisMgr.ReplaceNode(EmptyAction, DamageAction);
	}
}