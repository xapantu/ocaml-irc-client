module type IO = sig
  type 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
  val catch : (unit -> 'a t) -> (exn -> 'a t) -> 'a t
  val sleep : float -> unit t
  val return : 'a -> 'a t
  val cancel : 'a t -> unit
  val (<?>) : 'a t -> 'a t -> 'a t
  exception Canceled

  type file_descr

  type inet_addr

  val open_socket : inet_addr -> int -> file_descr t
  val close_socket : file_descr -> unit t

  val read : file_descr -> Bytes.t -> int -> int -> int t
  val write : file_descr -> Bytes.t -> int -> int -> int t

  val gethostbyname : string -> inet_addr list t

  val iter : ('a -> unit t) -> 'a list -> unit t
end
