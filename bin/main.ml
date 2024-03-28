open Mm_audio
open Music

let sample_rate = 44100
let channels = 2

let sd freq _ =
  let lpf =
    new Audio.Mono.Effect.biquad_filter sample_rate `Low_pass (freq *. 5.) 2.
  in
  let adsr = Audio.Mono.Effect.ADSR.make sample_rate (0., 0.25, 0., 1.) in
  let g = new Audio.Mono.Generator.white_noise sample_rate in
  let g = new Audio.Mono.Generator.chain g lpf in
  let g = new Audio.Mono.Generator.adsr adsr g in
  let g = new Audio.Generator.of_mono g in
  g

let bd freq _ =
  let lpf =
    new Audio.Mono.Effect.biquad_filter sample_rate `Low_pass (freq *. 1.) 2.
  in
  let adsr = Audio.Mono.Effect.ADSR.make sample_rate (0.001, 0.3, 0., 1.) in
  let g = new Audio.Mono.Generator.sine sample_rate 80. in
  let g2 = new Audio.Mono.Generator.sine sample_rate 90. in
  let g = new Audio.Mono.Generator.mult g g2 in
  let g2 = new Audio.Mono.Generator.white_noise ~volume:0.5 sample_rate in
  let g = new Audio.Mono.Generator.add g g2 in
  let g = new Audio.Mono.Generator.chain g lpf in
  let g = new Audio.Mono.Generator.adsr adsr g in
  let g = new Audio.Mono.Generator.chain g (new Audio.Mono.Effect.clip 0.9) in
  let g = new Audio.Mono.Generator.chain g (new Audio.Mono.Effect.amplify 5.) in
  let g = new Audio.Generator.of_mono g in
  g

let blen = sample_rate / 3
(* let no = Audio.create channels blen *)

let gen i =
  let buf = Audio.create channels blen in
  (i 440. 1.)#fill buf 0 blen;
  buf

let bd = gen bd
let sd = gen sd

let () =
  let oss = new Oss.writer channels sample_rate in
  (* let wav = new Audio.IO.Writer.to_wav_file channels sample_rate "out.wav" in *)
  let buf = Audio.append bd 0 blen sd 0 blen in

  (* wav#write buf 0 blen; *)
  while true do
    oss#write buf 0 (2 * blen)
  done;
  (* wav#close *)
  oss#close
