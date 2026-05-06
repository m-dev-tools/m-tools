CSVTST  ; Tests for csv.m — parser and file importer
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tParseFieldPlain(.pass,.fail)
        do tParseFieldQuoted(.pass,.fail)
        do tParseFieldQuotedComma(.pass,.fail)
        do tParseFieldDoubledQuote(.pass,.fail)
        do tParseFieldLast(.pass,.fail)
        do tParseFieldMissing(.pass,.fail)
        do tFieldCount(.pass,.fail)
        do tFieldCountQuoted(.pass,.fail)
        do tImportFile(.pass,.fail)
        do tImportHeaders(.pass,.fail)
        do tImportRowCount(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
; ── parseField ────────────────────────────────────────────────────────────────
        ;
tParseFieldPlain(pass,fail)     ;@TEST "parseField: simple unquoted fields"
        do eq^STDASSERT(.pass,.fail,$$parseField^csv("alice,30,portland",1),"alice","field 1")
        do eq^STDASSERT(.pass,.fail,$$parseField^csv("alice,30,portland",2),"30","field 2")
        do eq^STDASSERT(.pass,.fail,$$parseField^csv("alice,30,portland",3),"portland","field 3")
        quit
        ;
tParseFieldQuoted(pass,fail)    ;@TEST "parseField: quoted field (no special chars)"
        do eq^STDASSERT(.pass,.fail,$$parseField^csv("""Alice"",30",1),"Alice","quoted field 1")
        quit
        ;
tParseFieldQuotedComma(pass,fail)       ;@TEST "parseField: quoted field containing a comma"
        new line
        set line="""Smith, Bob"",30,Portland"
        do eq^STDASSERT(.pass,.fail,$$parseField^csv(line,1),"Smith, Bob","quoted with comma")
        do eq^STDASSERT(.pass,.fail,$$parseField^csv(line,2),"30","field after quoted")
        quit
        ;
tParseFieldDoubledQuote(pass,fail)      ;@TEST "parseField: doubled quote = literal quote char"
        ; Field value:  a"b       (one literal double-quote in the middle)
        ; CSV encoding: "a""b"    (doubled = escaped quote inside quoted field)
        ; Full line:    "a""b",c
        ; MUMPS literal for that line: """a""""b"",c"
        new line
        set line="""a""""b"",c"
        do eq^STDASSERT(.pass,.fail,$$parseField^csv(line,1),"a""b","a""b parsed correctly")
        do eq^STDASSERT(.pass,.fail,$$parseField^csv(line,2),"c","field after quoted-with-quote")
        quit
        ;
tParseFieldLast(pass,fail)      ;@TEST "parseField: last field has no trailing comma"
        do eq^STDASSERT(.pass,.fail,$$parseField^csv("a,b,c",3),"c","last field no trailing comma")
        quit
        ;
tParseFieldMissing(pass,fail)   ;@TEST "parseField: returns empty for out-of-range field"
        do eq^STDASSERT(.pass,.fail,$$parseField^csv("a,b",5),"","field beyond end = empty")
        quit
        ;
; ── fieldCount ────────────────────────────────────────────────────────────────
        ;
tFieldCount(pass,fail)  ;@TEST "fieldCount: counts unquoted CSV fields"
        do eq^STDASSERT(.pass,.fail,$$fieldCount^csv("a,b,c"),3,"3 plain fields")
        do eq^STDASSERT(.pass,.fail,$$fieldCount^csv("only"),1,"1 field, no delimiters")
        quit
        ;
tFieldCountQuoted(pass,fail)    ;@TEST "fieldCount: ignores commas inside quotes"
        new line
        set line="""Smith, Bob"",30,Portland"
        do eq^STDASSERT(.pass,.fail,$$fieldCount^csv(line),3,"3 fields despite quoted comma")
        quit
        ;
; ── importFile ────────────────────────────────────────────────────────────────
        ;
tImportFile(pass,fail)  ;@TEST "importFile: data values are stored correctly"
        do setup
        do eq^STDASSERT(.pass,.fail,$get(^csvTest(1,"name")),"Alice","row 1 name")
        do eq^STDASSERT(.pass,.fail,$get(^csvTest(1,"age")),"32","row 1 age")
        do eq^STDASSERT(.pass,.fail,$get(^csvTest(2,"name")),"Bob","row 2 name")
        do eq^STDASSERT(.pass,.fail,$get(^csvTest(3,"city")),"Oakland","row 3 city")
        do teardown
        quit
        ;
tImportHeaders(pass,fail)       ;@TEST "importFile: headers stored in correct order"
        do setup
        do eq^STDASSERT(.pass,.fail,$get(^csvTest("headers",1)),"name","header 1")
        do eq^STDASSERT(.pass,.fail,$get(^csvTest("headers",2)),"age","header 2")
        do eq^STDASSERT(.pass,.fail,$get(^csvTest("headers",3)),"city","header 3")
        do eq^STDASSERT(.pass,.fail,$get(^csvTest("headers",4)),"role","header 4")
        do teardown
        quit
        ;
tImportRowCount(pass,fail)      ;@TEST "importFile: count node reflects total rows"
        do setup
        do eq^STDASSERT(.pass,.fail,$get(^csvTest("count")),4,"4 data rows imported")
        do teardown
        quit
        ;
; ── Test fixtures ─────────────────────────────────────────────────────────────
        ;
setup   ; Write a temp CSV file and import it
        new file
        set file="/tmp/csvtst.csv"
        ;
        ; Write the CSV file using MUMPS I/O
        open file:(newversion)
        use file
        write "name,age,city,role",!
        write "Alice,32,Portland,engineer",!
        write "Bob,28,Seattle,designer",!
        write "Carol,35,Oakland,manager",!
        write """Dana, L."",29,Portland,engineer",!
        close file
        use $principal
        ;
        do importFile^csv(file,"csvTest")
        quit
        ;
teardown        ; Remove temp file and global
        open "/tmp/csvtst.csv"
        close "/tmp/csvtst.csv":(delete)
        kill ^csvTest
        quit
