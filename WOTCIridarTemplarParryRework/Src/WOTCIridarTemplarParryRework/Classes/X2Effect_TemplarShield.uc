class X2Effect_TemplarShield extends X2Effect_Persistent;

/*
var name EffectAppliedAnimName;
var name EffectRemovedAnimName;

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local X2Action_PlayAnimation	PlayAnimation;
	local XComGameState_Unit		UnitState;
	local XGUnit					Unit;
	local XComUnitPawn				UnitPawn;

	UnitState = XComGameState_Unit(VisualizeGameState.GetGameStateForObjectID(ActionMetadata.StateObject_NewState.ObjectID));
	if(UnitState == none)
	{
		UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	}

	if (EffectApplyResult == 'AA_Success' && UnitState != none)
	{	
		Unit = XGUnit(ActionMetadata.VisualizeActor);
		if (Unit != None)
		{
			UnitPawn = Unit.GetPawn();

			// The unit may already be locked down (i.e. Viper bind), if so, do not play the stun start anim
			if (UnitPawn != none && UnitPawn.GetAnimTreeController().CanPlayAnimation(EffectAppliedAnimName))
			{
				// Play the start stun animation
				PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				PlayAnimation.Params.AnimName = EffectAppliedAnimName;
				//PlayAnimation.bResetWeaponsToDefaultSockets = true;
			}
		}
	}

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata)
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);

	AddX2ActionsForVisualization_Removed_Internal(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated private function AddX2ActionsForVisualization_Removed_Internal(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	local X2Action_PlayAnimation	PlayAnimation;
	local XComGameState_Unit		UnitState;
	local XGUnit					Unit;
	local XComUnitPawn				UnitPawn;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);

	if (EffectApplyResult == 'AA_Success' && UnitState != none)
	{	
		Unit = XGUnit(ActionMetadata.VisualizeActor);
		if (Unit != None)
		{
			UnitPawn = Unit.GetPawn();

			if (UnitPawn != none && UnitPawn.GetAnimTreeController().CanPlayAnimation(EffectRemovedAnimName))
			{
				PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
				PlayAnimation.Params.AnimName = EffectRemovedAnimName;
				PlayAnimation.Params.PlayRate = -1.0f;
			}
		}
	}
}
*/







/*
function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'X2Effect_TemplarShield_Event', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
	
	//	local X2EventManager EventMgr;
	//	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.FindAbility('ABILITY_NAME').ObjectID));
	//	EventMgr = `XEVENTMGR;
	//	EventMgr.TriggerEvent('X2Effect_TemplarShield_Event', AbilityState, SourceUnit, NewGameState);
	
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', AbilityActivated_Listener, ELD_OnStateSubmitted,, UnitState);	

	native function RegisterForEvent( ref Object SourceObj, 
									Name EventID, 
									delegate<OnEventDelegate> NewDelegate, 
									optional EventListenerDeferral Deferral=ELD_Immediate, 
									optional int Priority=50, 
									optional Object PreFilterObject, 
									optional bool bPersistent, 
									optional Object CallbackData );
	
	super.RegisterForEvents(EffectGameState);
}

static function EventListenerReturn AbilityActivated_Listener(Object EventData, Object EventSource, XComGameState NewGameState, name InEventID, Object CallbackData)
{
    local XComGameState_Unit            UnitState;
    local XComGameState_Ability         AbilityState;
	local X2AbilityTemplate				AbilityTemplate;
		
	AbilityState = XComGameState_Ability(EventData);
	UnitState = XComGameState_Unit(EventSource);
	AbilityTemplate = AbilityState.GetMyTemplate();
	
    return ELR_NoInterrupt;
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	
	if (UnitState != none)
	{
		
	}

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	super.OnEffectAdded(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}


simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult)
{
	
	if (EffectApplyResult == 'AA_Success')
	{
	
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if (UnitState != none)
	{
		
	}
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);
}

function UnitEndedTacticalPlay(XComGameState_Effect EffectState, XComGameState_Unit UnitState);
function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) { return true; }
function bool AllowCritOverride() { return false; }
function bool ShotsCannotGraze() { return false; }
function bool AllowDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState) { return true; }
function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) { return false; }
function bool ChangeHitResultForTarget(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) { return false; }
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers);
// CHL issue #467: function added to allow mods to modify the outcome of X2AbilityToHitCalc_StatCheck
function GetToHitModifiersForStatCheck(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, out array<ShotModifierInfo> ShotModifiers);
function bool UniqueToHitModifiers() { return false; }
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers);
// CHL issue #467: function added to allow mods to modify the outcome of X2AbilityToHitCalc_StatCheck
function GetToHitAsTargetModifiersForStatCheck(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, out array<ShotModifierInfo> ShotModifiers);
function bool UniqueToHitAsTargetModifiers() { return false; }
function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) { return 0; }
function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState) { return 0; }
function int GetBaseDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int BaseDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState) { return 0; }
function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData) { return 0; }
function int GetExtraShredValue(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData) { return 0; }
function int GetConditionalExtraShredValue(int UnconditionalShred, XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData) { return 0; }
function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState);
function bool AllowReactionFireCrit(XComGameState_Unit UnitState, XComGameState_Unit TargetState) { return false; }
function ModifyReactionFireSuccess(XComGameState_Unit UnitState, XComGameState_Unit TargetState, out int Modifier);
function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType) { return false; }
function ModifyGameplayVisibilityForTarget(out GameRulesCache_VisibilityInfo InOutVisibilityInfo, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit);
function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) { return false; }
function GetStatCheckModToSuccessCheck(XComGameState_Effect EffectState, XComGameState_Unit UnitState, XComGameState_Ability AbilityState, out int Successes);
function bool RetainIndividualConcealment(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return false; }     //  return true to keep individual concealment when squad concealment is broken
function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) { return true; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) { return true; }
function bool CanAbilityHitUnit(name AbilityName) { return true; }
function bool PreDeathCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return false; }
function bool PreBleedoutCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return false; }
function bool ForcesBleedout(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return bEffectForcesBleedout; }
function bool ForcesBleedoutWhenDamageSource(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return false; }
function      AdjustEffectDuration(const out EffectAppliedData ApplyEffectParameters, out int Duration);
function Actor GetProjectileVolleyTemplate(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext) { return none; }
function bool AdjustSuperConcealModifier(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameState_Ability AbilityState, XComGameState RespondToGameState, const int BaseModifier, out int CurrentModifier) { return false; }
function bool FreeKillOnDamage(XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState, const int ToKillTarget, const out EffectAppliedData ApplyEffectParameters) { return false; }
function bool GrantsFreeActionPointForApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState) { return false; }
function bool GrantsFreeActionPoint_Target(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState) { return false; }
function bool ImmediateSelectNextTarget(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Target) { return false; }
function bool ShouldUseMidpointCameraForTarget(XComGameState_Ability AbilityState, XComGameState_Unit Target) { return false; }
*/
defaultproperties
{
	EffectAppliedAnimName = "HL_HunkerDwn_Start"
	EffectRemovedAnimName = "HL_HunkerDwn_Start"

	DuplicateResponse = eDupe_Ignore
	EffectName = "IRI_X2Effect_TemplarShield_Effect"
}
