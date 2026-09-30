////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Managed application module: starts and stops the connector's services.

&After("OnStart")
&После("ПриНачалеРаботыСистемы")
Procedure mol_OnStart()
	
	ShouldRelaunch = mol_Server.OnStart(LaunchParameter);	
	If ShouldRelaunch Then
		mol_Client.RestartSessionAfterAddingRoles();
	EndIf;
	
EndProcedure
