
#Region Public

Function ToObject(Text) Export

	Ctx = InitParser(Text);
	
	Return Parse(Ctx);
	
EndFunction

#EndRegion

#Region Private

Function InitParser(Text)
	
	BinaryArray = SplitBinaryData(GetBinaryDataFromString(Text), 1);
	Source = New Array();
	For Each Byte In BinaryArray Do                       
		Source.Add(NumberFromHexString("0x" + String(Byte)));
	EndDo; 
	
	Ctx = NewContext();
	Ctx.Current = Source[0];
	Ctx.Source  = Source;
	Ctx.Len     = Source.Count();
	Ctx.Idx     = 0;
	Ctx.Indent  = 0;
	Ctx.Chars   = GenerateCharsStructure();
	
	Return Ctx;
		
EndFunction  

Function GenerateCharsStructure()
	
	Result = New Structure();
	Result.Insert("hash"    , 35 ); // #
	Result.Insert("hyphen"  , 45 ); // -
	Result.Insert("CR"      , 13 ); // Chars.CR
	Result.Insert("LF"      , 10 ); // Chars.LF
	Result.Insert("OBrace"  , 123); // {
	Result.Insert("CBrace"  , 125); // }
	Result.Insert("OBracket", 91 ); // [
	Result.Insert("CBracket", 93 ); // ]
	Result.Insert("Tab"     , 9  ); // Tab
	Result.Insert("Space"   , 32 ); // " "
	Result.Insert("Comma"   , 44 ); // ,
	Result.Insert("Colon"   , 58 ); // :
	Result.Insert("SQuotes" , 39 ); // '
	Result.Insert("DQuotes" , 34 ); // "
	
	Return Result; // Ctx.Chars.DQuotes
	
EndFunction

Function Parse(Ctx) 
	
	State  = LastState(Ctx);
	Peeked = Ctx.Source[Ctx.Idx + 1];
	Result = Undefined;
	
	If Ctx.Current = Ctx.Chars.Hash Then
		ChompComment(Ctx);
		Result = Parse(Ctx);	
	ElsIf Ctx.Current = Ctx.Chars.Hyphen And CheckAheadN(Ctx, 1, Ctx.Chars.Hyphen) And CheckAheadN(Ctx, 2, Ctx.Chars.Hyphen) Then
		Bump(Ctx);
		Bump(Ctx);
		Bump(Ctx);
		Result = Parse(Ctx);
	ElsIf Ctx.Current = Ctx.Chars.CR Or Ctx.Current = Ctx.Chars.LF Then
		ChompNewlines(Ctx);
		Ctx.Indent = 0; 
		Result = Parse(Ctx);
	ElsIf IsScalarStart(Ctx.Current, Peeked, State) Then
		Result = ParseMaybeScalar(Ctx);
	ElsIf Ctx.Current = Ctx.Chars.OBrace Then
		Ctx.Expected.Add(Ctx.Chars.CBrace);
		Node = ParseMappingFlow(Ctx);
		If LastArrayElement(Ctx.Expected) = Ctx.Chars.CBrace Then
			PopIfMatch(Ctx.Expected, Ctx.Chars.CBrace)	
		EndIf;    
		Result = ParseMappingMaybe(Ctx, Node);
	ElsIf Ctx.Current = Ctx.Chars.OBracket Then
		Node = ParseSequenceFlow(Ctx);
		Result = ParseMappingMaybe(Ctx, Node);
	ElsIf Ctx.Current = Ctx.Chars.Hyphen Then
		Next = Ctx.Source[Ctx.Idx + 1];
		If Next <> Undefined And ((Next = 13 OR Next = 10) Or (Next = 32 OR Next = 9)) Then
			Result = ParseSequenceBlock(Ctx);	
		Else
			Raise "unexpected";
		EndIf;	
	ElsIf Ctx.Current = Ctx.Chars.CBrace Or Ctx.Current = Ctx.Chars.CBracket Then
		Raise StrTemplate("unexpected symbol '%1'", Char(Ctx.Current));	
	ElsIf (Ctx.Current = 32 OR Ctx.Current = 9) Then
		ChompIndent(Ctx);
		If (Ctx.Idx >= Ctx.Len - 1) Then
			Raise "unexpected end of input";
		EndIf;
		Result = Parse(Ctx);
	Else
		Raise "failed to parse at top level";		
	EndIf;
			
	Return Result;
		
EndFunction

