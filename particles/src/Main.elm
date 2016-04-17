import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Color
import Signal
import Signal.Extra
import Time
import Random
import Window
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

type alias Simulation =
  { particles: List Particle
  , socialMode: Bool
  , debugMode: Bool
  , width: Int
  , height: Int
  , domains: List Domain
  }

type alias Particle =
  { x: Float
  , y: Float
  , d: Float
  }

type alias Domain =
  { particles: List Particle
  , center: Particle
  }

type Action
  = Move
  | Rotate Int
  | ToggleSocial Bool
  | ToggleDebug Bool
  | Resize Int
  | Socialize

rand : Random.Generator Int
rand =
  Random.int -45 45

sizeDomain: Float
sizeDomain =
  100

init : Simulation
init =
  Simulation (List.repeat 100 (Particle 0 0 0)) False False 500 500 []

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

drawDomain: Domain -> Form
drawDomain d =
  circle sizeDomain
    |> outlined (solid Color.lightRed)
    |> move (d.center.x, d.center.y)

updateDomains: Particle -> List Domain -> List Domain
updateDomains p domains =
  let
      belong = List.filter (\d -> distance2 d.center p <= sizeDomain*sizeDomain) domains
  in if List.isEmpty belong
  then (Domain [p] p) :: domains
  else List.map (\d -> if List.member d belong then addParticle d  p else d) domains

addParticle: Domain -> Particle -> Domain
addParticle d p =
    { d | particles = p :: d.particles, center = (Particle d.center.x d.center.y (d.center.d + p.d)) }

distance2: Particle -> Particle -> Float
distance2 a b =
  (a.x - b.x)^2 + (a.y - b.y)^2

socializeParticle: List Domain -> Particle -> Particle
socializeParticle domains p =
  case List.filter (.particles >> List.member p) domains |> List.head of
    Nothing ->
      p -- Cannot happen
    Just d ->
      let
        avgDir = toFloat ((round d.center.d) % 360) / (List.length d.particles |> toFloat)
      in
        { p | d = p.d * 0.2 + avgDir * 0.8}

update: Action -> Simulation -> Simulation
update op simul =
  case op of
    Move ->
      { simul | particles = List.map (moveParticle (simul.width, simul.height)) simul.particles }
    Rotate s ->
        { simul | particles = fst (List.foldr rotateParticle ([], Random.initialSeed s) simul.particles) }
    ToggleSocial x -> { simul | socialMode = x}
    ToggleDebug x -> { simul | debugMode = x}
    Resize x -> { simul | width = x }
    Socialize ->
      if simul.socialMode then
        let
          domains = List.foldr updateDomains [] simul.particles
          particles = List.map (socializeParticle domains) simul.particles
        in
          { simul | particles = particles, domains = if simul.debugMode then domains else [] }
      else
        { simul | domains = [] }

main : Signal Html
main =
  let
    operations = Signal.mailbox (ToggleSocial True)
    signals = Signal.mergeMany
        [ Signal.map Resize Window.width
        , operations.signal
        , Signal.map (Time.inMilliseconds >> round >> Rotate) (Time.every (200 * Time.millisecond))
        , Signal.map (always Move) (Time.fps 30)
        , Signal.map (always Socialize) (Time.fps 5)
        ]
    particles = Signal.Extra.foldp' update (flip update init) signals |> Signal.map fromSimulation
  in
    Signal.map (view operations.address) particles

fromSimulation : Simulation -> (Bool, Bool, Html)
fromSimulation s =
  let
      particles = List.map drawParticle s.particles
      domains = List.map drawDomain s.domains
  in
    (s.socialMode, s.debugMode, List.append particles domains |> collage s.width s.height |> fromElement)

view : Signal.Address Action -> (Bool, Bool, Html) -> Html
view addr (isSocial, isDebug, simul) =
  div []
  [ div [ class "simulation" ] [ simul ]
  , div [ classList [("controls", True), ("activated", isSocial)] ]
    [ Html.text "Social: "
    , label [onClick addr (ToggleSocial (not isSocial))] [ Html.text "on" ]
    , label [onClick addr (ToggleSocial (not isSocial))] [ Html.text "off" ]
    , input [ type' "button", onClick addr (ToggleSocial (not isSocial)) ] []
    ]
  , div [ classList [("controls", True), ("activated", isDebug)] ]
    [ Html.text "Debug: "
    , label [onClick addr (ToggleDebug (not isDebug))] [ Html.text "on" ]
    , label [onClick addr (ToggleDebug (not isDebug))] [ Html.text "off" ]
    , input [ type' "button", onClick addr (ToggleDebug (not isDebug)) ] []
    ]
  ]
