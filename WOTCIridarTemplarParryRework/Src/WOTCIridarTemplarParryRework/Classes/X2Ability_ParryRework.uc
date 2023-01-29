class X2Ability_ParryRework extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateTemplarShield());

	return Templates;
}

static function X2AbilityTemplate CreateTemplarShield()
{
	local X2AbilityTemplate					Template;
	local X2AbilityCost_ActionPoints		ActionPointCost;
	local X2Effect_TemplarShieldAnimations	AnimSetEffect;
	local X2Effect_TemplarShield			ShieldedEffect;
	
	`CREATE_X2ABILITY_TEMPLATE(Template, 'IRI_TemplarShield');

	// Icon Setup
	Template.IconImage = "img:///IRIParryReworkPerk.UIPerk_TemplarShield";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.ShotHUDPriority = class'UIUtilities_Tactical'.const.CLASS_CORPORAL_PRIORITY;

	// Shooter Conditions
	Template.AbilityShooterConditions.AddItem(default.LivingShooterProperty);
 	Template.AddShooterEffectExclusions();

	// Triggering and Targeting
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Costs
	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = 1;
	ActionPointCost.AllowedTypes.AddItem('Momentum');
	ActionPointCost.bConsumeAllPoints = true;
	Template.AbilityCosts.AddItem(ActionPointCost);

	// Effects
	AnimSetEffect = new class'X2Effect_TemplarShieldAnimations';
	AnimSetEffect.BuildPersistentEffect(1, false, true,, eGameRule_PlayerTurnBegin);
	AnimSetEffect.AddAnimSetWithPath("WoTC_Shield_Animations.Anims.AS_Shield");
	AnimSetEffect.AddAnimSetWithPath("IRIParryReworkAnims.Anims.AS_TemplarShield"); // Flinch replaced with CS animations, Ballistic Shields' Hurt replaced by original templar animations.
	Template.AddTargetEffect(AnimSetEffect);

	ShieldedEffect = new class'X2Effect_TemplarShield';
	ShieldedEffect.BuildPersistentEffect(1, false, true,, eGameRule_PlayerTurnBegin);
	ShieldedEffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.GetMyHelpText(), Template.IconImage, true, , Template.AbilitySourceName);
	ShieldedEffect.EffectName = class'X2Effect_TemplarShield'.default.EffectName;
	Template.AddTargetEffect(ShieldedEffect);

	// State and Viz
	Template.Hostility = eHostility_Defensive;
	Template.bFrameEvenWhenUnitIsHidden = true;
	Template.AbilityConfirmSound = "TacticalUI_ActivateAbility";
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
	Template.BuildInterruptGameStateFn = TypicalAbility_BuildInterruptGameState;
	Template.bShowActivation = false; // Don't show flyover, it obscures the fancy animation.
	Template.CustomSelfFireAnim = 'HL_Shield_Extend';
	Template.CustomFireAnim = 'HL_Shield_Extend';
	Template.bSkipExitCoverWhenFiring = true;
	Template.bSkipFireAction = false;
	Template.OverrideAbilityAvailabilityFn = TemplarShield_OverrideAbilityAvailability;
	Template.DefaultSourceItemSlot = eInvSlot_PrimaryWeapon;

	if (!class'X2DLCInfo_ParryRework'.default.bSkipTemplarShieldIntegration)
	{
		Template.OverrideAbilities.AddItem('ParryActivate');
		Template.OverrideAbilities.AddItem('Parry');
	}
	
	return Template;
}

static private function TemplarShield_OverrideAbilityAvailability(out AvailableAction Action, XComGameState_Ability AbilityState, XComGameState_Unit OwnerState)
{
	if (Action.AvailableCode == 'AA_Success')
	{
		if (OwnerState.ActionPoints.Length == 1 && OwnerState.ActionPoints[0] == 'Momentum')
			Action.ShotHUDPriority = class'UIUtilities_Tactical'.const.PARRY_PRIORITY;
	}
}
