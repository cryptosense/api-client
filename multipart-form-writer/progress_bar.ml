let erase_progress_bar _size =
  print_string "\013\027[K"

let display_progress_bar total_size current_progress =
  let width = match Terminal_size.get_columns () with
  | Some w -> w
  | None -> 80
  in
  let equal_count = (width - 10) * current_progress / total_size in
  let progress = float_of_int current_progress  /. float_of_int total_size  *. 100.0 in
  let pre_progress = "[" in
  let progress_bar = String.make equal_count '=' in
  let progress_padding = String.make (width - 10 - equal_count) ' ' in
  let post_progress = Printf.sprintf "] %0.2f%%" progress in
  let post_progress_padding_length = 10 - 1 - String.length post_progress in
  let post_progress_padding =
      if total_size = current_progress then
          (String.make post_progress_padding_length ' ') ^ "\n"
      else
          String.make post_progress_padding_length ' '
  in
  let final =
    pre_progress
    ^ progress_bar
    ^ progress_padding
    ^ post_progress
    ^ post_progress_padding
  in
  print_string final;
  String.length final

let progress_bar ~size stream =
    let consumed = ref 0 in
    let bar_length = ref 0 in
    let progress_callback elt =
        let chunk_size = String.length elt in
        consumed := !consumed + chunk_size;
        erase_progress_bar !bar_length;
        bar_length := display_progress_bar size !consumed;
        elt
    in
    Lwt_stream.map progress_callback stream
