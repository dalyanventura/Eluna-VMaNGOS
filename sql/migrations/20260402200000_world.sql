DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20260402200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20260402200000');
-- Add your query below.

-- ============================================================
-- Turtle WoW Patch 1.17.2 — Rogue Class Changes
-- ============================================================

-- ============================================================
-- BASELINE CHANGES
-- ============================================================

-- Combo Points no longer vanish on target switch (handled in MiscHandler.cpp).

-- Sinister Strike: Energy cost reduced from 45 to 40 for all ranks.
-- This change was done because Improved Sinister Strike became baseline (Combat tree).
UPDATE `spell_template` SET `manaCost` = 40
WHERE `entry` IN (1752, 1757, 1758, 1759, 11293, 11294, 26862);

-- Sprint: Cooldown reduced from 5 minutes to 4 minutes.
-- Compensates for Endurance talent (which reduced Sprint/Evasion CDs) being removed.
UPDATE `spell_template` SET `recoveryTime` = 240000, `categoryRecoveryTime` = 240000
WHERE `entry` IN (2983, 8696, 11305);

-- Evasion: Cooldown reduced from 5 minutes to 4 minutes.
UPDATE `spell_template` SET `recoveryTime` = 240000, `categoryRecoveryTime` = 240000
WHERE `entry` IN (5277, 26669);

-- Crippling Poison II: Slow reduced from 70% to 60%.
-- The proc debuff (applied on target) stores its slow as a negative effectBasePoints.
-- Vanilla spell ID 11202 is the Crippling Poison II on-target debuff aura.
UPDATE `spell_template` SET `effectBasePoints1` = -60
WHERE `entry` = 11202 AND `effectBasePoints1` = -70;

-- Wound Poison: Change from flat healing power reduction to -5% healing per stack.
-- effectApplyAuraName1 = 118 (SPELL_AURA_MOD_HEALING_PCT), effectBasePoints1 = -5.
-- The stacking healing reduction sum is handled in Unit::SpellHealingBonusTaken (C++).
-- Ranks 1-4 proc debuffs: 13218, 13222, 13223, 13224; Rank 5: 27189.
UPDATE `spell_template` SET
    `effectApplyAuraName1` = 118,
    `effectBasePoints1` = -5,
    `stackAmount` = 5
WHERE `entry` IN (13218, 13222, 13223, 13224, 27189);

-- Hemorrhage: Energy cost raised from 35 to 45 (compensated by new Bloody Mess talent).
-- Charges of the Hemorrhage debuff increased from 30 to 50.
-- The energy cost is on the active ability (all ranks), charges on the debuff proc.
UPDATE `spell_template` SET `manaCost` = 45
WHERE `entry` IN (16511, 17347, 17348, 26864);
-- Hemorrhage debuff proc charges from 30 to 50. Proc spell entry 16511 (rank 1) reuses
-- the same spell for the debuff in vanilla; update the procCharges field on the debuff.
UPDATE `spell_template` SET `procCharges` = 50
WHERE `entry` IN (16511, 17347, 17348, 26864) AND `procCharges` = 30;

-- ============================================================
-- ASSASSINATION CHANGES
-- ============================================================

-- Remorseless Attacks: Duration of the proc buff increased from 20 s to 40 s.
-- durationIndex 9 = 20 s in vanilla DBC; we override with a raw custom duration via
-- the effectAmplitude field approach is not available here, so we set durationIndex to
-- match the 40 s SpellDuration entry. DurationIndex 36 = 40000 ms in many vanilla DBCs.
-- If your DBC does not have index 36 = 40 s, use index 21 (21 s) and adjust accordingly.
UPDATE `spell_template` SET `durationIndex` = 36
WHERE `entry` IN (14161, 14162) AND `durationIndex` = 9;

