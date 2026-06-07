import ctsetbonus.SetTweaks as SB;
import crafttweaker.entity.IEntity;
import crafttweaker.entity.IEntityLivingBase;
import crafttweaker.damage.IDamageSource;
import crafttweaker.player.IPlayer;
import crafttweaker.event.EntityLivingHurtEvent;
import crafttweaker.event.PlayerTickEvent;
import mods.mahzenutils.Stacks;

// ==========================================
// BALANCING
// ==========================================

// Partial Set (2/4)
val outOfCombatSeconds as int = 5; 
val maxCharges as int = 2;
val speedBuffDurationSeconds as int = 3;
val speedBuffAmplifier as int = 4; // Haste V

// Full Set (4/4 + Weapon)
val thirdHitBonusDamage as double = 1.0; // 100% bonus damage on the 3rd hit

// ==========================================
// DEFINITION
// ==========================================

val bonusDescriptionPartial as string = "Going " + outOfCombatSeconds + " seconds without dealing damage grants " + maxCharges + " Swiftness charges. Attacking consumes one charge to grant attack speed for your next strike.";

val bonusDescriptionFull as string = "Iron and Steel weapons deal " + ((thirdHitBonusDamage * 100.0) as int) + "% bonus damage on every 3rd consecutive strike against the same enemy.";

val material as string = "Chain";

val head as string = "minecraft:chainmail_helmet";
val chest as string = "minecraft:chainmail_chestplate";
val legs as string = "minecraft:chainmail_leggings";
val feet as string = "minecraft:chainmail_boots";

val weapons as string[] = [
    // Vanilla Iron
    "minecraft:iron_sword",
    "minecraft:iron_axe",
    
    // Spartan Weaponry Iron
    "spartanweaponry:dagger_iron",
    "spartanweaponry:longsword_iron",
    "spartanweaponry:katana_iron",
    "spartanweaponry:scythe_iron",
    "spartanweaponry:saber_iron",
    "spartanweaponry:rapier_iron",
    "spartanweaponry:greatsword_iron",
    "spartanweaponry:hammer_iron",
    "spartanweaponry:warhammer_iron",
    "spartanweaponry:spear_iron",
    "spartanweaponry:halberd_iron",
    "spartanweaponry:pike_iron",
    "spartanweaponry:lance_iron",
    "spartanweaponry:battleaxe_iron",
    "spartanweaponry:mace_iron",
    "spartanweaponry:glaive_iron",
    "spartanweaponry:staff_iron",
    
    // Steel Weapons
    "spartanweaponry:dagger_steel",
    "spartanweaponry:longsword_steel",
    "spartanweaponry:katana_steel",
    "spartanweaponry:scythe_steel",
    "spartanweaponry:saber_steel",
    "spartanweaponry:rapier_steel",
    "spartanweaponry:greatsword_steel",
    "spartanweaponry:hammer_steel",
    "spartanweaponry:warhammer_steel",
    "spartanweaponry:spear_steel",
    "spartanweaponry:halberd_steel",
    "spartanweaponry:pike_steel",
    "spartanweaponry:lance_steel",
    "spartanweaponry:battleaxe_steel",
    "spartanweaponry:mace_steel",
    "spartanweaponry:glaive_steel",
    "spartanweaponry:staff_steel"
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

Stacks.registerStack("chain_speed_charges", maxCharges, 0, "PERMANENT", "PRESERVE");
Stacks.registerStack("chain_combo", 3, 0, "PERMANENT", "PRESERVE");

// ==========================================
// EVENTS
// ==========================================

// 1. PASSIVE TICK EVENT
events.onPlayerTick(function(event as PlayerTickEvent) {
    if (event.phase == "END" && event.player.world.time % 20 == 0) {
        val player = event.player;
        
        if (!isNull(player) && player.hasSetBonus(armorBonusNamePartial) == true) {
            
            if (player.onCooldown("chain_combat_timer") == false) {
                
                val currentCharges = player.getStacks("chain_speed_charges");
                
                if (currentCharges < maxCharges) {
                    player.addStacks("chain_speed_charges", 1);
                    player.debugMessage(material + " Armor: Gained Swiftness charge (" + (currentCharges + 1) + "/" + maxCharges + ").");
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
    
    // ---------------------------------------------------------
    // ATTACKER LOGIC
    // ---------------------------------------------------------
    if (attackerEntity instanceof IPlayer) {
        val attacker as IPlayer = attackerEntity.asIPlayer();
        
        if (!isNull(attacker) && event.amount > 0) {
            
            // --- Partial Set (2/4) ---
            if (attacker.hasSetBonus(armorBonusNamePartial) == true) {
                
                attacker.startCooldown("chain_combat_timer", outOfCombatSeconds * 20);
                
                val currentCharges = attacker.getStacks("chain_speed_charges");
                if (currentCharges > 0) {
                    attacker.removeStacks("chain_speed_charges", 1);
                    
                    attacker.applyPotionEffect("minecraft:haste", speedBuffDurationSeconds * 20, speedBuffAmplifier);
                    attacker.debugMessage(material + " Armor: Charge consumed. (" + (currentCharges - 1) + " remaining)");
                }
            }
            
            // --- Full Set (4/4 + Weapon) ---
            if (attacker.hasSetBonus(weaponBonusName) == true) {
                
                targetEntity.addStacks("chain_combo", 1);
                val currentCombo = targetEntity.getStacks("chain_combo");
                
                if (currentCombo >= 3) {
                    val totalBonus as double = thirdHitBonusDamage;
                    event.amount = event.amount * (1.0 + totalBonus);
                    
                    attacker.debugMessage(material + " Weapon: +" + ((totalBonus * 100.0) as int) + "% damage!");
                    
                    targetEntity.clearStacks("chain_combo");
                    
                } else {
                    attacker.debugMessage(material + " Weapon: Strike " + currentCombo + " logged.");
                }
            }
        }
    }
});