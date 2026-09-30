////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// HTTP transport that carries Moleculer packets to and from the sidecar.

#Region Protected

Function ExecuteRequest(Context, Connection = Undefined) Export
	
	Payload = mol_ContextFactory.ToPayload(Context);	
	Packet = ToPacket(Payload, Context);
	
	Response = Send(Packet, Connection);
	If mol_Helpers.IsErrorResponse(Response) Then 
		mol_Errors.RaiseError(Response.Error);
	EndIf; 
	
	Packet = Response.Result;
	Context.NodeID = Packet.Sender;
	For Each KeyValue In Packet.Meta Do
		Context.Meta[KeyValue.Key] = KeyValue.Value;
	EndDo;   
	
	If Packet.Stream <> False Then
		Return Packet.Stream;
	EndIf;
	
	Return Packet.Data;
	
EndFunction

#Region Transporters 

#Region HTTP

Function Transporter_HTTP_Receive(HTTPServiceRequest) Export
	
	Packet  = GetPacketFromRequestResponseBody(HTTPServiceRequest);
	Context = mol_ContextFactory.FromPayload(Packet.Data);
	
	If Packet.Stream <> False Then
		Context.Stream = Packet.Stream;
	EndIf; 
	
	Return RequestHandler(Context);	
			
EndFunction

#EndRegion

#EndRegion

#EndRegion 

#Region Private

Function This()
	Return mol_Transport;	
EndFunction

Function ThisMetadata()
	Return Metadata.CommonModules.mol_Transport;	
EndFunction  

#Region Constructors

Function NewPacket()

	Result = New Structure();
	Result.Insert("sender", mol_Broker.NodeID());
	Result.Insert("meta"  , New Map());
	Result.Insert("data"  , Undefined);
	Result.Insert("stream", False);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Transporters 

