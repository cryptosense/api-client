let execute command =
  let ic = Unix.open_process_in command in
  let all_input = ref [] in
  try
    while true do
      all_input := input_line ic :: !all_input
    done;
    ""
  with
    End_of_file ->
    close_in ic;
    List.fold_left (fun acc l -> l ^ acc) "" !all_input
