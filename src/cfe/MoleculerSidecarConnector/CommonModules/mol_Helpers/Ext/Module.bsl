////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Server helpers for HTTP, JSON and payload handling.

#Region Public

#Region Constructors 

#Region Request

Function NewRequestParameters() Export

	Result = New Structure();    
	Result.Insert("method"    , Undefined);
	Result.Insert("path"      , Undefined);
	Result.Insert("headers"   , Undefined);
	Result.Insert("query"     , Undefined);
	Result.Insert("useSSL"    , Undefined);
	Result.Insert("endpoint"  , Undefined);
	Result.Insert("port"      , Undefined);
	Result.Insert("timeout"   , Undefined);
		
	Return Result;
	
EndFunction

Function NewRequestOptions(Val Options) Export
	
	Method     = Options.Method;    
	Headers    = Options.Headers;
    Query      = Options.Query; 
	Protocol   = ?(Options.UseSSL, "https:", "http:");
			
	ReqOptions = New Structure();
	ReqOptions.Insert("method"  , Method  );
	ReqOptions.Insert("headers" , New Map );
	ReqOptions.Insert("protocol", Protocol);     
	
	Host = Options.Endpoint;
	Path = Options.Path;
	
	If StrFind(Host, "/") Then
		HostParts = StrSplit(Host, "/"); 
		Host = HostParts[0];  
		If StrEndsWith(HostParts[1], "/") Then
			HostParts[1] = Left(HostParts[1], StrLen(HostParts[1]) - 1);
		EndIf; 
		If Not StrStartsWith(Path, "/") Then
			Path = "/" + Path;
		EndIf;
		Path = "/" + HostParts[1] + Path;
	EndIf;
	
	Port = Undefined;
	If ValueIsFilled(Options.Port) Then
		Port = Options.Port;
	EndIf;
	
	If ValueIsFilled(Query) Then
		Path = StrTemplate("%1?%2", Path, Query);
	EndIf;
	ReqOptions.Headers.Insert("host", Host);	
	If (ReqOptions.Protocol = "http:" And Port <> 80) Or (ReqOptions.Protocol = "https:" And Port <> 443) Then
		ReqOptions.Headers["host"] = StrTemplate("%1:%2", Host, Format(Port, "NG="));
	EndIf;
	
	//ReqOptions.Headers.Insert("user-agent", "1C");
	If Headers <> Undefined Then
		// have all header keys in lower case - to make signing easy
		For Each KeyValue In Headers Do
			ReqOptions.Headers.Insert(Lower(KeyValue.Key), KeyValue.Value);
		EndDo;
	EndIf;
	
	ReqOptions.Insert("Host", Host);
	ReqOptions.Insert("Port", Port);
	ReqOptions.Insert("Path", Path);
	
	Return ReqOptions;
	
EndFunction

#EndRegion

#Region Response

Function NewResponse(Error = Undefined, Result = Undefined) Export
	Response = New Structure();
	Response.Insert("Error" , Error );
	Response.Insert("Result", Result);
	Return Response;
EndFunction 

Function IsErrorResponse(Response) Export
	Return True 
		And IsStructure(Response) 
		And Response.Property("Error")
		And Response.Error <> Undefined;	
EndFunction
                      	
#EndRegion

#EndRegion

#Region HTTPConnection

Function GetCachedHTTPConnection(Options, Timeout) Export
	
	Cache = Undefined;
	If Options.Id <> Undefined Then
		Cache = mol_Reuse.GetHTTPConnectionCache();
		If Has(Cache, Options.Id) Then
			If Cache[Options.Id].Timeout = Timeout Then 
				Return Cache[Options.Id];
			Else     
				Cache.Delete(Options.Id);
			EndIf;
		EndIf;
	EndIf;
	
	ProxyServer = Undefined;
	If Options.Proxy <> Undefined Then
		ProxyInfo = Options.Proxy;
		ProxyServer = New InternetProxy(False);	   
		ProxyServer.Set(
			ProxyInfo.Protocol,
			ProxyInfo.Server,
			ProxyInfo.Port,
			ProxyInfo.User,
			ProxyInfo.Password
		);	
	EndIf;
	
	SecureConnection = Undefined;
	If Options.UseSSL Then
		SecureConnection = New OpenSSLSecureConnection(); 
	EndIf;  
	
	Endpoint = Options.Endpoint;
	If StrFind(Endpoint, "/") Then
		EndopointParts = StrSplit(Endpoint, "/"); 
		Endpoint = EndopointParts[0];
	EndIf;    
	
	HTTPConnection = New HTTPConnection(
		Endpoint,
		Options.Port,
		, // User
		, // Password
		ProxyServer,
		?(Timeout = Undefined, 120, Timeout),
		SecureConnection
	);     
	
	If Options.Id <> Undefined Then
		Cache.Insert(Options.Id, HTTPConnection);	
	EndIf;
	
	Return HTTPConnection;
	
EndFunction

#EndRegion

#Region AWSSigningV4

// Returns the authorization header
//
// Parameters: 
// Request     - HTTPQuery - HTTP Request
// AccessKey   - String - Access key
// SecretKey   - String - Secret key
// Region      - String - Region
// RequestDate - Date   - Request date    
// Sha256sum   - String - Sha256sum
// ServiceName - String - Service name (optional, default = "")
// 
// Returns - String - Authorization header value
Function SignV4(Request, AccessKey, SecretKey, Region, RequestDate, Sha256sum, ServiceName = "") Export
	
	If Not IsObject(Request) Then
		mol_Errors.RaiseTypeError("Request", Request, Type("Structure"));	
	EndIf;
	
	If Not IsString(AccessKey) Then
		mol_Errors.RaiseTypeError("AccessKey", AccessKey, Type("String"));	
	EndIf;
	
	If Not IsString(SecretKey) Then
		mol_Errors.RaiseTypeError("SecretKey", SecretKey, Type("String"));	
	EndIf;
	
	If Not IsString(Region) Then
		mol_Errors.RaiseTypeError("Region", Region, Type("String"));	
	EndIf;
	
	If AccessKey = "" Then   
		Message = NStr("
		|	ru = 'AccessKey обязателен для заполнения при создании подписи';
		|	en = 'AccessKey is required for signing';");
		mol_Errors.RaiseCustomError("AccessKeyRequired", Message);
	EndIf;
	
	If SecretKey = "" Then         
		Message = NStr("
		|	ru = 'SecretKey обязателен для заполнения при создании подписи';
		|	en = 'SecretKey is required for signing';");
		mol_Errors.RaiseCustomError("SecretKeyRequired", Message);
	EndIf;
	
  	SignedHeaders     = GetSignedHeaders(Request.Headers);
  	CanonicalRequest  = GetCanonicalRequest(Request.Method, Request.Path, Request.Headers, SignedHeaders, Sha256sum);
	ServiceIdentifier = ?(ValueIsFilled(ServiceName), ServiceName, "s3");
  	StringToSign      = GetStringToSign(CanonicalRequest, RequestDate, Region, ServiceIdentifier);
  	SigningKey        = GetSigningKey(RequestDate, Region, SecretKey, ServiceIdentifier);
  	Credential        = GetCredential(AccessKey, Region, RequestDate, ServiceIdentifier);
  	Signature         = Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, StringToSign)));

  	Return StrTemplate(
		"%1 Credential=%2, SignedHeaders=%3, Signature=%4",
		"AWS4-HMAC-SHA256",
		Credential,
		Lower(StrConcat(SignedHeaders, ";")),
		Signature
	);
	
