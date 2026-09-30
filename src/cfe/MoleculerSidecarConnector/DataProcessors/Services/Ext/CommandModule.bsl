////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Command module of the services data processor.

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