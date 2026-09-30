////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// HTTP service that receives Moleculer packets from the sidecar.

Function GatewayPOST(Request)       
	Return mol_Transport.Transporter_HTTP_Receive(Request);
EndFunction
