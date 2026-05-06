IDXTST
         new pass,fail
         do start^STDASSERT(.pass,.fail)
         do setup
         do tBuildIndexes(.pass,.fail)
         do tByDoneOpen(.pass,.fail)
         do tByDoneDone(.pass,.fail)
         do tByFirst(.pass,.fail)
         do tCountOpen(.pass,.fail)
         do tCountDone(.pass,.fail)
         do tGenericAdd(.pass,.fail)
         do tGenericRemove(.pass,.fail)
         do tGenericLookup(.pass,.fail)
         do tGenericCount(.pass,.fail)
         do tIndexAdd(.pass,.fail)
         do tIndexStatus(.pass,.fail)
         do tIndexDel(.pass,.fail)
         do teardown
         do report^STDASSERT(pass,fail)
         quit
         ;
setup()
         ; Build a small ^tasks dataset directly (no tasks.m dependency)
         kill ^tasks,^tasksByDone,^tasksByFirst,^idxTest
         set ^tasks(1)="Learn MUMPS"
         set ^tasks(1,"done")=0
         set ^tasks(2)="Write tests"
         set ^tasks(2,"done")=1
         set ^tasks(3)="Learn YottaDB"
         set ^tasks(3,"done")=0
         set ^tasks(4)="Build an app"
         set ^tasks(4,"done")=1
         quit
         ;
teardown()
         kill ^tasks,^tasksByDone,^tasksByFirst,^idxTest
         quit
         ;
tBuildIndexes(pass,fail)
         do build^idx()
         do true^STDASSERT(.pass,.fail,$data(^tasksByDone),"build: tasksByDone exists")
         do true^STDASSERT(.pass,.fail,$data(^tasksByFirst),"build: tasksByFirst exists")
         quit
         ;
tByDoneOpen(pass,fail)
         new res,n
         set n=$$byDone^idx(0,.res)
         do eq^STDASSERT(.pass,.fail,n,2,"byDone(0): 2 open tasks")
         ; IDs 1 and 3 are open — in collation order
         do eq^STDASSERT(.pass,.fail,$get(res(1)),1,"byDone(0): first is id 1")
         do eq^STDASSERT(.pass,.fail,$get(res(2)),3,"byDone(0): second is id 3")
         quit
         ;
tByDoneDone(pass,fail)
         new res,n
         set n=$$byDone^idx(1,.res)
         do eq^STDASSERT(.pass,.fail,n,2,"byDone(1): 2 done tasks")
         do eq^STDASSERT(.pass,.fail,$get(res(1)),2,"byDone(1): first is id 2")
         do eq^STDASSERT(.pass,.fail,$get(res(2)),4,"byDone(1): second is id 4")
         quit
         ;
tByFirst(pass,fail)
         new res,n
         ; Tasks starting with "L": ids 1 ("Learn MUMPS") and 3 ("Learn YottaDB")
         set n=$$byFirst^idx("L",.res)
         do eq^STDASSERT(.pass,.fail,n,2,"byFirst(L): 2 tasks start with L")
         do eq^STDASSERT(.pass,.fail,$get(res(1)),1,"byFirst(L): first is id 1")
         do eq^STDASSERT(.pass,.fail,$get(res(2)),3,"byFirst(L): second is id 3")
         ; Task starting with "W": id 2 ("Write tests")
         set n=$$byFirst^idx("W",.res)
         do eq^STDASSERT(.pass,.fail,n,1,"byFirst(W): 1 task starts with W")
         do eq^STDASSERT(.pass,.fail,$get(res(1)),2,"byFirst(W): is id 2")
         quit
         ;
tCountOpen(pass,fail)
         do eq^STDASSERT(.pass,.fail,$$countOpen^idx(),2,"countOpen: 2 open tasks")
         quit
         ;
tCountDone(pass,fail)
         do eq^STDASSERT(.pass,.fail,$$countDone^idx(),2,"countDone: 2 done tasks")
         quit
         ;
