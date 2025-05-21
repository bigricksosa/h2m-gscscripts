// Created by Xevrac
// Modify NUKE to MOAB style 
// Use DVAR nukeEndsGame to 0 for no endgame nuke like MW3 MOAB
// Infinite nukes patch by Sly Elliot
// Version 2.3.0 - Map-specific effects patch by Sosa

#include scripts\utility;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\h2_killstreaks\_nuke;
#include maps\mp\h2_killstreaks\_emp;

init()
{
    // MW3 map detection
    mw3Maps = [];
    mw3Maps[mw3Maps.size] = "mp_alpha";
    mw3Maps[mw3Maps.size] = "mp_bootleg";
    mw3Maps[mw3Maps.size] = "mp_bravo";
    mw3Maps[mw3Maps.size] = "mp_dome";
    mw3Maps[mw3Maps.size] = "mp_hardhat";
    mw3Maps[mw3Maps.size] = "mp_lambeth";
    mw3Maps[mw3Maps.size] = "mp_paris";
    mw3Maps[mw3Maps.size] = "mp_underground";

    currentMap = getDvar("mapname");
    level.isMW3Map = false;
    
    // Proper GSC array checking
    for(i = 0; i < mw3Maps.size; i++)
    {
        if(mw3Maps[i] == currentMap)
        {
            level.isMW3Map = true;
            break;
        }
    }
    // Store original functions before replacing
    level.original = spawnStruct();
    level.original.nukeDeath = maps\mp\h2_killstreaks\_nuke::nukeDeath;
    level.original.cancelNuke = maps\mp\h2_killstreaks\_nuke::cancelNukeOnDeath;
    level.original.nukeEffects = maps\mp\h2_killstreaks\_nuke::nukeEffects;
    level.original.doNuke = maps\mp\h2_killstreaks\_nuke::doNuke;

    // Replace functions with custom versions
    replaceFunc(maps\mp\h2_killstreaks\_nuke::nukeDeath, ::customNukeDeath);
    replaceFunc(maps\mp\h2_killstreaks\_nuke::cancelNukeOnDeath, ::customCancelNuke);
    replaceFunc(maps\mp\h2_killstreaks\_nuke::nukeEffects, ::customNukeEffects);
    replaceFunc(maps\mp\h2_killstreaks\_nuke::doNuke, ::customDoNuke);

    // Set nuke behavior based on map
    setDvar("nukeEndsGame", level.isMW3Map ? 0 : 1);

    // Original initialization code
    level._effect["emp_flash"] = loadfx("fx/explosions/nuke_flash");
    level.teamEMPed["allies"] = false;
    level.teamEMPed["axis"] = false;
    level.empPlayer = undefined;

    if(level.teamBased)
        level thread EMP_TeamTracker();
    else
        level thread EMP_PlayerTracker();

    level.killstreakFuncs["emp_mp"] = ::h2_EMP_Use;
    level thread onPlayerConnect();
}

customDoNuke(allowCancel)
{
    if(!level.isMW3Map) {
        self [[ level.original.doNuke ]](allowCancel);
        return;
    }

    // MW3-style MOAB implementation
    level endon("nuke_cancelled");
    level.nukeInfo = spawnStruct();
    level.nukeInfo.player = self;
    level.nukeInfo.team = self.pers["team"];
    level.nukeinfo.xpscalar = 1;
    level.nukeIncoming = true;

    h2_nukeCountdown();

    if(level.teambased) {
        thread teamPlayerCardSplash("callout_used_nuke", self, self.team);
    }
    else if(!level.hardcoreMode) {
        self iprintlnbold(&"LUA_KS_TNUKE");
    }

    level thread delaythread_nuke(level.nukeTimer - 3.3, ::nukeSoundIncoming);
    level thread delaythread_nuke(level.nukeTimer, ::nukeSoundExplosion);
    level thread delaythread_nuke(level.nukeTimer, ::customNukeEffects);
    level thread delaythread_nuke(level.nukeTimer + 1.5, ::nukeDeath);
    level thread delaythread_nuke(level.nukeTimer + 1.5, ::nukeEarthquake);
    level thread nukeAftermathEffect();

    if(level.cancelMode && allowCancel)
        level thread customCancelNuke(self);

    // Timer sound logic
    clockObject = spawn("script_origin", (0,0,0));
    clockObject hide();
    while(!isDefined(level.nukeDetonated)) {
        clockObject playSound("h2_nuke_timer");
        wait 1.0;
    }
}

customNukeEffects()
{
    if(!level.isMW3Map) {
        level [[ level.original.nukeEffects ]]();
        return;
    }

    // MW3-style effects without slow-mo
    level endon("nuke_cancelled");
    level.nukeCountdownTimer destroy();
    level.nukeCountdownIcon destroy();
    level.nukeDetonated = true;
    
    level maps\mp\h2_killstreaks\_emp::h2_EMP_Use();
    level._effect["emp_flash"] = loadfx("fx/explosions/nuke_flash");
    level maps\mp\h2_killstreaks\_emp::destroyActiveVehicles(level.nukeInfo.player);
    
    foreach(player in level.players) {
        // Fixed vector syntax
        forwardVec = anglestoforward(player.angles);
        playerForward = (forwardVec[0], forwardVec[1], 0);
        playerForward = VectorNormalize(playerForward);

        nukeEnt = spawn("script_model", 
                       player.origin + (playerForward * 5000));
        nukeEnt setModel("tag_origin");
        nukeEnt.angles = (0, player.angles[1] + 180, 90);
        nukeEnt thread nukeEffect(player);
        player.nuked = true;
    }
}

customNukeDeath()
{
    if(!level.isMW3Map) {
        level [[ level.original.nukeDeath ]]();
        return;
    }

    // MOAB-style non-ending nuke
    level endon("nuke_cancelled");
    level notify("nuke_death");
    maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
    AmbientStop(1);

    foreach(player in level.players) {
        if(isAlive(player)) {
            player thread maps\mp\gametypes\_damage::finishPlayerDamageWrapper(
                level.nukeInfo.player, level.nukeInfo.player, 
                999999, 0, "MOD_EXPLOSIVE", "nuke_mp", 
                player.origin, player.origin, "none", 0, 0
            );
            player thread customCancelNuke(player);
        }
    }
}

customCancelNuke(player)
{
    if(!level.isMW3Map) {
        player [[ level.original.cancelNuke ]]();
        return;
    }

    // MOAB-style cancellation
    player waittill_any("death", "disconnect");
    if(isDefined(player) && level.cancelMode == 2) {
        player thread maps\mp\h2_killstreaks\_emp::h2_EMP_Use(0, 0);
    }

    // Cleanup logic
    maps\mp\gametypes\_gamelogic::resumeTimer();
    level.timeLimitOverride = false;
    level.nukeDetonated = undefined;
    level.nukeInfo = undefined;
    level.nukeIncoming = undefined;
    if(isDefined(player.nuked)) player.nuked = undefined;

    if(isDefined(level.nukeCountdownTimer)) 
        level.nukeCountdownTimer destroy();
    if(isDefined(level.nukeCountdownIcon)) 
        level.nukeCountdownIcon destroy();

    level notify("nuke_cancelled");
}

resetGameSpeed()
{
    wait 4.0;
    setSlowMotion(1.0, 1.0, 0.0);
}
