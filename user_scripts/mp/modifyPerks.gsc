// Disable deathstreaks and perks script by Sosa
// Based on NoSniper.gsc in h2m-gscscripts GitHub by Draakoor

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_gamelogic;

init()
{   
    level thread onPlayerConnect();
}

modifyPerks()
{
    // Remove deathstreaks besides Copycat
    deathstreaks = [
        "specialty_pistoldeath",       // Final Stand
        "specialty_grenadepulldeath",  // Martyrdom
        "specialty_painkiller"         // Painkiller
    ];

    foreach (deathstreak in deathstreaks)
    {
        if (self hasPerk(deathstreak))
        {
            self _unsetperk(deathstreaks); 
        }
    }

    // Replace Last Stand (perk) with Steady Aim
    if (self hasPerk("specialty_pistoldeath"))
    {
        self _unsetperk("specialty_pistoldeath"); // Last Stand (Perk)
        self giveperk("specialty_bulletaccuracy"); // Steady Aim
    }

    // Replace Last Stand Pro with Steady Aim Pro
    else if (self hasPerk("specialty_laststandoffhand"))
    {
        self _unsetPerk("specialty_laststandoffhand"); // Last Stand Pro
        self giveperk("specialty_holdbreath"); // Steady Aim Pro
    }
}

applyGameMode()
{   
    for (count=0; count<15; count++)
    {
        self modifyPerks();
        wait(3);
    }
}

onPlayerConnect()
{
    while (true)
    {
        level waittill("connected", player);        

        player thread onPlayerSpawned();
    }
}

onPlayerSpawned()
{
	self endon("disconnect");
	
	while (true)
	{
		self waittill("spawned_player");

		self thread applyGameMode();
	}
}
