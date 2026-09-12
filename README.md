# Microbot Context Menus - WoW Vanilla (1.12.1) AddOn

**Download the latest version here: https://github.com/Desorda/MicrobotContextMenus/releases/**

This addon adds right-click context menu items to control the utility behaviors and settings for your Companion Bot party members on the Microbot private server. It is not intended to be a replacement for the Companion Control Panel that is distributed with the server files, but rather a complement to it. Common companion toggle commands, role assignment, and spell cast requests can be accessed from these context menus for quick and easy use.

<img width="337" height="406" alt="grafik" src="https://github.com/user-attachments/assets/9ef5ad36-ca90-46e4-a106-b10802e0837f" />
<img width="618" height="488" alt="grafik" src="https://github.com/user-attachments/assets/7ad573c2-a996-4f79-9378-60ee12954b5b" />


It also adds some Microbot-specific general commands and settings that can be accessed by right-clicking the player frame. All features enabled by this addon can also be performed manually with the .z, .legacy, .settings, and companion whisper commands described on the [Microbot Wiki](http://Microbot.wikidot.com/).

<img width="458" height="246" alt="grafik" src="https://github.com/user-attachments/assets/9dea30c8-1487-4077-9d74-94ad292dff53" />
<img width="349" height="235" alt="grafik" src="https://github.com/user-attachments/assets/bc72e5fa-1664-4d8f-b7d7-57dab6ff27e1" />


### Features

All of these functions and more are available from right-click context menus:

- Swap between Normal and Heroic dungeon difficulty settings and reset instances
- Change Companions role and toggle helm/cloak display
- Cast useful companion class spells from a right-click context menu:
  - Open Mage Portals to major cities (faction-specific)
  - Ask Warlocks to Summon party members
  - Easily set and change Shaman Totems and Paladin Buffs/Auras
  - Choose Hunter and Warlock pets, and summon or dismiss them as needed
  - Toggle stealth on and off for Rogues and Druids
  - Assign you Companions as MT/OT for use in the Boss scripts
  - Change Mages or Paladins Spec
  - Control Revial options of your Rezzing Companions
  - Lists Companions Gear, Spells, Status and Talents
  - Set Eat/Drink Values as well as Offdps, offheal, heal and Healooc values
- Automatically prevent companions from using dangerous spells at the levels classes get them with a single click
- Dynamic menu options: class skills and role toggles will only appear on the menus when you can actually use them
- Bot Formation control
- dynamic Bot Gear control, only shows options if you can use them on that Companion and reminds you that Gear change is avaible again 2mins after using it
- Keeps track of followed/transfered Companions during the active Session and allows you to recall them
- Offers a Setting for Auto trading your Mages/Warlocks 10g after Requesting a Portal/Summon and a Setting that allows you to change multiple Companions at once with the Menus
- Native pfUI support.
- Adds a "Legendary" Loot treshhold so Lootpets can pick up things like Dragon Sinews or Elementium Ore when with players. 
- Adds a "Toggle PvP" Option to your own Menu
- Addon Settings can be Keybound
- Uninvite Option for your own Companions even if you are not Group/Raid Leader

### Usage

Right click on your player frame to see the Player Menu commands, and right click on a target, party or raid member to see the Companion Menu commands if it is one of your Companions.

### Known Issues

- Using some of the commands sometimes will change or remove your current target, so don't use them in combat. (This is necessary to ensure that the proper companion gets the command and not your whole group if there's some server lag).
- Reloading your UI or relogging will flash the Addons follow/transfer memory and you won't be able to control your followed comps or unfollow/untransfer them directly anymore (still can do it with the self Menu)
- Due to performance the Autotrade can go off to quickly, resulting in the Mage/Warlock trading you their consumable and not accepting your 10g. In this case just try again, the Companion will now be in the proper Mode from the start and accept the Gold. 

## Player Menu Commands

Right click on your player frame to see the Player Menu commands.

### Dungeon Settings

- **Set Difficulty: Normal**: Sets your dungeon difficulty to Normal. (Standard Loot and Enemy settings in instances)
- **Set Difficulty: Heroic**: Sets your dungeon difficulty to Heroic. (+100% XP and Loot, 1.5X Enemy damage and health in instances)
- **Reset all instances**: Resets all of your active instances. (Max 5 resets per hour, same as using "/script ResetInstances()")

