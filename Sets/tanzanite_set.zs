import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;

// ==========================================
// BALANCING
// ==========================================

val attackerMarkId as string = "tanzanite_attackers";
val recentAttackerDurationSeconds as int = 5; // 5 seconds of memory

// Partial Set (2/4)
val damageReductionPerAttacker as double = 0.05; // 5% less damage taken per unique attacker
val maxDamageReduction as double = 0.50; // Cap at 50% damage reduction (10 enemies)

// Full Set (4/4 + Weapon)
val bonusDamagePerAttacker as double = 0.10; // 10% bonus damage dealt per unique attacker
val maxBonusDamage as double = 1.0; // Cap at 100% bonus damage (10 enemies)

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Take " + ((damageReductionPerAttacker * 100.0) as int) + "% less damage for every unique enemy that attacked you in the last " + recentAttackerDurationSeconds + " seconds (Max " + ((maxDamageReduction * 100.0) as int) + "% reduction).";

val bonusDescriptionFull as string = "Tanzanite weapons deal " + ((bonusDamagePerAttacker * 100.0) as int) + "% bonus damage for every unique enemy that recently attacked you (Max " + ((maxBonusDamage * 100.0) as int) + "% bonus).";

val material as string = "Tanzanite";

val head as string = "shinygear:tanzanite_helmet";
val chest as string = "shinygear:tanzanite_chestplate";
val legs as string = "shinygear:tanzanite_leggings";
val feet as string = "shinygear:tanzanite_boots";

val weapons as string[] = [
    "shinygear:tanzanite_battleaxe",
    "shinygear:tanzanite_sword",
    "shinygear:tanzanite_axe",
    "shinygear:tanzanite_dagger",
    "shinygear:tanzanite_katana",
    "shinygear:tanzanite_warhammer",
    "shinygear:tanzanite_greatsword",
    "shinygear:tanzanite_halberd",
    "shinygear:tanzanite_spear",
    "shinygear:tanzanite_hammer",
    "shinygear:tanzanite_lance",
    "shinygear:tanzanite_crossbow",
    "shinygear:tanzanite_saber",
    "shinygear:tanzanite_rapier",
    "shinygear:tanzanite_longbow",
    "shinygear:tanzanite_longsword",
    "shinygear:tanzanite_pike",
    "shinygear:tanzanite_throwing_knife",
    "shinygear:tanzanite_throwing_axe",
    "shinygear:tanzanite_javelin",
    "shinygear:tanzanite_mace"
];

// ==========================================
// UNIVERSAL REGISTER BLOCK
// ==========================================

val armorSetName as string = material + " Armor Set";
val weaponSetName as string = material + " Weapon Set";

val armorBonusNamePartial as string = material + " Armor Partial Bonus";
val armorBonusNameFull as string = material + " Armor Full Bonus";
val weaponBonusName as string = material + " Weapon Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

SB.addEquipToSet(weaponSetName, "mainhand", weapons);

SB.addSetReqToBonus(armorBonusNamePartial, bonusDescriptionPartial, armorSetName, 2);
SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

SB.addSetReqToBonus(weaponBonusName, "", armorSetName, 4, 2);
SB.addSetReqToBonus(weaponBonusName, "", weaponSetName, -1, 2);

// ==========================================
// EVENT
// ==========================================

events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    // ---------------------------------------------------------
    // DEFENDER LOGIC
    // ---------------------------------------------------------
    if (targetEntity instanceof IPlayer) {
        val defender as IPlayer = targetEntity.asIPlayer();
        
        if (!isNull(defender)) {
            
            // 1. Record the attacker
            defender.markEntity(attackerMarkId, attackerEntity, recentAttackerDurationSeconds * 20, "add");
            
            // 2. Partial Set (2/4)
            if (defender.hasSetBonus(armorBonusNamePartial) == true) {
                
                val recentAttackers = defender.getMarkedEntities(attackerMarkId);
                
                if (!isNull(recentAttackers)) {
                    var activeAttackers = 0;
                    
                    for enemy in recentAttackers {
                        if (!isNull(enemy) && enemy.isAlive()) {
                            activeAttackers += 1;
                        }
                    }
                    
                    if (activeAttackers > 0) {
                        var reduction as double = (activeAttackers as double) * damageReductionPerAttacker;
                        if (reduction > maxDamageReduction) {
                            reduction = maxDamageReduction;
                        }
                        
                        defender.debugMessage(material + " Armor: Incoming damage reduced by " + ((reduction * 100.0) as int) + "% (" + activeAttackers + " attackers).");
                        event.amount = event.amount * (1.0 - reduction);
                    }
                }
            }
        }
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker)) {
            
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                if (event.amount > 0) {
                    
                    val recentAttackers = attacker.getMarkedEntities(attackerMarkId);
                    
                    if (!isNull(recentAttackers)) {
                        var activeAttackers = 0;
                        
                        for enemy in recentAttackers {
                            if (!isNull(enemy) && enemy.isAlive()) {
                                activeAttackers += 1;
                            }
                        }
                        
                        if (activeAttackers > 0) {
                            var totalBonus as double = (activeAttackers as double) * bonusDamagePerAttacker;
                            
                            if (totalBonus > maxBonusDamage) {
                                totalBonus = maxBonusDamage;
                            }
                            
                            attacker.debugMessage(material + " Weapon: +" + ((totalBonus * 100.0) as int) + "% damage from " + activeAttackers + " attackers.");
                            event.amount = event.amount * (1.0 + totalBonus);
                        }
                    }
                }
            }
        }
    }
});