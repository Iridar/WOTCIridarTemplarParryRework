class X2DLCInfo_ParryRework extends X2DownloadableContentInfo;

/*
Soul Shot - fire a psionic bow at the target. Deals high damage, but can miss.

TODO:
Icon

Potentially rework shield PFX for better performance.

Double check localization
*/

// Replace any instance of "Parry" ability in any soldier class' ability tree with Templar Shield.
static event OnPostTemplatesCreated()
{
	local X2SoldierClassTemplate			ClassTemplate;
	local X2SoldierClassTemplateManager		ClassMgr;
	local X2DataTemplate					DataTemplate;
	local int i;
	local int j;

	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach ClassMgr.IterateTemplates(DataTemplate)
	{
		ClassTemplate = X2SoldierClassTemplate(DataTemplate);
		if (ClassTemplate == none)
			continue;

		for (i = 0; i < ClassTemplate.SoldierRanks.Length; i++)
		{
			for (j = 0; j < ClassTemplate.SoldierRanks[i].AbilitySlots.Length; j++)
			{
				if (ClassTemplate.SoldierRanks[i].AbilitySlots[j].AbilityType.AbilityName == 'Parry')
				{
					ClassTemplate.SoldierRanks[i].AbilitySlots[j].AbilityType.AbilityName = 'IRI_TemplarShield';
				}
			}
		}
	}
}

static event OnLoadedSavedGame()
{
	OnLoadedSavedGameToStrategy();
}

// Replace any instance of "Parry" ability in any existing soldier ability tree with Templar Shield.
static event OnLoadedSavedGameToStrategy()
{
	local XComGameStateHistory				History;
	local XComGameState						NewGameState;
	local XComGameState_HeadquartersXCom	XComHQ;
	local bool								bChange;
	local StateObjectReference				UnitRef;
	local XComGameState_Unit				UnitState;
	local int i;

	History = `XCOMHISTORY;	
	XComHQ = `XCOMHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("WOTCMoreSparkWeapons: Add Starting Items");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	
	foreach XComHQ.Crew(UnitRef)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
		if (UnitState.IsSoldier())
		{
			
			for (i = UnitState.AbilityTree[0].Abilities.Length - 1; i >= 0; i--)
			{
				if (UnitState.AbilityTree[0].Abilities[i].AbilityName == 'Parry')
				{
					UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
					UnitState.AbilityTree[0].Abilities[i].AbilityName = 'IRI_TemplarShield';
					bChange = true;
				}
			}
		}
	}

	if (bChange)
	{
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function bool AbilityTagExpandHandler_CH(string InString, out string OutString, Object ParseObj, Object StrategyParseObj, XComGameState GameState)
{
    local XComGameStateHistory	History;
    local XComGameState_Effect	EffectState;
    local XComGameState_Ability	AbilityState;
    local XComGameState_Unit	UnitState;

    if (InString != "TEMPLAR_SHIELD_TAG")
        return false;

    History = `XCOMHISTORY;

    UnitState = XComGameState_Unit(StrategyParseObj);
	if (UnitState == none)
	{
		EffectState = XComGameState_Effect(ParseObj);
		if (EffectState != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		}
		else 
		{
			AbilityState = XComGameState_Ability(ParseObj);
			if (AbilityState != none)
			{
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			}
		}
	}
    if (UnitState == none)
		return false;

	// Grobo: might want to remove the coloring.
	OutString = "<font color='#a622fa'>" $ class'X2Effect_TemplarShield'.static.GetShieldStrength(UnitState, GameState) $ "</font>";

    return true;
}
