#define NORMAL_LOG		0
#define ERROR_LOG		1
#define CRITICAL_LOG	2

char g_sLogFile[PLATFORM_MAX_PATH];
char g_sPluginName[128];
char g_sBuffer[512];

methodmap Logs {
	public static void Create(char[] sDirectory, char[] sFilePrefix, char[] sFileName) {
		char sLogPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sLogPath, sizeof(sLogPath), sDirectory);
		if (!DirExists(sLogPath)) {
			CreateDirectory(sLogPath, 504);
			if (!DirExists(sLogPath))
				SetFailState("Nie udało się utworzyć katalogu /sourcemod/%s . Proszę to zrobić ręcznie.", sDirectory);
		}
		BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "%s%s%s.log", sDirectory, sFilePrefix, sFileName);
		strcopy(g_sLogFile, sizeof(g_sLogFile), sLogPath);
		PrintToServer("[ pLogs ] Plik oraz ścieżka zostały pomyślnie utworzone. (%s%s%s).", sDirectory, sFilePrefix, sFileName);
	}
	public static void SetPluginName(char[] sName) {
		strcopy(g_sPluginName, sizeof(g_sPluginName), sName);
	}
	public static void Normal(char[] sMessage, any:...) {
		VFormat(g_sBuffer, sizeof(g_sBuffer), sMessage, 2);
		WriteLog(NORMAL_LOG, g_sBuffer);
		PrintToServer(g_sBuffer);
	}
	public static void Error(char[] sMessage, any:...) {
		VFormat(g_sBuffer, sizeof(g_sBuffer), sMessage, 2);
		WriteLog(ERROR_LOG, g_sBuffer);
		LogError(g_sBuffer);
	}
	public static void Critical(char[] sMessage, any:...) {
		VFormat(g_sBuffer, sizeof(g_sBuffer), sMessage, 2);
		WriteLog(CRITICAL_LOG, g_sBuffer);
		SetFailState("[ %s [OFF] ] %s", g_sPluginName, g_sBuffer);
	}
}

stock void WriteLog(int iLogType, char[] sMessage) {
	char sMap[128], sTime[64], sBuffer[1024], sPrefix[64];
	switch (iLogType) {
		case NORMAL_LOG:sPrefix = "";
		case ERROR_LOG:sPrefix = "[ BŁĄD ] ";
		case CRITICAL_LOG:sPrefix = "[ BŁĄD KRYTYCZNY ]";
	}
	int iTime = GetTime();
	GetCurrentMap(sMap, sizeof(sMap));
	FormatTime(sTime, sizeof(sTime), "%H:%M:%S", iTime);
	File fFile = OpenFile(g_sLogFile, "a");
	Format(sBuffer, sizeof(sBuffer), "%s[ %s ~ %s ] (%s) %s", sPrefix, sMap, sTime, g_sPluginName, sMessage);
	fFile.WriteLine(sBuffer);
	delete fFile;
}

