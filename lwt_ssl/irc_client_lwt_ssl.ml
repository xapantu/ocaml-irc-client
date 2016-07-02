module Io = struct
  type 'a t = 'a Lwt.t
  let (>>=) = Lwt.bind
  let return = Lwt.return
  let catch = Lwt.catch
  let cancel = Lwt.cancel
  let sleep = Lwt_unix.sleep
  let (<?>) = Lwt.((<?>))
  exception Canceled = Lwt.Canceled

  type file_descr = Lwt_ssl.socket

  type inet_addr = Lwt_unix.inet_addr

  let _ =
    Ssl_threads.init ();
    Ssl.init ()

  let open_socket addr port =
    let sock = Lwt_unix.socket Lwt_unix.PF_INET Lwt_unix.SOCK_STREAM 0 in
    let sockaddr = Lwt_unix.ADDR_INET (addr, port) in
    let ctx = Ssl.create_context Ssl.SSLv23 Ssl.Client_context in
    Lwt_unix.connect sock sockaddr >>= fun () ->
        Lwt_ssl.ssl_connect sock ctx

  let close_socket = Lwt_ssl.close

  let read socket s i1 i2 =
    Lwt.catch (fun () ->
        Lwt_ssl.read socket s i1 i2
      ) (function
    | Ssl.Read_error(Ssl.Error_syscall) ->
      (* for some unknown reason, the connection was closed *)
      Lwt.return 0
    | e -> raise e
      ) 

  let write = Lwt_ssl.write

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
