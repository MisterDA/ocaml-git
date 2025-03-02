module type S = sig
  val connect : Mimic.ctx -> Mimic.ctx Lwt.t val ctx : Mimic.ctx
end

module Make
    (TCP : Mirage_protocols.TCP)
    (Happy_eyeballs : Git_mirage_happy_eyeballs.S with type flow = TCP.flow) : S
