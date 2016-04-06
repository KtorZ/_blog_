import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Color
import Signal
import Time
import Random
import Window
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type alias Simulation =
  { particles: List Particle
  , socialMode: Bool
  , width: Int
  , height: Int
  }

type alias Particle =
  { x: Float
  , y: Float
  , d: Float
  }

type Action
  = Move
  | Rotate Int
  | Toggle Bool
  | Resize Int

rand : Random.Generator Int
rand =
  Random.int -30 30

init : Simulation
init =
  Simulation (List.repeat 300 (Particle 0 0 0)) False 500 500
    |> update (Rotate 14)
    |> update (Rotate 14)
    |> update (Rotate 14)
    |> update (Rotate 14)
    |> update (Rotate 14)
    |> update (Rotate 14)

moveParticle : (Int, Int) -> Particle -> Particle
moveParticle (w,h) p =
  let
      x = toFloat ((round (5 * cos (degrees p.d) + p.x) + w//2) % w - w//2)
      y = toFloat ((round (5 * sin (degrees p.d) + p.y) + h//2) % h - h//2)
  in
    { p | x = x, y = y }

rotateParticle : Particle -> (List Particle, Random.Seed) -> (List Particle, Random.Seed)
rotateParticle p (xp, s) =
  let
    (d, seed) = Random.generate rand s
  in
    ({p |  d = toFloat((round(p.d) + d) % 360)}::xp, seed)

drawParticle: Particle -> Form
drawParticle p =
  ngon 3 10
    |> filled Color.lightBlue
    |> move (p.x,p.y)
    |> rotate (degrees p.d)

update: Action -> Simulation -> Simulation
update op simul =
  case op of
    Move ->
      if simul.socialMode then
        { simul | particles = List.map (moveParticle (simul.width, simul.height)) simul.particles }
      else
        simul
    Rotate s ->
      if simul.socialMode then
         { simul | particles = fst (List.foldr rotateParticle ([], Random.initialSeed s) simul.particles) }
      else
        simul
    Toggle x -> { simul | socialMode = x}
    Resize x -> { simul | width = x }

main : Signal Html
main =
  let
    operations = Signal.mailbox (Toggle False)
    sigMove = Signal.map (always Move) (Time.fps 30)
    sigRotate = Signal.map (Time.inMilliseconds >> round >> Rotate) (Time.every (200 * Time.millisecond))
    sigWidth = Signal.map Resize Window.width
    simulation = Signal.foldp update init (Signal.mergeMany [sigMove, sigRotate, sigWidth, operations.signal])
    particles = Signal.map fromSimulation simulation
  in
    Signal.map (view operations.address) particles

fromSimulation : Simulation -> (Bool, Html)
fromSimulation s =
  (s.socialMode, s |> (fromElement << collage s.width s.height << (List.map drawParticle) << .particles))


view : Signal.Address Action -> (Bool, Html) -> Html
view addr (on, simul) =
  div []
  [ div [ class "simulation" ] [ simul ]
  , div [ classList [("controls", True), ("activated", on)] ]
    [ label [onClick addr (Toggle (not on))] [ Html.text "on" ]
    , label [onClick addr (Toggle (not on))] [ Html.text "off" ]
    , input [ type' "button", onClick addr (Toggle (not on)) ] []
    ]
  ]
