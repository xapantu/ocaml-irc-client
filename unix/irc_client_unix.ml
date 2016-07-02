module Io = struct
  type 'a t = 'a
  let (>>=) x f = f x
  let (<?>) a b = a
  let return x = x
  let catch = fun f g ->
    try
      f ()
    with
    | e -> g e
  let cancel = fun a -> ()
  exception Canceled
  let sleep = fun _ -> raise Canceled

  type file_descr = Unix.file_descr

  type inet_addr = Unix.inet_addr

  let open_socket addr port =
    let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
    let sockaddr = Unix.ADDR_INET (addr, port) in
    Unix.connect sock sockaddr;
    sock

  let close_socket = Unix.close

  let read = Unix.read
  let write = Unix.write

  let gethostbyname name =
    try
      let entry = Unix.gethostbyname name in
      Array.to_list entry.Unix.h_addr_list
    with Not_found ->
      []

  let iter = List.iter
end

include Irc_client.Make(Io)
