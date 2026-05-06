JSONTST
         new pass,fail
         do start^STDASSERT(.pass,.fail)
         do tStr(.pass,.fail)
         do tStrEscape(.pass,.fail)
         do tNum(.pass,.fail)
         do tBool(.pass,.fail)
         do tNull(.pass,.fail)
         do tObj(.pass,.fail)
         do tArr(.pass,.fail)
         do tNested(.pass,.fail)
         do report^STDASSERT(pass,fail)
         quit
         ;
tStr(pass,fail)
         do eq^STDASSERT(.pass,.fail,$$str^json("hello"),"""hello""","str: simple string")
         do eq^STDASSERT(.pass,.fail,$$str^json(""),""""_"""","str: empty string")
         do eq^STDASSERT(.pass,.fail,$$str^json("a b"),"""a b""","str: string with space")
         quit
         ;
tStrEscape(pass,fail)
         ; double quote inside string
         do eq^STDASSERT(.pass,.fail,$$str^json("say ""hi"""),"""say \""hi\""""","str: escaped quote")
         ; backslash
         do eq^STDASSERT(.pass,.fail,$$str^json("a\b"),"""a\\b""","str: escaped backslash")
         ; newline ($char(10))
         do eq^STDASSERT(.pass,.fail,$$str^json("a"_$char(10)_"b"),"""a\nb""","str: escaped newline")
         ; tab ($char(9))
         do eq^STDASSERT(.pass,.fail,$$str^json("a"_$char(9)_"b"),"""a\tb""","str: escaped tab")
         quit
         ;
tNum(pass,fail)
         do eq^STDASSERT(.pass,.fail,$$num^json(42),"42","num: integer")
         do eq^STDASSERT(.pass,.fail,$$num^json(3.14),"3.14","num: decimal")
         do eq^STDASSERT(.pass,.fail,$$num^json(-7),"-7","num: negative")
         do eq^STDASSERT(.pass,.fail,$$num^json(0),"0","num: zero")
         quit
         ;
tBool(pass,fail)
         do eq^STDASSERT(.pass,.fail,$$bool^json(1),"true","bool: 1 is true")
         do eq^STDASSERT(.pass,.fail,$$bool^json(0),"false","bool: 0 is false")
         do eq^STDASSERT(.pass,.fail,$$bool^json(99),"true","bool: non-zero is true")
         quit
         ;
tNull(pass,fail)
         do eq^STDASSERT(.pass,.fail,$$null^json(),"null","null: returns null")
         quit
         ;
tObj(pass,fail)
         new keys,vals,result
         set keys(1)="name",vals(1)=$$str^json("Alice")
         set keys(2)="age",vals(2)=$$num^json(30)
         set result=$$obj^json(.keys,.vals)
         do eq^STDASSERT(.pass,.fail,result,"{""name"":""Alice"",""age"":30}","obj: two fields")
         ; empty object
         new k,v
         set result=$$obj^json(.k,.v)
         do eq^STDASSERT(.pass,.fail,result,"{}","obj: empty object")
         quit
         ;
tArr(pass,fail)
         new items,result
         set items(1)=$$str^json("a")
         set items(2)=$$str^json("b")
         set items(3)=$$str^json("c")
         set result=$$arr^json(.items)
         do eq^STDASSERT(.pass,.fail,result,"[""a"",""b"",""c""]","arr: string array")
         ; empty array
         new it
         set result=$$arr^json(.it)
         do eq^STDASSERT(.pass,.fail,result,"[]","arr: empty array")
         quit
         ;
tNested(pass,fail)
         ; {"user":{"name":"Bob"},"scores":[1,2,3]}
         new innerK,innerV,outerK,outerV,scoreItems,result
         ; inner object: {"name":"Bob"}
         set innerK(1)="name",innerV(1)=$$str^json("Bob")
         ; scores array: [1,2,3]
         set scoreItems(1)=$$num^json(1)
         set scoreItems(2)=$$num^json(2)
         set scoreItems(3)=$$num^json(3)
         ; outer object
         set outerK(1)="user",outerV(1)=$$obj^json(.innerK,.innerV)
         set outerK(2)="scores",outerV(2)=$$arr^json(.scoreItems)
         set result=$$obj^json(.outerK,.outerV)
         do eq^STDASSERT(.pass,.fail,result,"{""user"":{""name"":""Bob""},""scores"":[1,2,3]}","nested obj+arr")
         quit
