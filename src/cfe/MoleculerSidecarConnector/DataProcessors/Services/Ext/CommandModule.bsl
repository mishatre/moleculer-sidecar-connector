
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FormParameters = New Structure();
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.ServiceListForm", 
		FormParameters, 
		CommandExecuteParameters.Source, 
		"DataProcessor.mol_AdminPanel.Form.ServiceListForm" + ?(CommandExecuteParameters.Window = Undefined, ".SeparateWindow", ""), 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL
	);
EndProcedure

#EndRegion