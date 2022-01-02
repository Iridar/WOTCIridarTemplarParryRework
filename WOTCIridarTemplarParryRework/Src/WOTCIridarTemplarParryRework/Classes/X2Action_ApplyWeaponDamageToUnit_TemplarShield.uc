class X2Action_ApplyWeaponDamageToUnit_TemplarShield extends X2Action_ApplyWeaponDamageToUnit;

// Conditionally replace the "unit gets shot" animation while psionic shield is active.
// OR: Skip playing any animation at all if set up so.

var bool bSkipAnimation;

simulated function Name ComputeAnimationToPlay(const string AppendEffectString="")
{	
	local name AnimName;

	AnimName = super.ComputeAnimationToPlay(AppendEffectString);

	`LOG("Computed AnimName:" @ AnimName,, 'IRITEST');

	return 'HL_Deflect_Storm';

	//return AnimName;
}

simulated function bool ShouldPlayAnimation()
{
	if (bSkipAnimation)
		return false;

	return super.ShouldPlayAnimation();
}