-- Ruthlessness: Proc chance increased per rank.
-- Rank 1: 20% -> 33%, Rank 2: 40% -> 66%, Rank 3: 60% -> 100%.
-- Ruthlessness is a talent that procs an extra combo point; the proc chance is in
-- procChance on the talent trigger spell. Vanilla talent trigger IDs: 14160, 14161, 14162.
-- Note: 14161/14162 may overlap with Remorseless above; Ruthlessness triggers are
-- stored as SPELL_AURA_ADD_TARGET_TRIGGER entries on the talent spells.
UPDATE `spell_template` SET `procChance` = 33  WHERE `entry` = 14158;
UPDATE `spell_template` SET `procChance` = 66  WHERE `entry` = 14159;
UPDATE `spell_template` SET `procChance` = 100 WHERE `entry` = 14160;

-- ============================================================
-- ROGUE: ONE-HANDED AXE PROFICIENCY
-- ============================================================

-- Rogues can now wield One-Handed Axes.
-- We insert a new custom proficiency spell (entry 60100) and add it to every
-- Rogue race in playercreateinfo_spell so all new Rogues start with axe proficiency.
-- Existing Rogues will need the spell granted via character_spell or the trainer.

-- Custom proficiency spell for Rogue one-handed axes.
-- SPELL_EFFECT_PROFICIENCY (60), ITEM_CLASS_WEAPON (2), subclass mask = 1 (AXE one-hand).
DELETE FROM `spell_template` WHERE `entry` = 60100;
INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
    (60100, 0, 0, 0, 0, 0, 0,
     464, 0, 0, 0, 0,
     0, 0, 1, 0, 0,
     0, 0, 1, 0,
     0, 0, 0, 0,
     0, 101, 0, 0, 0, 0,
     0, 0, 0, 0, 0,
     0, 1, 0, 0, 0,
     0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     0, 0, 0, 0, 0, 0, 0, 0,
     2, 1, 0,
     60, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     1, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 0,
     0, 0, 383, 0, 0,
     'One-Handed Axes', 0, '', 0,
     'Allows you to use one-handed axes.', 0, '', 0,
     0, 0, 0,
     0, 0, 8, 0,
     0, 0, 0, -1,
     1, 1, 1,
     0, 0, 0, 0);

-- Grant this proficiency spell to all new Rogue characters (all races).
-- Race IDs: 1=Human, 2=Orc, 3=Dwarf, 4=NightElf, 5=Undead, 6=Tauren, 7=Gnome, 8=Troll,
--           10=BloodElf(not in vanilla), 11=Draenei(not in vanilla).
-- Vanilla Rogue races: Human(1), Orc(2), Dwarf(3), NightElf(4), Undead(5), Gnome(7), Troll(8).
-- Also HighElf(10) and Goblin(12) if present on this server.
DELETE FROM `playercreateinfo_spell` WHERE `spell` = 60100 AND `class` = 4;
INSERT INTO `playercreateinfo_spell` (`race`, `class`, `spell`, `note`) VALUES
    (1,  4, 60100, 'Rogue One-Handed Axes'),
    (2,  4, 60100, 'Rogue One-Handed Axes'),
    (3,  4, 60100, 'Rogue One-Handed Axes'),
    (4,  4, 60100, 'Rogue One-Handed Axes'),
    (5,  4, 60100, 'Rogue One-Handed Axes'),
    (7,  4, 60100, 'Rogue One-Handed Axes'),
    (8,  4, 60100, 'Rogue One-Handed Axes'),
    (9,  4, 60100, 'Rogue One-Handed Axes'),
    (10, 4, 60100, 'Rogue One-Handed Axes'),
    (11, 4, 60100, 'Rogue One-Handed Axes'),
    (12, 4, 60100, 'Rogue One-Handed Axes');

-- Grant to existing Rogue characters who don't already have it.
INSERT IGNORE INTO `character_spell` (`guid`, `spell`, `active`, `disabled`)
SELECT `guid`, 60100, 1, 0
FROM `characters` WHERE `class` = 4;