EndFunction

// Returns the authorization header
//
// Parameters: 
// Request       - HTTPQuery - HTTP Request
// AccessKey     - String - Access key
// SecretKey     - String - Secret key
// Region        - String - Region
// RequestDate   - Date   - Request date    
// ContentSha256 - String - Sha256sum
// ServiceName   - String - Service name (optional, default = "s3")
// 
// Returns - String - Authorization header value
Function SignV4ByServiceName(Request, AccessKey, SecretKey, Region, RequestDate, ContentSha256, ServiceName = "s3") Export
	Return SignV4(Request, AccessKey, SecretKey, Region, RequestDate, ContentSha256, ServiceName);
EndFunction

// Returns a presigned URL string
//
// Parameters: 
//  Request      - HTTPQuery         - HTTP Request
//  AccessKey    - String            - Access key
//  SecretKey    - String            - Secret key
//  SessionToken - String, Undefined - Session token
//  Region       - String            - Region
//  RequestDate  - Date              - Request date    
//  Expires      - Undefined         - URL expiration in seconds
// 
// Returns:
//  - String - URL string
Function PresignSignatureV4(Request, AccessKey, SecretKey, SessionToken = Undefined, Region, RequestDate, Expires) Export
	
	If Not IsObject(Request) Then   
		mol_Errors.RaiseTypeError("Request", Request, Type("Structure"));	
	EndIf;

	If Not IsString(AccessKey) Then
		mol_Errors.RaiseTypeError("AccessKey", AccessKey, Type("String"));	
	EndIf; 

	If Not IsString(SecretKey) Then
		mol_Errors.RaiseTypeError("SecretKey", SecretKey, Type("String"));	
	EndIf; 

	If Not IsString(Region) Then
		mol_Errors.RaiseTypeError("Region", Region, Type("String"));	
	EndIf; 
	
	If AccessKey = "" Then
		Message = NStr("
		|	ru = 'AccessKey обязателен для заполнения при создании подписи';
		|	en = 'AccessKey is required for signing';");
		mol_Errors.RaiseCustomError("AccessKeyRequired", Message);
	EndIf;
	
	If SecretKey = "" Then  
		Message = NStr("
		|	ru = 'SecretKey обязателен для заполнения при создании подписи';
		|	en = 'SecretKey is required for signing';");
		mol_Errors.RaiseCustomError("SecretKeyRequired", Message);
	EndIf;
  
	If Not IsNumber(Expires) Then
		mol_Errors.RaiseTypeError("Expires", Expires, Type("Number"));	
	EndIf;
  
	If Expires < 1 Then 
		Message = NStr("
		|	ru = 'Expires не может быть меньше 1 секунды';
		|	en = 'Expires param cannot be less than 1 seconds';");
		mol_Errors.RaiseCustomError("ExpiresParam", Message);
	EndIf;

	If Expires > 604800 Then              
		Message = NStr("
		|	ru = 'Expires не может быть больше 7 дней';
		|	en = 'Expires param cannot be greater than 7 days';");
		mol_Errors.RaiseCustomError("ExpiresParam", Message);
	EndIf;

	Iso8601Date   = MakeDateLong(RequestDate);
	SignedHeaders = GetSignedHeaders(Request.Headers);	
	Credential    = GetCredential(AccessKey, Region, RequestDate);
	
	HashedPayload = "UNSIGNED-PAYLOAD";
  
	RequestQuery = New Array();
	RequestQuery.Add(StrTemplate("X-Amz-Algorithm=%1"    , "AWS4-HMAC-SHA256"));
	RequestQuery.Add(StrTemplate("X-Amz-Credential=%1"   , UriEscape(Credential)));
	RequestQuery.Add(StrTemplate("X-Amz-Date=%1"         , Iso8601Date));
	RequestQuery.Add(StrTemplate("X-Amz-Expires=%1"      , Format(Expires, "NG=")));
	RequestQuery.Add(StrTemplate("X-Amz-SignedHeaders=%1", UriEscape(Lower(StrConcat(SignedHeaders, ";")))));
	If SessionToken <> Undefined And SessionToken <> "" Then
		RequestQuery.Add(StrTemplate("X-Amz-Security-Token=%1", UriEscape(SessionToken)));
	EndIf;
  
	PathParts = StrSplit(Request.Path, "?");

	Resource = PathParts[0];
	Query = ?(PathParts.Count() = 2, PathParts[1], "");
	If Query <> "" Then
		Query = Query + "&" + StrConcat(RequestQuery, "&");
	Else
		Query = StrConcat(RequestQuery, "&");
	EndIf;
  
	Path = Resource + "?" + Query;
  
	CanonicalRequest = GetCanonicalRequest(Request.Method, Path, Request.Headers, SignedHeaders, HashedPayload); 
	StringToSign     = GetStringToSign(CanonicalRequest, RequestDate, Region);	
	SigningKey       = GetSigningKey(RequestDate, Region, SecretKey);	
	Signature        = Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, StringToSign)));
	
	Return StrTemplate("%1//%2%3&X-Amz-Signature=%4",
		Request.Protocol,
		Request.Headers["host"],
		Path,
		Signature
	);
		
EndFunction

// Calculate the signature of the POST policy
//
// Parameters: 
// Region       - String - Region
// Date         - Date   - Request date    
// SecretKey    - String - Secret key
// PolicyBase64 - String - Policy encoded as base64 string
// 
// Returns:
//  - String - String signature
Function PostPresignSignatureV4(Region, Date, SecretKey, PolicyBase64) Export
	
	If Not IsString(Region) Then
		mol_Errors.RaiseTypeError("Region", Region, Type("String"));	
	EndIf;
	
	If Not IsValidDate(Date) Then     
		mol_Errors.RaiseTypeError("Date", Date, Type("Date"));	
	EndIf;
	
	If Not IsString(SecretKey) Then
		mol_Errors.RaiseTypeError("SecretKey", SecretKey, Type("String"));	
	EndIf; 
	
	If Not IsString(PolicyBase64) Then 
		mol_Errors.RaiseTypeError("PolicyBase64", PolicyBase64, Type("String"));	
	EndIf;
	
  	SigningKey = GetSigningKey(Date, Region, SecretKey);	
  	Return Lower(GetHexStringFromBinaryData(CreateHMAC(SigningKey, PolicyBase64)));  	

EndFunction

#EndRegion

#Region JWT

Function GenereteAccessToken(SecretKey, UserName, Recipients, LifeTime = Undefined) Export
	
	// Arbitrary large number (roughly 10 years)
	MAX_LIFETIME = 315569520;
	
	Token = New AccessToken; 
	Token.Issuer          = "ssl"; 
	Token.Recipients      = EnsureArray(Recipients);
	Token.UserMatchingKey = UserName;
	Token.CreationTime    = ToUnixDateTime(CurrentUniversalDate()); 
	Token.LifeTime        = ?(LifeTime = Undefined, MAX_LIFETIME, LifeTime);
	
	Token.Sign(AccessTokenSignAlgorithm.HS256, SecretKey); 
	
	Return String(Token);
	
EndFunction

#EndRegion

#Region Crypto

Function CreateHMAC(Val Key_, Val Message, Val Algorithm = Undefined) Export

	If Algorithm = Undefined Then
		Algorithm = HashFunction.SHA256;
	EndIf;

	If IsString(Key_) Then
		Key_ = GetBinaryDataFromString(Key_, TextEncoding.UTF8, False);
	EndIf;
	If IsString(Message) Then
		Message = GetBinaryDataFromString(Message, TextEncoding.UTF8, False);
	EndIf;

	Return HMAC(Key_, Message, Algorithm);

EndFunction 

Function DataHashing(Val Algorithm, Val Data) Export

	If IsString(Data) Then
		Data = GetBinaryDataFromString(Data, TextEncoding.UTF8, False);
	EndIf;

	Hashing = New DataHashing(Algorithm);
	Hashing.Append(Data);

	Return Lower(GetHexStringFromBinaryData(Hashing.HashSum));

EndFunction

#EndRegion

#Region JSON

Function ToJSONString(Object, Format = False) Export
	
	If IsString(Object) Then
		Return Object;
	EndIf;  
	
	JSONWriterSettings = New JSONWriterSettings(
		, // New Lines 
		?(Format, Chars.TAB, ""), // Padding symbols
	);
	
	JSONWriter = New JSONWriter();
	JSONWriter.SetString(JSONWriterSettings);
	
	WriteJSON(JSONWriter, Object, , "JSONTransfromUnsupportedTypes", mol_Helpers);  
	
	String = JSONWriter.Close();
	
	Return String;
	
EndFunction

Function FromJSONString(String) Export
	
	LastErrorInfo = Undefined;
	
	JSONReader = New JSONReader();
	
	Try
		JSONReader.SetString(String);
		Result = ReadJSON(JSONReader, False);
		JSONReader.Close();
		
		Return Result; 
		 
	Except       
		JSONReader.Close();
		LastErrorInfo = ErrorInfo();
		ErrorMessage = "Couldn't parse JSON string using basic parser. Trying custom parser...";
		mol_Logger.Debug("FromJSONString", ErrorMessage, LastErrorInfo, Metadata.CommonModules.mol_Helpers);				
	EndTry;
	
	JSONReader = New JSONReader();
	
	Try 
		JSONReader.SetString(String);
		Object = Undefined;
		ReadJSONCustom(JSONReader, Object);
		Result = Object;
		JSONReader.Close(); 
		
		Return Result;
		
	Except
		LastErrorInfo = ErrorInfo();
		ErrorMessage = "Couldn't parse JSON string using custom parser. Bailing...";
		mol_Logger.Info("FromJSONString", ErrorMessage, LastErrorInfo, Metadata.CommonModules.mol_Helpers);	
		Raise;	
	EndTry;
	
EndFunction

Function FromJSONStream(Stream) Export
	
	JSONReader = New JSONReader();
	
	Try
		JSONReader.OpenStream(Stream);
		Result = ReadJSON(JSONReader, False);
		JSONReader.Close();
		Stream.Close();
		
		Return Result; 
		 
	Except       
		JSONReader.Close();
		ErrorInfo = ErrorInfo();
		ErrorMessage = "Couldn't parse JSON string using basic parser. Trying custom parser...";
		mol_Logger.Info("FromJSONString", ErrorMessage, ErrorInfo, Metadata.CommonModules.mol_Helpers);				
	EndTry;
	
EndFunction

#EndRegion 

#Region XML

Function FromXMLString(String) Export
	
	XMLReader = New XMLReader();
	XMLReader.SetString(String);
	Result = ParseXMLRecursive(XMLReader);
	XMLReader.Close();
	
	Return Result;
	
EndFunction

#EndRegion 

#Region YAML

Function FromYAMLString(String) Export
	
	Params = New Structure();
	Params.Insert("string", String);
	
	Return mol_Broker.Call("$sidecar.parseYAML", Params); 	
	
EndFunction

#EndRegion

#Region HTTP

#Region Headers

Function ParseHeader(Headers, Key_) Export
	
	Result = New Structure();
	Result.Insert("Value");
	Result.Insert("Params", New Structure());
	
	Header = mol_Helpers.Get(Headers, Key_,, True);
		
	Properties = StrSplit(Header, ";", False);
	For Each Property In Properties Do
		Parts = StrSplit(Property, "=", False);
		NameValue = TrimAll(Parts[0]);
		If Parts.Count() = 1 Then 
			Result.Value = NameValue;
		Else                
			Value = TrimAll(Parts[1]);
			//Value = Mid(Value, 2, StrLen(Value) - 2);
			Result.Params.Insert(NameValue, Value);
		EndIf;
	EndDo;   

	Return Result; 
	
EndFunction

Function SetContentLengthHeader(HTTPRequest) Export
	BinaryData = HTTPRequest.GetBodyAsBinaryData();  
	If BinaryData <> Undefined Then
		HTTPRequest.Headers.Insert("content-length", Format(BinaryData.Size(), "NG="));	
    EndIf;
EndFunction

#EndRegion

#Region Multipart

Function EncodeMultipartData(WritableStream, Parts) Export
	
	Hashing = New DataHashing(HashFunction.SHA256);

	Delimiter     = StrReplace(New UUID, "-", "");
	LineDelimiter = Chars.CR + Chars.LF;
	
	Hashing.Append(WritableStream);
	
	Writer = New DataWriter(WritableStream, TextEncoding.UTF8, ByteOrder.LittleEndian, "", "", False);
	For Each Part In Parts Do
		Writer.WriteLine("--" + Delimiter + LineDelimiter);
		Writer.WriteLine(HeadersToString(Part.Headers));
		If TypeOf(Part.Data) = Type("BinaryData") Then
			Writer.Write(Part.Data);
		ElsIF TypeOf(Part.Data) = Type("MemoryStream") Then
			Writer.Write(Part.Data.CloseAndGetBinaryData());
		ElsIF TypeOf(Part.Data) = Type("Stream") Then 
			MemoryStream = New MemoryStream();
			Part.Data.CopyTo(MemoryStream);
			Writer.Write(MemoryStream.CloseAndGetBinaryData());
		Else
			Writer.WriteLine(Part.Data);
		EndIf;
		Writer.WriteLine(LineDelimiter);
	EndDo;
	Writer.WriteLine("--" + Delimiter + "--" + LineDelimiter);
	Writer.Close();   
	
	Size        = WritableStream.Size();        
	Sha256Sum   = Lower(GetHexStringFromBinaryData(Hashing.HashSum));
	ContentType = StrTemplate("multipart/form-data; boundary=%1", Delimiter);
	
	Result = New Structure();
	Result.Insert("Size");
	Result.Insert("Sha256Sum");
	Result.Insert("ContentType");
	
	Result.Size        = Size;
	Result.Sha256Sum   = Sha256Sum;
	Result.ContentType = ContentType;
	
	Return Result;
	
EndFunction

Function DecodeMultipartData(ReadableStream, Headers) Export
	
	Result = New Structure();
	Result.Insert("Fields", New Map());
	Result.Insert("Files" , New Map());
	
	ContentType = ParseHeader(Headers, "Content-Type");
	
	Delimiter     = ContentType.Params.Boundary;
	LineDelimiter = Chars.CR + Chars.LF;
	
	Markers = New Array();
	Markers.Add(GetBinaryDataBufferFromString("--" + Delimiter));
	Markers.Add(GetBinaryDataBufferFromString("--" + Delimiter + Chars.LF));
	Markers.Add(GetBinaryDataBufferFromString("--" + Delimiter + Chars.CR));
	Markers.Add(GetBinaryDataBufferFromString("--" + Delimiter + LineDelimiter));
	Markers.Add(GetBinaryDataBufferFromString(LineDelimiter + "--" + Delimiter + LineDelimiter));
	Markers.Add(GetBinaryDataBufferFromString("--" + Delimiter + "--"));
	
	Reader = New DataReader(ReadableStream, TextEncoding.UTF8, ByteOrder.LittleEndian, "");

	Reader.ReadTo(Markers);
	
	CommonDataBuffer = Reader.ReadIntoBinaryDataBuffer();
	DataBuffer       = CommonDataBuffer.Split(Markers);
	
	For Each Buffer In DataBuffer Do
		
		If Buffer.Size <= 2 Then 
			Continue;
		EndIf;
		
		Stream     = New MemoryStream(Buffer);
		PartReader = New DataReader(Stream);
		
		Headers = ReadMultipartHeaders(PartReader);
		Params  = ParseHeader(Headers, "Content-Disposition").Params;
		Params.Name = Mid(Params.Name, 2, StrLen(Params.Name) - 2);
		
		If Params.Property("filename") Then    
			Stream = PartReader.Read().OpenStreamForRead();
			Result.Files.Insert(Params.Name, Stream);
			//PartReader.Close();
		Else                     
			BinaryData = PartReader.Read().GetBinaryData();
			Value = GetStringFromBinaryData(BinaryData);
			Result.Fields.Insert(Params.Name, Value);
			PartReader.Close();
			Stream.Close();
		EndIf;
		
	EndDo;
	
   	Return Result;	
	
EndFunction

#EndRegion 

#Region FormData 

#Region Constructors

Function NewFormFieldOpts(FileName = Undefined, Type = Undefined, Headers = Undefined) Export
	
	Result = New Structure();
	Result.Insert("Type"    , Type);
	Result.Insert("FileName", FileName);
	Result.Insert("Headers" , Headers);
	
	Return Result;
	
EndFunction

#EndRegion

Function FormField(Name, Data, Opts = Undefined) Export
	
	Field = NewFormField();
	// Required
	Field.Name = Name;
	Field.Data = Data;
   	// Optional
	Field.Type     = mol_Helpers.Get(Opts, "Type");              
	Field.FileName = mol_Helpers.Get(Opts, "FileName");
	Field.Headers  = mol_Helpers.Get(Opts, "Headers", New Map());

	Key_  = "Content-Disposition";
	Value = "form-data";
	If mol_Helpers.Has(Field.Headers, Key_, True, Key_) Then
		Value = Field.Headers[Key_];
	EndIf;

	Parts = New Array;
	Parts.Add(Value);
	Parts.Add(StringKeyValue("name", Field.Name));
	If ValueIsFilled(Field.FileName) Then
		Parts.Add(StringKeyValue("filename", Field.FileName));
	EndIf;

	Field.Headers[Key_]           = StrConcat(Parts, "; ");
	Field.Headers["Content-Type"] = Field.Type;

	Return Field;
	
EndFunction

#EndRegion

Procedure SetRequestResponseBody(HTTPRequestResponse, Body) Export

	If IsString(Body) Then
		HTTPRequestResponse.SetBodyFromString(Body, "UTF-8", ByteOrderMarkUse.DontUse);	
	ElsIf IsBinaryData(Body) Then
		HTTPRequestResponse.SetBodyFromBinaryData(Body);	
	EndIf;
	
EndProcedure

#EndRegion

#Region DynamicEvaluation

Procedure ExecuteModuleProcedure(Val _ModuleName, Val _ProcedureName, Val _Parameters = Undefined) Export
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Execute StrTemplate("%1.%2(%3)", _ModuleName, _ProcedureName, _Args);
		
EndProcedure

Function ExecuteModuleFunction(Val _ModuleName, Val _FunctionName, Val _Parameters = Undefined) Export
	
	_Args = BuildArgsString(_Parameters, "_Parameters");
	
	Return Eval(StrTemplate("%1.%2(%3)", _ModuleName, _FunctionName, _Args));
	
EndFunction

#EndRegion

#Region Info

Function GetOsPlatform(SystemInfo) Export

	If SystemInfo.PlatformType = PlatformType.Windows_x86 Or SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		Return "win32";
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86 Or SystemInfo.PlatformType = PlatformType.MacOS_x86_64 Then 
		Return "darwin";
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86 Or SystemInfo.PlatformType = PlatformType.Linux_x86_64 Then
		Return "linux";
	Else
		Return "Unknown";
	EndIf;	
	
EndFunction
	
Function GetOsArch(SystemInfo) Export

	If SystemInfo.PlatformType = PlatformType.Windows_x86 Then
		Return "x86"; 
	ElsIf SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		Return "x64";
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86 Then
		Return "x86"; 
	ElsIf SystemInfo.PlatformType = PlatformType.MacOS_x86_64 Then
		Return "x64/arm64";
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86 Then
		Return "i386"; 
	ElsIf SystemInfo.PlatformType = PlatformType.Linux_x86_64 Then
		Return "x64";
	Else
		Return "Unknown";
	EndIf;
	
EndFunction

Function GetExtensionVersion(ExtensionName) Export
	
	Filter = New Structure();
	Filter.Insert("Name", ExtensionName);
	
	SetPrivilegedMode(True);
	Extensions = ConfigurationExtensions.Get(Filter);
	SetPrivilegedMode(False);
	
	If Extensions.Count() = 0 Then
		Return "Unknown";	
	EndIf;
	
	Return Extensions[0].Version;
	
EndFunction

#EndRegion

#Region Validation

Function IsObject(Value) Export
	Return mol_HelpersClientServer.IsObject(Value);
EndFunction

Function IsStructure(Value) Export
	Return mol_HelpersClientServer.IsStructure(Value);
EndFunction

Function IsMap(Value) Export
	Return mol_HelpersClientServer.IsMap(Value);	
EndFunction

Function IsArray(Value) Export
	Return mol_HelpersClientServer.IsArray(Value);	
EndFunction

Function IsString(Value) Export
	Return mol_HelpersClientServer.IsString(Value);
EndFunction

Function IsNumber(Value) Export
	Return mol_HelpersClientServer.IsNumber(Value);	
EndFunction

Function IsBinaryData(Value) Export
	Return mol_HelpersClientServer.IsBinaryData(Value);	
EndFunction

Function IsValidDate(Value) Export
	Return mol_HelpersClientServer.IsValidDate(Value);	
EndFunction 

Function IsStream(Value) Export
	Return mol_HelpersClientServer.IsStream(Value);	
EndFunction

Function CanBeNumber(Value) Export
	Return mol_HelpersClientServer.CanBeNumber(Value);
EndFunction

#EndRegion

#Region BackgroundJobs

Function ExecuteInBackground() Export
	
	BackgroundJobs.Execute("");
	
EndFunction

#EndRegion

Function Get(Object, Property, EmptyValue = Undefined, IgnoreCase = False) Export
	
	Value = Undefined;
	If IsStructure(Object) Or TypeOf(Object) = Type("FixedStructure") Then
		If IgnoreCase = False Then 
			Object.Property(Property, Value);
		Else
			For Each KeyValue In Object Do
				If Lower(Property) = Lower(KeyValue.Key) Then
					Value = KeyValue.Value;
					Break;
				EndIf;
			EndDo;
		EndIf;	
	ElsIf IsMap(Object) Or TypeOf(Object) = Type("FixedMap") Then
		If IgnoreCase = False Then
			Value = Object.Get(Property);
		Else
			For Each KeyValue In Object Do
				If Lower(Property) = Lower(KeyValue.Key) Then
					Value = KeyValue.Value;
					Break;
				EndIf;
			EndDo;
		EndIf;
	Else           
		Template = NStr("
		|	ru = 'Значения типа ""%1"" не поддерживается';
		|	en = 'Value of type ""%1"" is not supported';");
		Message = StrTemplate(Template, TypeOf(Object));
		mol_Errors.RaiseCustomError("TypeError", Message);
	EndIf;
	
	Return ?(Value <> Undefined, Value, EmptyValue);
	
EndFunction

Procedure Set(Object, Property, Value) Export
	
	If IsStructure(Object) Or IsMap(Object) Then
		Object.Insert(Property, Value);
	Else
		Template = NStr("
		|	ru = 'Значения типа ""%1"" не поддерживается';
		|	en = 'Value of type ""%1"" is not supported';");
		Message = StrTemplate(Template, TypeOf(Object));
		mol_Errors.RaiseCustomError("TypeError", Message);
	EndIf;
	
EndProcedure

Function Has(Object, Property, IgnoreCase = False, _Key = Undefined) Export
	
	If IsStructure(Object) Or TypeOf(Object) = Type("FixedStructure") Then
		If IgnoreCase = False Then 
			HasProperty = Object.Property(Property);
			If HasProperty Then
				_Key = Property;	
			EndIf;
			Return HasProperty;
		Else
			For Each KeyValue In Object Do
				If Lower(Property) = Lower(KeyValue.Key) Then
					_Key = KeyValue.Key;
					Return True;
				EndIf;
			EndDo;
			Return False;
		EndIf;
	ElsIf IsMap(Object) Or TypeOf(Object) = Type("FixedMap") Then
		If IgnoreCase = False Then
			HasProperty = Object.Get(Property) <> Undefined;
			If HasProperty Then
				_Key = Property;	
			EndIf;
			Return HasProperty;
		Else
			For Each KeyValue In Object Do
				If Lower(Property) = Lower(KeyValue.Key) Then
					_Key = KeyValue.Key;
					Return True;
				EndIf;
			EndDo;
			Return False;
		EndIf;
	EndIf;  
	
	Template = NStr("
	|	ru = 'Значения типа ""%1"" не поддерживается';
	|	en = 'Value of type ""%1"" is not supported';");
	Message = StrTemplate(Template, TypeOf(Object));
	mol_Errors.RaiseCustomError("TypeError", Message);
	
EndFunction

Procedure RemoveEmptyProperties(Object, Exclude = Undefined) Export
	
	If Not IsStructure(Object) And Not IsMap(Object) Then
		mol_Errors.RaiseTypeError("Object", Object, Type("Structure"), Type("Map"));
	EndIf; 
	
	ExcludeMap = New Map();
	If IsString(Exclude) Then
		For Each PropertyName In StrSplit(Exclude, ",") Do
			ExcludeMap.Insert(PropertyName, 1);		
		EndDo;		
	ElsIf IsArray(Exclude) Then
		For Each PropertyName In Exclude Do
			ExcludeMap.Insert(PropertyName, 1);		
		EndDo;
	EndIf;
	
	For Each KeyValue In Object Do
		Value  = KeyValue.Value;
		Delete = False;
		If False 
			OR (IsString(Value) And IsBlankString(Value)) 
			OR (IsStructure(Value) Or IsMap(Value) Or IsArray(Value)) And Value.Count() = 0 
			OR Value = Null
			OR Value = Undefined Then
			Delete = True;	
		EndIf;
		If Delete And ExcludeMap.Get(KeyValue.Key) = Undefined Then
			Object.Delete(KeyValue.Key);
		EndIf;
	EndDo;
	
EndProcedure

Function NormalizePath(Path) Export

	If StrFind(Path, "/") Then
		Parts = StrSplit(Path, "/"); 
		Path = Parts[0];  
		If StrEndsWith(Parts[1], "/") Then
			Parts[1] = Left(Parts[1], StrLen(Parts[1]) - 1);
		EndIf; 
		If Not StrStartsWith(Path, "/") Then
			Path = "/" + Path;
		EndIf;
		Path = "/" + Parts[1] + Path;
	EndIf;
	
	Return Path;
	
EndFunction

Function MakeDateLong(Date = Undefined) Export 
	
	If Date = Undefined Then
		Date = CurrentUniversalDate();
	EndIf;
	
	Return Format(Date, "DF=yyyyMMddTHHmmssZ");	 
	
EndFunction 

Function MakeDateShort(Date = Undefined) Export 
	
	If Date = Undefined Then
		Date = CurrentUniversalDate();
	EndIf;
	
	Return Format(Date, "DF=yyyyMMdd");	 
	
EndFunction 

Function ToSha256(Payload) Export
	Return DataHashing(HashFunction.SHA256, Payload);
EndFunction

Function UriEscape(String) Export  
	Return EncodeString(String, StringEncodingMethod.URLEncoding, "UTF-8");		
EndFunction

Function UriResourceEscape(String) Export
	Return StrReplace(UriEscape(String), "%2F", "/");	
EndFunction

Function GetScope(Region, Date, ServiceName = "s3") Export
	Return StrTemplate("%1/%2/%3/aws4_request", MakeDateShort(date), region, serviceName);	
EndFunction

Function Match(Text, Pattern) Export

	// Simple patterns
	If StrFind(Pattern, "?") = 0 Then
		// Exact match (eg. "prefix.event")
		FirstStarPosition = StrFind(Pattern, "*");
		If FirstStarPosition = 0 Then 
			Return Pattern = Text;
		EndIf;
		
		// Eg. "prefix**"
		Length = StrLen(Pattern);
		If Length > 2 And Right(Pattern, 2) = "**" And FirstStarPosition > Length - 3 Then
			Pattern = Left(Pattern, Length - 2);
			Return StrStartsWith(Text, Pattern);
		EndIf;
		
		// Eg. "prefix*"
		If Length > 1 And Right(Pattern, 1) = "*" And FirstStarPosition > Length - 2 Then
			Pattern = Left(Pattern, Length - 1);
			If StrStartsWith(Text, Pattern) Then
				Return StrFind(Text, ".") = 0;
			EndIf;
			Return False;
		EndIf;

		// Accept simple text, without point character (*)
		If Length = 1 And FirstStarPosition = 0 Then
			Return StrFind(Text, ".") = 0;
		EndIf;

		// Accept all inputs (**)
		If Length = 2 And FirstStarPosition = 0 And Right(Pattern, 1) = 1 Then
			Return True;
		EndIf;
		
	EndIf;    
	
	// Regex (eg. "prefix.ab?cd.*.foo")
	RegEx = mol_Reuse.GetRegexCache(Pattern); 
	Return False;    
	//Result = StrFindAllByRegularExpression(Text, RegEx);
	//
	//Return Result.Count() <> 0;
	
EndFunction

Function EnsureArray(Value) Export  
	
	If TypeOf(Value) = Type("Array") Then
		Return Value;
	EndIf;
	
	Result = New Array();
	Result.Add(Value);
	
	Return Result;
	
EndFunction

Function ToUnixDateTime(Date) Export
	InitialUnixDate = '19700101';
	Return Date - InitialUnixDate;	
EndFunction

#EndRegion

#Region Protected 

#Region Moleculer

Function GetVersionedFullName(Name, Val Version = Undefined) Export
	Return mol_HelpersClientServer.GetVersionedFullName(Name, Version);
EndFunction 

#EndRegion   

#Region Cache

#Region Stack

Function PushToStack(StackName, Value) Export
	
	Cache = mol_ReuseCalls.GetCacheStack();
	If Not Cache.Property(StackName) Then
		Cache.Insert(StackName, New Array());
	EndIf;
	
	Cache[StackName].Add(Value); 
	
	Return Value;
	
EndFunction

Function PopFromStack(StackName) Export

	Cache = mol_ReuseCalls.GetCacheStack();
	If Not Cache.Property(StackName) Then
		Return Undefined;
	EndIf;    
	
	Length = Cache[StackName].Count();
	If Length = 0 Then
		Return Undefined;
	EndIf; 
	
	Item = Cache[StackName].Get(Length - 1);
	Cache[StackName].Delete(Length - 1);
	
	Return Item;
		
EndFunction

Function LastFromStack(StackName) Export
	
	Cache = mol_ReuseCalls.GetCacheStack();
	If Not Cache.Property(StackName) Then
		Return Undefined;
	EndIf;    
	
	Length = Cache[StackName].Count();
	If Length = 0 Then
		Return Undefined;
	EndIf; 
	
	Item = Cache[StackName].Get(Length - 1);
	
	Return Item;
	
EndFunction

Function ClearStack(StackName) Export
	
	Cache = mol_ReuseCalls.GetCacheStack();
	If Not Cache.Property(StackName) Then
		Return Undefined;
	EndIf;
	
	Cache.Delete(StackName);
	
EndFunction

#EndRegion

#EndRegion

#Region JSON

Function JSONTransfromUnsupportedTypes(Property, Value, AdditionalParameters, Cancel) Export
	
	Type = TypeOf(Value);
	
	If Type = Type("UUID") Then
		Return String(Value);
	ElsIf Type = Type("CommonModule") Then
		Return Undefined;
	ElsIf Type = Type("ErrorInfo") Then 
		Return ErrorProcessing.DetailErrorDescription(Value); 
	Else
		Return StrTemplate("<incorrect value>[%1:%2]", TypeOf(Value), String(Value));
	EndIf;
	
EndFunction

#EndRegion

#EndRegion 

#Region Private

#Region AWSSigningV4

// GetCanonicalRequest generate a canonical request of style.
// 
// Parameters:
// Method        - String          - HTTP Request method ("GET", "POST", "PUT", etc)
// Path          - String          - URL Path
// Headers       - Map             - Request headers
// SignedHeaders - Array Of String - Array of headers that must be signed
// HashedPayload - String          - Hashed payload
// 
// Returns:
//  String - Canonical request -
//    <HTTPMethod>\n
//    <CanonicalURI>\n
//    <CanonicalQueryString>\n
//    <CanonicalHeaders>\n
//    <SignedHeaders>\n
//    <HashedPayload>
//
Function GetCanonicalRequest(Method, Path, Headers, SignedHeaders, HashedPayload)
	
	If Not IsString(Method) Then  
		mol_Errors.RaiseTypeError("Method", Method, Type("String"));	
	EndIf;    
	
	If Not IsString(Path) Then      
		mol_Errors.RaiseTypeError("Path", Path, Type("String"));	
	EndIf;
	
	If Not IsMap(Headers) Then
		mol_Errors.RaiseTypeError("Headers", Headers, Type("Map"));	
	EndIf;
	
	If Not IsArray(SignedHeaders) Then 
		mol_Errors.RaiseTypeError("SignedHeaders", SignedHeaders, Type("Array"));	
	EndIf;
	
	If Not IsString(HashedPayload) Then    
		mol_Errors.RaiseTypeError("HashedPayload", HashedPayload, Type("String"));	
	EndIf; 
	
	HeadersArray = New Array();
	For Each HeaderName In SignedHeaders Do
		// Trim spaces from the value (required by V4 spec)
		Value = TrimAll(Headers[HeaderName]);
		HeadersArray.Add(StrTemplate("%1:%2", Lower(HeaderName), Value));
	EndDo;

	PathParts = StrSplit(Path, "?");
	
	FULL_QUERY_PARTS = 2;
	RequestResource = PathParts[0];
	RequestQuery = ?(PathParts.Count() = FULL_QUERY_PARTS, PathParts[1], "");   
	
	If RequestQuery <> "" Then
		
		QueryParts = StrSplit(RequestQuery, "&");
		QueryList  = New ValueList;
		For Each QueryPart In QueryParts Do
			KeyValue = StrSplit(QueryPart, "=");
			QueryList.Add(KeyValue[0], ?(KeyValue.Count() = FULL_QUERY_PARTS, KeyValue[1], ""));	
		EndDo;
		
		QueryList.SortByValue(SortDirection.Asc);  
		QueryParts = New Array();
		
		For Each QueryItem In QueryList Do
			QueryParts.Add(
				QueryItem.Value + "=" + ?(QueryItem.Presentation <> "", QueryItem.Presentation, "")
			);
		EndDo;
		
		RequestQuery = StrConcat(QueryParts, "&");
		
	EndIf; 
	
	RequestParts = New Array();
	RequestParts.Add(Upper(Method));
	RequestParts.Add(RequestResource);
	RequestParts.Add(RequestQuery);
	RequestParts.Add(StrConcat(HeadersArray, Chars.LF));
	RequestParts.Add("");
	RequestParts.Add(Lower(StrConcat(SignedHeaders, ";")));
	RequestParts.Add(HashedPayload);
	
	Return StrConcat(RequestParts, Chars.LF);	
	
EndFunction

// Generate a credential string
//
// Parameters:
// AccessKey   - String            - Access key ID
// Region      - String            - Region
// RequestDate - Date              - Request date (optional)
// ServiceName - String, Undefined - Service name (optional, default "s3")
// 
// Returns:
//  String - Credential string
Function GetCredential(AccessKey, Region, RequestDate = Undefined, ServiceName = "s3")
	
	If Not IsString(AccessKey) Then        
		mol_Errors.RaiseTypeError("AccessKey", AccessKey, Type("String"));
	EndIf;     
	
	If Not IsString(Region) Then                                      
		mol_Errors.RaiseTypeError("Region", Region, Type("String"));
	EndIf; 
	
	If RequestDate <> Undefined And Not IsValidDate(RequestDate) Then
		mol_Errors.RaiseTypeError("RequestDate", RequestDate, Type("Date"));	
	EndIf;     
	
	If Not IsString(ServiceName) Then
		mol_Errors.RaiseTypeError("ServiceName", ServiceName, Type("String"));	
	EndIf;
	
  	Return StrTemplate("%1/%2", AccessKey, GetScope(Region, RequestDate, ServiceName)); 	

EndFunction

// Returns signed headers array - alphabetically sorted
//
// Parameters:
// Headers - Map - Request headers
// 
// Returns:
//	Array Of String - Array of Names of signed headers
Function GetSignedHeaders(Headers)
	
	If Not IsMap(Headers) Then    
		mol_Errors.RaiseTypeError("Headers", Headers, Type("Map"));	
	EndIf;
	
	// Excerpts from @lsegal - https://github.com/aws/aws-sdk-js/issues/659#issuecomment-120477258
	//
	//  User-Agent:
	//
	//      This is ignored from signing because signing this causes problems with generating pre-signed URLs
	//      (that are executed by other agents) or when customers pass requests through proxies, which may
	//      modify the user-agent.
	//
	//  Content-Length:
	//
	//      This is ignored from signing because generating a pre-signed URL should not provide a content-length
	//      constraint, specifically when vending a S3 pre-signed PUT URL. The corollary to this is that when
	//      sending regular requests (non-pre-signed), the signature contains a checksum of the body, which
	//      implicitly validates the payload length (since changing the number of bytes would change the checksum)
	//      and therefore this header is not valuable in the signature.
	//
	//  Content-Type:
	//
	//      Signing this header causes quite a number of problems in browser environments, where browsers
	//      like to modify and normalize the content-type header in different ways. There is more information
	//      on this in https://github.com/aws/aws-sdk-js/issues/244. Avoiding this field simplifies logic
	//      and reduces the possibility of future bugs
	//
	//  Authorization:
	//
	//      Is skipped for obvious reasons
	IgnoredHeaders = New Array();
	IgnoredHeaders.Add("authorization" );
	IgnoredHeaders.Add("content-length");
	IgnoredHeaders.Add("content-type"  );
	IgnoredHeaders.Add("user-agent"    ); 
	
	HeadersList = New ValueList;
	For Each KeyValue In Headers Do
		Header = KeyValue.Key;
		If IgnoredHeaders.Find(Header) = Undefined Then
			HeadersList.Add(Header);
		EndIf;
	EndDo;
	
	HeadersList.SortByValue(SortDirection.Asc);
	
	Return HeadersList.UnloadValues(); 	

EndFunction 

// Returns the key used for calculating signature  
//
// Parameters:
// Date        - Date   - Request date    
// Region      - String - Region
// SecretKey   - String - S3 Secret key
// ServiceName - String - Service name (optional, default = "s3")
// 
// Returns:
//  BinaryData - 
Function GetSigningKey(Date, Region, SecretKey, ServiceName = "s3")
	
	If Not IsValidDate(Date) Then               
		mol_Errors.RaiseTypeError("Date", Date, Type("Date"));
	EndIf;
	
	If Not IsString(Region) Then                        
		mol_Errors.RaiseTypeError("Region", Region, Type("String"));
	EndIf;
	
	If Not IsString(SecretKey) Then                  
		mol_Errors.RaiseTypeError("SecretKey", SecretKey, Type("String"));
	EndIf; 
	
	If Not IsString(ServiceName) Then                         
		mol_Errors.RaiseTypeError("ServiceName", ServiceName, Type("String"));
	EndIf;  
	
	DateLine = MakeDateShort(Date);
	
	HMAC1 = CreateHMAC("AWS4" + SecretKey, DateLine   );
	HMAC2 = CreateHMAC(HMAC1             , Region     );
	HMAC3 = CreateHMAC(HMAC2             , ServiceName);

	Return CreateHMAC(HMAC3, "aws4_request");
	
EndFunction

// Returns the string that needs to be signed      
//
// Parameters:       
// CanonicalRequest - String - Canonical request
// RequestDate      - Date   - Request date    
// Region           - String - Region
// ServiceName      - String - Service name (optional, default = "s3")
// 
// Returns:
//  String - String that needs to be signed
Function GetStringToSign(CanonicalRequest, RequestDate, Region, ServiceName = "s3") 
	
	If Not IsString(CanonicalRequest) Then       
		mol_Errors.RaiseTypeError("CanonicalRequest", CanonicalRequest, Type("String"));
	EndIf;
	
	If Not IsValidDate(RequestDate) Then                                 
		mol_Errors.RaiseTypeError("RequestDate", RequestDate, Type("Date"));
	EndIf;
	
	If Not IsString(Region) Then                          
		mol_Errors.RaiseTypeError("Region", Region, Type("String"));	
	EndIf; 
	
	If Not IsString(ServiceName) Then  
		mol_Errors.RaiseTypeError("ServiceName", ServiceName, Type("String"));	
	EndIf;
		
	Hash  = DataHashing(HashFunction.SHA256, CanonicalRequest);
  	Scope = GetScope(Region, RequestDate, ServiceName);

	StringToSignParts = New Array();
	StringToSignParts.Add("AWS4-HMAC-SHA256");
	StringToSignParts.Add(MakeDateLong(RequestDate));
	StringToSignParts.Add(Scope);
	StringToSignParts.Add(Hash); 
	
	Return StrConcat(StringToSignParts, Chars.LF);	      

EndFunction 

#EndRegion

#Region Crypto

// Calculates HMAC (hash-based message authentication code).
//
// Parameters:
//   Key_      - BinaryData   - secret key.
//   Data      - BinaryData   - data to calculate HMAC.
//   Algorithm - HashFunction - Defines method for calculating the hash-sum.
//
// Returns:
//   BinaryData - calculated HMAC value.
//
Function HMAC(Key_, Data, Algorithm)

	BlockSize = 64;

	If Key_.Size() > BlockSize Then
		Hashing = New DataHashing(Algorithm);
		Hashing.Append(Key_);

		BufferKey = GetBinaryDataBufferFromBinaryData(Hashing.HashSum);
	Else
		BufferKey = GetBinaryDataBufferFromBinaryData(Key_);
	EndIf;

	ModifiedKey = New BinaryDataBuffer(BlockSize);
	ModifiedKey.Write(0, BufferKey);

	InternalKey = ModifiedKey.Copy();
	ExternalKey = ModifiedKey;
                         
	InternalAlignment = mol_Reuse.GetAlignmentBuffer(BlockSize, 54); 
	ExternalAlignment = mol_Reuse.GetAlignmentBuffer(BlockSize, 92); 

	InternalHashing = New DataHashing(Algorithm);
	ExternalHashing = New DataHashing(Algorithm);

	InternalKey.WriteBitwiseXor(0, InternalAlignment);
	ExternalKey.WriteBitwiseXor(0, ExternalAlignment);

	ExternalHashing.Append(GetBinaryDataFromBinaryDataBuffer(ExternalKey));
	InternalHashing.Append(GetBinaryDataFromBinaryDataBuffer(InternalKey));

	If ValueIsFilled(Data) Then
		InternalHashing.Append(Data);
	EndIf;

	ExternalHashing.Append(InternalHashing.HashSum);

	Return ExternalHashing.HashSum;

EndFunction

#EndRegion

#Region JSON

Procedure ReadJSONCustom(JSONReader, Object)

	PropertyName = Undefined;
    
    While JSONReader.Read() Do
        JSONType = JSONReader.CurrentValueType;
        
        If JSONType = JSONValueType.ObjectStart 
        Or JSONType = JSONValueType.ArrayStart Then
            NewObject = ?(JSONType = JSONValueType.ObjectStart, New Structure, New Array);
			If PropertyName <> Undefined And (Lower(PropertyName) = "metadata" Or Lower(PropertyName) = "meta") Then
				NewObject = New Map();
			EndIf;
            
            ReadJSONCustom(JSONReader, NewObject);   
			
			If IsArray(Object) Then
                Object.Add(NewObject);
            ElsIf (IsStructure(Object) Or IsMap(Object)) And ValueIsFilled(PropertyName) Then
                Object.Insert(PropertyName, NewObject);
            EndIf;
            
            If Object = Undefined Then
                Object = NewObject;
            EndIf;
        ElsIf JSONType = JSONValueType.PropertyName Then
            PropertyName = JSONReader.CurrentValue;     
			If IsStructure(Object) And Not IsValidStructureName(PropertyName) Then
				NewMap = New Map();
				For Each KeyValue In Object Do
					NewMap.Insert(KeyValue.Key, KeyValue.Value); 	
				EndDo;
				Object = NewMap;
			EndIf;		
        ElsIf IsJSONPrimitive(JSONType) Then
            If IsArray(Object) Then
                Object.Add(JSONReader.CurrentValue);
            ElsIf (IsStructure(Object) Or IsMap(Object)) Then
                Object.Insert(PropertyName, JSONReader.CurrentValue);
            EndIf;
        Else
            Return;
        EndIf;
    EndDo;
	
EndProcedure

Function IsJSONPrimitive(JSONType)
	Return JSONType = JSONValueType.Number 
        Or JSONType = JSONValueType.String 
        Or JSONType = JSONValueType.Boolean 
        Or JSONType = JSONValueType.Null;	
EndFunction  

Function IsValidStructureName(PropertyName)

	TempStructure = New Structure();
	Try
		TempStructure.Insert(PropertyName, Undefined);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region XML

Function ParseXMLRecursive(XMLReader)

	Result = New Structure; 

	While XMLReader.Read() Do
		NodeType = XMLReader.NodeType;
		
		If NodeType = XMLNodeType.StartElement THen
			If Result.Property(XMLReader.Name) Then
				If TypeOf(Result[XMLReader.Name]) <> Type("Array") Then 
					TempArray = New Array();
					TempArray.Add(Result[XMLReader.Name]);
					Result[XMLReader.Name] = TempArray;
				EndIf;
				Result[XMLReader.Name].Add(ParseXMLRecursive(XMLReader));    
			Else
				Result.Insert(XMLReader.Name, ParseXMLRecursive(XMLReader));
			EndIf;
		ElsIf NodeType = XMLNodeType.EndElement Then
			If TypeOf(Result) = Type("Structure") And Result.Count() = 0 Then
				Return Undefined;
			EndIf;
			Return Result;
		ElsIf NodeType = XMLNodeType.Text Then
			Value = XMLReader.Value;
			XMLReader.Read(); // Read till EndElement
			Return Value;
		Else
			// Ignored	
		EndIf;
	EndDo;

	Return Result;
	
EndFunction

#EndRegion

#Region DynamicEvaluation

Function BuildArgsString(Args, ArgsVarName)
	Result = "";
	If Args <> Undefined And Args.Count() > 0 Then
		For Index = 0 To Args.UBound() Do
			Result = Result + StrTemplate("%1[%2],", ArgsVarName, XMLString(Index));	
		EndDo; 
		Result = Mid(Result, 1, StrLen(Result) - 1);
	EndIf;
	Return Result;
EndFunction

#EndRegion

#Region HTTP 

#Region Headers

Function StringKeyValue(Key, Value, Delimiter = "=")
	Return StrTemplate("%1%2""%3""",Key, Delimiter, Value);	
EndFunction

Function HeadersToString(Headers)
	
	Strings       = New Array;
	LineDelimiter = Chars.CR + Chars.LF;

	SortedHeaders = "Content-Disposition,Content-Type,Content-Location";
	For Each Key_ In StrSplit(SortedHeaders, ",") Do
		Value = mol_Helpers.Get(Headers, Key_);
		If Value <> False And ValueIsFilled(Value) Then
			Strings.Add(StrTemplate("%1: %2", Key_, Value));
		EndIf;
	EndDo;

	Keys = StrSplit(Upper(SortedHeaders), ",");
	For Each Header In Headers Do
		If Keys.Find(Upper(Header.Key)) = Undefined Then
			Strings.Add(StrTemplate("%1: %2", Header.Key, Header.Value));
		EndIf;
	EndDo;
	Strings.Add(LineDelimiter);

	Return StrConcat(Strings, LineDelimiter);

EndFunction
	
Function ReadMultipartHeaders(Reader)
	
	Headers = New Map();
	While True Do
		String = Reader.ReadLine();
		If String = "" Then
			Break;
		EndIf;
		Parts = StrSplit(String, ":");
		Headers.Insert(TrimAll(Parts[0]), TrimAll(Parts[1]));
	EndDo;

	Return Headers; 
		
EndFunction 

#EndRegion

#Region FormData 

#Region Constructors

Function NewFormField()

	Result = New Structure();
	Result.Insert("Name");
	Result.Insert("FileName");
	Result.Insert("Data");
	Result.Insert("Type"); 
	Result.Insert("Headers");
	
	Return Result;

EndFunction   

#EndRegion

#EndRegion

#EndRegion

#EndRegion