### Menu Settings

- **Set AutoTrade on/off**: Allows you to Auto trade your Mages/Warlocks 10g after Requesting a Portal/Summon
- **Broadcast to None/Class/Role/All**: Controls to which other Companions your settings should be copied to. Affected Menus will have a -CLASS/ROLE/ALL marker at the end. Will show dynamically if it makes sense.

### Return Companions

- **Unfollow all**: Allows you recall all followed Companions at once (.z unfollow)
- **Untransfer all**: Allows you recall all transfered Companions at once (.z untransfer)
- **Remove all**: Allows you all your Companions at once (.z remove all)

## Companion Class specific Menu Commands

Right click on a target, party or raid member to see the Companion Menu commands available for that character if it is one of your Companions.

### Mage

- **Open Portal**: Will ask your mage to open a portal to any of the major cities of their character faction, provided they are high enough level to do so.
- **Deny Danger Spells**
- **Set Spec**: Allows you to change a Mages spec (Fire/Frost/Arcane) after hiring them.  Will only show the Spec the Companion is not already in.

### Shaman

- **Toggle Totems**: Toggles Totem usage
- **Set Earth Totem**: Ask your shaman to use only this Earth Totem.
- **Set Fire Totem**: Ask your shaman to use only this Fire Totem, also lets you directly cast Frost Resistance Totem.
- **Set Water Totem**: Ask your shaman to use only this Water Totem also lets you directly cast Fire Resistance and Poison Cleansing Totem.
- **Set Air Totem**: Ask your shaman to use only this Air Totem also lets you directly cast Nature Resistance Totem.
- **Clear Totem Settings**: Reset all of your custom totem settings.
- **Set Weapon**: Lets you Pick the Shamans Weapon Spell (Tank and Mdps only).
- **Revial**: Lets you control Reincarnation and Soulstone usage and dispel Divine Intervention.

### Paladin

- **Set first Blessing**: Ask your paladin to use only this Blessing. Dynamically upgrades to the Greater version when available.
- **Set second lessing**: Ask your paladin to use only this as alternative Blessing. Needs a first Blessing to be set. Dynamically upgrades to the Greater version when available.
- **Set Aura**: Ask your paladin to use this Aura.
- **Set Spec**: Allows you to change a Paladins spec (Might/Magic) after hiring them. Will only show the Spec the Companion is not already in.
- **Set Weapon Nightfall/Normal**: Allows you to change a Paladins Weapon to Nightfall and back (MDPS and Tank only)
- **Revial**: Soulstone usage and dispel Divine Intervention.
- **Deny Danger Spells**

### Warlock

- **Choose Demon**: Select the demon you want your warlock to use (Imp, Felhunter, Voidwalker, or Succubus).
- **Pet Control**: Ask your Warlock to summon or dismiss their pet.
- **Summon Player**: Ask your Warlock to summon your current targeted player to your location. There is a confirmation window prior to summoning, and the player must be in your group or raid. After using this command, you must ask your companions to help finish the summoning ritual with the ".z use" command unless you have other players who will click the portal.
- **Set Soulstone on**: Ask your Warlock to only use their Soulstone on the target of your choosing.
- **Deny Danger Spells**	

### Hunter

- **Choose Beast**: Select the beast type you want your hunter to use (all Beast families are available from the dropdown).
- **Pet Control**: Ask your Hunter to summon or dismiss their pet, allows you to deny them the use of their pets growl/taunt
- **Set Aspect**: Ask your Hunter to use this Aspect.
- **Deny Danger Spells**	

### Rogue 

- **Toggle Stealth**: Ask your Rogue turn their Stealth ability on or off. Turning it off will prevent them from stealthing until your turn it back on.

### Druid

- **Toggle Stealth**: Ask your Druid to turn their Prowl ability on or off. Turning it off will prevent them from stealthing until your turn it back on.
- **Revial**: Lets you control Ressurection and Soulstone usage and dispel Divine Intervention.

### Priest

- **Set Power Infusion On**: Ask your Priest to always cast their Power Infusion on a specific Target (lite/legacy Priests only)
- **Set Fear Ward On**: Ask your Priest to always cast their Fear Ward on a specific Target (Dwarf Priest only)
- **Revial**: Soulstone usage and dispel Divine Intervention.
- **Deny Danger Spells**

