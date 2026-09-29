
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure();
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.ConfigurationForm", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		"DataProcessor.mol_AdminPanel.Form.ConfigurationForm" + ?(CommandExecuteParameters.Window = Undefined, ".SeparateWindow", ""), 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL
	);
EndProcedure

#EndRegion