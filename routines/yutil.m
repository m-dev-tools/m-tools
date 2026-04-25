yutil   ; Helpers for the y* shell tools (yglobsize, ydiff, yexport, yseed).
        ; Each entry point is invoked via `yrun ^yutil ARGS` with $ZCMDLINE
        ; supplying the arguments. Output goes to stdout.
        quit
        ;
; ── Node counting ────────────────────────────────────────────────────────────
        ;
count   ; $ZCMDLINE: <gname>  →  prints node count under ^<gname>
        new gname,n,r,prefix,plen
        set gname=$zcmdline
        if gname="" write 0,! quit
        set prefix="^"_gname_"("
        set plen=$length(prefix)
        set n=$select($data(@("^"_gname))#2:1,1:0)
        set r="^"_gname
        for  set r=$query(@r) quit:r=""  do  quit:$extract(r,1,plen)'=prefix
        . set n=n+1
        write n,!
        quit
        ;
; ── Flat global dump ─────────────────────────────────────────────────────────
        ;
        ; Emits one line per node under ^<gname>, format:
        ;   <ref>=<value>
        ; where <ref> includes the global name and quoted subscripts so that
        ; the line could be re-applied via XECUTE "set "_<line> on a fresh
        ; database. Used by ydiff (compare two dumps) and yexport (--format=raw).
dump    ; $ZCMDLINE: <gname>
        new gname,r,prefix,plen
        set gname=$zcmdline
        if gname="" quit
        set prefix="^"_gname_"("
        set plen=$length(prefix)
        if $data(@("^"_gname))#2 write "^",gname,"=",@("^"_gname),!
        set r="^"_gname
        for  set r=$query(@r) quit:r=""  do  quit:$extract(r,1,plen)'=prefix
        . write r,"=",@r,!
        quit
        ;
; ── JSON export ──────────────────────────────────────────────────────────────
        ;
        ; Emits a JSON array of {"ref": "<reference>", "value": "<value>"}
        ; objects covering every node under ^<gname>. Pairs with yseed.
exportJson      ; $ZCMDLINE: <gname>
        new gname,r,prefix,plen,first,ref,val
        set gname=$zcmdline
        if gname="" write "[]",! quit
        set prefix="^"_gname_"("
        set plen=$length(prefix)
        set first=1
        write "["
        if $data(@("^"_gname))#2 do  set first=0
        . set ref="^"_gname,val=@("^"_gname)
        . write "{""ref"":",$$str^json(ref),",""value"":",$$str^json(val),"}"
        set r="^"_gname
        for  set r=$query(@r) quit:r=""  do  quit:$extract(r,1,plen)'=prefix
        . if 'first write ","
        . set first=0
        . write "{""ref"":",$$str^json(r),",""value"":",$$str^json(@r),"}"
        write "]",!
        quit
        ;
; ── List globals with data ───────────────────────────────────────────────────
        ;
        ; Walks $ZGBLDIR's namespace and prints one global name per line for
        ; every top-level global that has either a value or descendants.
listGlobals     ; $ZCMDLINE ignored
        new g,name
        set g="^%"
        for  set g=$order(@g) quit:g=""  do
        . set name=$extract(g,2,$length(g))
        . if $data(@g)>0 write name,!
        quit