-- ============================================================
-- NEW POISON: Corrosive Poison
-- Deals Physical damage over time (bypasses Nature/poison immunity).
-- 30% proc chance, 105 charges, stacks up to 5 times.
-- Rank 1 (lvl 56): 100 Physical dmg over 12 s (8.33/tick at 2s tick)
-- Rank 2 (lvl 60/book): 128 Physical dmg over 12 s (10.67/tick)
-- ============================================================

-- Corrosive Poison weapon enchant – Rank 1 (applied to weapon by player)
DELETE FROM `spell_template` WHERE `entry` IN (60101, 60102, 60103, 60104);

INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
-- 60101: Corrosive Poison I weapon enchant (30% proc, 105 charges, triggers 60103)
-- attributes: 464 (passive, no cast bar), effect1=6(apply aura), aura=36(periodic trigger),
-- amplitude=2000(2s), triggerSpell1=60103, dispel=4(poison), school=0(physical)
(60101, 0, 0, 0, 0, 4, 0,
 464, 0, 0, 0, 0,
 0, 0, 1, 0, 0,
 0, 0, 1, 0,
 0, 0, 0, 0,
 0, 30, 105, 0, 56, 56,
 0, 3, 0, 0, 0,
 0, 1, 0, 0, 0,
 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 1, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 36, 0, 0,
 2000, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 60103, 0, 0,
 0, 0, 0,
 0, 0, 188, 0, 0,
 'Corrosive Poison', 0, 'Rank 1', 0,
 'Each strike has a 30%% chance of poisoning the enemy for 100 Physical damage over 12 sec. Stacks up to 5 times. 105 charges.', 0, '', 0,
 0, 0, 0,
 0, 0, 8, 131072,
 0, 0, 0, -1,
 1, 1, 1,
 0, 0, 0, 0),
-- 60102: Corrosive Poison II weapon enchant (triggers 60104)
(60102, 0, 0, 0, 0, 4, 0,
 464, 0, 0, 0, 0,
 0, 0, 1, 0, 0,
 0, 0, 1, 0,
 0, 0, 0, 0,
 0, 30, 105, 0, 60, 60,
 0, 3, 0, 0, 0,
 0, 1, 0, 0, 0,
 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 1, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 36, 0, 0,
 2000, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 60104, 0, 0,
 0, 0, 0,
 0, 0, 188, 0, 0,
 'Corrosive Poison', 0, 'Rank 2', 0,
 'Each strike has a 30%% chance of poisoning the enemy for 128 Physical damage over 12 sec. Stacks up to 5 times. 105 charges.', 0, '', 0,
 0, 0, 0,
 0, 0, 8, 131072,
 0, 0, 0, -1,
 1, 1, 1,
 0, 0, 0, 0),
-- 60103: Corrosive Poison I DoT effect (Physical school, SPELL_AURA_PERIODIC_DAMAGE, 6 ticks x 2s)
-- 100 dmg total / 6 ticks = ~16 per tick; effectBasePoints = 15 (base) + 1 die
-- school=0(physical), dispel=0(not dispellable as poison by conventional means),
-- dmgClass=1(magic) kept 0 (physical) so it bypasses nature immunity
(60103, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0,
 0, 0, 6, 0, 0,
 0, 0, 1, 0,
 0, 0, 0, 0x20000, 0,
 0, 101, 0, 0, 56, 56,
 3, 3, 0, 0, 0,
 0, 1, 0, 0, 5,
 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 1, 0, 0,
 1, 0, 0,
 0, 0, 0,
 0, 0, 0,
 15, 0, 0,
 0, 0, 0,
 0, 0, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 29, 0, 0,
 2000, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 188, 0, 0,
 'Corrosive Poison', 0, '', 0,
 'Deals 100 Physical damage over 12 sec.', 0, 'Deals $w1 Physical damage every $t1 sec.', 0,
 0, 0, 0,
 0, 0, 8, 131072,
 0, 1, 0, -1,
 1, 1, 1,
 0, 0, 0, 0),
