init()
{
    level thread onPlayerConnect();
}

onPlayerConnect()
{
    while (true)
    {
        level waittill("connected", player);

        player.selectedSniper = undefined;
        player.hasSeenHelp = false;
        player.primaryWeapon = undefined;

        player thread handleCommands();
        player thread onSpawned(); // handles spawn logic
    }
}

onSpawned()
{
    self endon("disconnect");

    while (true)
    {
        self waittill("spawned_player");

        if (!self.hasSeenHelp)
        {
            self.hasSeenHelp = true;
            self thread showHelpText();
        }

        // Track the current weapon on spawn (assume primary is first given)
        self.primaryWeapon = self getCurrentWeapon();

        if (isDefined(self.selectedSniper))
        {
            self giveSniperWeapon(self.selectedSniper);
        }
    }
}

handleCommands()
{
    self endon("disconnect");

    while (true)
    {
        self waittill("say", msg);

        msg = tolower(msg);

        if (msg == "!weaponmenu")
        {
            self thread showHelpText();
        }
        else if (msg == "!intervention")
        {
            self.selectedSniper = "h2_cheytac_mp";
            self iprintlnbold("Sniper selected: Intervention");
            if (isAlive(self)) self giveSniperWeapon(self.selectedSniper);
        }
        else if (msg == "!barrett")
        {
            self.selectedSniper = "h2_barrett_mp";
            self iprintlnbold("Sniper selected: Barrett");
            if (isAlive(self)) self giveSniperWeapon(self.selectedSniper);
        }
        else if (msg == "!wa2000")
        {
            self.selectedSniper = "h2_wa2000_mp";
            self iprintlnbold("Sniper selected: WA2000");
            if (isAlive(self)) self giveSniperWeapon(self.selectedSniper);
        }
        else if (msg == "!m40")
        {
            self.selectedSniper = "h2_m40a3_mp";
            self iprintlnbold("Sniper selected: M40A3");
            if (isAlive(self)) self giveSniperWeapon(self.selectedSniper);
        }
        else if (msg == "!as50")
        {
            self.selectedSniper = "h2_as50_mp";
            self iprintlnbold("Sniper selected: AS50");
            if (isAlive(self)) self giveSniperWeapon(self.selectedSniper);
        }
        else if (msg == "!msr")
        {
            self.selectedSniper = "h2_msr_mp";
            self iprintlnbold("Sniper selected: MSR");
            if (isAlive(self)) self giveSniperWeapon(self.selectedSniper);
        }
    }
}

showHelpText()
{
    self iPrintlnBold("^2Sniper Commands:");
    self iPrintln("!intervention → Intervention");
    self iPrintln("!barrett → Barrett");
    self iPrintln("!wa2000 → WA2000");
    self iPrintln("!m40 → M40A3");
    self iPrintln("!as50 → AS50");
    self iPrintln("!msr → MSR");
    self iPrintln("Type !weaponmenu to show this list again.");
    self iPrintln("If your weapon is missing on respawn, try switching weapons");
}

giveSniperWeapon(weapon)
{
    if (!isDefined(self.primaryWeapon))
    {
        self iprintln("Primary weapon not detected.");
        return;
    }

    self takeWeapon(self.primaryWeapon);  // Only take the original primary
    self giveWeapon(weapon);
    self switchToWeapon(weapon);
    self iPrintln("If your weapon is missing on respawn, try switching weapons");
    self.primaryWeapon = weapon; // Update tracked primary
}
