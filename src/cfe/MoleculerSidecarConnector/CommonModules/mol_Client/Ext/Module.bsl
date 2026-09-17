 
#Region Protected
 
Procedure RestartSessionAfterAddingRoles() Export
	
	Config = MoleculerClientServer.GetConfig();
	
	Title = Config.Caption;
	Text  = NStr(
		"ru = 'Перезапускаем сеанс после авто добавления роли!'; 
		|en = 'Restart the session after auto adding the role!'"
	);
	#If ThickClientOrdinaryApplication Then
		DoMessageBox(Text, 2, Title);
	#Else
		ShowUserNotification(Title,, Text);
	#EndIf
	
	LaunchParameterString = StrTemplate(" /C""%1;%2"" /DEBUG ",
		LaunchParameter,
		Config.LaunchParameters.SkipRolesCheck
	); // Защита от циклического перезапуска в БСП 3.1.6+ https://www.hostedredmine.com/issues/955636
	Exit(False, True, LaunchParameterString);

EndProcedure

#EndRegion