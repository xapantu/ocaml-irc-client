module Make(Io: Irc_transport.IO) = struct
  type connection_t = {
    sock: Io.file_descr;
    buffer: Buffer.t;
    read_length: int;
    read_data: Bytes.t; (* for reading *)
    lines: string Queue.t; (* lines read so far *)
    mutable terminated: bool;
  }

  open Io

  let rec really_write ~connection ~data ~offset ~length =
    if length = 0 then return () else
      Io.write connection.sock data offset length
      >>= (fun chars_written ->
        really_write ~connection ~data
          ~offset:(offset + chars_written)
          ~length:(length - chars_written))

  let send_raw ~connection ~data =
    let formatted_data = Bytes.unsafe_of_string (Printf.sprintf "%s\r\n" data) in
    let length = Bytes.length formatted_data in
    really_write ~connection ~data:formatted_data ~offset:0 ~length

  module M = Irc_message

  let send ~connection msg =
    send_raw ~connection ~data:(M.to_string msg)

  let send_join ~connection ~channel =
    send ~connection (M.join ~chans:[channel] ~keys:None)
  
  let send_join_passwd ~connection ?password:(p=None) ~channel =
    let k = 
      match p with
      | None -> None
      | Some p -> Some [p]
    in
    send ~connection (M.join ~chans:[channel] ~keys:k)

  let send_nick ~connection ~nick =
    send ~connection (M.nick nick)

  let send_pass ~connection ~password =
    send ~connection (M.pass password)

  let send_pong ~connection ~message =
    send ~connection (M.pong message)
  
  let send_ping ~connection ~message =
    send ~connection (M.ping message)

  let send_privmsg ~connection ~target ~message =
    send ~connection (M.privmsg ~target message)

  let send_notice ~connection ~target ~message =
    send ~connection (M.notice ~target message)

  let send_quit ~connection =
    send ~connection (M.quit ~msg:None)

  let send_user ~connection ~username ~mode ~realname =
    let msg = M.user ~username ~mode ~realname in
    send ~connection msg

  let mk_connection_ sock =
    let read_length = 1024 in
    { sock = sock;
      buffer=Buffer.create 128;
      read_length;
      read_data = Bytes.make read_length ' ';
      lines = Queue.create ();
      terminated = false;
    }

  let rec next_line_ ~connection:c : string option Io.t =
    if c.terminated
    then return None
    else if Queue.length c.lines > 0
    then return (Some (Queue.pop c.lines))
    else (
      (* Read some data into our string. *)
      Io.read c.sock c.read_data 0 c.read_length
      >>= function
      | 0 ->
        c.terminated <- true;
        return None (* EOF from server - we have quit or been kicked. *)
      | len ->
        (* read some data, push lines into [c.lines] (if any) *)
        let input = Bytes.sub_string c.read_data 0 len in
        let lines = Irc_helpers.handle_input ~buffer:c.buffer ~input in
        List.iter (fun l -> Queue.push l c.lines) lines;
        next_line_ ~connection:c
    )

  let rec wait_for_welcome ~connection =
    next_line_ ~connection
    >>= function
    | None -> return ()
    | Some line ->
      match M.parse line with
        | `Ok {M.command = M.Other ("001", _); _} ->
          (* we received "RPL_WELCOME", i.e. 001 *)
          return ()
        | `Ok {M.command = M.PING message; _} ->
          (* server may ask for ping at any time *)
          send_pong ~connection ~message >>= fun () -> wait_for_welcome ~connection
        | _ -> wait_for_welcome ~connection


  let connect
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ~addr ~port ~nick () =
    Io.open_socket addr port >>= (fun sock ->
      let connection = mk_connection_ sock in
      begin
        match password with
        | Some password -> send_pass ~connection ~password
        | None -> return ()
      end
      >>= fun () -> send_nick ~connection ~nick
      >>= fun () -> send_user ~connection ~username ~mode ~realname
      >>= fun () -> wait_for_welcome ~connection
      >>= fun () -> return connection)

  let connect_by_name
      ?(username="irc-client") ?(mode=0) ?(realname="irc-client")
      ?password ~server ~port ~nick () =
    Io.gethostbyname server
    >>= (function
      | [] -> Io.return None
      | addr :: _ ->
        connect ~addr ~port ~username ~mode ~realname ~nick ?password ()
        >>= fun connection -> Io.return (Some connection))

  let listen ~connection ~callback =
    let rec ping_pong_thread () =
      catch (fun () ->
          send_ping ~connection ~message:"ping"
          >>= fun () -> sleep 20.0
          >>= fun () -> return (Format.printf "Connection timeout@.")
        ) (function
          | Canceled ->
            sleep 30.0
            >>= ping_pong_thread
          | e -> raise e
        )
    in
    let p = ping_pong_thread () in
    let rec listen' () =
      next_line_ ~connection
      >>= function
      | None -> return ()
      | Some line ->
        begin match M.parse line with
          | `Ok {M.command = M.PING message; _} ->
            (* Handle pings without calling the callback. *)
            send_pong ~connection ~message
          | `Ok {M.command = M.PONG _; _} ->
            return (cancel p)
          | result -> callback connection result
        end
        >>= listen'
    in
    (listen' ()) <?> p

end
