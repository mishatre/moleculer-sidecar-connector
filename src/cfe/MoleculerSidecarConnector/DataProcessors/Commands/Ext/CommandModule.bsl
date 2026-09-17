
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure();
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.Configuration", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		"DataProcessor.mol_AdminPanel.Form.Configuration" + ?(CommandExecuteParameters.Window = Undefined, ".SeparateWindow", ""), 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL
	);
EndProcedure

#EndRegion