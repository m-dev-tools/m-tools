TXNTST
         new pass,fail
         do start^STDASSERT(.pass,.fail)
         do tCommitPersists(.pass,.fail)
         do tRollbackReverts(.pass,.fail)
         do tAtomicBothOrNeither(.pass,.fail)
         do tErrorCausesRollback(.pass,.fail)
         do tRunSuccess(.pass,.fail)
         do tLevelOutside(.pass,.fail)
         do tLevelInside(.pass,.fail)
         do tNestedLevel(.pass,.fail)
         do tTransferSuccess(.pass,.fail)
         do tTransferInsufficientFunds(.pass,.fail)
         do tTransferAtomicOnFailure(.pass,.fail)
         do report^STDASSERT(pass,fail)
         quit
         ;
tCommitPersists(pass,fail)
         ; A committed transaction persists after commit
         new ok,err
         kill ^txnTest
         tstart ():serial
         set ^txnTest(1)="hello"
         tcommit
         do eq^STDASSERT(.pass,.fail,$get(^txnTest(1)),"hello","commit: value persists")
         kill ^txnTest
         quit
         ;
tRollbackReverts(pass,fail)
         ; A rolled-back transaction leaves no trace
         kill ^txnTest
         tstart ():serial
         set ^txnTest(1)="should disappear"
         trollback
         do eq^STDASSERT(.pass,.fail,$data(^txnTest(1)),0,"rollback: global not set")
         kill ^txnTest
         quit
         ;
tAtomicBothOrNeither(pass,fail)
         ; Commit writes both globals; rollback writes neither
         kill ^txnTest
         tstart ():serial
         set ^txnTest("a")=1
         set ^txnTest("b")=2
         tcommit
         do eq^STDASSERT(.pass,.fail,$get(^txnTest("a")),1,"atomic commit: a set")
         do eq^STDASSERT(.pass,.fail,$get(^txnTest("b")),2,"atomic commit: b set")
         kill ^txnTest
         tstart ():serial
         set ^txnTest("a")=1
         set ^txnTest("b")=2
         trollback
         do eq^STDASSERT(.pass,.fail,$data(^txnTest("a")),0,"atomic rollback: a absent")
         do eq^STDASSERT(.pass,.fail,$data(^txnTest("b")),0,"atomic rollback: b absent")
         kill ^txnTest
         quit
         ;
tErrorCausesRollback(pass,fail)
         ; run() catches errors and rolls back automatically
         new ok,err
         kill ^txnTest
         ; This code sets the global then divides by zero — the set should be rolled back
         do run^txn("set ^txnTest(""x"")=42  set ^txnTest(""y"")=1/0",.ok,.err)
         do eq^STDASSERT(.pass,.fail,ok,0,"run error: ok=0")
         do true^STDASSERT(.pass,.fail,err'="","run error: err message set")
         do eq^STDASSERT(.pass,.fail,$data(^txnTest("x")),0,"run error: rollback reverted set")
         kill ^txnTest
         quit
         ;
tRunSuccess(pass,fail)
         ; run() commits on success
         new ok,err
         kill ^txnTest
         do run^txn("set ^txnTest(""k"")=""good""",.ok,.err)
         do eq^STDASSERT(.pass,.fail,ok,1,"run success: ok=1")
         do eq^STDASSERT(.pass,.fail,err,"","run success: err empty")
         do eq^STDASSERT(.pass,.fail,$get(^txnTest("k")),"good","run success: value persists")
         kill ^txnTest
         quit
         ;
tLevelOutside(pass,fail)
         ; $TLEVEL is 0 when not in a transaction
         do eq^STDASSERT(.pass,.fail,$$level^txn(),0,"level: 0 outside txn")
         do eq^STDASSERT(.pass,.fail,$$inTxn^txn(),0,"inTxn: 0 outside txn")
         quit
         ;
tLevelInside(pass,fail)
         ; $TLEVEL is 1 inside a single transaction
         tstart ():serial
         do eq^STDASSERT(.pass,.fail,$$level^txn(),1,"level: 1 inside txn")
         do eq^STDASSERT(.pass,.fail,$$inTxn^txn(),1,"inTxn: 1 inside txn")
         trollback
         quit
         ;
tNestedLevel(pass,fail)
         ; Nested TSTART increments $TLEVEL
         tstart ():serial
         tstart ():serial
         do eq^STDASSERT(.pass,.fail,$$level^txn(),2,"level: 2 in nested txn")
         tcommit
         do eq^STDASSERT(.pass,.fail,$$level^txn(),1,"level: back to 1 after inner commit")
         tcommit
         do eq^STDASSERT(.pass,.fail,$$level^txn(),0,"level: 0 after outer commit")
         quit
         ;
tTransferSuccess(pass,fail)
         ; transfer() debits and credits correctly
         new ok
         kill ^txnAcct
         set ^txnAcct("alice")=100,^txnAcct("bob")=50
         set ok=$$transfer^txn("^txnAcct(""alice"")","^txnAcct(""bob"")",30)
         do eq^STDASSERT(.pass,.fail,ok,1,"transfer success: returns 1")
         do eq^STDASSERT(.pass,.fail,^txnAcct("alice"),70,"transfer success: alice debited")
         do eq^STDASSERT(.pass,.fail,^txnAcct("bob"),80,"transfer success: bob credited")
         kill ^txnAcct
         quit
         ;
tTransferInsufficientFunds(pass,fail)
         ; transfer() refuses when sender has insufficient balance
         new ok
         kill ^txnAcct
         set ^txnAcct("alice")=20,^txnAcct("bob")=50
         set ok=$$transfer^txn("^txnAcct(""alice"")","^txnAcct(""bob"")",30)
         do eq^STDASSERT(.pass,.fail,ok,0,"transfer insufficient: returns 0")
         kill ^txnAcct
         quit
         ;
tTransferAtomicOnFailure(pass,fail)
         ; When transfer fails, neither account changes
         new ok
         kill ^txnAcct
         set ^txnAcct("alice")=20,^txnAcct("bob")=50
         set ok=$$transfer^txn("^txnAcct(""alice"")","^txnAcct(""bob"")",30)
         do eq^STDASSERT(.pass,.fail,^txnAcct("alice"),20,"transfer atomic: alice unchanged")
         do eq^STDASSERT(.pass,.fail,^txnAcct("bob"),50,"transfer atomic: bob unchanged")
         kill ^txnAcct
         quit