tGenericAdd(pass,fail)
         ; Generic add inserts an index entry
         do add^idx("^idxTest","red",42)
         do add^idx("^idxTest","red",99)
         do add^idx("^idxTest","blue",7)
         do true^STDASSERT(.pass,.fail,$data(^idxTest("red",42)),"add: red/42 present")
         do true^STDASSERT(.pass,.fail,$data(^idxTest("red",99)),"add: red/99 present")
         do true^STDASSERT(.pass,.fail,$data(^idxTest("blue",7)),"add: blue/7 present")
         kill ^idxTest
         quit
         ;
tGenericRemove(pass,fail)
         ; Generic remove deletes only the specified entry
         do add^idx("^idxTest","red",42)
         do add^idx("^idxTest","red",99)
         do remove^idx("^idxTest","red",42)
         do eq^STDASSERT(.pass,.fail,$data(^idxTest("red",42)),0,"remove: 42 gone")
         do true^STDASSERT(.pass,.fail,$data(^idxTest("red",99)),"remove: 99 still there")
         kill ^idxTest
         quit
         ;
tGenericLookup(pass,fail)
         new res,n
         do add^idx("^idxTest","cat",10)
         do add^idx("^idxTest","cat",20)
         do add^idx("^idxTest","cat",30)
         set n=$$lookup^idx("^idxTest","cat",.res)
         do eq^STDASSERT(.pass,.fail,n,3,"lookup: returns count 3")
         do eq^STDASSERT(.pass,.fail,$get(res(1)),10,"lookup: first id")
         do eq^STDASSERT(.pass,.fail,$get(res(2)),20,"lookup: second id")
         do eq^STDASSERT(.pass,.fail,$get(res(3)),30,"lookup: third id")
         kill ^idxTest
         quit
         ;
tGenericCount(pass,fail)
         do add^idx("^idxTest","x",1)
         do add^idx("^idxTest","x",2)
         do add^idx("^idxTest","x",3)
         do eq^STDASSERT(.pass,.fail,$$count^idx("^idxTest","x"),3,"count: 3 entries for x")
         do eq^STDASSERT(.pass,.fail,$$count^idx("^idxTest","z"),0,"count: 0 entries for z")
         kill ^idxTest
         quit
         ;
tIndexAdd(pass,fail)
         ; indexAdd updates indexes when called after adding to ^tasks
         kill ^tasksByDone,^tasksByFirst
         set ^tasks(5)="New task"
         set ^tasks(5,"done")=0
         do indexAdd^idx(5)
         do true^STDASSERT(.pass,.fail,$data(^tasksByDone(0,5)),"indexAdd: done index updated")
         do true^STDASSERT(.pass,.fail,$data(^tasksByFirst("N",5)),"indexAdd: first-char index updated")
         kill ^tasks(5),^tasksByDone(0,5),^tasksByFirst("N",5)
         quit
         ;
tIndexStatus(pass,fail)
         ; indexStatus moves task between done=0 and done=1 buckets
         do build^idx()
         ; Task 1 is open (done=0). Mark it done.
         set ^tasks(1,"done")=1
         do indexStatus^idx(1,0)
         do eq^STDASSERT(.pass,.fail,$data(^tasksByDone(0,1)),0,"indexStatus: removed from open bucket")
         do true^STDASSERT(.pass,.fail,$data(^tasksByDone(1,1)),"indexStatus: added to done bucket")
         ; Restore for teardown
         set ^tasks(1,"done")=0
         do build^idx()
         quit
         ;
tIndexDel(pass,fail)
         ; indexDel removes task from all indexes
         do build^idx()
         do indexDel^idx(1,0,"Learn MUMPS")
         do eq^STDASSERT(.pass,.fail,$data(^tasksByDone(0,1)),0,"indexDel: removed from done index")
         do eq^STDASSERT(.pass,.fail,$data(^tasksByFirst("L",1)),0,"indexDel: removed from first-char index")
         ; Restore for teardown
         do build^idx()
         quit
