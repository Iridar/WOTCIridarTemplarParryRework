class X2Action_ApplyWeaponDamageToUnit_TemplarShield extends X2Action_ApplyWeaponDamageToUnit;

// Conditionally replace the "unit gets shot" animation while psionic shield is active.

simulated function Name ComputeAnimationToPlay(const string AppendEffectString="")
{	
	local name AnimName;

	AnimName = super.ComputeAnimationToPlay(AppendEffectString);

	`LOG("Computed AnimName:" @ AnimName,, 'IRITEST');

	return 'HL_Deflect_Storm';

	//return AnimName;
}