Function ParseMaybeScalar(Ctx)

	State = LastState(Ctx);
	If State = "FlowIn" Or State = "FlowOut" Or State = "FlowKey" Then 
		Return ParseScalar(Ctx);
	Else
        StartState(Ctx, "BlockMapping");
        Node = ParseScalar(Ctx);
        EndState(Ctx, "BlockMapping");
        Return ParseMappingMaybe(Ctx, Node);
	EndIf;
	
EndFunction

Function ParseScalar(Ctx)
	
	State = LastState(Ctx);
	If Ctx.Current = Ctx.Chars.DQuotes Then
		ScalStart = Ctx.Idx;
		ScalEnd   = ScalStart;
		
		Advance(Ctx);
		Res = TakeWhile(Ctx, Ctx.Chars.DQuotes);
		If Res.Error Then
			Raise "unexpected end of input; expected '""'";	
		EndIf;            
		
		If Bump(Ctx) Then
			ScalEnd = Ctx.Idx;
		Else
			ScalEnd = Ctx.Len;
		EndIf;
		
		EntireLiteral = SliceRange(Ctx, ScalStart, ScalEnd);
		
		Return EntireLiteral;
		
	ElsIf Ctx.Current = Ctx.Chars.SQuotes Then
		ScalStart = Ctx.Idx;
		ScalEnd   = ScalStart;
		
		Advance(Ctx);
		Res = TakeWhile(Ctx, Ctx.Chars.SQuotes);
		If Res.Error Then
			Raise "unexpected end of input; expected '''";	
		EndIf;            
		
		If Bump(Ctx) Then
			ScalEnd = Ctx.Idx;
		Else
			ScalEnd = Ctx.Len;
		EndIf;
		
		EntireLiteral = SliceRange(Ctx, ScalStart, ScalEnd);
		
		Return EntireLiteral;	
	Else        
		
		Result = TakeWhileNextIsPlain(Ctx, State);
		While True Do
			ChompWhitespace(Ctx);
			ChompComment(Ctx);
			
			Result1 = TakeWhileNextIsPlain(Ctx, State);
			If Result1.Start = Result1.End Then
				Break;
			Else 
				Result.End = Result1.End;
			EndIf;
			If (Ctx.Idx >= Ctx.Len - 1) Then
				Break;
			EndIf;
			
		EndDo;
		
		EntireLiteral = SliceRange(Ctx, Result.Start, Result.End);
		
		If Lower(EntireLiteral) = "true" Then
			Return True;
		ElsIf Lower(EntireLiteral) = "false" Then
			Return False;
		Else
			Try
				Return Number(EntireLiteral);
			Except
			EndTry;
		EndIf;
		
		Return EntireLiteral;	
	EndIf;
	
EndFunction

Function ParseMappingFlow(Ctx)
	
	If Ctx.Current <> Ctx.Chars.OBrace Then
		Raise "expected left brace";
	EndIf;
	
	Advance(Ctx);
	
	Entries = New Map();
	While True Do
		If Ctx.Current = Ctx.Chars.CBrace Then
			Bump(Ctx);
			Return Entries;
		ElsIf Ctx.Current = Ctx.Chars.Comma Then
			Advance(Ctx);
		Else
			Ctx.Expected.Add(Ctx.Chars.Colon);
			StartState(Ctx, "FlowMapping");
			EntryKey = Parse(Ctx);
			EndState(Ctx, "FlowMapping");
			
			ChompWhitespace(Ctx);
			ChompComment(Ctx);
			
			If Ctx.Current = Ctx.Chars.Colon Then
				PopIfMatch(Ctx.Expected, Ctx.Chars.Colon);
				Advance(Ctx);
				ChompWhitespace(Ctx);   
				
				StartState(Ctx, "Flow");
				Value = Parse(Ctx);
				EndState(Ctx, "Flow");
				
				ChompWhitespace(Ctx);
				ChompComment(Ctx);
				
				Entries.Insert(EntryKey, Value);
				
			Else
				Raise "failed to parse flow mapping";	
			EndIf;
		EndIf;
		
		
	EndDo;
	
EndFunction

Function ParseMappingMaybe(Ctx, Node)
	
	ChompWhitespace(Ctx);
	ChompComment(Ctx);
	
	If Ctx.Current = Ctx.Chars.Colon Then	
		LastExpected = LastArrayElement(Ctx.Expected);	
		If Not (LastExpected = Ctx.Chars.CBrace Or LastExpected = Ctx.Chars.Colon) Then
			Return ParseMappingBlock(Ctx, Node);	
		EndIf;		
	EndIf;
	
	Return Node;
	