### Warrior

- **Deny Danger Spells**

### Deny Danger Spells breakdown

You can click this command to automatically deny dangerous spells that people often don't want their companions to use. It will only appear if your companion has the spells or if you are broadcasting to all Companions.

- **Priest**: Psychic Scream and Holy Nova
- **Mage**: Blink
- **Warlock**: Fear, Death Coil and Howl of Terror
- **Paladin**: Turn Undead
- **Warrior**: Intimidating Shout
- **Hunter**: Scare Beast

## Companion general Menu Commands

Right click on a target, party or raid member to see the Companion Menu commands available for that character if it is one of your Companions.

### Companion Settings

General settings that changes a Companions behavior or gives Infos about them.

- **Toggle AoE/Helm/Cloak**: Toggles companion AoE, helm, or cloak setting (all classes).
- **Set Role**: Sets the companion's role. Will dynamically display the roles available based on the companion's class. Will not display for classes that only have one role available.
- **Set Drink/Eat**: Opens a Textbox in which you can put the desired % of health/mana under which the Companion should start drinking/eating (all classes).
- **Set Offheal/Offdps**: Allows you to set 
		Offheal - at which % of ally health a dps should start healing or 
		Offdps - % of mana they should stop doing dps (dps with healing spells).
- **Set Heal/HealOOC**: Allows you to set 
		Heal - at which % of ally health a healer should start healing in combat or 
		HealOOC - at which % of ally health a healer should start healing out of combat (healers).
- **Threat Limiter on/off**: Normaly your Companions will try to stay beyond the Threat of the Tank, set this off for them to go all out (all classes)
- **Assign/unassign as Tank**: Allows you to add/remove a Companion from the List of assigned Tanks for Boss Scripts
- **Reset Companion**: Try to reset your Companions if they are stuck in combat, teleport etc. (all classes)
- **Debug on/off**: Allows your Companionen to give Debug output for what they are doing (all classes)
- **List Spells/Gear/Talents/Status**: Gives detailed Info about your Companion (all classes)
- **Clear deny List**: Clears whatever the Companion has been previously denied (all classes)

### Set Gear 

Allows you to change your Companions worn Gear to predefined Gearsets, many of them requiring your Gear to fulfull certain Conditions.
This function has a 2 Minute Cooldown Server Side so the Addon will remind you once it is avaible again.

- **Normal**: (level 50+) Sets them back to their original gear
- **Fire Res**: (T1+, 255 Fire Resistance) Set them into Fire Resistance focused Gear.
- **Shadow Res**: (T2+, 255 Shadow Resistance) Set them into Shadow Resistance focused Gear.
- **Nature Res**: (T3+, 255 Nature Resistance) Set them into Nature Resistance focused Gear.
- **Frost Res**: (T4+, 255 Frost Resistance) Set them into Frost Resistance focused Gear.
- **Viscidius**: (T3+, 255 Nature Resistance) Set them into Nature Resistance and Frost Weapon focused Gear.
- **Ony Cloak**: (T1+, Onyxia Scale Cloak worn) Set them in their normal gear plus a Onyxia Scale Cloak.

### Set Formation 

Lets you control where your Companions will move to in relation to you, plus their distance in yards.

### Set CC and Focus Marks	

These menus allow you to set a companion's crowd control and focus targets by assigning them a specific raid icon as described on the [Microbot Wiki page for Behavior .z commands](http://Microbot.wikidot.com/zcommands#toc19). Will only show Options the Companion is not yet set to.

- **Set CC Mark**: Sets the companion's CC mark. This companion will attempt to keep all enemies with this raid icon crowd controlled.
- **Set Focus Mark**: Sets the companion's focus mark. This companion will focus their damage and attacks exclusively on living enemies with this raid icon and ignore other targets.

### Set Follow and Transfer on

Lets you change who the Companion is listening to. The Addon will keep Track of Companions that are followed/transferred and will give you a unfollow/untransfer Option for them.
You can follow to your other Companions by role (like following your heals to a RDPS) and you will always get all real players in the Group/Raid and your Target as Options for follow/transfer.
Return follow will return Companions that where followed onto you.

