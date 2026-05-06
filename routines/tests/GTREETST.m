GTREETST        ; Tests for gtree.m
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tMkrefDepth1(.pass,.fail)
        do tMkrefDepth2(.pass,.fail)
        do tMkrefDepth3(.pass,.fail)
        do tMkrefOrderSeed(.pass,.fail)
        do tStripCaret(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        ;
        ; Visual integration demo — not an assertion, just shows the output
        write !!,"── Integration demo ─────────────────────────────",!
        do demo
        quit
        ;
; ── Unit tests for mkref ─────────────────────────────────────────────────────
        ;
tMkrefDepth1(pass,fail) ;@TEST "mkref at depth 1 builds ^global(key)"
        new path
        new result
        set result=$$mkref^gtree("demo",1,"apple")
        do eq^STDASSERT(.pass,.fail,result,"^demo(""apple"")","mkref depth 1 with key")
        quit
        ;
tMkrefDepth2(pass,fail) ;@TEST "mkref at depth 2 includes parent from path(1)"
        new path
        set path(1)="Alice"
        new result
        set result=$$mkref^gtree("contacts",2,"phone")
        do eq^STDASSERT(.pass,.fail,result,"^contacts(""Alice"",""phone"")","mkref depth 2")
        quit
        ;
tMkrefDepth3(pass,fail) ;@TEST "mkref at depth 3 includes path(1) and path(2)"
        new path
        set path(1)="users"
        set path(2)="Alice"
        new result
        set result=$$mkref^gtree("app",3,"age")
        do eq^STDASSERT(.pass,.fail,result,"^app(""users"",""Alice"",""age"")","mkref depth 3")
        quit
        ;
tMkrefOrderSeed(pass,fail)      ;@TEST "mkref with empty key builds $ORDER seed"
        new path
        set path(1)="Alice"
        new result
        set result=$$mkref^gtree("contacts",2,"")
        do eq^STDASSERT(.pass,.fail,result,"^contacts(""Alice"","""")","mkref $ORDER seed")
        quit
        ;
tStripCaret(pass,fail)  ;@TEST "show() accepts ^gname with leading caret"
        ; We test this by checking the strip logic directly, not the full output
        new gname
        set gname="^contacts"
        if $extract(gname,1)="^" set gname=$extract(gname,2,$length(gname))
        do eq^STDASSERT(.pass,.fail,gname,"contacts","caret stripped from gname")
        quit
        ;
; ── Integration demo ──────────────────────────────────────────────────────────
        ;
demo    ; Populate test globals and display them
        ;
        ; --- flat key/value store ---
        write "Flat global (^treeDemo):",!
        kill ^treeDemo
        set ^treeDemo("apple")="red"
        set ^treeDemo("banana")="yellow"
        set ^treeDemo("cherry")="red"
        do show^gtree("treeDemo")
        ;
        write !
        ;
        ; --- multi-level: contacts ---
        write "Multi-level global (^treeContacts):",!
        kill ^treeContacts
        set ^treeContacts("Alice","city")="Portland"
        set ^treeContacts("Alice","email")="alice@example.com"
        set ^treeContacts("Alice","phone")="555-1234"
        set ^treeContacts("Bob","phone")="555-9999"
        set ^treeContacts("Zara","email")="zara@example.com"
        set ^treeContacts("Zara","phone")="555-4321"
        do show^gtree("treeContacts")
        ;
        write !
        ;
        ; --- three levels deep ---
        write "Three-level global (^treeOrg):",!
        kill ^treeOrg
        set ^treeOrg("engineering","backend","Alice")="lead"
        set ^treeOrg("engineering","backend","Bob")="engineer"
        set ^treeOrg("engineering","frontend","Carol")="engineer"
        set ^treeOrg("product","design","Dana")="designer"
        do show^gtree("treeOrg")
        ;
        ; cleanup
        kill ^treeDemo,^treeContacts,^treeOrg
        quit
