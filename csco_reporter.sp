#include <sourcemod>

Menu MainMenu = null;
new Handle:db = INVALID_HANDLE;
new Handle:cvar_Showmessage = INVALID_HANDLE;
new Handle:cvar_MessageDelay = INVALID_HANDLE;
new Handle:cvar_CheckBanlist = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "onepointsix reporter",
	author = "Sovietball",
	version = "1.0",
	description = "Allows CS:CO players to report suspicious gamers for the admins to check.",
	url = "http://onepointsix.org"
};
 
public void OnPluginStart()
{
	AutoExecConfig(true, "csgo_reporter");
	RegConsoleCmd("report", PrintMenu);
	RegConsoleCmd("sm_report", PrintMenu);
	cvar_Showmessage = CreateConVar("sm_join_showprotectmessage", "1", "Enable welcomemessage");	
	cvar_MessageDelay = CreateConVar("sm_showmessage_delay", "5.0", "Seconds after join the message is shown in chat");
	cvar_CheckBanlist = CreateConVar("sm_check_banlist", "1", "Checks if joining client is a hacker, and kick him if that is the case");	
	SQL_TConnect(MysqlHandler, "onepointsix_report_service");
}

public OnClientPutInServer(client)
{
	new String:new_client_steamid[64];
	new String:query[256];
	
	GetClientAuthId(client, AuthId_SteamID64, new_client_steamid, sizeof(new_client_steamid));
	Format(query, sizeof(query), "select steamid from banlist where steamid='%s'", new_client_steamid);
	
	PrintToServer(query);
	
	if(GetConVarInt(cvar_CheckBanlist) == 1)
	{
		SQL_TQuery(db, CheckBanHandler, query, client);
	}
	
	if(GetConVarInt(cvar_Showmessage) == 1)
	{
		CreateTimer (GetConVarFloat(cvar_MessageDelay), MessageHandler, client);
	}
	
}

public CheckBanHandler(Handle:owner, Handle:h, const String:error[], any:client)
{
	new found = SQL_GetRowCount(h);
	if(found)
	{
		new String:name[64];
		new String:name_format[64];
		GetClientName(client,name,sizeof(name));
		Format(name_format,sizeof(name_format),"%s",name);
		PrintToChatAll("onepointsix.org | We kicked %s because he is hacking.",name);
		KickClient(client, "onepointsix.org | You got kicked because u are in our hacker banlist. Please visit cheatbuster.onepointsix.org if you are not hacking.");
	}
}

public Action:MessageHandler(Handle: timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client))
	{
		PrintToChat(client, "onepointsix.org | This server is supporting our CS:CO Reporter plugin. Use sm_report in your console to report hackers.");
	}
}

public MysqlHandler(Handle:owner, Handle:h, const String:error[], any:data)
{
	if (h == INVALID_HANDLE)
	{
		PrintToServer("Failed to connect: %s", error);
	} else
	{
		PrintToServer("Mysql connected successfully with onepointsix.org.");
		db = h;
		SQL_TQuery(db, MysqlResult, "SET NAMES 'UTF8'", 0, DBPrio_High);
	}
}
 
public void OnMapEnd()
{
	if (MainMenu != INVALID_HANDLE)
	{
		delete(MainMenu);
		MainMenu = null;
	}
}
 
Menu BuildMenu()
{
	Menu menu = new Menu(HandlerReport);
	
	new String:name[64];
	new String:name_format[64];
	new String:uid[12];
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientName(i,name,sizeof(name)))
		{		
			Format(uid,sizeof(uid),"%i",i);
			Format(name_format,sizeof(name_format),"%s",name);
			menu.AddItem(uid, name_format);
		}
	}

	menu.SetTitle("Report suspicious gamer:");
 
	return menu;
 
}
public int HandlerReport(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		new String:selected[2];
		menu.GetItem(param2, selected, sizeof(selected));
		BustPlayer(StringToInt(selected),param1);
	}
}

public BustPlayer(uid,cid){
	new String:hacker_steamid[64];
	new String:client_steamid[64];
	new String:query[256];
	new String:name[64];
	
	if(uid != cid)
	{
		GetClientAuthId(uid, AuthId_SteamID64, hacker_steamid, sizeof(hacker_steamid));
		GetClientAuthId(cid, AuthId_SteamID64, client_steamid, sizeof(client_steamid));
		Format(query, sizeof(query), "insert into reportlist(reporter,hacker) values('%s',%s')", client_steamid, hacker_steamid);
		SQL_FastQuery(db, query);

		GetClientName(uid,name,sizeof(name));		
		PrintToChat(cid, "onepointsix.org | You have successfully reported %s (%s).", name, hacker_steamid);
	} else {
		PrintToChat(cid, "onepointsix.org | You can't report yourself :).");
	}
}

public MysqlResult(Handle:owner, Handle:h, const String:error[], any:data)
{
	return;
}

public Action PrintMenu(int client, int args)
{
	MainMenu = BuildMenu();
 
	MainMenu.Display(client, MENU_TIME_FOREVER);
 
	return Plugin_Handled;
}