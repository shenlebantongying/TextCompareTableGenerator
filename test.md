# Input/Output
```SML
fun copyFile(name1, name2) =
    let
        val file1 = TextIO.openIn name1
        val s     = TextIO.inputAll file1
        val _     = TextIO.closeIn file1
        val file2 = TextIO.openOut name2
    in
        TextIO.output(file2, s);
        TextIO.closeOut file2
end
```
```Ocaml
let copy_file name1 name2 =
   let file1 = open_in name1 in
   let size = in_channel_length file1 in
   let buf = String.create size in
       really_input file1 buf 0 size;
       close_in file1;
   let file2 = open_out name2 in
       output_string file2 buf;
       close_out file2
```
# Local Declarations
```SML
fun pyt(x,y) =
   let
      val xx = x * x
      val yy = y * y
   in
      Math.sqrt(xx + yy)
   end
```
```Ocaml
let pyt x y =
   let xx = x *. x in
   let yy = y *. y in
   sqrt (xx +. yy)
```
