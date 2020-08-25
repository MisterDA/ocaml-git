(*
 * Copyright (c) 2013-2017 Thomas Gazagnaire <thomas@gazagnaire.org>
 * and Romain Calascibetta <romain.calascibetta@gmail.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(** The synchronization commands to a git repository. *)

module type S = sig
  type hash

  type store

  type error = private [> `Msg of string | `Exn of exn | `Not_found ]

  val pp_error : error Fmt.t

  val fetch :
    resolvers:Conduit.resolvers ->
    Smart_git.endpoint ->
    store ->
    ?version:[> `V1 ] ->
    ?capabilities:Smart.Capability.t list ->
    [ `All | `Some of Reference.t list | `None ] ->
    ((hash * (Reference.t * hash) list) option, error) result Lwt.t

  val push :
    resolvers:Conduit.resolvers ->
    Smart_git.endpoint ->
    store ->
    ?version:[> `V1 ] ->
    ?capabilities:Smart.Capability.t list ->
    [ `Create of Reference.t
    | `Delete of Reference.t
    | `Update of Reference.t * Reference.t ]
    list ->
    (unit, error) result Lwt.t
end

module Make
    (Digestif : Digestif.S)
    (Pack : Smart_git.APPEND with type +'a fiber = 'a Lwt.t)
    (Index : Smart_git.APPEND with type +'a fiber = 'a Lwt.t)
    (Conduit : Conduit.S
                 with type +'a io = 'a Lwt.t
                  and type input = Cstruct.t
                  and type output = Cstruct.t)
    (Store : Minimal.S with type hash = Digestif.t)
    (HTTP : Smart_git.HTTP) : sig
  type hash = Digestif.t

  type store = Store.t

  type error =
    [ `Msg of string | `Exn of exn | `Not_found | `Store of Store.error ]

  val pp_error : error Fmt.t

  val fetch :
    resolvers:Conduit.resolvers ->
    Smart_git.endpoint ->
    store ->
    ?version:[> `V1 ] ->
    ?capabilities:Smart.Capability.t list ->
    [ `All | `Some of Reference.t list | `None ] ->
    src:Pack.uid ->
    dst:Pack.uid ->
    idx:Index.uid ->
    Pack.t ->
    Index.t ->
    ([ `Pack of hash * (Reference.t * hash) list | `Empty ], [> error ]) result
    Lwt.t

  val push :
    resolvers:Conduit.resolvers ->
    Smart_git.endpoint ->
    store ->
    ?version:[> `V1 ] ->
    ?capabilities:Smart.Capability.t list ->
    [ `Create of Reference.t
    | `Delete of Reference.t
    | `Update of Reference.t * Reference.t ]
    list ->
    (unit, [> error ]) result Lwt.t
end
