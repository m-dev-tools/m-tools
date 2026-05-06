TASKSTST        ; Tests for tasks.m
        new pass,fail
        do start^STDASSERT(.pass,.fail)
        ;
        ; clean state before all tests
        do clearAll^tasks()
        ;
        do tAddReturnsId(.pass,.fail)
        do tAddStoresTitle(.pass,.fail)
        do tAddRequiresTitle(.pass,.fail)
        do tNewTaskIsOpen(.pass,.fail)
        do tDoneMarksComplete(.pass,.fail)
        do tUndoneReopens(.pass,.fail)
        do tDoneOnMissing(.pass,.fail)
        do tDelRemovesTask(.pass,.fail)
        do tDelOnMissing(.pass,.fail)
        do tExistsAfterAdd(.pass,.fail)
        do tExistsAfterDel(.pass,.fail)
        do tCountEmpty(.pass,.fail)
        do tCountAfterAdds(.pass,.fail)
        do tCountOpen(.pass,.fail)
        do tClearDone(.pass,.fail)
        do tIdsIncrement(.pass,.fail)
        ;
        ; clean up after tests
        do clearAll^tasks()
        ;
        do report^STDASSERT(pass,fail)
        quit
        ;
; ── Helpers ───────────────────────────────────────────────────────────────────
        ;
clean   ; Reset tasks global between tests that need isolation
        do clearAll^tasks()
        quit
        ;
; ── Tests ─────────────────────────────────────────────────────────────────────
        ;
tAddReturnsId(pass,fail)        ;@TEST "add() returns a numeric ID"
        do clean
        new id
        set id=$$add^tasks("Buy milk")
        do true^STDASSERT(.pass,.fail,id>0,"add returns positive ID")
        quit
        ;
tAddStoresTitle(pass,fail)      ;@TEST "add() stores the title retrievably"
        do clean
        new id,title
        set id=$$add^tasks("Walk the dog")
        set title=$$getTitle^tasks(id)
        do eq^STDASSERT(.pass,.fail,title,"Walk the dog","title stored correctly")
        quit
        ;
tAddRequiresTitle(pass,fail)    ;@TEST "add() raises error on empty title"
        new ok,errMsg
        do tryCatch^safe("set id=$$add^tasks("""")",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,0,"empty title raises error")
        quit
        ;
tNewTaskIsOpen(pass,fail)       ;@TEST "newly added task has done=0"
        do clean
        new id
        set id=$$add^tasks("New task")
        do eq^STDASSERT(.pass,.fail,$$isDone^tasks(id),0,"new task is open")
        quit
        ;
tDoneMarksComplete(pass,fail)   ;@TEST "done() sets done=1"
        do clean
        new id
        set id=$$add^tasks("Finish report")
        do done^tasks(id)
        do eq^STDASSERT(.pass,.fail,$$isDone^tasks(id),1,"done() marks task complete")
        quit
        ;
tUndoneReopens(pass,fail)       ;@TEST "undone() sets done=0 again"
        do clean
        new id
        set id=$$add^tasks("Write tests")
        do done^tasks(id)
        do undone^tasks(id)
        do eq^STDASSERT(.pass,.fail,$$isDone^tasks(id),0,"undone() reopens task")
        quit
        ;
tDoneOnMissing(pass,fail)       ;@TEST "done() raises error for non-existent ID"
        new ok,errMsg
        do tryCatch^safe("do done^tasks(99999)",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,0,"done() on missing ID raises error")
        quit
        ;
tDelRemovesTask(pass,fail)      ;@TEST "del() removes the task"
        do clean
        new id
        set id=$$add^tasks("Temporary task")
        do del^tasks(id)
        do eq^STDASSERT(.pass,.fail,$$exists^tasks(id),0,"task gone after del()")
        quit
        ;
tDelOnMissing(pass,fail)        ;@TEST "del() raises error for non-existent ID"
        new ok,errMsg
        do tryCatch^safe("do del^tasks(99999)",.ok,.errMsg)
        do eq^STDASSERT(.pass,.fail,ok,0,"del() on missing ID raises error")
        quit
        ;
tExistsAfterAdd(pass,fail)      ;@TEST "exists() returns 1 after add"
        do clean
        new id
        set id=$$add^tasks("Check existence")
        do eq^STDASSERT(.pass,.fail,$$exists^tasks(id),1,"exists() after add")
        quit
        ;
tExistsAfterDel(pass,fail)      ;@TEST "exists() returns 0 after del"
        do clean
        new id
        set id=$$add^tasks("Delete me")
        do del^tasks(id)
        do eq^STDASSERT(.pass,.fail,$$exists^tasks(id),0,"exists() after del")
        quit
        ;
tCountEmpty(pass,fail)  ;@TEST "count() returns 0 on empty task list"
        do clean
        do eq^STDASSERT(.pass,.fail,$$count^tasks(),0,"count empty")
        quit
        ;
tCountAfterAdds(pass,fail)      ;@TEST "count() reflects correct total"
        do clean
        do add^tasks("Task one")
        do add^tasks("Task two")
        do add^tasks("Task three")
        do eq^STDASSERT(.pass,.fail,$$count^tasks(),3,"count after 3 adds")
        quit
        ;
tCountOpen(pass,fail)   ;@TEST "countOpen() excludes completed tasks"
        do clean
        new id1,id2,id3
        set id1=$$add^tasks("Open one")
        set id2=$$add^tasks("Open two")
        set id3=$$add^tasks("Done one")
        do done^tasks(id3)
        do eq^STDASSERT(.pass,.fail,$$countOpen^tasks(),2,"2 open out of 3")
        quit
        ;
tClearDone(pass,fail)   ;@TEST "clearDone() removes only completed tasks"
        do clean
        new id1,id2,deleted
        set id1=$$add^tasks("Keep me")
        set id2=$$add^tasks("Delete me")
        do done^tasks(id2)
        set deleted=$$clearDone^tasks()
        do eq^STDASSERT(.pass,.fail,deleted,1,"clearDone returns count deleted")
        do eq^STDASSERT(.pass,.fail,$$exists^tasks(id1),1,"open task survived")
        do eq^STDASSERT(.pass,.fail,$$exists^tasks(id2),0,"done task removed")
        quit
        ;
tIdsIncrement(pass,fail)        ;@TEST "each add() gets a unique incrementing ID"
        do clean
        new id1,id2,id3
        set id1=$$add^tasks("First")
        set id2=$$add^tasks("Second")
        set id3=$$add^tasks("Third")
        do true^STDASSERT(.pass,.fail,id2>id1,"id2 > id1")
        do true^STDASSERT(.pass,.fail,id3>id2,"id3 > id2")
        quit
