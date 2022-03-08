/* [ Includes ] */
#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <cstrike>
#include <pLogs>
#include <SteamWorks>

/* [ Compiler Options ] */
#pragma newdecls required
#pragma semicolon		1

/* [ Defines ]  */
#define LoopValidClients(%1)			for(int %1 = 1; %1 < MaxClients; %1++) if(IsValidClient(%1))
#define PLUGIN_NAME						"[CS:GO] Pawel - [ Take Vip ]"
#define PLUGIN_AUTHOR					"Paweł"
#define PLUGIN_DESC						"Vip na jendą mapę na serwery CS:GO by Pawel"
#define PLUGIN_VERSION					"1.0.0"
#define PLUGIN_URL						"[ https://steamcommunity.com/id/pawelsteam | Paweł#8244 ]"

#define CVAR_REQUIRE_STEAM_GROUP		0
#define CVAR_STEAM_GROUP_ID				1
#define CVAR_REQUIRE_NICK_PHRASE		2
#define CVAR_VIPS_NUM					3
#define CVAR_ENABLE_COMMAND_ROUND		4
#define CVAR_REMOVE_VIP_ON_DISCONNECT	5
#define CVAR_CHECK_LETTER_SIZE			6
#define MAX_CVARS_FIELDS				7

/* [ Enums ] */
enum struct Enum_CoreInfo {
	char sChatTag[64];
	char sPhrase[32];
	char sFlags[16];
	int iCvar[MAX_CVARS_FIELDS];
	bool bVipSystem;
}
enum struct Enum_ClientInfo {
	bool bVip;
}
Enum_CoreInfo g_eCore;
Enum_ClientInfo g_eInfo[MAXPLAYERS + 1];

/* [ Natives ] */
native int pVip_GetGroupIdByFlags(char[] sFlags, int iTeam = 0);
native bool pVip_SetClientGroup(int iClient, int iGroupId);

