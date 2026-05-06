VALIDATETST
         new pass,fail
         do start^STDASSERT(.pass,.fail)
         do tRequiredPass(.pass,.fail)
         do tRequiredFail(.pass,.fail)
         do tMinlenPass(.pass,.fail)
         do tMinlenFail(.pass,.fail)
         do tMaxlenPass(.pass,.fail)
         do tMaxlenFail(.pass,.fail)
         do tNumberPass(.pass,.fail)
         do tNumberFail(.pass,.fail)
         do tIntegerPass(.pass,.fail)
         do tIntegerFail(.pass,.fail)
         do tRangePass(.pass,.fail)
         do tRangeFail(.pass,.fail)
         do tInlistPass(.pass,.fail)
         do tInlistFail(.pass,.fail)
         do tCombinedPass(.pass,.fail)
         do tCombinedFail(.pass,.fail)
         do tFirstErrorOnly(.pass,.fail)
         do tMinval(.pass,.fail)
         do tMaxval(.pass,.fail)
         do report^STDASSERT(pass,fail)
         quit
         ;
tRequiredPass(pass,fail)
         new ok,err
         set ok=$$check^validate("hello","required",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"required: non-empty passes")
         do eq^STDASSERT(.pass,.fail,err,"","required: no error on pass")
         quit
         ;
tRequiredFail(pass,fail)
         new ok,err
         set ok=$$check^validate("","required",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"required: empty fails")
         do true^STDASSERT(.pass,.fail,err'="","required: error message set")
         quit
         ;
tMinlenPass(pass,fail)
         new ok,err
         set ok=$$check^validate("abc","minlen:3",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"minlen: exact length passes")
         set ok=$$check^validate("abcd","minlen:3",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"minlen: longer passes")
         quit
         ;
tMinlenFail(pass,fail)
         new ok,err
         set ok=$$check^validate("hi","minlen:3",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"minlen: too short fails")
         quit
         ;
tMaxlenPass(pass,fail)
         new ok,err
         set ok=$$check^validate("hi","maxlen:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"maxlen: short string passes")
         set ok=$$check^validate("hello","maxlen:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"maxlen: exact length passes")
         quit
         ;
tMaxlenFail(pass,fail)
         new ok,err
         set ok=$$check^validate("toolong","maxlen:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"maxlen: too long fails")
         quit
         ;
tNumberPass(pass,fail)
         new ok,err
         set ok=$$check^validate("42","number",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"number: integer string passes")
         set ok=$$check^validate("3.14","number",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"number: decimal string passes")
         set ok=$$check^validate("-5","number",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"number: negative passes")
         quit
         ;
tNumberFail(pass,fail)
         new ok,err
         set ok=$$check^validate("abc","number",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"number: alpha string fails")
         set ok=$$check^validate("","number",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"number: empty fails")
         quit
         ;
tIntegerPass(pass,fail)
         new ok,err
         set ok=$$check^validate("42","integer",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"integer: whole number passes")
         set ok=$$check^validate("-7","integer",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"integer: negative integer passes")
         quit
         ;
tIntegerFail(pass,fail)
         new ok,err
         set ok=$$check^validate("3.14","integer",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"integer: decimal fails")
         set ok=$$check^validate("","integer",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"integer: empty fails")
         quit
         ;
tRangePass(pass,fail)
         new ok,err
         set ok=$$check^validate("5","range:1,10",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"range: in-range passes")
         set ok=$$check^validate("1","range:1,10",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"range: lower bound passes")
         set ok=$$check^validate("10","range:1,10",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"range: upper bound passes")
         quit
         ;
tRangeFail(pass,fail)
         new ok,err
         set ok=$$check^validate("15","range:1,10",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"range: above max fails")
         set ok=$$check^validate("0","range:1,10",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"range: below min fails")
         quit
         ;
tInlistPass(pass,fail)
         new ok,err
         set ok=$$check^validate("red","inlist:red,green,blue",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"inlist: first item passes")
         set ok=$$check^validate("blue","inlist:red,green,blue",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"inlist: last item passes")
         quit
         ;
tInlistFail(pass,fail)
         new ok,err
         set ok=$$check^validate("yellow","inlist:red,green,blue",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"inlist: invalid value fails")
         do true^STDASSERT(.pass,.fail,$find(err,"one of"),"inlist: error lists choices")
         quit
         ;
tCombinedPass(pass,fail)
         new ok,err
         set ok=$$check^validate("hello","required|minlen:3|maxlen:10",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"combined: valid value passes all rules")
         quit
         ;
tCombinedFail(pass,fail)
         new ok,err
         set ok=$$check^validate("hi","required|minlen:3|maxlen:10",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"combined: short value fails minlen")
         quit
         ;
tFirstErrorOnly(pass,fail)
         new ok,err
         set ok=$$check^validate("","required|minlen:3",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"first error: required fires before minlen")
         do true^STDASSERT(.pass,.fail,$find(err,"required"),"first error: required message returned")
         quit
         ;
tMinval(pass,fail)
         new ok,err
         set ok=$$check^validate("10","minval:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"minval: above minimum passes")
         set ok=$$check^validate("3","minval:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"minval: below minimum fails")
         quit
         ;
tMaxval(pass,fail)
         new ok,err
         set ok=$$check^validate("3","maxval:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"maxval: below maximum passes")
         set ok=$$check^validate("10","maxval:5",.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"maxval: above maximum fails")
         quit
