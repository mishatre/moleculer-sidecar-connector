////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Publication list form.

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	AttachIdleHandler("UpdatePublicationsStatusInfo", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterPublications(Command)
	RegisterPublicationsAtServer()	
EndProcedure

&AtClient
Procedure UnregisterPublications(Command)
	UnregisterPublicationsAtServer();
EndProcedure

#EndRegion 

#Region Private 

#Region IdleHandlers

&AtClient
Procedure UpdatePublicationsStatusInfo() Export
		
EndProcedure

#EndRegion

&AtServer
Procedure RegisterPublicationsAtServer()
	
	mol_Broker.RegisterPublications();
	
EndProcedure

&AtServer
Procedure UnregisterPublicationsAtServer()
	
	mol_Broker.UnregisterPublications();
	
EndProcedure

#EndRegion


