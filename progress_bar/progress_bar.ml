let clear_progress_bar () = print_string "\013\027[K"

let display_progress_bar total_size current_progress =
  let width =
    match Terminal_size.get_columns () with
    | Some w -> w
    | None -> 80
  in
  let available_count = width - 10 in
  let filled_count =
    if total_size > 0 then
      available_count * current_progress / total_size
    else
      0
  in
  let percentage =
    if total_size > 0 then
      float_of_int current_progress /. float_of_int total_size *. 100.0
    else
      0.
  in
  let filled = String.make filled_count '=' in
  let empty = String.make (available_count - filled_count) ' ' in
  let line_end =
    if current_progress = total_size then
      "\n"
    else
      ""
  in
  clear_progress_bar ();
  Printf.printf "[%s%s] %6.2f%%%s%!" filled empty percentage line_end
