#!/usr/bin/env ocaml

exception TCG of string

(* TODO: Code is horrible *)
type lineTag = SecTitle | SecBody | SecEnd | Text
type taggedLine = { tag : lineTag; str : string }

(* TODO: how to do unsafe string operations to boost the speed of this? *)
let strTrimEndSpace (s : string) =
  let is_space = function ' ' | '\n' | '\r' | '\t' -> true | _ -> false in
  let rec aux s pos_of_end_without_space =
    if is_space (String.get s pos_of_end_without_space) then
      aux s (pos_of_end_without_space - 1)
    else String.sub s 0 (pos_of_end_without_space + 1)
  in
  aux s (String.length s - 1)

let obtainLines fileName : string list =
  let inFile = open_in fileName in
  let try_read () = try Some (input_line inFile) with End_of_file -> None in
  let rec getLine acc =
    match try_read () with
    | Some s -> getLine (strTrimEndSpace s :: acc)
    | None ->
        close_in inFile;
        List.rev acc
  in
  getLine []

let rec tagLines (lines : string list) : taggedLine list =
  let rec pl lst ~inSecQ:inseq (acc : taggedLine list) : taggedLine list =
    match lst with
    | [] -> acc
    | h :: t ->
        if String.equal h "```" then
          pl t ~inSecQ:false ({ tag = SecEnd; str = h } :: acc)
        else if String.starts_with ~prefix:"```" h then
          pl t ~inSecQ:true
            ({ tag = SecTitle; str = String.sub h 3 (String.length h - 3) }
            :: acc)
        else if inseq then pl t ~inSecQ:inseq ({ tag = SecBody; str = h } :: acc)
        else pl t ~inSecQ:inseq ({ tag = Text; str = h } :: acc)
  in
  List.rev (pl lines ~inSecQ:false [])

let rec print_char_n_times (c : char) (n : int) =
  if n > 0 then (
    print_char c;
    print_char_n_times c (n - 1))
  else ()

let rec printSec l1 l2 secWidth =
  let printSecTitle (t1 : string) (t2 : string) (secWidth : int) =
    print_char '-';
    print_string t1;
    print_char_n_times '-' (secWidth - String.length t1);
    print_char '+';
    print_char '-';
    print_string t2;
    print_char_n_times '-' (secWidth - String.length t2);
    print_newline ()
  in
  let rec print_n_spaces n = print_char_n_times ' ' n in
  let rec aux lst1 lst2 =
    match (lst1, lst2) with
    | [], [] -> ()
    | h1 :: t1, [] ->
        print_char ' ';
        print_string h1;
        print_n_spaces (secWidth - String.length h1);
        print_char '|';
        print_newline ();
        aux t1 []
    | [], h2 :: t2 ->
        print_n_spaces (secWidth + 1);
        print_char '|';
        print_string h2;
        print_newline ();
        aux [] t2
    | h1 :: t1, h2 :: t2 ->
        print_char ' ';
        print_string h1;
        print_n_spaces (secWidth - String.length h1);
        print_char '|';
        print_char ' ';
        print_string h2;
        print_n_spaces (secWidth - String.length h2);
        print_newline ();
        aux t1 t2
  in
  printSecTitle (List.hd l1) (List.hd l2) secWidth;
  aux (List.tl l1) (List.tl l2)

let shutter (lst : taggedLine list) : unit =
  let maxSecWidth =
    List.fold_left
      (fun acc x -> if String.length x > acc then String.length x else acc)
      0
  in
  let rec p l (cache1 : string list) (cache2 : string list) ~useCache2:u2 =
    match l with
    | [] -> ()
    | h :: t -> (
        match h with
        | { tag = SecTitle; _ } ->
            if u2 then p t cache1 (h.str :: cache2) ~useCache2:u2
            else p t [ h.str ] [] ~useCache2:false
        | { tag = SecBody; _ } ->
            if u2 then p t cache1 (h.str :: cache2) ~useCache2:u2
            else p t (h.str :: cache1) cache2 ~useCache2:u2
        | { tag = SecEnd; _ } ->
            if u2 then (
              let secWidth = max (maxSecWidth cache1) (maxSecWidth cache2) in
              printSec (List.rev cache1) (List.rev cache2) secWidth;
              print_endline (String.make ((secWidth * 2) + 3) '=');
              p t [] [] ~useCache2:false)
            else p t cache1 cache2 ~useCache2:true
        | { tag = Text; _ } ->
            print_endline h.str;
            p t cache1 cache2 ~useCache2:false)
  in
  p lst [] [] ~useCache2:false

let () =
  if Array.length Sys.argv <= 1 then raise (TCG "Need file input")
  else shutter (tagLines (obtainLines Sys.argv.(1)))
