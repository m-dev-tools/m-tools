GLOBALTST       ; Tests for globals.m
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tSetGet(.pass,.fail)
        do tGetMissing(.pass,.fail)
        do tDelete(.pass,.fail)
        do tExists(.pass,.fail)
        do tListKeys(.pass,.fail)
        do tMultiLevel(.pass,.fail)
        do tListContacts(.pass,.fail)
        do tListFields(.pass,.fail)
        do tDelContact(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
; ── Setup / teardown helpers ──────────────────────────────────────────────────
        ;
clean   ; Remove test globals — call at start of tests that need a clean state
        do basicDelAll^globals()
        kill ^contacts
        quit
        ;
; ── Tests ─────────────────────────────────────────────────────────────────────
        ;
tSetGet(pass,fail)      ;@TEST "set and get a value roundtrips correctly"
        do clean
        do basicSet^globals("color","blue")
        new result
        set result=$$basicGet^globals("color")
        do eq^STDASSERT(.pass,.fail,result,"blue","get after set")
        quit
        ;
tGetMissing(pass,fail)  ;@TEST "get on missing key returns empty string"
        do clean
        new result
        set result=$$basicGet^globals("nosuchkey")
        do eq^STDASSERT(.pass,.fail,result,"","get missing key returns empty")
        quit
        ;
tDelete(pass,fail)      ;@TEST "delete removes the value"
        do clean
        do basicSet^globals("x","42")
        do basicDel^globals("x")
        new result
        set result=$$basicGet^globals("x")
        do eq^STDASSERT(.pass,.fail,result,"","value gone after delete")
        quit
        ;
tExists(pass,fail)      ;@TEST "$DATA check: exists() returns 1/0 correctly"
        do clean
        do basicSet^globals("present","yes")
        do eq^STDASSERT(.pass,.fail,$$exists^globals("present"),1,"exists() on set key")
        do eq^STDASSERT(.pass,.fail,$$exists^globals("absent"),0,"exists() on missing key")
        quit
        ;
tListKeys(pass,fail)    ;@TEST "$ORDER: listKeys returns all keys in order"
        do clean
        do basicSet^globals("banana","1")
        do basicSet^globals("apple","2")
        do basicSet^globals("cherry","3")
        ; $ORDER returns keys in collation order (alphabetic for strings)
        new result
        set result=$$listKeys^globals()
        do eq^STDASSERT(.pass,.fail,result,"apple,banana,cherry","keys in collation order")
        quit
        ;
tMultiLevel(pass,fail)  ;@TEST "multi-level subscripts store independently"
        kill ^contacts
        do storeContact^globals("Alice","phone","555-1234")
        do storeContact^globals("Alice","email","alice@example.com")
        do storeContact^globals("Bob","phone","555-5678")
        do eq^STDASSERT(.pass,.fail,$$getContact^globals("Alice","phone"),"555-1234","Alice phone")
        do eq^STDASSERT(.pass,.fail,$$getContact^globals("Alice","email"),"alice@example.com","Alice email")
        do eq^STDASSERT(.pass,.fail,$$getContact^globals("Bob","phone"),"555-5678","Bob phone")
        ; Alice's data doesn't bleed into Bob's
        do eq^STDASSERT(.pass,.fail,$$getContact^globals("Bob","email"),"","Bob email missing")
        quit
        ;
tListContacts(pass,fail)        ;@TEST "$ORDER on first level lists contact names"
        kill ^contacts
        do storeContact^globals("Zara","phone","1")
        do storeContact^globals("Alice","phone","2")
        do storeContact^globals("Bob","phone","3")
        new result
        set result=$$listContacts^globals()
        do eq^STDASSERT(.pass,.fail,result,"Alice,Bob,Zara","contacts in collation order")
        quit
        ;
tListFields(pass,fail)  ;@TEST "$ORDER on second level lists fields for one contact"
        kill ^contacts
        do storeContact^globals("Alice","phone","555-1234")
        do storeContact^globals("Alice","email","alice@example.com")
        do storeContact^globals("Alice","city","Portland")
        new result
        set result=$$listFields^globals("Alice")
        do eq^STDASSERT(.pass,.fail,result,"city,email,phone","Alice fields in order")
        quit
        ;
tDelContact(pass,fail)  ;@TEST "kill ^contacts(name) removes all fields for that contact"
        kill ^contacts
        do storeContact^globals("Alice","phone","555-1234")
        do storeContact^globals("Bob","phone","555-9999")
        do delContact^globals("Alice")
        do eq^STDASSERT(.pass,.fail,$$getContact^globals("Alice","phone"),"","Alice deleted")
        do eq^STDASSERT(.pass,.fail,$$getContact^globals("Bob","phone"),"555-9999","Bob unaffected")
        quit