/* [ Plugin Author And Informations ] */
public Plugin myinfo = {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESC, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

/* [ Plugin Startup ] */
public void OnPluginStart() {
	/* [ Commands ] */
	RegConsoleCmd("sm_wezvip", TakeVip_Command);
	
	/* [ Events ] */
	HookEvent("round_start", Event_RoundStart);
	
	/* [ Log File ] */
	char sDate[16];
	FormatTime(sDate, sizeof(sDate), "%Y-%m-%d", GetTime());
	Logs.Create("logs/pLogs/", "pLog_", sDate);
	Logs.SetPluginName(PLUGIN_NAME);
}

/* [ Standard Actions ] */
public void OnConfigsExecuted() {
	LoadConfig();
}

public void OnMapStart() {
	LoopValidClients(i)
	g_eInfo[i].bVip = false;
}
public void OnClientPostAdminCheck(int iClient) {
	if (IsValidClient(iClient) && g_eInfo[iClient].bVip)
		GiveClientFlags(iClient);
}

public void OnClientDisconnect(int iClient) {
	if (IsValidClient(iClient)) {
		if (g_eCore.iCvar[CVAR_REMOVE_VIP_ON_DISCONNECT] && g_eInfo[iClient].bVip) {
			CPrintToChatAll("%s {lime}%N{default} własnie wyszedł z serwera. Do odebrania jest {lime}Vip{default} pod komendą {lime}!wezvip{default}.", g_eCore.sChatTag);
			g_eInfo[iClient].bVip = false;
			g_eCore.iCvar[CVAR_VIPS_NUM]++;
		}
	}
}

public void OnLibraryAdded(const char[] sName) {
	if (StrEqual(sName, "pVip-Core")) {
		g_eCore.bVipSystem = true;
		return;
	}
}

public void OnLibraryRemoved(const char[] sName) {
	if (StrEqual(sName, "pVip-Core"))g_eCore.bVipSystem = false;
}

public void OnAllPluginsLoaded() {
	g_eCore.bVipSystem = LibraryExists("pVip-Core");
}

/* [ Commands ] */
public Action TakeVip_Command(int iClient, int iArgs) {
	if (!iClient) {
		PrintToServer("Tej komendy możesz użyć tylko z poziomu gracza.");
		return Plugin_Handled;
	}
	if (GetRoundNumber() < g_eCore.iCvar[CVAR_ENABLE_COMMAND_ROUND]) {
		CPrintToChat(iClient, "%s Komenda nie została jeszcze włączona.", g_eCore.sChatTag);
		return Plugin_Handled;
	}
	if (CheckFlags(iClient, g_eCore.sFlags)) {
		CPrintToChat(iClient, "%s Nie możesz odebrać {lime}Vip'a{default}, ponieważ już go posiadasz.", g_eCore.sChatTag);
		return Plugin_Handled;
	}
	if (!g_eCore.iCvar[CVAR_VIPS_NUM]) {
		CPrintToChat(iClient, "%s Wszystkie {lime}Vip'y{default} zostały już odebrane.", g_eCore.sChatTag);
		return Plugin_Handled;
	}
	if (g_eCore.iCvar[CVAR_REQUIRE_STEAM_GROUP] && !IsGroupMember(iClient, g_eCore.iCvar[CVAR_STEAM_GROUP_ID])) {
		CPrintToChat(iClient, "%s Musisz być członkiem naszej grupy steam, aby móc odebrać {lime}Vip'a{default}.", g_eCore.sChatTag);
		return Plugin_Handled;
	}
	if (g_eCore.iCvar[CVAR_REQUIRE_NICK_PHRASE] && !CheckPhrase(iClient, g_eCore.sPhrase)) {
		CPrintToChat(iClient, "%s Musisz posiadać w nicku frazę {lime}%s{default}, aby móc odebrać {lime}Vip'a{default}.", g_eCore.sChatTag, g_eCore.sPhrase);
		return Plugin_Handled;
	}
	CPrintToChat(iClient, "%s Gratulacje! Aktywowałeś darmowego {lime}Vip'a{default} na jedną mapę.", g_eCore.sChatTag);
	if (g_eCore.iCvar[CVAR_REMOVE_VIP_ON_DISCONNECT])
		CPrintToChat(iClient, "%s Usługa będzie, aktywna dopóki nie wyjdziesz z serwera.", g_eCore.sChatTag);
	CPrintToChat(iClient, "%s Na kolejnej mapie również możesz odebrać darmowego {lime}Vip'a{default} jeżeli tylko zdążysz.", g_eCore.sChatTag);
	g_eInfo[iClient].bVip = true;
	g_eCore.iCvar[CVAR_VIPS_NUM]--;
	GiveClientFlags(iClient);
	if (g_eCore.bVipSystem) {
		int iGroupId = pVip_GetGroupIdByFlags(g_eCore.sFlags);
		if (iGroupId != -1)
			pVip_SetClientGroup(iClient, iGroupId);
	}
	CPrintToChatAll("%s {lime}%N{default} aktywował darmowego {lime}Vip'a{default} na jedną mapę ({lime}!wezvip{default}). Pozostałe {lime}Vip'y{default} do odebrania: %d.", g_eCore.sChatTag, iClient, g_eCore.iCvar[CVAR_VIPS_NUM]);
	return Plugin_Handled;
}

/* [ Events ] */
public Action Event_RoundStart(Event eEvent, const char[] sName, bool bDontBroadcast) {
	if (IsWarmup())return;
	if (GetRoundNumber() == g_eCore.iCvar[CVAR_ENABLE_COMMAND_ROUND]) {
		CPrintToChatAll("--------------------------------------------------------------------");
		CPrintToChatAll("%s Odbierz darmowego {lime}Vip'a{default}! Wpisz {lime}!wezvip{default}.", g_eCore.sChatTag);
		CPrintToChatAll("%s Pozostałe {lime}Vip'y{default} do odebrania: %d.", g_eCore.sChatTag, g_eCore.iCvar[CVAR_VIPS_NUM]);
		CPrintToChatAll("--------------------------------------------------------------------");
		CreateTimer(15.0, Timer_GiveFlags, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

/* [ Timers ] */
public Action Timer_GiveFlags(Handle hTimer) {
	LoopValidClients(i) {
		if (g_eInfo[i].bVip) {
			if (CheckStatus(i))GiveClientFlags(i);
			else {
				g_eCore.iCvar[CVAR_VIPS_NUM]++;
				g_eInfo[i].bVip = false;
				CPrintToChatAll("%s {lime}%N{default} chciał oszukać system i stracił darmowego {lime}Vip'a{default}. Do odebrania jest {lime}Vip{default} pod komendą {lime}!wezvip{default}.", g_eCore.sChatTag, i);
				if (g_eCore.bVipSystem)
					pVip_SetClientGroup(i, 0);
				RemoveClientFlags(i);
			}
		}
	}
	CreateTimer(15.0, Timer_GiveFlags, _, TIMER_FLAG_NO_MAPCHANGE);
}

/* [ Helpers ] */
bool CheckFlags(int iClient, char[] sFlags) {
	if (StrEqual(sFlags, ""))return true;
	if (GetUserFlagBits(iClient) & ADMFLAG_ROOT)return true;
	int iCount = CountCharacters(sFlags);
	int iAccess = 0;
	char sFlag[16];
	for (int i = 0; i < iCount; i++) {
		Format(sFlag, sizeof(sFlag), "%c", sFlags[i]);
		if (GetUserFlagBits(iClient) & ReadFlagString(sFlag))
			iAccess++;
	}
	if (iAccess == iCount)
		return true;
	if (GetUserFlagBits(iClient) & ReadFlagString(sFlags))return true;
	if (StrEqual(sFlags, ""))return true;
	return false;
}

int CountCharacters(char[] sPhrase) {
	int iCharacters = 0;
	for (int i = 0; i < strlen(sPhrase); i++)
	iCharacters++;
	return iCharacters;
}

bool CheckPhrase(int iClient, char[] sPhrase) {
	char sName[MAX_NAME_LENGTH];
	GetClientName(iClient, sName, sizeof(sName));
	if (StrContains(sName, sPhrase, g_eCore.iCvar[CVAR_CHECK_LETTER_SIZE] ? true:false) != -1)
		return true;
	return false;
}

int GetRoundNumber() {
	int iRound = (GetTeamScore(CS_TEAM_CT) + GetTeamScore(CS_TEAM_T) + 1);
	if (iRound < 16)
		return iRound;
	if (iRound > 15 && iRound < 31)
		return iRound - 15;
	if (iRound > 30)
		return iRound - 30;
	return 0;
}

bool IsGroupMember(int iClient, int iGroupId) {
	return SteamWorks_GetUserGroupStatus(iClient, iGroupId);
}

void GiveClientFlags(int iClient) {
	AdminFlag afFlag;
	for (int i = 0; i < sizeof(g_eCore.sFlags); i++) {
		BitToFlag(ReadFlagString(g_eCore.sFlags[i]), afFlag);
		AddUserFlags(iClient, afFlag);
	}
}

void RemoveClientFlags(int iClient) {
	AdminFlag afFlag;
	for (int i = 0; i < sizeof(g_eCore.sFlags); i++) {
		BitToFlag(ReadFlagString(g_eCore.sFlags[i]), afFlag);
		RemoveUserFlags(iClient, afFlag);
	}
}

bool CheckStatus(int iClient) {
	if (g_eCore.iCvar[CVAR_REQUIRE_STEAM_GROUP] && !IsGroupMember(iClient, g_eCore.iCvar[CVAR_STEAM_GROUP_ID])) {
		CPrintToChat(iClient, "%s {lightred}Wykryto brak członkostwa w grupie steam...{default}.", g_eCore.sChatTag);
		CPrintToChat(iClient, "%s Darmowy {lime}Vip{default} zostaje usunięty...", g_eCore.sChatTag);
		return false;
	}
	if (g_eCore.iCvar[CVAR_REQUIRE_NICK_PHRASE] && !CheckPhrase(iClient, g_eCore.sPhrase)) {
		CPrintToChat(iClient, "%s {lightred}Wykryto brak frazy w nicku...", g_eCore.sChatTag);
		CPrintToChat(iClient, "%s Darmowy {lime}Vip{default} zostaje usunięty...", g_eCore.sChatTag);
		return false;
	}
	return true;
}

bool IsValidClient(int iClient, bool bForceAlive = false) {
	if (iClient <= 0)return false;
	if (iClient > MaxClients)return false;
	if (!IsClientConnected(iClient))return false;
	if (IsFakeClient(iClient))return false;
	if (IsClientSourceTV(iClient))return false;
	if (!IsClientInGame(iClient))return false;
	if (bForceAlive && !IsPlayerAlive(iClient))return false;
	return true;
}

void LoadConfig() {
	KeyValues kvKeyValues = new KeyValues("Pawel Take Vip - Config");
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/pPlugins/pTakeVip.cfg");
	if (!kvKeyValues.ImportFromFile(sPath)) {
		if (!FileExists(sPath)) {
			if (GenerateConfig())LoadConfig();
			else Logs.Critical("Nie udało się utworzyć pliku konfiguracyjnego.");
			delete kvKeyValues;
			return;
		}
		else {
			Logs.Critical("Aktualny plik konfiguracyjny jest uszkodzony! Trwa tworzenie nowego...");
			if (GenerateConfig())LoadConfig();
			else Logs.Critical("Nie udało się utworzyć pliku konfiguracyjnego.");
			delete kvKeyValues;
			return;
		}
	}
	if (kvKeyValues.JumpToKey("Ustawienia")) {
		g_eCore.iCvar[CVAR_REQUIRE_STEAM_GROUP] = kvKeyValues.GetNum("Require_Steam_Group", 0);
		g_eCore.iCvar[CVAR_STEAM_GROUP_ID] = kvKeyValues.GetNum("Steam_Group_Id", 0);
		g_eCore.iCvar[CVAR_REQUIRE_NICK_PHRASE] = kvKeyValues.GetNum("Require_Nick_Phrase", 1);
		g_eCore.iCvar[CVAR_VIPS_NUM] = kvKeyValues.GetNum("Vips_Num", 3);
		g_eCore.iCvar[CVAR_ENABLE_COMMAND_ROUND] = kvKeyValues.GetNum("Enable_Command_Round", 2);
		g_eCore.iCvar[CVAR_REMOVE_VIP_ON_DISCONNECT] = kvKeyValues.GetNum("Remove_Vip_On_Disconenct", 1);
		g_eCore.iCvar[CVAR_CHECK_LETTER_SIZE] = kvKeyValues.GetNum("Check_Letters_Size", 1);
		kvKeyValues.GetString("Flags", g_eCore.sFlags, sizeof(g_eCore.sFlags));
		kvKeyValues.GetString("Phrase", g_eCore.sPhrase, sizeof(g_eCore.sPhrase));
		kvKeyValues.GetString("Chat_Tag", g_eCore.sChatTag, sizeof(g_eCore.sChatTag));
		kvKeyValues.GoBack();
	}
	delete kvKeyValues;
}

bool GenerateConfig() {
	KeyValues kvKeyValues = new KeyValues("Pawel Take Vip - Config");
	char sPath[PLATFORM_MAX_PATH];
	char sDirectory[PLATFORM_MAX_PATH] = "configs/pPlugins/";
	BuildPath(Path_SM, sPath, sizeof(sPath), sDirectory);
	if (!DirExists(sPath)) {
		CreateDirectory(sPath, 504);
		if (!DirExists(sPath))
			Logs.Critical("Nie udało się utworzyć katalogu /sourcemod/configs/pPlugins/ . Proszę to zrobić ręcznie.");
	}
	BuildPath(Path_SM, sPath, sizeof(sPath), "%spTakeVip.cfg", sDirectory);
	if (kvKeyValues.JumpToKey("Ustawienia", true)) {
		kvKeyValues.SetString("Flags", "ot");
		kvKeyValues.SetString("Require_Steam_Group", "0");
		kvKeyValues.SetString("Steam_Group_Id", "0");
		kvKeyValues.SetString("Require_Nick_Phrase", "1");
		kvKeyValues.SetString("Vips_Num", "3");
		kvKeyValues.SetString("Enable_Command_Round", "1");
		kvKeyValues.SetString("Remove_Vip_On_Disconenct", "1");
		kvKeyValues.SetString("Check_Letters_Size", "1");
		kvKeyValues.SetString("Chat_Tag", "{orange}PluginyCS.pl {grey}»{default}");
		kvKeyValues.SetString("Phrase", "PluginyCs.pl");
		kvKeyValues.GoBack();
	}
	kvKeyValues.Rewind();
	bool bResult = kvKeyValues.ExportToFile(sPath);
	delete kvKeyValues;
	return bResult;
}

bool IsWarmup() {
	int iWarmup = GameRules_GetProp("m_bWarmupPeriod", 4, 0);
	if (iWarmup == 1)return true;
	else return false;
} 