module Io = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return
  let catch = Lwt.catch
  let cancel = Lwt.cancel
  let sleep = Lwt_unix.sleep
  let (<?>) = Lwt.((<?>))
  exception Canceled = Lwt.Canceled

  type file_descr = Lwt_unix.file_descr

  type inet_addr = Lwt_unix.inet_addr

  let open_socket addr port =
    let sock = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let sockaddr = Lwt_unix.ADDR_INET (addr, port) in
    Lwt_unix.connect sock sockaddr >>= fun () ->
    return sock

  let close_socket = Lwt_unix.close

  let read = Lwt_unix.read
  let write = Lwt_unix.write

  let gethostbyname name =
    Lwt.catch
      (fun () ->
      Lwt_unix.gethostbyname name >>= fun entry ->
      let addrs = Array.to_list entry.Unix.h_addr_list in
      Lwt.return addrs
    ) (function
      | Not_found -> Lwt.return_nil
      | e -> Lwt.fail e
      )

  let iter = Lwt_list.iter_s
end

include Irc_client.Make(Io)
