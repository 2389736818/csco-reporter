#include <sourcemod>

Menu MainMenu = null;
new Handle:db = INVALID_HANDLE;

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
	RegConsoleCmd("report", PrintMenu);
	RegConsoleCmd("sm_report", PrintMenu);
	SQL_TConnect(MysqlHandler, "onepointsix_report_service");
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
	/* Create the menu Handle */
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