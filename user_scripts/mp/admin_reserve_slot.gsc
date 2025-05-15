#include common_scripts\utility;

main()
{
    level.adminGuids = [];
    level.adminGuids[0] = "1234567890abcdef"; // Example GUID
    level.adminGuids[1] = "abcdef1234567890"; // Add more as needed

    level.reservedAdminSlot = 1; // Always keep one slot free for admins

    level thread onPlayerConnect();
}

onPlayerConnect()
{
    while (true)
    {
        level waittill("connected", player);

        guid = player getGuid();

        if (level isAdminGuid(guid))
        {
            player.isAdmin = true;
            player iprintln("^2Admin access granted.");
        }
        else
        {
            player.isAdmin = false;

            // Check if server is full (minus reserved slot)
            maxPlayers = getDvarInt("sv_maxclients");
            activePlayers = getActivePlayerCount();

            if (activePlayers >= (maxPlayers - level.reservedAdminSlot))
            {
                // Server is full for non-admins, kick lowest priority player
                kicked = level kickNonAdminForAdmin();
                if (!kicked)
                {
                    // No one to kick, kick this player
                    player iprintlnbold("^1Server is full. Reserved for admins.");
                    wait 1;
                    kick(player getEntityNumber(), "Kicked: Server reserved for admin.");
                }
            }
        }
    }
}

getActivePlayerCount()
{
    count = 0;
    for (i = 0; i < level.players.size; i++)
    {
        if (isDefined(level.players[i]) && level.players[i] isAlive())
            count++;
    }
    return count;
}

isAdminGuid(guid)
{
    foreach (adminGuid in level.adminGuids)
    {
        if (adminGuid == guid)
            return true;
    }
    return false;
}

kickNonAdminForAdmin()
{
    // Look for the first non-admin player to kick
    foreach (player in level.players)
    {
        if (!isDefined(player)) continue;
        if (!isDefined(player.isAdmin) || player.isAdmin == false)
        {
            player iprintlnbold("^1You were kicked to free a slot for an admin.");
            wait 1;
            kick(player getEntityNumber(), "Kicked for admin slot.");
            return true;
        }
    }
    return false;
}