EndFunction

Function ParseMappingBlock(Ctx, StartKey)
	
	LastState = LastState(Ctx);
	If LastState = "FlowIn" Or LastState = "FlowKey" Or LastState = "FlowOut" Then
		Raise "block mappings may not appear in flow collections";	
	EndIf;   
	
	Indent = Ctx.Indent;
	If Ctx.Current = Ctx.Chars.Colon Then
		Advance(Ctx);
		Entries = New Map();
		ChompWhitespace(Ctx);
		ChompComment(Ctx);
		Value = Parse(Ctx);
		Entries.Insert(StartKey, Value);
		While True Do
			If (Ctx.Idx >= Ctx.Len - 1) Then
				Break;
			ElsIf (Ctx.Current = 13 OR Ctx.Current = 10) Then
				Ctx.Indent = 0;
				If BumpNewline(Ctx) Then
					Continue;
				Else
					Break;
				EndIf;
			ElsIf (Ctx.Current = 32 OR Ctx.Current = 9) Then
				ChompIndent(Ctx);
			ElsIf Ctx.Current = Ctx.Chars.Hash Then
				ChompComment(Ctx);
			ElsIf Ctx.Indent < Indent Then
				Break;
			Else
				Ctx.Expected.Add(Ctx.Chars.Colon);
				EntryKey = Parse(Ctx);
				ChompWhitespace(Ctx);
				ChompComment(Ctx);
				If Ctx.Current = Ctx.Chars.Colon Then
					PopIfMatch(Ctx.Expected, Ctx.Chars.Colon);
					Advance(Ctx);
					ChompWhitespace(Ctx);
					Value = Parse(Ctx);
					Entries.Insert(EntryKey, Value);
				Else
					Raise "failed to parse block mapping";	
				EndIf;
			EndIf;	
		EndDo;
		
		Return Entries;
		
	Else
		Raise "failed to parse block mapping, expected ':'";	
	EndIf;
	
EndFunction

Function ParseSequenceFlow(Ctx) 
	
	StartState(Ctx, "Flow");
	If Ctx.Current <> Ctx.Chars.OBracket Then
		Raise "failed to parse flow sequence";
	EndIf;
	
	Advance(Ctx);
	Elements = New Array();
	
	While True Do
		If Ctx.Current = Ctx.Chars.CBracket Then
			Bump(Ctx);
			EndState(Ctx, "Flow");
			Return Elements;
		ElsIf Ctx.Current = Ctx.Chars.Space Or Ctx.Current = Ctx.Chars.Tab Then
			ChompWhitespace(Ctx);
		ElsIf Ctx.Current = Ctx.Chars.Hash Then
			ChompComment(Ctx);
		Else
			Element = Parse(Ctx);
			Elements.Add(Element);
			ChompWhitespace(Ctx);
			
			If Ctx.Current = Ctx.Chars.Comma Then
				Advance(Ctx);
			ElsIf Ctx.Current = Ctx.Chars.Hash Then
				ChompComment(Ctx);
			ElsIf Ctx.Current = Ctx.Chars.CBracket Then
				Bump(Ctx);
				EndState(Ctx, "Flow");
				Return Elements;
			Else
				Raise "failed to parse flow sequence";
			EndIf;
		EndIf;  
	EndDo;
EndFunction

