SAFETST ; Tests for safe.m — error handling patterns
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tDivideNormal(.pass,.fail)
        do tDivideByZero(.pass,.fail)
        do tRequirePass(.pass,.fail)
        do tRequireFail(.pass,.fail)
        do tRequireMessage(.pass,.fail)
        do tTryCatchSuccess(.pass,.fail)
        do tTryCatchFailure(.pass,.fail)
        do tEtrapScope(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
; ── divide ────────────────────────────────────────────────────────────────────
        ;
tDivideNormal(pass,fail)        ;@TEST "divide() returns correct result normally"
        new result
        set result=$$divide^safe(10,2)
        do eq^STDASSERT(.pass,.fail,result,5,"10/2=5")
        quit
        ;
tDivideByZero(pass,fail)        ;@TEST "divide() returns empty string on divide-by-zero"
        new result
        set result=$$divide^safe(10,0)
        do eq^STDASSERT(.pass,.fail,result,"","divide by zero returns empty")
        quit
        ;
; ── require ───────────────────────────────────────────────────────────────────
        ;
tRequirePass(pass,fail) ;@TEST "require() does nothing when condition is true"
        new ok,errMsg
        set ok=1,errMsg=""
        ; If require fires $ECODE, tryCatch will catch it
        do tryCatch^safe("do require^safe(1=1,""should not fire"")",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,1,"require(true) does not raise")
        quit
        ;
tRequireFail(pass,fail) ;@TEST "require() raises U1 error when condition is false"
        new ok,errMsg
        set ok=1,errMsg=""
        do tryCatch^safe("do require^safe(1=0,""bad input"")",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,0,"require(false) raises error")
        quit
        ;
tRequireMessage(pass,fail)      ;@TEST "require() stores message in lastError()"
        new ok,errMsg
        do tryCatch^safe("do require^safe(0,""age must be positive"")",.ok,.errMsg)
        new msg
        set msg=$$lastError^safe()
        do eq^STDASSERT(.pass,.fail,msg,"age must be positive","lastError returns message")
        quit
        ;
; ── tryCatch ─────────────────────────────────────────────────────────────────
        ;
tTryCatchSuccess(pass,fail)     ;@TEST "tryCatch ok=1 when code succeeds"
        new ok,errMsg,x
        set x=0
        do tryCatch^safe("set x=42",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,1,"ok=1 on success")
        do eq^STDASSERT(.pass,.fail,x,42,"code actually ran")
        quit
        ;
tTryCatchFailure(pass,fail)     ;@TEST "tryCatch ok=0 and errMsg set when code errors"
        new ok,errMsg
        do tryCatch^safe("set x=1/0",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,0,"ok=0 on error")
        do true^STDASSERT(.pass,.fail,errMsg'="","errMsg is populated")
        quit
        ;
; ── $ETRAP scoping ───────────────────────────────────────────────────────────
        ;
tEtrapScope(pass,fail)  ;@TEST "new $ETRAP restores outer handler after quit"
        ; This tests the MUMPS scoping guarantee:
        ; new $ETRAP inside a called routine is restored when that routine quits.
        ;
        ; Outer handler: sets outerFired=1
        ; Inner routine: sets its own $ETRAP and raises an error (caught inside)
        ; After inner routine returns: outer handler should NOT have fired
        ;
        new outerFired,ok,errMsg
        set outerFired=0
        new $ETRAP
        set $ETRAP="set outerFired=1 set $ECODE="""""
        ;
        ; Call a routine that sets its own handler and catches its own error
        do tryCatch^safe("set x=1/0",.ok,.errMsg)
        ;
        ; Outer handler must not have fired — inner routine owned its error
        do eq^STDASSERT(.pass,.fail,outerFired,0,"outer $ETRAP not disturbed")
        do eq^STDASSERT(.pass,.fail,ok,0,"inner routine did catch the error")
        quit
