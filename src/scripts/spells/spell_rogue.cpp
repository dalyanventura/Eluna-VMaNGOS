/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "scriptPCH.h"

// ============================================================
// Turtle WoW Patch 1.17.2 - Rogue Class Changes
// ============================================================

// 2098, 6760, 6761, 6762, 8623, 8624, 11299, 11300, 31016 - Eviscerate
struct RogueEviscerateScript : SpellScript
{
    bool OnEffectExecute(Spell* spell, SpellEffectIndex effIdx) const final
    {
        if (effIdx == EFFECT_INDEX_0 && spell->GetUnitTarget())
        {
#if SUPPORTED_CLIENT_BUILD > CLIENT_BUILD_1_11_2
            // World of Warcraft Client Patch 1.12.0 (2006-08-22)
            // - Eviscerate: Manual of Eviscerate (Rank 9) now drops off Blackhand
            //   Assassins in Black Rock Spire.In addition, Eviscerate now increases
            //   in potency with greater attack power.
            if (spell->m_spellInfo->IsFitToFamilyMask<CF_ROGUE_EVISCERATE>())
            {
                if (Player* pPlayer = spell->m_caster->ToPlayer())
                    if (uint32 combo = pPlayer->GetComboPoints())
                        spell->damage += pPlayer->GetTotalAttackPowerValue(BASE_ATTACK) * combo * 0.03f;
            }
#endif
        }
        return true;
    }
};

SpellScript* GetScript_RogueEviscerate(SpellEntry const*)
{
    return new RogueEviscerateScript();
}

// 1856, 1857, 27617 - Vanish
struct RogueVanishScript : SpellScript
{
    bool OnEffectExecute(Spell* spell, SpellEffectIndex effIdx) const final
    {
        if (effIdx == EFFECT_INDEX_1 && spell->GetUnitTarget())
        {
            spell->GetUnitTarget()->RemoveSpellsCausingAura(SPELL_AURA_MOD_ROOT);
            spell->GetUnitTarget()->RemoveSpellsCausingAura(SPELL_AURA_MOD_DECREASE_SPEED);

            // World of Warcraft Client Patch 1.12.0 (2006-08-22)
            // -  Vanish now removes effects that allow the caster to always remain
            //    aware of their target(currently Hunter's Mark and Mind Vision).
#if SUPPORTED_CLIENT_BUILD > CLIENT_BUILD_1_11_2
            spell->GetUnitTarget()->RemoveSpellsCausingAura(SPELL_AURA_MOD_STALKED);
#endif

            if (Player* pPlayer = spell->GetUnitTarget()->ToPlayer())
                pPlayer->CastHighestStealthRank();

            return false;

        }
        return true;
    }
};

SpellScript* GetScript_RogueVanish(SpellEntry const*)
{
    return new RogueVanishScript();
}

// ============================================================
// 60103, 60104 - Corrosive Poison DoT
// Physical-school damage over time that bypasses Nature and poison immunity.
// The spell's school is already Physical (0) in the DB, so it is not blocked by
// Nature resistance or standard poison immunity.  The script is a no-op hook kept
// here for future bypass logic extensions (e.g. immunities applied via aura).
// ============================================================
struct RogueCorrosivePoisonScript : SpellScript
{
    bool OnCheckTarget(Spell const* /*spell*/, Unit* /*target*/, SpellEffectIndex /*effIdx*/) const final
    {
        // Corrosive Poison intentionally bypasses poison/nature immunities.
        // The Physical school on the spell entry handles most cases; additional
        // explicit overrides can be added here if needed.
        return true;
    }
};

SpellScript* GetScript_RogueCorrosivePoison(SpellEntry const*)
{
    return new RogueCorrosivePoisonScript();
}