-- 60104: Corrosive Poison II DoT effect (128 dmg / 6 ticks ≈ 21 per tick; effectBasePoints=20, die=1)
(60104, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0,
 0, 0, 6, 0, 0,
 0, 0, 1, 0,
 0, 0, 0, 0x20000, 0,
 0, 101, 0, 0, 60, 60,
 3, 3, 0, 0, 0,
 0, 1, 0, 0, 5,
 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 1, 0, 0,
 1, 0, 0,
 0, 0, 0,
 0, 0, 0,
 20, 0, 0,
 0, 0, 0,
 0, 0, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 29, 0, 0,
 2000, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 188, 0, 0,
 'Corrosive Poison', 0, 'Rank 2', 0,
 'Deals 128 Physical damage over 12 sec.', 0, 'Deals $w1 Physical damage every $t1 sec.', 0,
 0, 0, 0,
 0, 0, 8, 131072,
 0, 1, 0, -1,
 1, 1, 1,
 0, 0, 0, 0);

-- Register script for Corrosive Poison bypass logic (handled in spell_rogue.cpp).
UPDATE `spell_template` SET `script_name` = 'spell_rogue_corrosive_poison'
WHERE `entry` IN (60103, 60104);

-- Register Rupture script to trigger Taste for Blood buff.
-- Rupture spell IDs: 1943, 8639, 8640, 11273, 11274, 26867.
UPDATE `spell_template` SET `script_name` = 'spell_rogue_rupture'
WHERE `entry` IN (1943, 8639, 8640, 11273, 11274, 26867);

-- ============================================================
-- NEW ABILITY SPELL ENTRIES
-- These enable the mechanics implemented in spell_rogue.cpp scripts.
-- ============================================================

-- -----------------------------------
-- Taste for Blood (Assassination – Rank 1/2/3 buff applied after Rupture cast)
-- Increases the Rogue's damage by 3/6/10% for 6s + 2s per combo point.
-- This is the aura applied to the Rogue (not a talent spell itself).
-- We use three spell entries, one per talent rank, each triggered by script.
-- -----------------------------------
DELETE FROM `spell_template` WHERE `entry` IN (60110, 60111, 60112);
INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
-- Rank 1: +3% damage, durationIndex 9 (20 s base; actual duration set by script per combo pts)
(60110, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 2, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 4, 0, 0,
 'Taste for Blood', 0, 'Rank 1', 0,
 'Casting Rupture increases your damage by 3%% for 6 sec plus 2 sec per combo point spent.', 0,
 'Damage increased by $s1%%.', 0,
 0, 0, 0, 0, 0, 8, 2097152, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0),
-- Rank 2: +6% damage
(60111, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 5, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 4, 0, 0,
 'Taste for Blood', 0, 'Rank 2', 0,
 'Casting Rupture increases your damage by 6%% for 6 sec plus 2 sec per combo point spent.', 0,
 'Damage increased by $s1%%.', 0,
 0, 0, 0, 0, 0, 8, 2097152, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0),
-- Rank 3: +10% damage
(60112, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 9, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 9, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 4, 0, 0,
 'Taste for Blood', 0, 'Rank 3', 0,
 'Casting Rupture increases your damage by 10%% for 6 sec plus 2 sec per combo point spent.', 0,
 'Damage increased by $s1%%.', 0,
 0, 0, 0, 0, 0, 8, 2097152, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0);

-- -----------------------------------
-- Honor Among Thieves: Physical critical hits by nearby party members grant 2 or 5 Energy.
-- Two ranks of the aura. Script-driven proc handler in spell_rogue.cpp.
-- effectBasePoints1 stores the energy amount: rank1=2, rank2=5.
-- -----------------------------------
DELETE FROM `spell_template` WHERE `entry` IN (60120, 60121, 60122);
INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
-- 60120: Honor Among Thieves Rank 1 – passive aura on Rogue, grants 2 energy per party crit
-- SPELL_AURA_DUMMY (4) used; actual energy grant handled by script proc
(60120, 0, 0, 0, 0, 0, 0,
 464, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 21, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0,
 'Honor Among Thieves', 0, 'Rank 1', 0,
 'Physical critical hits by party members within 20 yards grant you 2 Energy. This effect can only trigger once every 2 sec.', 0, '', 0,
 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0),