Function Send(Packet, Val Connections = Undefined)
	
	If Connections = Undefined Then
		Connections = Moleculer.GetConnections();	
	Else       
		Connections = mol_Helpers.EnsureArray(Connections);	
	EndIf; 
	
	If Connections.Count() = 0 Then
		Message = NStr("
		|	ru = 'Нет доступных подключений к sidecar. Невозможно отправить запрос';
		|	en = 'No available sidecar connections. Cannot send request.';");
		Error   = mol_Errors.RequestRejected(Message);
		mol_Logger.Error("Send", mol_Errors.ToString(Error), , ThisMetadata());
		mol_Errors.RaiseError(Error);	
	EndIf;         
	
	LastConnection = Undefined;
	LastErrorInfo  = Undefined;

	For Each Connection In Connections Do
		LastConnection = Connection;
		Template = NStr("
		|	ru = 'Попытка подключения через соединение ""%1"" (%2:%3)';
		|	en = 'Trying connection ""%1"" (%2:%3)';");
		Message = StrTemplate(Template, 
			Connection.Id, 
			Connection.Description, 
			Connection.Type
		);
		mol_Logger.Debug("Send", Message, , ThisMetadata());
		Try
			If Connection.Type = "HTTP" Then
				SetSafeModeDisabled(True);
				Response = Transporter_HTTP_Send(Connection, Packet);
				SetSafeModeDisabled(False);
				Return Response;
			Else                                         
				Template = NStr("
				|	ru = 'Неподдерживаемый тип соединения ""%1""';
				|	en = 'Unsupported connection type ""%1""';");
				Message = StrTemplate(Template, Connection.Type); 
				mol_Errors.RaiseCustomError("ValidationError", Message);
			EndIf;
		Except   
			SetSafeModeDisabled(False);
			LastErrorInfo = mol_Errors.GetCurrentError();
			If LastErrorInfo = Undefined Then
				// Unhandled error
				LastErrorInfo = mol_Errors.FromErrorInfo(ErrorInfo());	
			EndIf;
			Template = NStr("
			|	ru = 'Не удалось отправить запрос через соединение ""%1"" (%2:%3).
			|Ошибка: %3';
			|	en = 'Failed to send request through connection ""%1"" (%2:%3).
			|Error: %3';");
			Message = StrTemplate(Template, 
				Connection.Id, 
				Connection.Description, 
				Connection.Type
			);
			mol_Logger.Debug("Send", Message, , ThisMetadata());	
		EndTry;
	EndDo;
	
	Template = NStr("
	|	ru = 'Все попытки подключения завершились с ошибками. Невозможно отправить запрос.
	|Последнее соединение: ""%1"" (%2:%3).
	|Последняя ошибка: %4
	|
	|%5';
	|	en = 'All available connection failed. Cannot send request.
	|Last connection: ""%1"" (%2:%3).
	|Last error: %4
	|
	|%5';");
	Message = StrTemplate(Template, 
		Connection.Id, 
		Connection.Description, 
		Connection.Type,
		LastErrorInfo.Message,
		mol_Errors.ToString(LastErrorInfo)
	);
	mol_Logger.Error("Send", Message, , ThisMetadata()); 
	mol_Errors.RaiseError(LastErrorInfo);
	
EndFunction  

#Region HTTP

// Assembles everything the transport is about to send: the body from the packet, the header set
// including the signed subset, and the timeout the connection is cached with. Split out of
// Transporter_HTTP_Send so the header set can be asserted while no sidecar runs, because a test cannot
// otherwise see what the transport puts on the wire.
Function PrepareHTTPRequest(Connection, Packet, Val Headers = Undefined) Export 
	
	HTTPRequest = New HTTPRequest();	
	PackingResult = SetPacketAsRequestResponseBody(HTTPRequest, Packet);
		
	If Not mol_Helpers.IsMap(Headers) Then
		Headers = New Map();
	EndIf;
	
	Headers.Insert("content-type"  , PackingResult.ContentType);
	Headers.Insert("content-length", Format(PackingResult.Size, "NG="));
	
	RequestParameters = mol_Helpers.NewRequestParameters(); 
	RequestParameters.Endpoint = Connection.Endpoint;
	RequestParameters.Port     = Connection.Port;
	RequestParameters.UseSSL   = Connection.UseSSL;
	RequestParameters.Headers  = Headers;
	RequestParameters.Method   = "POST";
	RequestParameters.Path     = "/sidecar";
	RequestParameters.Query    = "";                    
	
	Options = mol_Helpers.NewRequestOptions(RequestParameters);
	
	#Region AuthHeader
	
	Region      = "main";
	ServiceName = "moleculer";
	
	Date = CurrentUniversalDate(); 
	Options.Headers.Insert("x-amz-date"          , mol_Helpers.MakeDateLong(date));
	Options.Headers.Insert("x-amz-content-sha256", PackingResult.Sha256Sum);
	AuthorizationHeader = mol_Helpers.SignV4(
		Options, 
		Connection.AccessKey, 
		Connection.SecretKey, 
		Region, 
		Date, 
		PackingResult.Sha256Sum,
		ServiceName
	);      
	Options.Headers.Insert("authorization", AuthorizationHeader); 
	
	#EndRegion 
	
	HTTPRequest.ResourceAddress = Options.Path;
	HTTPRequest.Headers         = Options.Headers; 
	
	Timeout = 120;
	If mol_Helpers.Has(Packet.Data, "Timeout") And Packet.Data.Timeout <> Undefined Then
		// Moleculer track timeout in ms but HTTPConnection in seconds
		Timeout = Packet.Data.Timeout / 1000
	EndIf;  
	
	Result = New Structure("Request, Timeout");
	Result.Request = HTTPRequest;
	Result.Timeout = Timeout;
	
	Return Result;
	
EndFunction

Function Transporter_HTTP_Send(Connection, Packet, Val Headers = Undefined) 
	
	Prepared = PrepareHTTPRequest(Connection, Packet, Headers);
	
	HTTPConnection = mol_Helpers.GetCachedHTTPConnection(Connection, Prepared.Timeout);
	
	Response = Undefined;
	Try
		Response = HTTPConnection.Post(Prepared.Request);
	Except                                
		mol_Errors.RaiseError(ErrorInfo());
	EndTry;
	
	Packet = GetPacketFromRequestResponseBody(Response);	
	Return ResponseFromStatus(Response.StatusCode, Packet);     
	
EndFunction

// Turns a decoded response body into the response the caller sees. Split out of Transporter_HTTP_Send so
// the non-2xx branch can be asserted from a fixture rather than from a live sidecar: a failed call
// answers with a bare error object instead of a packet, and that shape is worth pinning.
Function ResponseFromStatus(StatusCode, Packet) Export
	
	If StatusCode <> 200 Then 
		Error = mol_Errors.RegenerateError(Packet);
		Return mol_Helpers.NewResponse(Error, Undefined);		
	EndIf;
	
	If Not Packet.Property("Data") Then
		Packet.Insert("data");
	EndIf;
	
	Return mol_Helpers.NewResponse(Undefined, Packet);     
	
EndFunction

Function SetPacketAsRequestResponseBody(HTTPRequestResponse, Val Packet) Export
	
	Stream = Undefined;
	If Packet.Stream <> False Then 
		Stream = Packet.Stream;
		Packet.Stream = True;
	EndIf; 
	
	PacketPayload = mol_Helpers.ToJSONString(Packet);
	
	If Packet.Stream Then 
		
		PacketFormField = mol_Helpers.FormField("packet", 
			PacketPayload, 
			mol_Helpers.NewFormFieldOpts("packet", "application/json")
		);
		StreamFormField = mol_Helpers.FormField("stream", 
			Stream, 
			mol_Helpers.NewFormFieldOpts("stream", "application/octet-stream")
		);
		
		Parts = New Array();
		Parts.Add(PacketFormField);
		Parts.Add(StreamFormField);
		
		Return mol_Helpers.EncodeMultipartData(HTTPRequestResponse.GetBodyAsStream(), Parts);	
 
	EndIf; 
	
	Result = New Structure();
	Result.Insert("ContentType");
	Result.Insert("Sha256Sum");
	Result.Insert("Size");

	Body = GetBinaryDataFromString(PacketPayload, TextEncoding.UTF8, False);	
	mol_Helpers.SetRequestResponseBody(HTTPRequestResponse, Body);
	
	Result.Size        = Body.Size();
	Result.Sha256Sum   = mol_Helpers.ToSha256(Body);
	Result.ContentType = "application/json";

	Return Result;	
	
EndFunction

Function GetPacketFromRequestResponseBody(HTTPRequestResponse)
	
	Packet = Undefined;

	// TODO: Parse media types independently of parameters such as charset and boundary.
	ContentType = mol_Helpers.ParseHeader(HTTPRequestResponse.Headers, "Content-Type");
	If ContentType.Value = "application/json" Then
		Packet = FromJSONPacketBody(HTTPRequestResponse.GetBodyAsString());
	ElsIf ContentType.Value = "multipart/form-data" Then 		
		Data = mol_Helpers.DecodeMultipartData(
			HTTPRequestResponse.GetBodyAsStream(), 
			HTTPRequestResponse.Headers                              
		);
		Packet = FromMultipartPacketBody(Data);
	Else               
		Message = NStr("
		|	ru = 'Неккоректно сформированный запрос/ответ';
		|	en = 'Malformed request/response';");
		mol_Errors.RaiseCustomError("InvalidPacketData", Message);
	EndIf;          
	
	Return Packet;
	
EndFunction

#EndRegion

#EndRegion

#Region Handlers

Function RequestHandler(Context)
		
	// The action name, guarded the same way mol_ContextFactory.Handler guards it: an inbound packet that
	// carries no action at all leaves Context.Action undefined, and reading a name off it would raise where
	// the original string comparison simply answered false.
	If Context.Action <> Undefined Then
		If StrStartsWith(Context.Action.Name, "$internal") Then
			Handler = mol_Broker.Delete_FindInternalHandler(Context.Action.Name);
			If Handler <> Undefined Then
				Context.Locals.Insert("handler", Handler);
			EndIf;
		EndIf;
	EndIf;
	
	If Not mol_Helpers.Has(Context.Locals, "Handler") Then
		Error = mol_Errors.RequestRejected("Handler is not provided");
		Return SendError(Error);
	EndIf;
	
	Response = Context.This.Handler(Context);
	If mol_Helpers.IsErrorResponse(Response) Then
		If mol_Helpers.IsStream(Context.Stream) Then
			Context.Stream.Close();		
		EndIf;
		Return SendError(Response.Error);
	EndIf;
	
	Data = Response.Result;      
	
	IsStream = mol_Helpers.IsStream(Data) Or mol_Helpers.IsBinaryData(Data);
	
	Packet = NewPacket();
	Packet.Meta   = Context.Meta;
	Packet.Data   = ?(IsStream, Undefined, Data );
	Packet.Stream = ?(IsStream, Data     , False);
		
	ServiceResponse = New HTTPServiceResponse(200);
	PackingResult = SetPacketAsRequestResponseBody(ServiceResponse, Packet);
	                                          
	ServiceResponse.Headers.Insert("content-type", PackingResult.ContentType);
	
	If mol_Helpers.IsStream(Context.Stream) Then
		Context.Stream.Close();		
	EndIf;
	
	Return ServiceResponse;
	
EndFunction

#EndRegion

Function SendError(Error)
	
	If Error = Undefined Then
		Return New HTTPServiceResponse(500, "Internal Server Error");
	EndIf;
	
	Headers = New Map();
	Headers.Insert("Content-Type", "application/json; charset=utf-8");
	
	Code = ?(mol_Helpers.IsNumber(Error.Code), // && _.inRange(error.code, 400, 599),
		Error.Code, 500);  
    Payload = mol_Helpers.ToJSONString(Error);
	
	Response = New HTTPServiceResponse(Code, , Headers);
	
	mol_Helpers.SetRequestResponseBody(Response, Payload);
		
	Return Response;
	
EndFunction

Function ToPacket(Payload, Context) Export
	
	Result = NewPacket();
	
	IsStream = mol_Helpers.IsStream(Context.Options.Stream) Or mol_Helpers.IsBinaryData(Context.Options.Stream);
	Result.meta   = mol_Helpers.Get(Payload, "Meta", New Map());
	Result.data   = Payload;
	Result.stream = ?(IsStream, Context.Options.Stream, False);
	
	Return Result;
	
EndFunction

// Decodes the two body shapes the transport accepts. Exported because these are the only halves of the
// wire contract a test can reach without a sidecar: a JSON body is a string, and the multipart data is
// what DecodeMultipartData returns, so neither needs an HTTP request object.
//
// The JSON shape matters beyond packets: a failed call answers with a bare error object, with no packet
// wrapper, and mol_Errors.RegenerateError is what turns that back into an error.
Function FromJSONPacketBody(Body) Export
	
	Return mol_Helpers.FromJSONString(Body);
	
EndFunction

Function FromMultipartPacketBody(MultipartData) Export
	
	Packet        = mol_Helpers.FromJSONStream(MultipartData.Files.Get("packet"));
	Packet.Stream = MultipartData.Files.Get("stream");
	
	Return Packet;
	
EndFunction

#EndRegion







