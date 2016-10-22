(** Generic IRC client library, functorised over the
    {{:Irc_transport.IO.html}Irc_transport.IO} module. *)

module Make : functor (Io: Irc_transport.IO) ->
  sig
    type connection_t
    (** A connection to an IRC server. *)

    val send : connection:connection_t -> Irc_message.t -> unit Io.t
    (** Send the given message *)

    val send_join : connection:connection_t -> channel:string -> unit Io.t
    (** Send the JOIN command. *)
    
    val send_join_passwd : connection:connection_t -> ?password:string option -> channel:string -> unit Io.t
    (** Send the JOIN command with a password. *)

    val send_nick : connection:connection_t -> nick:string -> unit Io.t
    (** Send the NICK command. *)

    val send_pass : connection:connection_t -> password:string -> unit Io.t
    (** Send the PASS command. *)

    val send_pong : connection:connection_t -> message:string -> unit Io.t
    (** Send the PONG command. *)

    val send_privmsg : connection:connection_t ->
      target:string -> message:string -> unit Io.t
    (** Send the PRIVMSG command. *)

    val send_notice : connection:connection_t ->
      target:string -> message:string -> unit Io.t
    (** Send the NOTICE command. *)

    val send_quit : connection:connection_t -> unit Io.t
    (** Send the QUIT command. *)

    val send_user : connection:connection_t ->
      username:string -> mode:int -> realname:string -> unit Io.t
    (** Send the USER command. *)

    val connect :
      ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
      addr:Io.inet_addr -> port:int -> nick:string -> unit ->
      connection_t Io.t
    (** Connect to an IRC server at address [addr]. The PASS command will be
        sent if [password] is not None. *)

    val connect_by_name :
      ?username:string -> ?mode:int -> ?realname:string -> ?password:string ->
      server:string -> port:int -> nick:string -> unit ->
      connection_t option Io.t
    (** Try to resolve the [server] name using DNS, otherwise behaves like
        {!connect}. Returns [None] if no IP could be found for the given
        name. *)

    val listen : connection:connection_t ->
      callback:(
        connection_t ->
        Irc_message.parse_result ->
        unit Io.t
      ) ->
      unit Io.t
    (** [listen connection callback] listens for incoming messages on
        [connection]. All server pings are handled internally; all other
        messages are passed, along with [connection], to [callback]. *)
  end