Function ParseSequenceBlock(Ctx)

	LastState = LastState(Ctx);
	If LastState = "FlowIn" Or LastState = "FlowKey" Or LastState = "FlowOut" Then
		Raise "block sequences may not appear in flow collections";	
	EndIf;
	
	StartState(Ctx, "Block");
	
	Indent = Ctx.Indent;
	If Ctx.Current <> Ctx.Chars.Hyphen Then
		Raise "failed to parse block sequence";	
	EndIf;
	
	Seq = New Array();
	While True Do
		If (Ctx.Idx >= Ctx.Len - 1) Then
			Break;
		ElsIf Ctx.Current = Ctx.Chars.Hash Then
			ChompComment(Ctx);
		ElsIf (Ctx.Current = 13 OR Ctx.Current = 10) Then
			Ctx.Indent = 0;
			If BumpNewline(Ctx) Then
				Continue;
			Else
				Break;
			EndIf;
		ElsIf (Ctx.Current = 32 OR Ctx.Current = 9) Then
			ChompIndent(Ctx);       
		ElsIf Ctx.Indent < Indent Then
			Break;
		ElsIf Ctx.Current = Ctx.Chars.Hyphen Then
			Next = GetAheadN(Ctx, 1);
			If (Next = 13 OR Next = 10) Then
                Advance(Ctx);
                Advance(Ctx);
                Ctx.Indent = 0;
                If (Ctx.Current = 32 OR Ctx.Current = 9) Then
                    ChompIndent(Ctx);
                    If Ctx.Indent < Indent Then
                        Break;
                    Else 
                        Node = Parse(Ctx);
                        Seq.Add(Node);
                    EndIf;
                ElsIf 0 < Indent Then
                    Break;
                Else 
                    Node = Parse(Ctx);
                    Seq.Add(Node);
                EndIf;
            ElsIf (Next = 32 OR Next = 9) Then
                Advance(Ctx);
                Advance(Ctx);
                Node = Parse(Ctx);
                Seq.Add(Node);
            Else
                Raise "unexpected '-'";
            EndIf;
		ElsIf Ctx.Indent = Indent Then
			Break;	      
		Else 
			Raise "expected sequence item";
		EndIf;
	EndDo;
	
    EndState(Ctx, "Block");
	
	Return Seq;
	
EndFunction

Function LastState(Ctx)
	
	Len = Ctx.States.Count();
	If Len = 0 Then
		Return Undefined;
	EndIf;   
	
	Return Ctx.States[Len - 1];
	
EndFunction

Function PopState(Ctx)
	
	Len = Ctx.States.Count();
	If Len = 0 Then
		Return Undefined;
	EndIf;   
	
	State = Ctx.States[Len - 1];
	Ctx.States.Delete(Len - 1);
	
	Return State;
	
EndFunction

Function StartState(Ctx, StateKind)
	
	NextState = Undefined;
	
	LastState = LastState(Ctx);
	If LastState <> Undefined Then
		If StateKind = "Flow" Then
			NextState = "FlowIn";
		ElsIf StateKind = "FlowMapping" Then
			NextState = "FlowKey";
		ElsIf StateKind = "Block" Then
			If LastState = "FlowIn" Or LastState = "FlowOut" Or LastState = "FlowKey" Then
				Raise "block collections cannot be values in flow collections";
			ElsIf LastState = "BlockIn" Or LastState = "BlockOut" Or LastState = "BlockKey" Then
				NextState = "BlockIn";
			EndIf;
		ElsIf StateKind = "BlockMapping" Then
			NextState = "BlockKey";
		EndIf;	
	Else  
		If StateKind = "Flow" Then
			NextState = "FlowIn";
		ElsIf StateKind = "FlowMapping" Then
			NextState = "FlowKey";
		ElsIf StateKind = "Block" Then
			NextState = "BlockOut";
		ElsIf StateKind = "BlockMapping" Then
			NextState = "BlockKey";
		EndIf;	
	EndIf;
	
	Ctx.States.Add(NextState);
	
EndFunction

Function EndState(Ctx, Expect)
	
	Actual = PopState(Ctx);
	
	If Actual <> Undefined Then
		
		CtxMatches = False;
		If Expect = "Flow" Then
			CtxMatches = Actual = "FlowIn" Or Actual = "FlowOut";
		ElsIf Expect = "FlowMapping" Then
			CtxMatches = Actual = "FlowKey";
		ElsIf Expect = "Block" Then
			CtxMatches = Actual = "BlockIn" Or Actual = "BlockOut";
		ElsIf Expect = "BlockMapping" Then
			CtxMatches = Actual = "BlockKey";
		EndIf; 
		
		If Not CtxMatches Then
			Raise StrTemplate(
	            "expected but failed to end state {%1}, instead found {%2}",
	            Expect,
				Actual
	        );
		EndIf;	
		
    Else
        Raise StrTemplate(
            "expected state {%1} but no states remained",
            Expect
        );
	EndIf;
	
EndFunction


Function AtEnd(Ctx) 
	
	Return (Ctx.Idx >= Ctx.Len - 1);
	
EndFunction

Function Peek(Ctx) 
	
	// NextIdx = Ctx.Idx + 1;
	If Ctx.Len <= Ctx.Idx + 1 Then
		Return Undefined;
	EndIf;
	
	Return Ctx.Source[Ctx.Idx + 1];
	
