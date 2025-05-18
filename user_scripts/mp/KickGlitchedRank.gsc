init()
{
    level thread onplayerconnect();
}

onplayerconnect()
{
    while(true)
    {
        level waittill("connected", player);
        player thread onplayerspawned();
    }
}

onplayerspawned()
{
    while(true)
    {
        self waittill("spawned_player");
        if(self.first)
        {
            if(isMaxLevel(self))
            {
                self thread kickMaxLevel(); 
            }
            else if(!isMaxLevel(self))
            {
                self iprintln("Welcome: "+self.name);
            }
            self.first = false;
        }
    }
}

kickMaxLevel()
{
    self iprintln("Unlock All Detected! Goodbye.");
    wait 10;
    kick( self getentitynumber(), "EXE_PLAYERKICKED" );
}

isMaxLevel(player)
{
    if(self.pers["prestige"] >= 10 && self.pers["rank"] >= 900)
    {
        return true;
    }
    else
        return false;
}
//Made by Raine#4071. 