-- 60121: Honor Among Thieves Rank 2 – grants 5 energy
(60121, 0, 0, 0, 0, 0, 0,
 464, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 21, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 4, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0,
 'Honor Among Thieves', 0, 'Rank 2', 0,
 'Physical critical hits by party members within 20 yards grant you 5 Energy. This effect can only trigger once every 2 sec.', 0, '', 0,
 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0),
-- 60122: Energy-grant trigger spell for Honor Among Thieves (used by script)
-- SPELL_EFFECT_ENERGIZE (30), powerType=3(energy), effectBasePoints1=1 (or 4; actual grant set by script)
(60122, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0, 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 3, 0, 0, 0, 0,
 'Honor Among Thieves', 0, '', 0,
 'Restores Energy.', 0, '', 0,
 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0);

-- -----------------------------------
-- Surprise Attack: 120% weapon damage after target dodges, awards 1 combo point.
-- 10-second cooldown, 10 Energy, instant attack.
-- Cannot be blocked, dodged, or parried.
-- Script in spell_rogue.cpp handles: only available after target dodges, next-melee queue.
-- -----------------------------------
DELETE FROM `spell_template` WHERE `entry` = 60130;
INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
-- 60130: Surprise Attack
-- attributes: 65536 = SPELL_ATTR_EX_IS_ABILITY, attributesEx: 512=can't be dodged, +256=can't be blocked, +128=can't be parried
-- SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL (17) + SPELL_EFFECT_ADD_COMBO_POINTS (80)
-- effectBasePoints1 = 19 means 20% extra (base 100% + 20% = 120% weapon damage), die sides=1
-- effectBasePoints2 = 0 (1 combo point via AddComboPoints), effect2=80
-- cooldown: 10000 ms, energy cost: 10
(60130, 0, 0, 0, 0, 0, 0,
 65536, 896, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 10000, 10000, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 0, 3, 10, 0, 0, 0, 3, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 1, -1, 4,
 17, 80, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 19, 0, 0,
 0, 0, 0,
 0, 0, 0,
 6, 6, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 558, 0, 0,
 'Surprise Attack', 0, '', 0,
 'A surprise strike that deals 120%% weapon damage. Only usable after the target dodges. Awards 1 combo point.', 0, '', 0,
 0, 1400, 1500, 0, 0, 8, 0, 0, 1, 0, -1, 1.2, 1, 1, 0, 0, 0, 0);

UPDATE `spell_template` SET `script_name` = 'spell_rogue_surprise_attack' WHERE `entry` = 60130;

-- -----------------------------------
-- Exploit Vulnerability: Capstone for Subtlety.
-- 135% weapon damage + increases party damage to target by 15% for 6s.
-- Awards 2 combo points. 3-minute cooldown, 40 Energy.
-- -----------------------------------
DELETE FROM `spell_template` WHERE `entry` IN (60140, 60141);
INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
-- 60140: Exploit Vulnerability active spell (weapon dmg + triggers debuff on target + 2 combo pts)
-- effect1=17(weapon dmg noschool), effect2=64(trigger spell 60141), effect3=80(add combo points)
-- effectBasePoints1=34 (35% extra = 135% total), effectBasePoints3=1 (2 combo points via AddComboPoints=1 = +1 on top of base 1)
-- 3 min cooldown=180000 ms, 40 energy cost
(60140, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 180000, 180000, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 0, 3, 40, 0, 0, 0, 3, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 1, -1, 4,
 17, 64, 80,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 34, 14, 1,
 0, 0, 0,
 0, 0, 0,
 6, 6, 6,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 60141, 0,
 0, 0, 0,
 0, 0, 559, 0, 0,
 'Exploit Vulnerability', 0, '', 0,
 'A marking strike that deals 135%% weapon damage and increases your party''s damage dealt to the target by 15%% for 6 sec. Awards 2 combo points.', 0, '', 0,
 0, 1400, 1500, 0, 0, 8, 0, 0, 1, 0, -1, 1.35, 1, 1, 0, 0, 0, 0),
