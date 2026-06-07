import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;
import crafttweaker.event.EntityLivingDeathEvent;
import mods.mahzenutils.PlayerUtils;

// ==========================================
// BALANCING
// ==========================================

val mufflePotionId as string = "ebwizardry:muffle";

// Full Set (4/4)
val assassinateBonusDamage as double = 2.0; 
val assassinateCooldownSeconds as int = 60; 
val killResetRadius as double = 6.0;

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionFull as string = "Sneaking grants the Muffle effect. Melee attacking an enemy while Muffled consumes the effect to deal " + ((assassinateBonusDamage * 100.0) as int) + "% bonus damage. This effect has a " + assassinateCooldownSeconds + " second cooldown. An enemy dying within " + killResetRadius + " blocks of you instantly resets this cooldown.";

val material as string = "Leather";

val head as string = "minecraft:leather_helmet";
val chest as string = "minecraft:leather_chestplate";
val legs as string = "minecraft:leather_leggings";
val feet as string = "minecraft:leather_boots";

// ==========================================
// UNIVERSAL REGISTER BLOCK
// ==========================================

val armorSetName as string = material + " Armor Set";
val armorBonusNameFull as string = material + " Armor Full Bonus";

SB.addEquipToSet(armorSetName, "head", head);
SB.addEquipToSet(armorSetName, "chest", chest);
SB.addEquipToSet(armorSetName, "legs", legs);
SB.addEquipToSet(armorSetName, "feet", feet);

SB.addSetReqToBonus(armorBonusNameFull, bonusDescriptionFull, armorSetName, 4);

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT
events.onPlayerTick(function(event as PlayerTickEvent) {
    if (event.phase == "END" && event.player.world.time % 10 == 0) {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNameFull) == true) {
            
            if (PlayerUtils.isSneaking(player)) {
                
                if (player.onCooldown("leather_assassinate_cd") == false) {
                    
                    player.applyPotionEffect(mufflePotionId, 20, 0);
                }
            }
        }
    }
});

// 2. COMBAT EVENT
events.onEntityLivingHurt(function(event as EntityLivingHurtEvent) {
    val damageSource as IDamageSource = event.damageSource;
    val attackerEntity as IEntity = damageSource.getTrueSource();
    val targetEntity as IEntityLivingBase = event.entityLivingBase;
    
    if (isNull(attackerEntity) || isNull(targetEntity)) {
        return;
    }
    
    if (damageSource.damageType != "player") {
        return;
    }
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            if (attacker.hasSetBonus(armorBonusNameFull) == true) {
                
                val muffleAmp = attacker.getPotionAmplifier(mufflePotionId);
                
                if (muffleAmp >= 0) {
                    
                    event.amount = event.amount * (1.0 + assassinateBonusDamage);
                    
                    attacker.removePotionEffect(<potion:ebwizardry:muffle>);
                    
                    attacker.startCooldown("leather_assassinate_cd", assassinateCooldownSeconds * 20);
                    
                    attacker.debugMessage(material + " Armor: +" + ((assassinateBonusDamage * 100.0) as int) + "% Damage!");
                }
            }
        }
    }
});

// 3. DEATH EVENT
events.onEntityLivingDeath(function(event as EntityLivingDeathEvent) {
    val deadEntity = event.entityLivingBase;
    
    if (!isNull(deadEntity)) {
        
        val nearbyPlayers = deadEntity.getNearbyPlayers(killResetRadius);
        
        if (!isNull(nearbyPlayers)) {
            for player in nearbyPlayers {
                if (!isNull(player) && player.isAlive()) {
                    
                    if (player.hasSetBonus(armorBonusNameFull) == true) {
                        
                        if (player.onCooldown("leather_assassinate_cd")) {
                            
                            player.startCooldown("leather_assassinate_cd", 0);
                            player.debugMessage(material + " Armor: Cooldown reset!");
                        }
                    }
                }
            }
        }
    }
});