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
    local XComUnitPawn				Pawn;
    local XComLWTuple				Tuple;
	local XComAnimTreeController	AnimTreeController;

    Pawn = XComUnitPawn(EventSource);
	if (Pawn == none)
		return ELR_NoInterrupt;

	AnimTreeController = Pawn.GetAnimTreeController();
	if (AnimTreeController == none)
		return ELR_NoInterrupt;

	if (AnimTreeController.IsPlayingCurrentAnimation('HL_Shield_Absorb') ||
		AnimTreeController.IsPlayingCurrentAnimation('HL_Shield_AbsorbAndFold'))
	{
		Tuple = XComLWTuple(EventData);
		if (Tuple == none)
			return ELR_NoInterrupt;

		`LOG(GetFuncName() @ "overriding hit effect hit result",, 'IRITEST');
		Tuple.Data[0].b = false;
		Tuple.Data[7].i = eHit_Reflect; // HitResult - Using eHit_Reflect to make hit effects spawn on the left hand.
	}

    return ELR_NoInterrupt;
}

static private function EventListenerReturn OnOverrideMetaHitEffect(Object EventData, Object EventSource, XComGameState NullGameState, Name Event, Object CallbackData)
{
    local XComUnitPawn				Pawn;
    local XComLWTuple				Tuple;
	local XComAnimTreeController	AnimTreeController;

    Pawn = XComUnitPawn(EventSource);
	if (Pawn == none)
		return ELR_NoInterrupt;

	AnimTreeController = Pawn.GetAnimTreeController();
	if (AnimTreeController == none)
		return ELR_NoInterrupt;

	if (AnimTreeController.IsPlayingCurrentAnimation('HL_Shield_Absorb') ||
		AnimTreeController.IsPlayingCurrentAnimation('HL_Shield_AbsorbAndFold'))
	{
		Tuple = XComLWTuple(EventData);
		if (Tuple == none)
			return ELR_NoInterrupt;

		`LOG(GetFuncName() @ "overriding hit effect hit result",, 'IRITEST');
		Tuple.Data[0].b = false;		// Setting to *not* override the Hit Effect, so it can play as we want. 
		Tuple.Data[5].i = eHit_Reflect; // HitResult - Using eHit_Reflect to make hit effects spawn on the left hand.
	}

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
	if (TargetUnit != none && TargetUnit.IsUnitAffectedByEffectName(class'X2TemplarShield'.default.ShieldEffectName))
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
			if (TargetUnit != none && TargetUnit.IsUnitAffectedByEffectName(class'X2TemplarShield'.default.ShieldEffectName))
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