-- 60141: Exploit Vulnerability debuff on target (+15% damage taken for 6 s)
-- SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN (255 or closest available) – use SPELL_AURA_MOD_DAMAGE_TAKEN (87) with flag
-- Actually use SPELL_AURA_MOD_SPELL_DAMAGE_OF_STAT_PERCENT is wrong; use 57 SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN
-- In vanilla aura defines: 57 = SPELL_AURA_MOD_DAMAGE_PERCENT_TAKEN, effectBasePoints1=14 (15% taken)
-- durationIndex 6 = 6 seconds in vanilla DBC
(60141, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 6, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 14, 0, 0,
 0, 0, 0,
 0, 0, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 57, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 559, 0, 0,
 'Exploit Vulnerability', 0, '', 0,
 'Damage dealt to this target is increased by 15%%.', 0, 'All damage taken increased by $s1%%.', 0,
 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0);

UPDATE `spell_template` SET `script_name` = 'spell_rogue_exploit_vulnerability' WHERE `entry` = 60140;

-- -----------------------------------
-- Smoke Bomb: Creates 8-yard cloud for 8 sec reducing hit chance of all inside by 20%.
-- 5 minute cooldown, 35 Energy cost.
-- Implemented as a persistent area effect spell (dynamic object or area trigger).
-- -----------------------------------
DELETE FROM `spell_template` WHERE `entry` IN (60150, 60151);
INSERT INTO `spell_template`
    (`entry`, `build`, `school`, `category`, `castUI`, `dispel`, `mechanic`,
     `attributes`, `attributesEx`, `attributesEx2`, `attributesEx3`, `attributesEx4`,
     `stances`, `stancesNot`, `targets`, `targetCreatureType`, `requiresSpellFocus`,
     `casterAuraState`, `targetAuraState`, `castingTimeIndex`, `recoveryTime`,
     `categoryRecoveryTime`, `interruptFlags`, `auraInterruptFlags`, `channelInterruptFlags`,
     `procFlags`, `procChance`, `procCharges`, `maxLevel`, `baseLevel`, `spellLevel`,
     `durationIndex`, `powerType`, `manaCost`, `manCostPerLevel`, `manaPerSecond`,
     `manaPerSecondPerLevel`, `rangeIndex`, `speed`, `modelNextSpell`, `stackAmount`,
     `totem1`, `totem2`,
     `reagent1`, `reagent2`, `reagent3`, `reagent4`, `reagent5`, `reagent6`, `reagent7`, `reagent8`,
     `reagentCount1`, `reagentCount2`, `reagentCount3`, `reagentCount4`, `reagentCount5`, `reagentCount6`, `reagentCount7`, `reagentCount8`,
     `equippedItemClass`, `equippedItemSubClassMask`, `equippedItemInventoryTypeMask`,
     `effect1`, `effect2`, `effect3`,
     `effectDieSides1`, `effectDieSides2`, `effectDieSides3`,
     `effectBaseDice1`, `effectBaseDice2`, `effectBaseDice3`,
     `effectDicePerLevel1`, `effectDicePerLevel2`, `effectDicePerLevel3`,
     `effectRealPointsPerLevel1`, `effectRealPointsPerLevel2`, `effectRealPointsPerLevel3`,
     `effectBasePoints1`, `effectBasePoints2`, `effectBasePoints3`,
     `effectBonusCoefficient1`, `effectBonusCoefficient2`, `effectBonusCoefficient3`,
     `effectMechanic1`, `effectMechanic2`, `effectMechanic3`,
     `effectImplicitTargetA1`, `effectImplicitTargetA2`, `effectImplicitTargetA3`,
     `effectImplicitTargetB1`, `effectImplicitTargetB2`, `effectImplicitTargetB3`,
     `effectRadiusIndex1`, `effectRadiusIndex2`, `effectRadiusIndex3`,
     `effectApplyAuraName1`, `effectApplyAuraName2`, `effectApplyAuraName3`,
     `effectAmplitude1`, `effectAmplitude2`, `effectAmplitude3`,
     `effectMultipleValue1`, `effectMultipleValue2`, `effectMultipleValue3`,
     `effectChainTarget1`, `effectChainTarget2`, `effectChainTarget3`,
     `effectItemType1`, `effectItemType2`, `effectItemType3`,
     `effectMiscValue1`, `effectMiscValue2`, `effectMiscValue3`,
     `effectTriggerSpell1`, `effectTriggerSpell2`, `effectTriggerSpell3`,
     `effectPointsPerComboPoint1`, `effectPointsPerComboPoint2`, `effectPointsPerComboPoint3`,
     `spellVisual1`, `spellVisual2`, `spellIconId`, `activeIconId`, `spellPriority`,
     `name`, `nameFlags`, `nameSubtext`, `nameSubtextFlags`,
     `description`, `descriptionFlags`, `auraDescription`, `auraDescriptionFlags`,
     `manaCostPercentage`, `startRecoveryCategory`, `startRecoveryTime`,
     `minTargetLevel`, `maxTargetLevel`, `spellFamilyName`, `spellFamilyFlags`,
     `maxAffectedTargets`, `dmgClass`, `preventionType`, `stanceBarOrder`,
     `dmgMultiplier1`, `dmgMultiplier2`, `dmgMultiplier3`,
     `minFactionId`, `minReputation`, `requiredAuraVision`, `customFlags`)
VALUES
-- 60150: Smoke Bomb active spell – creates a persistent area trigger (effect=76 summon wild object)
-- durationIndex 39 = 8 seconds; recoveryTime 300000 = 5 min; manaCost 35 (energy)
-- For the area debuff we use a script-driven approach: script spawns a dummy creature/trigger
-- that periodically re-applies the -20% hit aura to all units inside.
-- effectImplicitTargetA1=16(dest target), effectBasePoints1=5 (8-yard radius encoded)
(60150, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 64, 0, 0, 0, 0, 1, 300000, 300000, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 0, 3, 35, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 32, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 4, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 60151, 0, 0,
 0, 0, 0,
 0, 0, 437, 0, 0,
 'Smoke Bomb', 0, '', 0,
 'Creates a cloud of thick smoke in an 8 yard radius around you for 8 sec. All targets inside the smoke have a 20%% reduced chance to be hit by attacks and spells for the duration.', 0, '', 0,
 0, 1400, 1500, 0, 0, 8, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0),
-- 60151: Smoke Bomb aura (-20% hit chance) applied to targets inside by script
-- SPELL_AURA_MOD_ATTACKER_MELEE_HIT_CHANCE (270) and SPELL_AURA_MOD_ATTACKER_RANGED_HIT_CHANCE (287)
-- Use SPELL_AURA_MOD_HIT_CHANCE (44) which affects all attack types, effectBasePoints=-20
-- durationIndex 1 = 1 second (refreshed by area trigger periodically)
(60151, 0, 0, 0, 0, 0, 0,
 65536, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 101, 0, 0, 0, 0, 39, 3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 -1, -1, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 -21, 0, 0,
 0, 0, 0,
 0, 0, 0,
 6, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 44, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 0,
 0, 0, 437, 0, 0,
 'Smoke Bomb', 0, '', 0,
 'Chance to hit reduced by 20%%.', 0, 'Hit chance reduced by $s1%%.', 0,
 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0);

UPDATE `spell_template` SET `script_name` = 'spell_rogue_smoke_bomb' WHERE `entry` = 60150;

-- End of migration.
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
