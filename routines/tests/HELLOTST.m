HELLOTST        ; Test suite for hello.m — run with: ydb -run ^HELLOTST
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        do tGreetWorld(.pass,.fail)
        do tGreetName(.pass,.fail)
        do tShoutUppercase(.pass,.fail)
        do tShoutAlreadyUpper(.pass,.fail)
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
tGreetWorld(pass,fail)  ;@TEST "greet() returns Hello, World!"
        new result
        set result=$$greet^hello("World")
        do eq^STDASSERT(.pass,.fail,result,"Hello, World!","greet(World)")
        quit
        ;
tGreetName(pass,fail)   ;@TEST "greet() works with any name"
        new result
        set result=$$greet^hello("Alice")
        do eq^STDASSERT(.pass,.fail,result,"Hello, Alice!","greet(Alice)")
        quit
        ;
tShoutUppercase(pass,fail)      ;@TEST "shout() uppercases the name"
        new result
        set result=$$shout^hello("alice")
        do eq^STDASSERT(.pass,.fail,result,"HELLO, ALICE!","shout(alice)")
        quit
        ;
tShoutAlreadyUpper(pass,fail)   ;@TEST "shout() handles already-uppercase input"
        new result
        set result=$$shout^hello("BOB")
        do eq^STDASSERT(.pass,.fail,result,"HELLO, BOB!","shout(BOB)")
        quit
