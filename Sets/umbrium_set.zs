import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.EntityLivingUpdateEvent;
import mods.mahzenutils.Stacks;

// ==========================================
// BALANCING
// ==========================================

val umbriumStackId as string = "umbrium_doom_stacks";
val doomTimerId as string = "umbrium_doom_timer";

// Partial Set (2/4)
val executionHealthThreshold as double = 0.50; // 50% Health
val executionBonusDamage as double = 0.50; // 50% Bonus Damage

// Full Set (4/4 + Weapon)
val damageToStackMultiplier as double = 1.0; // 1 Damage = 1 Stack
val doomExplosionMultiplier as double = 0.50; 
val doomDelaySeconds as int = 3; // 3 Seconds without taking damage to trigger the explosion

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Deals " + ((executionBonusDamage * 100.0) as int) + "% bonus damage to enemies that are below " + ((executionHealthThreshold * 100.0) as int) + "% maximum health.";

val bonusDescriptionFull as string = "Umbrium weapons stack Impending Doom based on damage dealt. Waiting " + doomDelaySeconds + " seconds triggers a detonation dealing " + ((doomExplosionMultiplier * 100.0) as int) + "% of the accumulated damage.";

val material as string = "Umbrium";

val head as string = "defiledlands:umbrium_helmet";
val chest as string = "defiledlands:umbrium_chestplate";
val legs as string = "defiledlands:umbrium_leggings";
val feet as string = "defiledlands:umbrium_boots";

val weapons as string[] = [
    "defiledlands:umbrium_sword",
    "defiledlands:umbrium_axe",
    "spartandefiled:dagger_umbrium",
    "spartandefiled:longsword_umbrium",
    "spartandefiled:katana_umbrium",
    "spartandefiled:scythe_umbrium",
    "spartandefiled:saber_umbrium",
    "spartandefiled:rapier_umbrium",
    "spartandefiled:greatsword_umbrium",
    "spartandefiled:hammer_umbrium",
    "spartandefiled:warhammer_umbrium",
    "spartandefiled:spear_umbrium",
    "spartandefiled:halberd_umbrium",
    "spartandefiled:pike_umbrium",
    "spartandefiled:lance_umbrium",
    "spartandefiled:battleaxe_umbrium",
    "spartandefiled:mace_umbrium",
    "spartandefiled:glaive_umbrium",
    "spartandefiled:staff_umbrium",
    "spartandefiled:parrying_dagger_umbrium",
    "spartandefiled:boomerang_umbrium",
    "spartandefiled:longbow_umbrium",
    "spartandefiled:throwing_knife_umbrium",
    "spartandefiled:throwing_axe_umbrium",
    "spartandefiled:javelin_umbrium"
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
// STACK REGISTRY
// ==========================================

Stacks.registerStack(umbriumStackId, 99999, 0, "PERMANENT", "PRESERVE");

// ==========================================
// EVENTS
// ==========================================

// 1. COMBAT EVENT
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    
    if (damageSource.damageType == "umbrium_burst") {
        return;
    }

    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(targetEntity)) {
        return; 
    }
    
    val currentDoomStacks = targetEntity.getStacks(umbriumStackId);
    if (currentDoomStacks > 0) {
        targetEntity.startCooldown(doomTimerId, doomDelaySeconds * 20);
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (!isNull(attackerEntity) && attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            // --- Partial Set (2/4) ---
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                val currentHealthRatio = (targetEntity.health as double) / (targetEntity.maxHealth as double);
                
                if (currentHealthRatio <= executionHealthThreshold) {
                    event.amount = event.amount * (1.0 + executionBonusDamage);
                    attacker.debugMessage(material + " Armor: +" + ((executionBonusDamage * 100.0) as int) + "% Damage!");
                }
            }
            
            // --- Full Set (4/4 + Weapon) ---
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                val stacksToAdd = (event.amount * damageToStackMultiplier) as int;
                
                if (stacksToAdd > 0) {
                    targetEntity.addStacks(umbriumStackId, stacksToAdd);
                    
                    targetEntity.startCooldown(doomTimerId, doomDelaySeconds * 20);
                    
                    attacker.debugMessage(material + " Weapon: Inflicted " + stacksToAdd + " stacks!");
                }
            }
        }
    }
});

// 2. PASSIVE TARGET TICK
events.onEntityLivingUpdate(function(event as EntityLivingUpdateEvent) {
    if (event.entityLivingBase.world.time % 10 == 0) {
        
        val targetEntity = event.entityLivingBase;
        
        if (!isNull(targetEntity) && targetEntity.isAlive()) {
            
            val stacks = targetEntity.getStacks(umbriumStackId);
            
            if (stacks > 0 && targetEntity.onCooldown(doomTimerId) == false) {
                
                val burstDamage as float = (stacks as float) * (doomExplosionMultiplier as float);
                
                targetEntity.clearStacks(umbriumStackId);
                
                targetEntity.dealCustomDamage(targetEntity as IEntity, burstDamage, "umbrium_burst");
            }
        }
    }
});