EndFunction    

Function Advance(Ctx) 
	
	If Not Bump(Ctx) then
		Raise "unexpected end of input";	
	EndIf;
	
EndFunction 

Function Bump(Ctx) 
	
	// NextIdx = Ctx.Idx + 1;
	If Ctx.Len < Ctx.Idx + 1 Then
		Return False;
	EndIf;
	
	Ctx.Idx     = Ctx.Idx + 1;
	Ctx.Current = Ctx.Source[Ctx.Idx];
	
	Return True;
	
EndFunction    

Function BumpNewline(Ctx)

	// NextIdx = Ctx.Idx + 1;
	If Ctx.Len <= Ctx.Idx + 1 Then
		Return False;
	EndIf;
	
	Value = Ctx.Source[Ctx.Idx + 1];
	
	If Value = Ctx.Chars.CR Or Value = Ctx.Chars.LF Then
		Return Bump(Ctx);
	Else
		Ctx.Idx     = Ctx.Idx + 1;
		Ctx.Current = Value;
	EndIf;
	
	Return True;
	
EndFunction

Function ChompComment(Ctx)
	
	If Ctx.Current = Ctx.Chars.Hash Then
		Ctx.Idx     = Ctx.Idx + 1;
		Ctx.Current = Ctx.Source[Ctx.Idx];
		While Not (Ctx.Current = 13 OR Ctx.Current = 10) Do
			Ctx.Idx     = Ctx.Idx + 1;
			Ctx.Current = Ctx.Source[Ctx.Idx];
			
		EndDo;
	EndIf;
		
EndFunction

Function ChompWhitespace(Ctx)
	
	While Ctx.Current = Ctx.Chars.Space Or Ctx.Current = Ctx.Chars.Tab Do
		Ctx.Idx     = Ctx.Idx + 1;
		Ctx.Current = Ctx.Source[Ctx.Idx];   
		
	EndDo;
		
EndFunction

Function ChompIndent(Ctx)
	
	Indent = 0;
	While Ctx.Current = Ctx.Chars.Space Or Ctx.Current = Ctx.Chars.Tab Do
		Ctx.Idx     = Ctx.Idx + 1;
		Ctx.Current = Ctx.Source[Ctx.Idx];
			
		Indent = Indent + 1;
	EndDo;
	
	Ctx.Indent = Indent;
		
EndFunction

Function ChompNewlines(Ctx)
	
	While Ctx.Current = Ctx.Chars.CR Or Ctx.Current = Ctx.Chars.LF Do
		Advance(Ctx);
	EndDo;
		
EndFunction

Function CheckAheadN(Ctx, Position, Value)
	
	NextIdx = Ctx.Idx + Position;
	If Ctx.Len - NextIdx <= 0 Then
		Return False;
	EndIf;
	
	Current = Ctx.Source[NextIdx];
	
	Return Current = Value;
	
EndFunction

Function GetAheadN(Ctx, Position)
	
	NextIdx = Ctx.Idx + Position;
	If Ctx.Len - NextIdx <= 0 Then
		Return Undefined;
	EndIf;
	
	Return Ctx.Source[NextIdx];
	
EndFunction

// Byte 

Function Code(Token, Index = 1)
	Return CharCode(Token, Index);
EndFunction

Function IsIndicator(Token)

	Return
	    Token = 45  OR // -
	    Token = 63  OR // ?
	    Token = 58  OR // :
	    Token = 44  OR // ,
	    Token = 91  OR // [
	    Token = 93  OR // ]
	    Token = 123 OR // {
	    Token = 125 OR // }
	    Token = 38  OR // &
	    Token = 42  OR // *
	    Token = 33  OR // !
	    Token = 124 OR // |
	    Token = 35  OR // #
	    Token = 62  OR // >
	    Token = 34  OR // "
	    Token = 39  OR // '
	    Token = 37  OR // %
	    Token = 64  OR // @
	    Token = 96;    // `
	
EndFunction

Function IsLinebreak(Token)

	Return (Token = 13 OR Token = 10);   // CR LF
	
	
		
EndFunction 

Function IsWhitespace(Token)

	Return (Token = 32 OR Token = 9); // " " Or TAB
	
	
	
EndFunction

Function IsNsChar(Token)
	Return (Not (Token = 32 OR Token = 9)); // " " Or TAB	
EndFunction    