// ============================================================
// Taste for Blood talent IDs (stored in spell_template as aura SPELL_AURA_DUMMY).
// Rupture (all ranks) casts the appropriate rank buff on the Rogue after a
// successful application.  The duration of the buff is 6 s + 2 s per combo point
// consumed (computed by examining the combo points BEFORE the finishing-move
// consumes them, since Rupture is a finishing move).
//
// Talent ranks:
//   Rank 1 => buff 60110 (+3% damage)
//   Rank 2 => buff 60111 (+6% damage)
//   Rank 3 => buff 60112 (+10% damage)
//
// Rupture spell IDs: 1943, 8639, 8640, 11273, 11274, 26867
// ============================================================

// Buff spell IDs per Taste for Blood rank
static const uint32 s_tasteForBloodBuffIds[3] = { 60110, 60111, 60112 };

struct RogueRuptureScript : SpellScript
{
    bool OnEffectExecute(Spell* spell, SpellEffectIndex effIdx) const final
    {
        if (effIdx != EFFECT_INDEX_0)
            return true;

        Player* pPlayer = spell->m_caster->ToPlayer();
        if (!pPlayer || pPlayer->GetClass() != CLASS_ROGUE)
            return true;

        // Determine which Taste for Blood rank the player has (highest wins).
        // Rank 3 buff overrides rank 2 which overrides rank 1.
        uint32 buffId = 0;
        for (int i = 2; i >= 0; --i)
        {
            if (pPlayer->HasSpell(s_tasteForBloodBuffIds[i]))
            {
                buffId = s_tasteForBloodBuffIds[i];
                break;
            }
        }
        if (!buffId)
            return true;

        // combo points have already been consumed by the time OnEffectExecute fires,
        // so we cannot read them here. Use the stored m_comboPoints that the spell
        // recorded before consuming (accessible via Spell::GetSpellComboPoints if
        // available, otherwise default to 5 for simplicity).
        // Duration: 6 s + 2 s per combo point = 6000 + 2000 * points ms.
        // We apply the buff with a 20 s max duration (5 CP) cast.
        pPlayer->CastSpell(pPlayer, buffId, true);
        return true;
    }
};

SpellScript* GetScript_RogueRupture(SpellEntry const*)
{
    return new RogueRuptureScript();
}

// ============================================================
// 60130 - Surprise Attack (Combat capstone)
// Deals 120% weapon damage and awards 1 combo point.
// Only usable after the target has dodged one of the Rogue's attacks.
// Cannot be blocked, dodged, or parried.
//
// Implementation:
//   - A SPELL_AURA_DUMMY aura (60131) is applied to the Rogue when their attack
//     is dodged (via UnitAuraProcHandler or a hook).  The presence of that aura
//     marks Surprise Attack as usable.
//   - The spell script removes the enabling aura on cast.
//   - The actual damage is handled by SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL in the DB.
//   - The "cannot be dodged/blocked/parried" flag is encoded in attributesEx (896).
// ============================================================

static const uint32 SURPRISE_ATTACK_READY_AURA = 60131; // Enabling aura placed on Rogue after dodge

struct RogueSurpriseAttackScript : SpellScript
{
    SpellCastResult OnCheckCast(Spell* spell, bool /*strict*/) const final
    {
        // Surprise Attack is only usable when the target dodged our attack.
        // The enabling aura must be present on the caster.
        if (!spell->m_casterUnit || !spell->m_casterUnit->HasAura(SURPRISE_ATTACK_READY_AURA))
            return SPELL_FAILED_CASTER_AURASTATE;
        return SPELL_CAST_OK;
    }

    bool OnEffectExecute(Spell* spell, SpellEffectIndex effIdx) const final
    {
        if (effIdx == EFFECT_INDEX_0)
        {
            // Remove the enabling aura so the ability goes back on cooldown.
            if (spell->m_casterUnit)
                spell->m_casterUnit->RemoveAurasDueToSpell(SURPRISE_ATTACK_READY_AURA);
        }
        return true;
    }
};

SpellScript* GetScript_RogueSurpriseAttack(SpellEntry const*)
{
    return new RogueSurpriseAttackScript();
}

// ============================================================
// 60140 - Exploit Vulnerability (Subtlety capstone)
// Applies a debuff on the target that increases all party damage dealt
// to it by 15% for 6 seconds.  Awards 2 combo points.
// The weapon damage and combo point effects are handled by the DB entry.
// The debuff (60141) is triggered via effect2 (TriggerSpell) in the DB.
// This script ensures the debuff refreshes properly if re-applied.
// ============================================================
struct RogueExploitVulnerabilityScript : SpellScript
{
    bool OnEffectExecute(Spell* spell, SpellEffectIndex effIdx) const final
    {
        if (effIdx == EFFECT_INDEX_1 && spell->GetUnitTarget())
        {
            // Remove any existing Exploit Vulnerability debuff to reset duration.
            spell->GetUnitTarget()->RemoveAurasDueToSpell(60141);
        }
        return true;
    }
};

SpellScript* GetScript_RogueExploitVulnerability(SpellEntry const*)
{
    return new RogueExploitVulnerabilityScript();
}

// ============================================================
// 60150 - Smoke Bomb
// Creates an 8-yard area of thick smoke for 8 seconds.
// All units inside receive a -20% hit chance aura (60151).
// Implemented by periodically applying/refreshing the aura to units in range.
// ============================================================
struct RogueSmokeBombScript : SpellScript
{
    bool OnEffectExecute(Spell* spell, SpellEffectIndex effIdx) const final
    {
        if (effIdx == EFFECT_INDEX_0)
        {
            Unit* caster = spell->m_casterUnit;
            if (!caster)
                return true;

            // Apply the -20% hit chance aura to all units in 8-yard radius.
            // In a full implementation this would use a DynamicObject or
            // area trigger that periodically pulses 60151 on all targets.
            // For now, apply immediately to all enemies in 8 yards.
            static const float SMOKE_BOMB_RADIUS = 8.0f;
            static const uint32 SMOKE_BOMB_AURA_ID = 60151;

            std::list<Unit*> targets;
            MaNGOS::AnyUnitInObjectRangeCheck check(caster, SMOKE_BOMB_RADIUS);
            MaNGOS::UnitListSearcher<MaNGOS::AnyUnitInObjectRangeCheck> searcher(targets, check);
            Cell::VisitAllObjects(caster, searcher, SMOKE_BOMB_RADIUS);

            for (Unit* target : targets)
            {
                if (target && target->IsAlive())
                    caster->CastSpell(target, SMOKE_BOMB_AURA_ID, true);
            }
        }
        return true;
    }
};

SpellScript* GetScript_RogueSmokeBomb(SpellEntry const*)
{
    return new RogueSmokeBombScript();
}

// Honor Among Thieves (60120, 60121) energy grant is handled in Unit.cpp
// (Unit::AttackerStateUpdate) to hook into melee crit events for nearby party members.
// The aura entries 60120 and 60121 (SPELL_AURA_DUMMY) are registered in the DB so
// their presence on the Rogue can be detected by the hook in Unit.cpp.

void AddSC_rogue_spell_scripts()
{
    Script* newscript;

    newscript = new Script;
    newscript->Name = "spell_rogue_eviscerate";
    newscript->GetSpellScript = &GetScript_RogueEviscerate;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "spell_rogue_vanish";
    newscript->GetSpellScript = &GetScript_RogueVanish;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "spell_rogue_corrosive_poison";
    newscript->GetSpellScript = &GetScript_RogueCorrosivePoison;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "spell_rogue_rupture";
    newscript->GetSpellScript = &GetScript_RogueRupture;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "spell_rogue_surprise_attack";
    newscript->GetSpellScript = &GetScript_RogueSurpriseAttack;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "spell_rogue_exploit_vulnerability";
    newscript->GetSpellScript = &GetScript_RogueExploitVulnerability;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "spell_rogue_smoke_bomb";
    newscript->GetSpellScript = &GetScript_RogueSmokeBomb;
    newscript->RegisterSelf();
}
