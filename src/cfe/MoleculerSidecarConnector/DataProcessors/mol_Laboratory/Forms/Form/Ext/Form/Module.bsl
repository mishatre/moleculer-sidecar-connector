////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Laboratory form for experimenting with service schemas.

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Params = New Structure();
	Params.Insert("withServices", True);
	Response = Moleculer.Call("$node.list", Params);
	
EndProcedure
