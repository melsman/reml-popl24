fun copy `[r1 r2] (xs : 'a list`r1) : 'a list`r2 =
  case xs of
     nil => nil
   | x :: xs => x :: xs (* If we do not copy xs, ReML complains! *)
