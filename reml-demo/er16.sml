(* It is an error to give multiple explicit regions to con1 *)

datatype t = A of int | B  (* t is boxed, which means that B and A are allocated *)

fun f () : int =
    let with r1 r2
        val x = if true then B`[r1] else A`[r2 r1] 9
    in case x of
           B => 1
         | A a => a
    end