// This function alters the visualization tree for units affected by the Templar Shield effect when they are attacked.
static private function ReplaceHitAnimation_PostBuildVis(XComGameState VisualizeGameState)
{
	local XComGameStateContext_Ability						AbilityContext;
	local XComGameStateVisualizationMgr						VisMgr;
	local array<X2Action>									FindActions;
	local X2Action											FindAction;
	local X2Action											ChildAction;
	local VisualizationActionMetadata						ActionMetadata;
	local XComGameState_Unit								OldUnitState;
	local XComGameState_Unit								NewUnitState;
	local X2Action_ApplyWeaponDamageToUnit					DamageAction;
	local X2Action_PlayAnimation							AdditionalAnimationAction;
	local X2Action_ApplyWeaponDamageToUnit_TemplarShield	ReplaceAction;
	local X2Action_MarkerNamed								EmptyAction;
	local X2Action											ParentAction;
	local array<X2Action>									ExitCoverActions;
	local array<X2Action>									ExitCoverParentActions;
	local array<X2Action>									FireActions;
	local X2Action_PlayAnimation							PlayAnimation;
	local name												InputEvent;
	local X2Action_MoveTurn									MoveTurnAction;
	local XComGameState_Unit								SourceUnit;
	local XComGameState_Ability								AbilityState;
	local array<int>										HandledUnits;
	local X2AbilityTemplate									AbilityTemplate;
	local XComGameStateHistory								History;
	local X2Action											CycleAction;
	local X2Action_TimedWait								TimedWait;
	local bool												bGrenadeLikeAbility;
	local bool												bAreaTargetedAbility;
	local X2Action_WaitForAnotherAction						WaitForAction;
	local array<X2Action>									WaitForActions;
	local array<X2Action>									DamageUnitActions;

	AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
	if (AbilityContext == none)
		return;

	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
	if (AbilityState == none)
		return;

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none)
		return;

	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (SourceUnit == none)
		return;

	if (AbilityContext.InputContext.TargetLocations.Length > 0 && ClassIsChildOf(AbilityTemplate.TargetingMethod, class'X2TargetingMethod_Grenade'))
	{
		bAreaTargetedAbility = true;
		bGrenadeLikeAbility = AbilityTemplate.TargetingMethod.static.UseGrenadePath();	
	}
	
	// Cycle through all Damage Unit actions created by the ability. If the ability affected multiple units, all of them will be covered this way.
	// This is a bit noodly. Rather than cycling through units present in this game state, or getting them from the game state by their ObjectID recorded in Context,
	// we iterate over Damage Unit actions directly, since ultimately this is what we need to interact with.
	VisMgr = `XCOMVISUALIZATIONMGR;
	VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', FindActions);
	foreach FindActions(FindAction)
	{
		ActionMetadata = FindAction.Metadata;
		OldUnitState = XComGameState_Unit(FindAction.Metadata.StateObject_OldState); // Unit State as it was before they were hit by the attack.
		NewUnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
		if (OldUnitState == none || NewUnitState == none || HandledUnits.Find(OldUnitState.ObjectID) != INDEX_NONE)
			continue;

		`LOG(GetFuncName() @ OldUnitState.GetFullName(),, 'IRITEST');
		`LOG("HP + Shield:" @ OldUnitState.GetCurrentStat(eStat_HP) @ " + " @ OldUnitState.GetCurrentStat(eStat_ShieldHP) @ "->" @ NewUnitState.GetCurrentStat(eStat_HP) @ " + " @ NewUnitState.GetCurrentStat(eStat_ShieldHP),, 'IRITEST');
		HandledUnits.AddItem(OldUnitState.ObjectID); // Use a tracking array to make sure each unit's visualization is adjusted only once.

		if (!OldUnitState.IsUnitAffectedByEffectName(class'X2TemplarShield'.default.ShieldEffectName)) // Check the old unit state specifically, as the attack could have removed the effect from the target.
			continue;

		// Gather various action arrays we will need.
		DamageAction = X2Action_ApplyWeaponDamageToUnit(FindAction);

		// We might need all Damage Unit actions relevant to this unit later.
		VisMgr.GetNodesOfType(VisMgr.BuildVisTree, class'X2Action_ApplyWeaponDamageToUnit', DamageUnitActions,, OldUnitState.ObjectID);

		// Parents of the Damage Unit action are Fire Actions.
		FireActions = DamageAction.ParentActions;

		// Parents of the Fire Action are Exit Cover Actions.
		ExitCoverActions.Length = 0;
		foreach FireActions(CycleAction)
		{
			foreach CycleAction.ParentActions(ParentAction)
			{
				ExitCoverActions.AddItem(ParentAction);
			}
		}
		ExitCoverParentActions.Length = 0;
		foreach ExitCoverActions(CycleAction)
		{
			foreach CycleAction.ParentActions(ParentAction)
			{
				ExitCoverParentActions.AddItem(ParentAction);
			}
		}

		// #1. START. Insert a Move Turn action to force the target unit to face the attacker or epicenter of the explosion. 
		if (bAreaTargetedAbility) // If the ability is area-targeted, like a grenade throw, then face the target location (the epicenter of the explosion)
		{
			`LOG("Adding move-turn action for grenade targeted ability",, 'IRITEST');
			MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, ExitCoverParentActions));
			MoveTurnAction.m_vFacePoint = AbilityContext.InputContext.TargetLocations[0];
		}
		else // Otherwise face the attacker.
		{	 // In this case Move Turn action is specifically inserted between Exit Cover's parents and Exit Cover itself.
			 // So Exit Cover won't begin playing until Move Turn action finishes.
			 // This is necessary because some Fire Actions take very little time between the Fire Action starting and damage hitting the target, 
			 // so we have to make sure the target unit is already facing the source when the Fire Action begins.
			`LOG("Adding move-turn action towards attacker:" @ SourceUnit.GetFullName(),, 'IRITEST');
			MoveTurnAction = X2Action_MoveTurn(class'X2Action_MoveTurn'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, true,, ExitCoverParentActions));
			MoveTurnAction.m_vFacePoint = `XWORLD.GetPositionFromTileCoordinates(SourceUnit.TileLocation);
		}

		// Keep the target unit's visualizer occupy after turning is finished and until Exit Cover begins. This is done to prevent Idle State Machine from turning the unit away.
		WaitForActions.Length = 0;
		foreach ExitCoverActions(CycleAction)
		{
			WaitForAction = X2Action_WaitForAnotherAction(class'X2Action_WaitForAnotherAction'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false, MoveTurnAction));
			WaitForAction.ActionToWaitFor = CycleAction;
			WaitForActions.AddItem(WaitForAction);
		}
		
		// #1. END.

		// #2. START. Insert a Play Animation action for "unit shields themselves from the attack" animation.

		// If this ability uses a grenade path, it may take a while for the projectile to arrive to the templar, so delay the animation action by amount of time that scales with distance between them.
			// For the animation to look smooth, at least 0.25 seconds must pass between Additional Animation starting playing and projectiles hitting the target,
			// but no more than 2 seconds, as shield is put away at that point.
			// Grenade takes 1.5 seconds to fly 10 tiles and explode after being thrown, though this doesn't take throw animation time into account.
		// This delay is added on top of the variable amount of time required for the Move Turn action. 
		if (bGrenadeLikeAbility)
		{
			`LOG("Ability uses grenade path, inserting delay action for:" @ 0.05f * SourceUnit.TileDistanceBetween(NewUnitState) @ "seconds.",, 'IRITEST');
			TimedWait = X2Action_TimedWait(class'X2Action_TimedWait'.static.AddToVisualizationTree(ActionMetadata, AbilityContext, false,, WaitForActions));
			TimedWait.DelayTimeSec = 0.075f * SourceUnit.TileDistanceBetween(NewUnitState); // So 0.75 second delay at 10 tile distance.

			AdditionalAnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,, TimedWait));
		}
		else
		{
			AdditionalAnimationAction = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, WaitForActions));
		}
		AdditionalAnimationAction.Params.AnimName = 'HL_Shield_Absorb';

		// Make child actions of the original Damage Unit action become children of the animation action.
		foreach DamageAction.ChildActions(ChildAction)
		{
			VisMgr.ConnectAction(ChildAction, VisMgr.BuildVisTree, false, AdditionalAnimationAction);
		}
		`LOG("Inserted additional animation action to play absorb anim. Unit is dead:" @ NewUnitState.IsDead(),, 'IRITEST');
		// #2. END

		`LOG("Attack missed:" @ !WasUnitHit(AbilityContext, OldUnitState.ObjectID),, 'IRITEST');
		`LOG("Unit is dead:" @ NewUnitState.IsDead(),, 'IRITEST');
		`LOG("Unit was protected:" @ class'X2TemplarShield'.static.WasUnitFullyProtected(OldUnitState, NewUnitState),, 'IRITEST');
		`LOG("Shield was absorbed:" @ class'X2TemplarShield'.static.WasShieldFullyConsumed(OldUnitState, NewUnitState),, 'IRITEST');

		// If the attack missed, we stop here.
		// TODO: This may need to be adjusted, because grazes count as a hit.
		if (!WasUnitHit(AbilityContext, OldUnitState.ObjectID))
		{
			`LOG("Unit was not hit by this damage action:" @ !WasUnitHit(AbilityContext, OldUnitState.ObjectID) @ ", skipping to the next one.",, 'IRITEST');
			continue;
		}
		// #3. START. 
		// If the unit did not receive health damage during this attack (i.e. shield took all the damage), then we don't need this unit to play any "unit was hit" animations.
		// So we replace all original Damage Unit actions for this unit with a custom version that can be configured to not play any animations, 
		// but otherwise functions identically and can do stuff like showing flyover.
		if (class'X2TemplarShield'.static.WasUnitFullyProtected(OldUnitState, NewUnitState))
		{
			foreach DamageUnitActions(CycleAction)
			{
				`LOG("Unit was fully protected, replacing the Unit Hurt action with a new one so it can show the damage flyover",, 'IRITEST');
				DamageAction = X2Action_ApplyWeaponDamageToUnit(CycleAction);
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

			// If unit didn't take any damage, but the shield was fully depleted by the attack, then play a different "absorb damage" animation that puts the shield away at the end.
			if (class'X2TemplarShield'.static.WasShieldFullyConsumed(OldUnitState, NewUnitState))
			{	
				AdditionalAnimationAction.Params.AnimName = 'HL_Shield_AbsorbAndFold';
				`LOG("Shield was fully consumed, but unit was fully protected, replacing additional anim into Absorb and Fold",, 'IRITEST');
			}
		}
		else if (class'X2TemplarShield'.static.WasShieldFullyConsumed(OldUnitState, NewUnitState))
		{	 
			// If the unit did in fact take some health damage despite being shielded (i.e. damage broke through the shield),
			// Then we keep the original Damage Unit action in the tree. Its "unit hit" animation will interrupt the "absorb damage" animation from the additional action
			// whenever the attack connects with the unit.
			// Check the shield is actually gone, because the additive animation will stop the particle effect, hiding the shield from the unit.
			// In theory the unit can take health damage without the shield being broken.
			`LOG("Unit took some health damage, adding additive animation to explode the shield",, 'IRITEST');

			// Play an additive animation with particle effects of the shield blowing up at the same time as the unit being hit.
			PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, AbilityContext,,, FireActions));
			PlayAnimation.Params.AnimName = 'ADD_Shield_Explode';
			PlayAnimation.Params.Additive = true;

			// Make this additive animation respond to the same input events as the damage action, so it plays when projectiles hit the unit.
			PlayAnimation.ClearInputEvents();
			foreach DamageAction.InputEventIDs(InputEvent)
			{
				PlayAnimation.AddInputEvent(InputEvent);
			}		

			foreach DamageAction.ChildActions(ChildAction)
			{
				VisMgr.ConnectAction(ChildAction, VisMgr.BuildVisTree, false, PlayAnimation);
			}
		}
		// #3. END
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