Function IsFlowIndicator(Token)
	
	Return
	    Token = 91  OR // [
	    Token = 93  OR // ]
	    Token = 123 OR // {
	    Token = 125 OR // }
	    Token = 44;    // ,
	
EndFunction

Function IsNsPlainSafe(Token, State)

	If State = "FlowIn" Or State = "FlowKey" Then
		Return (Not (Token = 32 OR Token = 9)) And Not IsFlowIndicator(Token) And Not (Token = 13 OR Token = 10);	
	EndIf;
	
	Return Token <> 32 And Token <> 9 And Token <> 13 And Token <> 10;
	
EndFunction

Function IsNsPlain(Token, Next = Undefined, State)
	
	Alt1 = IsNsPlainSafe(Token, State) And Token <> 58 And Token <> 35; // : AND #
	Alt2 = ?(Next = Undefined, False, (Not (Token = 32 OR Token = 9)) And Not (Token = 13 OR Token = 10) And Next = 35);
	Alt3 = ?(Next = Undefined, False, Token = 58 And IsNsPlainSafe(Next, State));
	
	Return Alt1 Or Alt2 Or Alt3;
	
EndFunction

Function IsScalarStart(Token, Next = Undefined, State)

	If (Token = 13 OR Token = 10) Then
		Return False;
	EndIf; 
	
	If (Not (Token = 32 OR Token = 9)) And Not (Token = 45 OR Token = 63 OR Token = 58 OR Token = 44 OR Token = 91 OR Token = 93 OR Token = 123 OR Token = 125 OR Token = 38 OR Token = 42 OR Token = 33 OR Token = 124 OR Token = 35 OR Token = 62 OR Token = 34 OR Token = 39 OR Token = 37 OR Token = 64 OR Token = 96) Then
		Return True
	EndIf;
	
	If Token = 34 Or Token = 39 Then // " OR '
		Return True;
	ElsIf Token = 63 Or Token = 58 Or Token = 45 Then // ? OR : OR -
		If Next <> Undefined Then
			Return IsNsPlainSafe(Next, State);
		EndIf;
	EndIf;
	
	Return False;
		
EndFunction

//

Function LastArrayElement(Array)

	Len = Array.Count();
	If Len = 0 Then
		Return Undefined;
	EndIf;
	
	Return Array[Len - 1];
	
EndFunction

Function PopIfMatch(Array, Expect)
	Last = LastArrayElement(Array);
	If Last <> Expect Then
		Raise "token was not expected";
	EndIf;
	
	Array.Delete(Array.Count() - 1);
	
EndFunction

// 

Function TakeWhile(Ctx, Value)
	
	Result = New Structure();
	Result.Insert("Error", False);
	Result.Insert("Start", Ctx.Idx);
	Result.Insert("End"  , Result.Start);
	
	While True Do
		//Peeked = Peek(Ctx);
		If Ctx.Current = Value Then
			Break;
		ElsIf Not Bump(Ctx) Then
			Result.End = Result.End + 1;
			Result.Error = True;
			Return Result;
		EndIf;
		Result.End = Result.End + 1;
	EndDo;
	
	Return Result;
	
EndFunction

Function TakeWhileNextIsPlain(Ctx, State)
	
	Result = New Structure();
	Result.Insert("Error", False);
	Result.Insert("Start", Ctx.Idx);
	Result.Insert("End"  , Result.Start);
	
	While True Do
		Peeked = Ctx.Source[Ctx.Idx + 1];
		If Not IsNsPlain(Ctx.Current, Peeked, State) Then
			Break;
		ElsIf Not Bump(Ctx) Then
			Result.End = Result.End + 1;
			Result.Error = True;
			Return Result;
		EndIf;
		Result.End = Result.End + 1;
	EndDo;
	
	Return Result;
	
EndFunction

Function SliceRange(Ctx, Start, Val End)  
	
	End = Min(Ctx.Len, End);
	
	Result = "";
	For Index = Start To End - 1 Do
		Result = Result + Char(Ctx.Source[Index]);	
	EndDo;
	
	Return Result;	                          
	
EndFunction    

#Region Constructors

Function NewContext()

	Result = New Structure();
	Result.Insert("Current" );
	Result.Insert("Source"  );
	Result.Insert("Len"     );
	Result.Insert("Idx"     );
	Result.Insert("Indent"  );
	Result.Insert("Expected", New Array());
	Result.Insert("States"  , New Array());
	Result.Insert("Chars"   );
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion












