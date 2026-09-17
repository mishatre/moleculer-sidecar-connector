
&After("OnStart")
&После("ПриНачалеРаботыСистемы")
Procedure mol_OnStart()
	
	ShouldRelaunch = mol_Server.OnStart(LaunchParameter);
	
	If ShouldRelaunch Then
		mol_Client.RestartSessionAfterAddingRoles();
	EndIf;
	
EndProcedure
                                                                    