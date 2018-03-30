;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname q2) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;; squash
;; start with (simulation PosReal)
(require rackunit)
(require 2htdp/image)
(require 2htdp/universe)
(require "extras.rkt")

(check-location "06" "q2.rkt")

(provide
 simulation
 initial-world
 world-ready-to-serve?
 world-after-tick
 world-after-key-event
 world-balls
 world-racket
 ball-x
 ball-y
 racket-x
 racket-y
 ball-vx
 ball-vy
 racket-vx
 racket-vy
 world-after-mouse-event
 racket-after-mouse-event
 racket-selected?
 )

;; constant

;; dimension of court
(define COURT-WIDTH 425)
(define COURT-HEIGHT 649)
(define COURT-X-CENTER (/ (+ COURT-WIDTH 1) 2))
(define COURT-Y-CENTER (/ (+ COURT-HEIGHT 1) 2))

;; dimension of ball
(define BALL-RADIUS 3)
(define MOUSE-CIRCLE-RADIUS 4)

;; dimension of racket
(define RACKET-WIDTH 47)
(define RACKET-HEIGHT 7)
(define HALF-RACKET-WIDTH (/ (- RACKET-WIDTH 1) 2))
(define HALF-RACKET-HEIGHT (/ (- RACKET-HEIGHT 1) 2))

;; colors
(define COLOR-BLACK "black")
(define COLOR-GREEN "green")
(define COLOR-YELLOW "yellow")
(define COLOR-WHITE "white")
(define COLOR-BLUE "blue")

;; key event
(define KEY-SPACE " ")
(define KEY-B "b")
(define KEY-UP "up")
(define KEY-DOWN "down")
(define KEY-LEFT "left")
(define KEY-RIGHT "right")

;; mouse even
(define MOUSE-DOWN "button-down")
(define MOUSE-UP "button-up")
(define MOUSE-DRAG "drag")

;; original state of ball and racket
(define INITIAL-X-CORD 330)
(define INITIAL-Y-CORD 384)
(define INITIAL-X-VEL 3)
(define INITIAL-Y-VEL -9)

;; pause interval, at the end of interval, reset world
(define RESET-INTERVAL 3)

;; selectable distance
(define SELECT-DISTANCE 25)

;; ball-pic
(define BALL (circle BALL-RADIUS "solid" COLOR-BLACK))

;; mouse-pic
(define MOUSE-CIRCLE (circle MOUSE-CIRCLE-RADIUS "solid" COLOR-BLUE))

;; racket-pic
(define RACKET (rectangle RACKET-WIDTH RACKET-HEIGHT "solid" COLOR-GREEN))


;; data definitions

;; A Color is represented as one of the following strings:
;; "black", "blue", "green", "white", "yellow"
;; INTERPRETATION: the color in string
;; OBSERVER TEMPLATE
;; (define (color-fn s)
;;   (cond
;;     [(string=? s "black") ...]
;;     [(string=? s "blue") ...]
;;     [(string=? s "green") ...]
;;     [(string=? s "white") ...]
;;     [(string=? s "yellow") ...]))

;; REPRESENTATION:
;; A World is represented as a
;; (make-world
;;  background
;;  balls
;;  mouse
;;  racket
;;  pause?
;;  pause-time
;;  ready-to-serve?
;;  speed)

;; INTERPRETATION:
;; background: Color, represented as the background of scene(court)
;; balls: BallList, represented as the list of balls in the world
;; racket: Racket, represented as the racket in the world
;; mouse: Mouse, represented as the mouse in the world
;; pause?: Boolean, is the world in pause?
;; pause-time: Integer, represented as the time that the world in pause
;; ready-to-serve?: Boolean, is the world ready-to-serve?
;; speed: PosReal, represented as the speed of simulator

;; IMPLEMENTATION:
(define-struct world
  (background balls racket mouse pause? pause-time ready-to-serve? speed))

;; CONTRACTOR TEMPLATE:
;; (make-world Color BallList Racket Mouse Boolean Integer Boolean PosReal)

;; OBSERVER TEMPLATE:
;; world-fn: World -> ??
;; (define (world-fn w)
;;  (...
;;    (world-background w)
;;    (world-balls w)
;;    (world-racket w)
;;    (world-mouse w)
;;    (world-pause? w)
;;    (world-pause-time w)
;;    (world-ready-to-serve? w)
;;    (world-speed w)))


;; REPRESENTATION:
;; A ball is represented as a (x y vx vy)
;; INTERPRETATION:
;; x, y: PosInteger, represenets the postion (x, y) of the ball
;; vx, vy: Integer, represents the velocity (vx, vy) of the ball

;; IMPLEMENTATION:
(define-struct ball (x y vx vy))

;; exmaples of ball for testing
(define outside-ball (make-ball -2 -3 1 1))
(define inside-ball (make-ball 20 20 -3 3))
(define down-ball (make-ball 300 700 3 -3))
(define collides-ball (make-ball 40 -2 3 2))


;; CONTRACTOR TEMPLATE:
;; (make-ball Number Number Integer Integer)

;; OBSERVER TEMPLATE:
;; ball-fn: Ball -> ??
;; (define (ball-fn b)
;; (... (ball-x b) (ball-y b) (ball-vx b) (ball-vy b)))


;; REPRESENTATION:
;; balls is represented as list of ball
;; CONSTRUCTOR TEMPLATES:
;; empty, the empty ball  list
;; (cons ball balls) WHERE ball is a Ball, balls is a BallList
;; OBSERVER TEMPLATE
;; balls-fn: BallList -> ??
;; (define (balls-fn bl)
;;   (cond
;;     [(empty? bl) ...]
;;     [else (...
;;            (first bl)
;;           (balls-fn (rest bl)))]))

;; REPRESENTATION:
;; A racket is represented as (make-racket x y vx vy mx my selected?)
;; INTERPRETATION:
;; x, y: PosInteger, represents the position (x, y) of the racket
;; vx, vy: Integer, represents the velocity (vx, vy) of the racket
;; mx, my: Integer, represents the ralative position (mx, my) of the mouse
;;    if it is unselect the number is 0
;; selected?: if the racket is selected

;; IMPLEMENTATION:
(define-struct racket (x y vx vy mx my selected?))

;; examples of racket, for testing
(define outside-racket (make-racket -3 -3 1 1 0 0 false))
(define inside-racket (make-racket 300 400 3 3 0 0 false))
(define up-racket (make-racket 300 3 3 -1 0 0 false))
(define left-racket (make-racket 20 400 -3 3 0 0 false))

(define next-tentative-racket (make-racket 303 403 3 3 0 0 false))

;; CONTRACTOR TEMPLATE:
;; (make-racket Number Number Integer Integer Integer Integer Boolean)

;; OBSERVER TEMPLATE:
;; racket-fn: Racket -> ??
;; (define (racket-fn r)
;; (...(racket-x r) (racket-y r)
;;     (racket-vx r) (racket-vy r)
;;     (rakcet-mx r) (racket-my r)
;;     (racket-selected?)))

;; REPRESENTATION:
;; A mouse is represented as a (x y)
;; INTERPRETATION:
;; x, y: PosInteger, represenets the postion (x, y) of the mouse

;; IMPLEMENTATION:
(define-struct mouse (x y))


;; constant
(define INITIAL-MOUSE
  (make-mouse COURT-X-CENTER COURT-Y-CENTER))

;; exmaples of ball for testing
(define test-mouse (make-mouse 300 300))

;; CONTRACTOR TEMPLATE:
;; (make-mosue Number Number)

;; OBSERVER TEMPLATE:
;; mosue-fn: Mouse -> ??
;; (define (mouse-fn b)
;; (... (mouse-x b) (mouse-y b)))


;; help function for key event
;; is-pause-key-event?: KeyEvent -> Boolean
;; is-up-key-event?: KeyEvent -> Boolean
;; is-down-key-event?: KeyEvent -> Boolean
;; is-left-key-event?: KeyEvent -> Boolean
;; is-right-key-event?: KeyEvent -> Boolean
;; GIVEN: a KeyEvent
;; RETURNS: true if the ke represents pause/up/down/left/right instruction
;; STRATEGY: do judgement
(define (is-pause-key-event? ke)
  (key=? ke KEY-SPACE))
(define (is-up-key-event? ke)
  (key=? ke KEY-UP))
(define (is-down-key-event? ke)
  (key=? ke KEY-DOWN))
(define (is-left-key-event? ke)
  (key=? ke KEY-LEFT))
(define (is-right-key-event? ke)
  (key=? ke KEY-RIGHT))
(define (is-add-ball-key-event? ke)
  (key=? ke KEY-B))

;; examples KeyEvents for testing
(define pause-ke "")
(define up-ke "up")
(define down-ke "down")
(define left-ke "left")
(define right-ke "right")
(define other-ke "q")



;; main funciton
;; simulate: PosNum -> World
;; GIVEN: the speed of simulate (bigger the number, slower the motion)
;; EFFECT: runs the simulation, starting with a ball and a racket in scene
;; RETURNS: the final state of the world
;; STRATEGY: divide into simpler functions
(define (simulation s)
  (big-bang (initial-world s)
            (on-tick world-after-tick s)
            (on-draw world-to-scene)
            (on-key world-after-key-event)
            (on-mouse world-after-mouse-event)))

;; init world
;; initial-world: PosNum -> World
;; RETURNS: a world with a ball and a racket, and the scene color given
;; STRATEGY: use template of make world
;; EXAMPLES: see tests
(define (initial-world s)
  (make-world
   COLOR-WHITE
   (list (make-ball INITIAL-X-CORD INITIAL-Y-CORD INITIAL-X-VEL INITIAL-Y-VEL)) 
   (make-racket INITIAL-X-CORD INITIAL-Y-CORD 0 0 0 0 false)
   INITIAL-MOUSE false 0 true s))


;; examples for test
(define initial-ball
  (make-ball INITIAL-X-CORD INITIAL-Y-CORD INITIAL-X-VEL INITIAL-Y-VEL))
(define initial-balls
  (list initial-ball))


(define initial-racket
  (make-racket INITIAL-X-CORD INITIAL-Y-CORD 0 0 0 0 false))

(define pause-world
  (make-world COLOR-WHITE (list inside-ball) inside-racket INITIAL-MOUSE
              true 0 false 1/10))

(define active-world
  (make-world COLOR-WHITE (list inside-ball) inside-racket
   INITIAL-MOUSE false 0 false 1/10))

;; test
(begin-for-test
  
  (check-equal?
   (world-after-tick (initial-world 1/10))
   (world-after-tick (world-after-tick
                      (make-world
                       COLOR-WHITE (list initial-ball)
                       initial-racket INITIAL-MOUSE
                       false 0 true 1/10)))
   "initial world")

  (check-equal?
   (world-after-tick pause-world)
   (make-world
    COLOR-YELLOW
    (list (make-ball
     (ball-x inside-ball) (ball-y inside-ball) 0 0))
    (make-racket
     (racket-x inside-racket) (racket-y inside-racket) 0 0 0 0 false)
    INITIAL-MOUSE
    true
    1
    false
    1/10)
   "world pause")

  (check-equal?
   (world-after-tick active-world)
   (make-world
    COLOR-WHITE
    (list next-tentative-ball)
    next-tentative-racket
    INITIAL-MOUSE
    false
    0
    false
    1/10)))



;; world status

;; world-after-tick: World -> World
;; GIVEN: a world w
;; RETURNS: the world that should follow w after a tick.  If the world
;;   is paused or the ball collides with back wall,
;;   returns it unchanged except the color of court,
;;   after 3 seconds, reset it. If the world is ready to serve, returns it
;;   unchanged. Otherwise, builds a new unpaused world
;; EXAMPLES: see tests
;; STRATEGY: divide in to cases and use template of make world
(define (world-after-tick w)
  (cond
    [(world-ready-to-serve? w)
     (initial-world (world-speed w))]
    [(or (world-pause? w)
         (balls-collides-back-wall? (world-balls w)))
     (world-remain-pause w)]
    [(racket-collides-front-wall? (world-racket w))
     (world-racket-remain-pause w)]
    [else
     (make-world COLOR-WHITE (balls-after-tick (world-balls w) (world-racket w))
      (racket-after-tick (world-racket w) (world-balls w)) (world-mouse w)
      (world-pause? w) 0 (world-ready-to-serve? w) (world-speed w))]))



;; ball status
;; balls-after-tick: (Ball Racket -> Ball) BallList Racket -> BallList
;; GIVEN: balls and a racket
;; RETURNS: next status of balls
;; EXAMPLES: see tests
;; STRATEGY: use hof of filter on list in which
;;     ball does not collide with back wall after one tick

;; REWRITTEN
(define (balls-after-tick bl r)
  (filter
   (lambda (b) (not (ball-collides-back-wall? b)))
   (map (lambda (x) (ball-after-tick x r)) bl)))

;;test
(begin-for-test
  (check-equal?
   (balls-after-tick
    (balls-after-tick
     (list inside-ball collides-back-wall-ball)
     inside-racket)
    inside-racket)
   (list (ball-next-tentative (ball-next-tentative inside-ball)))))
;; ball-after-tick: Ball Racket -> Ball
;; GIVEN: a ball and a racket
;; RETURNS: next status of the ball
;; EXAMPLES: see tests
;; STRATEGY: divide into cases
(define (ball-after-tick b r)
  (cond
    [(and
      (ball-collides-front-wall? (ball-next-tentative b))
      (not (ball-collides-side-wall? (ball-next-tentative b))))
     (ball-bounces-backward b)]
    [(and
      (ball-collides-side-wall? (ball-next-tentative b))
      (not (ball-collides-front-wall? (ball-next-tentative b))))
     (ball-bounces-inward b)]
    [(ball-collides-front-sides-wall? (ball-next-tentative b))
     (ball-bounces-return b)]
    [(balllist-collides-racket? (list b) r) (ball-bounces-react b r)]
    [else (ball-next-tentative b)]))


;; examples
(define collision-front-wall-ball
  (make-ball 300 3 3 -5))
(define collision-side-wall-ball1
  (make-ball 3 100 -5 3))
(define collision-back-wall-ball
  (make-ball 300 645 4 5))
(define collision-side-wall-ball2
  (make-ball 424 300 4 3))

(define collision-front-side-wall-ball1
  (make-ball 4 5 -5 -6))
(define collision-front-side-wall-ball2
  (make-ball 424 2 4 -3))

;; tests
(begin-for-test
  (check-equal?
   (ball-after-tick collision-front-wall-ball inside-racket)
   (make-ball 303 2 3 5))
  (check-equal?
   (ball-after-tick collision-side-wall-ball1 inside-racket)
   (make-ball 2 103 5 3))
  (check-equal?
   (ball-after-tick collision-side-wall-ball2 inside-racket)
   (make-ball 422 303 -4 3))
  (check-equal?
   (ball-after-tick collision-back-wall-ball inside-racket)
   (make-ball 304 650 4 5))
  (check-equal?
   (ball-after-tick collision-front-side-wall-ball1 inside-racket)
   (make-ball 1 1 5 6))
  (check-equal?
   (ball-after-tick collision-front-side-wall-ball2 inside-racket)
   (make-ball 422 1 -4 3)))

;; test
(begin-for-test
  (check-equal?
   (ball-after-tick inside-ball inside-racket)
   next-tentative-ball
   "ball-movement")
  (check-equal?
   (ball-next-tentative inside-ball)
   next-tentative-ball
   "ball-movement")
  
  (check-equal?
   (racket-after-tick inside-racket (list inside-ball))
   next-tentative-racket
   "racket-movement")
  (check-equal?
   (racket-next-tentative inside-racket)
   next-tentative-racket)
  "racket-movement")

;; help functions

;; ball-next-tentative: Ball -> Ball
;; GIVEN: a ball
;; RETURNS: next status of the ball
;; EXAMPLE: (ball-next-tentative inside-ball) = next-tentative-ball
;; STRATEGY: use template of make ball
(define (ball-next-tentative b)
  (make-ball
   (+ (ball-x b) (ball-vx b))
   (+ (ball-y b) (ball-vy b))
   (ball-vx b)
   (ball-vy b)))

;; example for testing
(define next-tentative-ball (make-ball 17 23 -3 3))


;; ball-collides-front-sides-wall?: Ball -> Boolean
;; GIVEN: a ball
;; RETURNS: if the ball will collide with both
;;    front and side wall at next tentative
;; EXAMPLE: (ball-collides-front-sides-wall? inside-ball) = false
;; STRATEGY: combine simpler functions
(define (ball-collides-front-sides-wall? b)
  (and (ball-collides-front-wall? b) (ball-collides-side-wall? b)))

;; ball-collides-front-wall?: Ball -> Boolean
;; GIVEN: a ball
;; RETURNS: if the ball will collide with
;;    front wall at next tentative
;; EXAMPLES: (ball-collides-front-wall? inside-ball) = false
;;    (ball-collides-front-wall? (next-tentative collides-front-wall-ball))
;;        = true
;; STRATEGY: use formualr
(define (ball-collides-front-wall? b)
  (if (< (ball-y b) 0)
  true
  false))

;; ball-collides-sides-wall?: Ball -> Boolean
;; GIVEN: a ball
;; RETURNS: if the ball will collide with
;;    side wall at next tentative
;; EXAMPLES: (ball-collides-side-wall? inside-ball) = false
;;    (ball-collides-side-wall? (next-tentative collides-side-wall-ball))
;;        = true
;; STRATEGY: use formular
(define (ball-collides-side-wall? b)
  (if 
   (or
       (< (ball-x b) 0)
       (> (ball-x b) COURT-WIDTH))
     true
     false))

;; ball-collides-back-wall?: Ball -> Boolean
;; GIVEN: a ball
;; RETURNS: if the ball will collide with back wall at next tentative
;; EXAMPLES: (ball-collides-back-wall? inside-ball) = false
;;    (ball-collides-back-wall? (next-tentative collides-back-wall-ball))
;;        = true
;; STRATEGY: use formular
(define (ball-collides-back-wall? b)
  (if (> (ball-y b) COURT-HEIGHT)
      true
      false))

;; balls-collides-back-wall?: (Ball -> Boolean) BallList -> Boolean
;; GIVEN: a list of ball
;; RETURNS: if all the ball will collide with back wall at next tentative
;; EXAMPLES: (balls-collides-back-wall? (list inside-ball)) = false
;;    (balls-collides-back-wall?
;;        (list (next-tentative collides-back-wall-ball))) = true
;; STRATEGY: use hof of andmap on list
;; REWRITTEN
(define (balls-collides-back-wall? bl)
  (andmap (lambda (b) (ball-collides-back-wall? b)) bl))

;; ball-bounces-backward: Ball -> Ball
;; GIVEN: a ball
;; RETURNS: status of the ball which collides with front wall
;; EXAMPLES: see tests
;; STRATEGY: use template of make ball
(define (ball-bounces-backward b)
  (make-ball
   (+ (ball-x b) (ball-vx b))
   (- (+ (ball-y b) (ball-vy b)))
   (ball-vx b)
   (- (ball-vy b))))

;; ball-bounces-inward: Ball -> Ball
;; GIVEN: a ball
;; RETURNS: status of the ball which collides with sides wall
;; EXAMPLES: see tests
;; STRATEGY: use template of make ball
(define (ball-bounces-inward b)
  (if (> (ball-x (ball-next-tentative b)) COURT-WIDTH)
      (make-ball
       (- (* 2 COURT-WIDTH) (+ (ball-x b) (ball-vx b)))
       (+ (ball-y b) (ball-vy b))
       (- (ball-vx b))
       (ball-vy b))
      (make-ball
       (- (+ (ball-x b) (ball-vx b)))
       (+ (ball-y b) (ball-vy b))
       (- (ball-vx b))
       (ball-vy b))))

;; ball-bounces-return: Ball -> Ball
;; GIVEN: a ball
;; RETURNS: status of the ball which collides with both front and side wall
;; STRATEGY: divide into cases and use template of make ball
(define (ball-bounces-return b)
  (if (> (ball-x (ball-next-tentative b)) COURT-WIDTH)
      (make-ball
       (- (* 2 COURT-WIDTH) (+ (ball-x b) (ball-vx b)) )
       (- (+ (ball-y b) (ball-vy b)))
       (- (ball-vx b))
       (-(ball-vy b)))
      (make-ball
       (- (+ (ball-x b) (ball-vx b)))
       (- (+ (ball-y b) (ball-vy b)))
       (- (ball-vx b))
       (- (ball-vy b)))))

;; ball-bounces-react: Ball Racket -> Ball
;; GIVEN: a ball and a racket
;; RETURNS: status of the ball react with the racket
;; EXAMPLES: see tests
;; STRATEGY: use template of make ball
(define (ball-bounces-react b r)
  (make-ball
   (+ (ball-x b) (ball-vx b))
   (+ (ball-y b)
      (distance-y-shift b r)
      (* (- 1 (/ (distance-y-ball-racket b r) (ball-vy b)))
         (- (racket-vy r) (ball-vy b)))
      (- (racket-vy r) (ball-vy b)))
   (ball-vx b)
   (- (racket-vy r) (ball-vy b))))

;; distance-y-shift: Ball Racket -> Number
;; GIVEN: a ball and a racket
;; RETURNS: the y shift of the racket in a tick
;; EXAMPLE: (distance-y-shift inside-ball inside-racket) = 380
;; STRATEGY: divide into cases and use formular
(define (distance-y-shift b r)
(cond
    [(> (racket-vy r) 0) (distance-y-ball-racket b r)]
    [(< (racket-vy r) 0) (- (distance-y-ball-racket b r))]
    [(= (racket-vy r) 0) 0]))

(begin-for-test
 (check-equal?
  (racket-y (world-racket
  (world-after-tick
   (make-world
   COLOR-WHITE (list (make-ball 331 192 -3 6))
   (make-racket 330 198 0 0 0 0 false)
   (make-mouse 0 0)
   false 0 false 0.1)
   )))
  198)

 (check-equal?
  (racket-y (world-racket
  (world-after-tick
   (make-world
   COLOR-WHITE (list (make-ball 331 198 -3 6))
   (make-racket 330 198 0 0 0 0 false)
   (make-mouse 0 0)
   false 0 false 0.1)
   )))
  198))

;; distance-y-ball-racket: Ball Racket -> PosReal
;; GIVEN: a ball and a racket
;; RETURNS: the y-distance between ball and racket
;; EXAMPLE: (distance-y-ball-racket inside-ball inside-racket) = 380
;; STRATEGY: use formular
(define (distance-y-ball-racket b r)
  (if (>= (abs (ball-vy b)) (abs (racket-vy r)))
      (- (racket-y r)
         (min (ball-y b)
              (ball-y (ball-next-tentative b))))
      (- (ball-y b)
         (min (racket-y r)
              (racket-y (racket-next-tentative r))))))

;; distance-x-shift: Ball Raket -> Ball
;; GIVEN: a ball and a racket
;; RETURNS: the x-shift between ball and racket
;; EXAMPLE: (distance-x-shift inside-ball inside-racket) = -380
;; STRATEGY: use formular
(define (distance-x-shift b r)
  (if (>= (abs (ball-vy b)) (abs (racket-vy r)))
      (* (abs (/ (distance-y-ball-racket b r) (ball-vy b)))
         (ball-vx b))
      (* (abs (/ (distance-y-ball-racket b r) (racket-vy r)))
         (racket-vx r))))

;; insect-x-cord: Ball Racket -> Number
;; GIVEN: a ball and a racket
;; RETURNS: the insect x-cord of ball and racket
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (insect-x-cord b r)
  (cond
    [(and (>= (abs (ball-vy b)) (abs (racket-vy r))) (> (ball-vy b) 0))
     (+ (ball-x b) (distance-x-shift b r))]
   ;; [(and (>= (abs (ball-vy b)) (abs (racket-vy r))) (< (ball-vy b) 0))
   ;;  (- (ball-x (ball-next-tentative b)) (distance-x-shift b r))]
    [(and (< (abs (ball-vy b)) (abs (racket-vy r))) (> (ball-vy b) 0))
     (+ (racket-x r) (distance-x-shift b r))]
   ;; [(and (< (abs (ball-vy b)) (abs (racket-vy r))) (< (ball-vy b) 0))
   ;; (- (racket-x (racket-next-tentative r)) (distance-x-shift b r))]
    ))


;; ball-x-intersect-racket?: Ball Racket -> Boolean
;; GIVEN: a ball and a racket
;; RETURNS: true if x-cord of ball and racket intersect
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use formular
(define (ball-x-intersect-racket? b r)
  (if (>= (abs (ball-vy b)) (abs (racket-vy r)))
       (<
        (- (racket-x r) HALF-RACKET-WIDTH 1)
        (insect-x-cord b r)
        (+ (racket-x r) HALF-RACKET-WIDTH 1))
       (<
        (- (ball-x b) HALF-RACKET-WIDTH 1)
        (insect-x-cord b r)
        (+ (ball-x b) HALF-RACKET-WIDTH 1))))


;; ball-y-intersect-racket?: Ball Racket -> Boolean
;; GIVEN: a ball and a racket
;; RETURNS: true if y-cord of ball and racket intersect
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (ball-y-intersect-racket? b r)
  (if (not (= (ball-y b) (racket-y r)))
      (<= (*
           (- (ball-y b) (racket-y r))
           (- (ball-y (ball-next-tentative b))
              (racket-y (racket-next-tentative r))))
          0)
      false)
  )

(begin-for-test
  (check-equal?
   (ball-y-intersect-racket?
    (make-ball 331 183 -3 9)
    (make-racket 330 192 0 -6 0 0 false))
   true))

;; ball-collides-racket?: Ball Racket -> Boolean
;; GIVEN: a ball and a racket
;; RETURNS: true if collides with each other
;; EXAMPLES: see tests
;; STRATEGY: apply formular 
(define (ball-collides-racket? b r)
  (and (not (< (ball-vy b) 0))
       (ball-x-intersect-racket? b r)
       (ball-y-intersect-racket? b r)))
 
;; balllist-collides-racket?: (Ball Racket -> Boolean)
;;     BallList Racket -> Boolean
;; GIVEN: a ball list and a racket
;; RETURNS: true if collide with each other
;; EXAMPLES: see tests
;; STRATEGY: use hof on ormap on balllist
;; REWRITTEN
(define (balllist-collides-racket? bl r)
  (ormap (lambda (b) (ball-collides-racket? b r)) bl))


;; examples
(define incourt-ball (make-ball 4 4 4 4))
(define upball (make-ball 4 -4 0 0))
(define leftball (make-ball -4 4 1 1))
(define rightball (make-ball 450 34 2 2))
(define downball (make-ball 34 659 -2 2))
(define upleftball (make-ball 4 4 -10 -10))
(define uprightball (make-ball 422 4 10 -10))

;; tests
(begin-for-test
  (check-equal?
   (balllist-collides-racket? (list) inside-racket)
   false))


;; help function for testing
;; ball-within-court?: Ball -> Boolean
;; GIVEN: a ball
;; RETURNS: true if the ball is in court
;; EXAMPLES: see tests
;; STRATEGY: combine simpler functions
(define (ball-within-court? b)
  (not
   (or (ball-collides-front-wall? b)
        (ball-collides-side-wall? b)
        (ball-collides-front-sides-wall? b)
        (ball-collides-back-wall? b))))

(begin-for-test
  (check-equal?
   (ball-within-court? incourt-ball)
   true
   "ball-position")
  
   (check-equal?
    (ball-within-court? upball)
    false
    "ball-position")
   
   (check-equal?
    (ball-within-court? leftball)
    false
    "ball-position")
    
   (check-equal?
    (ball-within-court? rightball)
    false
    "ball-position")
   
   (check-equal?
    (ball-within-court? downball)
    false
    "ball-position")
   
  )

;; racket status
;; racket-after-tick: Racket BallList -> Racket
;; GIVEN: a racket and balls
;; RETURNS: next status of the racket
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use template of make racket
(define (racket-after-tick r bl)
  (let ([rn (racket-next-tentative r)])
  (cond
    [(and (racket-collides-left-wall? rn) (racket-collides-back-wall? rn))
     (racket-collides-right-back-corner r)]
    [(and (racket-collides-right-wall? rn) (racket-collides-back-wall? rn))
     (racket-collides-left-back-corner r)]
    [(racket-collides-back-wall? rn) (racket-collides-back-wall r)]
    [(racket-collides-left-wall? rn) (racket-collides-left-wall r)]
    [(racket-collides-right-wall? rn) (racket-collides-right-wall r)]   
    [(balllist-collides-racket? bl r)
     (if (racket-selected? r)
        (selected-racket-collides-ball r)
        (unselected-racket-collides-ball r))]
    [(racket-selected? r) r]
    [else rn])))

;; racket-collides-left-back-corner: Racket -> Racket
;; GIVEN: a racket
;; WHERE: it will collide with left back corner next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (racket-collides-right-back-corner r)
  (make-racket
       (+ HALF-RACKET-WIDTH 1) (- COURT-HEIGHT HALF-RACKET-HEIGHT 1)
       0 0 (racket-mx r) (racket-my r) (racket-selected? r)))

;; racket-collides-right-back-corner: Racket -> Racket
;; GIVEN: a racket
;; WHERE: it will collide with right back corner next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (racket-collides-left-back-corner r)
  (make-racket
       (- COURT-WIDTH HALF-RACKET-WIDTH 1) (- COURT-HEIGHT HALF-RACKET-HEIGHT 1)
       0 0 (racket-mx r) (racket-my r) (racket-selected? r)))


;; racket-collides-back-wall: Racket -> Racket
;; GIVEN: a racket
;; WHERE: it will collide with back wall next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (racket-collides-back-wall r)
  (make-racket
       (+ (racket-x r) (racket-vx r)) (- COURT-HEIGHT HALF-RACKET-HEIGHT 1)
       (racket-vx r) 0 (racket-mx r) (racket-my r) (racket-selected? r)))

;; racket-collides-left-wall: Racket -> Racket
;; GIVEN: a racket
;; WHERE: it will collide with left wall next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (racket-collides-left-wall r)
  (make-racket
       (+ HALF-RACKET-WIDTH 1) (+ (racket-y r) (racket-vy r)) 0 (racket-vy r)
       (racket-mx r) (racket-my r) (racket-selected? r)))

;; racket-collides-right-wall: Racket -> Racket
;; GIVEN: a racket
;; WHERE: it will collide with right wall next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (racket-collides-right-wall r)
  (make-racket
       (- COURT-WIDTH HALF-RACKET-WIDTH 1) (+ (racket-y r) (racket-vy r)) 0
       (racket-vy r) (racket-mx r) (racket-my r) (racket-selected? r)))



;; selected-racket-collides-ball: Racket -> Racket
;; GIVEN: a racket
;; WHERE: a selected racket which will collide with ball next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (selected-racket-collides-ball r)
  (make-racket
         (racket-x r) (racket-y r) (racket-vx r) (max (racket-vy r) 0)
         (racket-mx r) (racket-my r) (racket-selected? r)))


;; unselected-racket-collides-ball: Racket -> Racket
;; GIVEN: a racket
;; WHERE: an unselected racket which will collide with ball next tick
;; RETURNS: next status of the racket next tick
;; EXAMPLES: see tests
;; STRATEGY: use template of racket
(define (unselected-racket-collides-ball r)
  (let ([rn (racket-next-tentative r)])
    (make-racket
     (racket-x rn) (- (racket-y rn) (racket-vy r))
     (racket-vx r) (max (racket-vy r) 0) (racket-mx r) (racket-my r)
     (racket-selected? r))))

;; examples
(define collides-front-wall-ball
  (make-ball 300 3 3 -4))
(define collides-left-wall-ball
  (make-ball 3 300 -4 4))
(define collides-right-wall-ball
  (make-ball 420 300 5 4))
(define collides-back-wall-ball
  (make-ball 300 645 4 9))

(define collides-front-wall-racket
  (make-racket 300 8 3 -10 0 0 false))
(define collides-left-wall-racket
  (make-racket 30 300 -9 9 0 0 false))
(define collides-right-wall-racket
  (make-racket 400 300 9 9 0 0 false))
(define collides-back-wall-racket
  (make-racket 300 645 4 9 0 0 false))
(define collides-right-back-wall-racket
  (make-racket 400 645 9 9 0 0 false))
(define collides-left-back-wall-racket
  (make-racket 30 645 -5 9 0 0 false))
(define collision-ball-downward
  (make-ball 300 300 1 4))
(define collision-ball-upward
  (make-ball 300 300 1 -4))
(define collision-ball-downward2
  (make-ball 300 300 -1 4))
(define collision-ball-upward2
  (make-ball 300 300 -1 -4))

(define collision-racket-upward
  (make-racket 302 302 1 -1 0 0 false))
(define collision-racket-upward-selected
  (make-racket 302 302 1 -1 0 0 true))
(define collision-racket-upward-selected-stopped
  (make-racket 302 302 1 0 0 0 true))
(define collision-racket-downward2
  (make-racket 298 298 1 -1 0 0 false))
(define collision-racket-downward
  (make-racket 302 302 -1 1 0 0 false))
(define collision-ball-slow1
  (make-ball 300 300 1 1))
(define collision-ball-slow2
  (make-ball 300 320 1 -1))
(define collision-racket-fast1
  (make-racket 300 320 -1 -40 0 0 false))
(define collision-racket-fast2
  (make-racket 300 300 -1 40 0 0 false))
(define collision-racket-stop
  (make-racket 302 302 0 0 0 0 false))

(begin-for-test
  (check-equal?
   (balllist-collides-racket?
    (list collision-ball-downward inside-ball) collision-racket-upward)
   true)
  (check-equal?
   (racket-after-tick
    collision-racket-upward-selected (list collision-ball-downward inside-ball))
   collision-racket-upward-selected-stopped)
  (check-equal?
   (balllist-collides-racket?
    (list collision-ball-downward) collision-racket-downward)
   true)
  (check-equal?
   (balllist-collides-racket?
    (list collision-ball-upward) collision-racket-downward2)
   false)
  (check-equal?
   (balllist-collides-racket?
    (list collision-ball-downward2) collision-racket-downward)
   true)
   (check-equal?
   (balllist-collides-racket?
    (list collision-ball-slow1) collision-racket-fast1)
   true)
  (check-equal?
   (balllist-collides-racket?
    (list collision-ball-slow2) collision-racket-fast2)
   false)
  )


(begin-for-test

;; ball collides with wall
  (check-equal?
   (ball-collides-front-wall?
    (ball-next-tentative collides-front-wall-ball ))
   true)
  (check-equal?
   (ball-collides-back-wall?
    (ball-next-tentative collides-back-wall-ball))
   true)
  (check-equal?
   (ball-collides-side-wall?
    (ball-next-tentative collides-left-wall-ball))
   true)
  
  (check-equal?
   (ball-collides-front-wall? inside-ball)
   false)
  (check-equal?
   (ball-collides-back-wall? inside-ball)
   false)
  (check-equal?
   (ball-collides-side-wall? inside-ball)
   false)
   
;; racket collides with wall
  (check-equal?
   (racket-collides-front-wall?
    (racket-next-tentative collides-front-wall-racket ))
   true)
  (check-equal?
   (racket-collides-back-wall?
    (racket-next-tentative collides-back-wall-racket))
   true)
  (check-equal?
   (racket-collides-left-wall?
    (racket-next-tentative collides-left-wall-racket))
   true)
  (check-equal?
   (racket-collides-right-wall?
    (racket-next-tentative collides-right-wall-racket))
   true)
   (check-equal?
    (racket-after-tick collides-right-back-wall-racket inside-ball)
    (make-racket 401 645 0 0 0 0 false))
    (check-equal?
    (racket-after-tick collides-left-back-wall-racket inside-ball)
   (make-racket 24 645 0 0 0 0 false))
  
  (check-equal?
   (racket-collides-front-wall?
    inside-racket)
   false)
  (check-equal?
   (racket-collides-back-wall?
    inside-racket)
   false)
  (check-equal?
   (racket-collides-left-wall?
    inside-racket)
   false)
  (check-equal?
   (racket-collides-right-wall?
    inside-racket)
   false)
  )


(begin-for-test
  (check-equal?
   (racket-after-tick collides-back-wall-racket (list inside-ball))
   (make-racket 304 645 4 0 0 0 false))
  (check-equal?
   (racket-after-tick collides-left-wall-racket (list inside-ball))
   (make-racket 24 309 0 9 0 0 false))
  (check-equal?
   (racket-after-tick collides-right-wall-racket (list inside-ball))
   (make-racket 401 309 0 9 0 0 false))
  
  (check-equal?
   (racket-after-tick collision-racket-upward (list collision-ball-upward))
   (make-racket 303 301 1 -1 0 0 false))
  (check-equal?
   (racket-after-tick collision-racket-downward (list collision-ball-downward))
   (make-racket 301 302 -1 1 0 0 false))
  (check-equal?
   (racket-after-tick collision-racket-upward (list collision-ball-downward2))
   (make-racket 303 302 1 0 0 0 false))
  (check-equal?
   (racket-after-tick collision-racket-upward (list inside-ball))
   (make-racket 303 301 1 -1 0 0 false))
  (check-equal?
   (racket-after-tick collision-racket-stop (list inside-ball))
   collision-racket-stop)

  (check-equal?
   (ball-after-tick collision-ball-upward collision-racket-upward)
   (make-ball 301 296 1 -4))
  (check-equal?
   (ball-after-tick collision-ball-downward collision-racket-downward)
   (make-ball 301 297.5 1 -3))
  (check-equal?
   (ball-after-tick collision-ball-downward2 collision-racket-upward)
   (make-ball 299 290.5 -1 -5))
  (check-equal?
   (ball-after-tick collision-ball-upward2 collision-racket-upward)
   (make-ball 299 296 -1 -4)))
  
;; help functions
;; racket-next-tentative: Racket -> Racket
;; GIVEN: a racket
;; RETURNS: next tentative status of the racket
;; EXAMPLE: (racket-next-tentative inside-racket) = next-tentative-racket
;; STRATEGY: use template of make racket
(define (racket-next-tentative r)
  (if(racket-selected? r)
     r
     (make-racket
      (+ (racket-x r) (racket-vx r))
      (+ (racket-y r) (racket-vy r))
      (racket-vx r)
      (racket-vy r)
      (racket-mx r)
      (racket-my r)
      (racket-selected? r))))

;; racket-collides-front-wall?: Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: if the next tentative will collides with the wall
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (racket-collides-front-wall? r)
  (if(< (racket-y (racket-next-tentative r)) (+ 0 HALF-RACKET-HEIGHT))
     true
     false))

;; racket-collides-back-wall?: Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: if the next tentative will collides with the wall
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (racket-collides-back-wall? r)
  (if(> (racket-y (racket-next-tentative r))
        (- COURT-HEIGHT HALF-RACKET-HEIGHT))
     true
     false))

;; racket-collides-left-wall?: Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: if the next tentative will collides with the wall
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (racket-collides-left-wall? r)
  (if(< (racket-x (racket-next-tentative r))
        (+ 0 HALF-RACKET-WIDTH))
     true
     false))


;; racket-collides-right-wall?: Racket -> Boolean
;; GIVEN: a racket
;; RETURNS: if the next tentative will collides with the wall
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (racket-collides-right-wall? r)
  (if(> (racket-x (racket-next-tentative r))
        (- COURT-WIDTH HALF-RACKET-WIDTH))
     true
     false))



;; key-event
;; world-after-key-event: World KeyEvent -> World
;; GIVEN: a world
;; RETURNS: the world that should follow the given
;;    world after the given keyevent
;;    on space/up/down/left/right and ignore all others
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and combine simpler functions
(define (world-after-key-event w ke)
  (if (world-pause? w)
      (world-remain-pause w)
      (cond
        [(is-pause-key-event? ke) (world-pause w)]
        [(and (is-up-key-event? ke)
              (not (world-ready-to-serve? w)))
         (world-racket-up w)] 
        [(and (is-down-key-event? ke)
              (not (world-ready-to-serve? w)))
         (world-racket-down w)]
        [(and (is-left-key-event? ke)
              (not (world-ready-to-serve? w)))
         (world-racket-left w)]
        [(and (is-right-key-event? ke)
              (not (world-ready-to-serve? w)))
         (world-racket-right w)]
        [(and (is-add-ball-key-event? ke)
              (not (world-ready-to-serve? w)))
         (world-add-ball w)]
        [else (world-after-tick w)])))



;; world-add-ball: World -> World
;; GIVEN: a world
;; RETURNS: the world with an added initial ball
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
;; (background balls racket mouse pause? pause-time ready-to-serve? speed)
(define (world-add-ball w)
    (make-world
           (world-background w)
           (append (world-balls w) (list initial-ball))
           (world-racket w)
           (world-mouse w)
           (world-pause? w)
           (world-pause-time w)
           (world-ready-to-serve? w)
           (world-speed w)))

;; examples for testing
(define inside-racket-up
  (make-racket 300 400 3 2 0 0 false))
(define inside-racket-down
  (make-racket 300 400 3 4 0 0 false))
(define inside-racket-left
  (make-racket 300 400 2 3 0 0 false))
(define inside-racket-right
  (make-racket 300 400 4 3 0 0 false))
(define inside-stop-racket
  (make-racket 300 400 0 0 0 0 false))
(define inside-stop-ball
  (make-ball 20 20 0 0))

(define in-pause-world
  (make-world
   COLOR-YELLOW (list inside-stop-ball) inside-stop-racket INITIAL-MOUSE
   true 2 false 1/10))

(define in-pause-world-speed1
  (make-world
   COLOR-YELLOW (list inside-stop-ball) inside-stop-racket INITIAL-MOUSE
   true 2 false 1))

(define ready-to-serve-world
  (make-world
   COLOR-WHITE (list initial-ball)initial-racket INITIAL-MOUSE
   false 0 true 1/10))
;; tests
(begin-for-test
  (check-equal?
   (world-after-key-event active-world " ")
   (make-world
    COLOR-YELLOW (list inside-stop-ball) inside-stop-racket INITIAL-MOUSE
    true 1 false 1/10))
  (check-equal?
   (world-after-key-event active-world "up")
   (make-world
    COLOR-WHITE (list inside-ball) inside-racket-up INITIAL-MOUSE
    false 0 false 1/10))
  (check-equal?
   (world-after-key-event active-world "down")
   (make-world
    COLOR-WHITE (list inside-ball) inside-racket-down INITIAL-MOUSE
    false 0 false 1/10))
  (check-equal?
   (world-after-key-event active-world "left")
   (make-world
    COLOR-WHITE (list inside-ball) inside-racket-left INITIAL-MOUSE
    false 0 false 1/10))
  (check-equal?
   (world-after-key-event active-world "right")
   (make-world
    COLOR-WHITE (list inside-ball) inside-racket-right INITIAL-MOUSE
    false 0 false 1/10))
  (check-equal?
   (world-after-key-event active-world "b")
   (make-world
    COLOR-WHITE (list inside-ball initial-ball) inside-racket INITIAL-MOUSE
    false 0 false 1/10))
  (check-equal?
   (world-after-key-event active-world "q")
   (make-world
    COLOR-WHITE (list next-tentative-ball) next-tentative-racket INITIAL-MOUSE
    false 0 false 1/10))
  (check-equal?
   (world-after-key-event in-pause-world " ")
   (world-after-tick in-pause-world))
  (check-equal?
   (world-after-key-event in-pause-world "b")
   (world-after-tick in-pause-world))
  (check-equal?
   (world-after-key-event ready-to-serve-world "b")
   (world-after-tick ready-to-serve-world))
  (check-equal?
   (world-after-key-event ready-to-serve-world "o")
   (world-after-tick ready-to-serve-world))
  (check-equal?
   (world-after-key-event ready-to-serve-world " ")
   (make-world
       COLOR-WHITE
       (list (make-ball
        (ball-x initial-ball)
        (ball-y initial-ball)
        INITIAL-X-VEL
        INITIAL-Y-VEL))
       initial-racket
       INITIAL-MOUSE
       false
       0
       false
       1/10))

  (check-equal?
   (world-after-key-event ready-to-serve-world "b")
   (world-after-tick ready-to-serve-world))
  (check-equal?
   (world-after-tick (world-after-key-event in-pause-world-speed1 " "))
   (initial-world 1)))

;; help functions
;; world-remain-pause: World -> World
;; GIVEN: a world
;; RETURNS: the world that remains in pause status
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
(define (world-remain-pause w)
  (if (>= (* (world-pause-time w) (world-speed w)) RESET-INTERVAL)
      (initial-world (world-speed w))
      (make-world
       COLOR-YELLOW
       (balls-pause (world-balls w))
       (make-racket
        (racket-x (world-racket w))
        (racket-y (world-racket w))
        0 0 0 0
        (racket-selected? (world-racket w)))
       (world-mouse w)
       true
       (+ (world-pause-time w) 1)
       false
       (world-speed w))))



;; world-racket-remain-pause: World -> World
;; GIVEN: a world
;; RETURNS: the world that remains time tick
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
(define (world-racket-remain-pause w)
  (if (>= (* (world-pause-time w) (world-speed w)) RESET-INTERVAL)
      (initial-world (world-speed w))
      (make-world
       COLOR-YELLOW
       (balls-pause (world-balls w))
       (make-racket
        (racket-x (world-racket w))
        (+ HALF-RACKET-HEIGHT 1)
        0 0 0 0
        (racket-selected? (world-racket w)))
       (world-mouse w)
       true
       (+ (world-pause-time w) 1)
       false
       (world-speed w))))


;; balls-pause: (Ball -> Ball) BallList -> BallList
;; GIVEN: balls
;; RETURNS: balls that remains in pause
;; EXAMPLES: see tests
;; STRATEGY: use hof of map on list
;; REWRITTEN
(define (balls-pause bl)
  (map (lambda (b) (make-ball (ball-x b) (ball-y b) 0 0)) bl))
;; exmaples for testing

;; tests
(begin-for-test
  (check-equal?
   (world-after-tick
    (make-world
     COLOR-WHITE
     (list inside-ball)
     collides-front-wall-racket
     INITIAL-MOUSE
     false 0 false 1/10))
   (make-world
    COLOR-YELLOW
    (list inside-stop-ball)
    (make-racket
     300 4 0 0 0 0 false)
    INITIAL-MOUSE
    true 1 false 1/10))
   
   (check-equal?
    (world-racket-remain-pause
     (make-world
     COLOR-YELLOW
     (list inside-stop-ball)
     (make-racket
     300 4 0 0 0 0 false)
     INITIAL-MOUSE
     true 30 false 1/10))
    (initial-world 1/10))

   (check-equal?
    (world-pause? (world-after-tick
     (make-world
     COLOR-WHITE
     (list (ball-next-tentative collides-back-wall-ball))
     inside-racket
     INITIAL-MOUSE
     false 0 false 1/10)))
    true)

   (check-equal?
    (world-after-tick
     (make-world
     COLOR-YELLOW
     (list inside-stop-ball)
     (make-racket
     300 4 0 0 0 0 false)
     INITIAL-MOUSE
     true 10 false 1/10))
    (make-world
     COLOR-YELLOW
     (list inside-stop-ball)
     (make-racket
     300 4 0 0 0 0 false)
     INITIAL-MOUSE
     true 11 false 1/10)))


;; world-pause: World -> World
;; GIVEN: a world
;; RETURNS: start to serve if ready to serve
;;    remain pause if in pause
;;    pause if not pause and not in ready-to-serve state
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use templare of make world
(define (world-pause w)
  (cond
    [(world-ready-to-serve? w)
     (make-world
       COLOR-WHITE
       (list initial-ball)
       (make-racket
        (racket-x (world-racket w))
        (racket-y (world-racket w))
       0 0 0 0
        (racket-selected? (world-racket w)))
       (world-mouse w)
       (world-pause? w)
       0
       false
       (world-speed w))]
    [(not (world-pause? w))
     (world-remain-pause w)]
    ))

;; world-racket-up: World -> World
;; GIVEN: a world
;; RETURNS: a world with a new racket status
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
(define (world-racket-up w)
  (make-world
   COLOR-WHITE
   (world-balls w)
   (make-racket
    (racket-x (world-racket w))
    (racket-y (world-racket w))
    (racket-vx (world-racket w))
    (- (racket-vy (world-racket w)) 1)
    (racket-mx (world-racket w))
    (racket-my (world-racket w))
    (racket-selected? (world-racket w)))
   (world-mouse w)
   false
   0
   false
   (world-speed w)))

;; world-racket-down: World -> World
;; GIVEN: a world
;; RETURNS: a world with a new racket status
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
(define (world-racket-down w)
  (make-world
   COLOR-WHITE
   (world-balls w)
   (make-racket
    (racket-x (world-racket w))
    (racket-y (world-racket w))
    (racket-vx (world-racket w))
    (+ (racket-vy (world-racket w)) 1)
    (racket-mx (world-racket w))
    (racket-my (world-racket w))
    (racket-selected? (world-racket w)))
   (world-mouse w)
   false
   0
   false
   (world-speed w)))


;; world-racket-left: World -> World
;; GIVEN: a world
;; RETURNS: a world with a new racket status
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
(define (world-racket-left w)
  (make-world
   COLOR-WHITE
   (world-balls w)
   (make-racket
    (racket-x (world-racket w))
    (racket-y (world-racket w))
    (- (racket-vx (world-racket w)) 1)
    (racket-vy (world-racket w))
    (racket-mx (world-racket w))
    (racket-my (world-racket w))
    (racket-selected? (world-racket w)))
   (world-mouse w)
   false
   0
   false
   (world-speed w)))


;; world-racket-right: World -> World
;; GIVEN: a world
;; RETURNS: a world with a new racket status
;; EXAMPLES: see tests
;; STRATEGY: use template of make world
(define (world-racket-right w)
  (make-world
   COLOR-WHITE
   (world-balls w)
   (make-racket
    (racket-x (world-racket w))
    (racket-y (world-racket w))
    (+ (racket-vx (world-racket w)) 1)
    (racket-vy (world-racket w))
    (racket-mx (world-racket w))
    (racket-my (world-racket w))
    (racket-selected? (world-racket w)))
   (world-mouse w)
   false
   0
   false
   (world-speed w)))

;; mouse-event
;; world-after-mouse-event: World Integer Integer MouseEvent -> World
;; GIVEN: a world, the x- and y- position of the mouse, and a
;;     mouse event
;; RETURNS: the world that should follow the given mouse event
;; STRATEGY: divide into cases and use template of make world
;; EXAMPLES: see tests
;; (background ball racket mouse pause? pause-time ready-to-serve? speed)
(define (world-after-mouse-event w mx my mev)
  (if (mouse-active w)
      (make-world
       (world-background w)
       (world-balls w)
       (racket-after-mouse-event (world-racket w) mx my mev)
       (make-mouse mx my)
       (world-pause? w)
       (world-pause-time w)
       (world-ready-to-serve? w)
       (world-speed w))
      w))

;; racket-after-mouse-event: Racket Integer Integer MouseEvent -> Racket
;; GIVEN: a racket, the x- and y- position of the mouse, and a mouse event
;; RETURNS: the racket that should follow the given mouse event
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use simplar functions
(define (racket-after-mouse-event r mx my me)
  (cond
    [(mouse=? me MOUSE-DOWN) (racket-after-button-down r mx my)]
    [(mouse=? me MOUSE-UP) (racket-after-button-up r mx my)]
    [(mouse=? me MOUSE-DRAG) (racket-after-drag r mx my)]
    [else r]))

;; help funtions
;; mouse-racket-distance: Integer Integer Racket -> PosReal
;; GIVEN: x-, y- position of mouse and a racket,
;; RETURNS: the distance between the center of racket and the mouse
;; EXAMPLES: see tests
;; STRATEGY: use formular

(define (mouse-racket-distance mx my r)
  (sqrt (+ (sqr (- mx (racket-x r)))
           (sqr (- my (racket-y r))))))

;; mouse-racket-distance: World -> Boolean
;; GIVEN: the world
;; RETURNS: true if the world is not pause or ready to serve
;; EXAMPLES: see tests
;; STRATEGY: use formular
(define (mouse-active w)
  (not (or (world-pause? w) (world-ready-to-serve? w))))

;; racket-after-button-down: Racket Integer Integer -> World
;; GIVENL a racket and x-, y- position of mouse
;; RETURNS: the racket that react with button-down
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use template of make racket
(define (racket-after-button-down r mx my)
  (if (<= (mouse-racket-distance mx my r) 25)
      (make-racket
       (racket-x r) (racket-y r) (racket-vx r) (racket-vy r)
       (- (racket-x r) mx) (- (racket-y r) my) true)
      r))

;; racket-after-button-up: Racket Integer Integer -> World
;; GIVENL a racket and x-, y- position of mouse
;; RETURNS: the racket that react with button-up
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use template of make racket
(define (racket-after-button-up r mx my)
  (if (racket-selected? r)
      (make-racket
       (racket-x r) (racket-y r) (racket-vx r) (racket-vy r)
       (racket-mx r) (racket-my r) false)
      r))

;; racket-after-drag: Racket Integer Integer -> World
;; GIVENL a racket and x-, y- position of mouse
;; RETURNS: the racket that react with drag
;; EXAMPLES: see tests
;; STRATEGY: divide into cases and use template of make racket

(define (racket-after-drag r mx my)
  (if (racket-selected? r)
      (make-racket
       (+ mx (racket-mx r))
       (+ my (racket-my r))
       (racket-vx r) (racket-vy r)
       (racket-mx r) (racket-my r) (racket-selected? r))
      r))


;; examples
(define mouse-inside (make-mouse 305 405))
(define mouse-outside (make-mouse 400 300))

(define selected-racket (make-racket 300 300 0 0 -3 -4 true))
(define unselected-racket (make-racket 400 400 -3 5 0 0 false))

(define active-world-mouse-inside
  (make-world
   COLOR-WHITE (list inside-ball)
   inside-racket mouse-inside false 0 false 1/10))

(define active-world-mouse-outside
 (make-world
   COLOR-WHITE (list inside-ball)
   inside-racket mouse-outside false 0 false 1/10))


(define ready-to-serve-world-mouse-inside
  (make-world
   COLOR-WHITE (list initial-ball)
   initial-racket mouse-inside false 0 true 1/10))

;; tests for mosue event
(begin-for-test

  (check-equal?
   (world-after-mouse-event
    active-world-mouse-inside
    (mouse-x mouse-inside) (mouse-y mouse-inside)
    "button-down")
   (make-world
    COLOR-WHITE (list inside-ball)
   (make-racket
    (racket-x inside-racket)
    (racket-y inside-racket)
    (racket-vx inside-racket)
    (racket-vy inside-racket)
    (- (racket-x inside-racket) (mouse-x mouse-inside))
    (- (racket-y inside-racket) (mouse-y mouse-inside))
    true)
   mouse-inside false 0 false 1/10))
  
  (check-equal?
   (world-after-mouse-event
    active-world-mouse-outside
    (mouse-x mouse-outside) (mouse-y mouse-outside)
    "button-down")
   (make-world
    COLOR-WHITE (list inside-ball)
    (make-racket
     (racket-x inside-racket)
     (racket-y inside-racket)
     (racket-vx inside-racket)
     (racket-vy inside-racket)
     (racket-mx inside-racket)
     (racket-my inside-racket)
     false)
    mouse-outside false 0 false 1/10))

  (check-equal?
   (world-after-mouse-event
    active-world-mouse-inside
    (mouse-x mouse-inside) (mouse-y mouse-inside)
    "move")
   (make-world
    COLOR-WHITE (list inside-ball)
    (make-racket
     (racket-x inside-racket)
     (racket-y inside-racket)
     (racket-vx inside-racket)
     (racket-vy inside-racket)
     (racket-mx inside-racket)
     (racket-my inside-racket)
     false)
    mouse-inside false 0 false 1/10))

  (check-equal?
   (world-after-mouse-event
    ready-to-serve-world
    (mouse-x mouse-inside) (mouse-y mouse-inside)
    "button-down")
   (make-world
    COLOR-WHITE (list initial-ball)
    (make-racket
     (racket-x initial-racket)
     (racket-y initial-racket)
     (racket-vx initial-racket)
     (racket-vy initial-racket)
     (racket-mx initial-racket)
     (racket-my initial-racket)
     false)
    INITIAL-MOUSE false 0 true 1/10))
  
  (check-equal?
   (racket-selected?
    (world-racket
     (world-after-tick
      (world-after-mouse-event
       (world-after-mouse-event
        active-world-mouse-inside
        (mouse-x mouse-inside) (mouse-y mouse-inside)
        "button-down")
       (mouse-x mouse-inside) (mouse-y mouse-inside)
       "button-up"))))
   false)

  (check-equal?
   (racket-selected?
    (world-racket
     (world-after-tick
      (world-after-mouse-event       
        active-world-mouse-inside
        (mouse-x mouse-inside) (mouse-y mouse-inside)
        "button-down"))))
   true)
  
  (check-equal?
   (racket-selected?
    (world-racket
     (world-after-mouse-event
      (world-after-mouse-event
       active-world-mouse-outside
       (mouse-x mouse-outside) (mouse-y mouse-outside)
       "button-down")
      (mouse-x mouse-outside) (mouse-y mouse-outside)
      "button-up")))
   false)

  (check-equal?
   (racket-after-drag selected-racket 400 300)
   (make-racket 397 296 0 0 -3 -4 true))

  (check-equal?
   (racket-after-mouse-event unselected-racket 400 300 "drag")
   unselected-racket)
  )

;; scene

;; help function
;; court-background: Color -> Scene
;; GIVEN: a color which represents a color
;; RETURNS: a scene which apply the color as its background
;; EXAMPLE: (court-background COLOR-WHITE) =
;;    (empty-scene COURT-WIDTH COURT-HEIGHT COLOR-WHITE)
;; STRATEGY: use template
(define (court-background c)
  (empty-scene COURT-WIDTH COURT-HEIGHT c))

(begin-for-test
  (check-equal?
   (court-background COLOR-YELLOW)
   (empty-scene COURT-WIDTH COURT-HEIGHT COLOR-YELLOW)
   "court-color"))

;; world-to-scene : World -> Scene
;; GIVEN: a world
;; RETURNS: a Scene that portrays the given world
;; EXAMPLES: see tests
;; STRATEGY: divide into cases
(define (world-to-scene w)
  (if (racket-selected? (world-racket w))
      (place-image
       MOUSE-CIRCLE
       (mouse-x (world-mouse w))
       (mouse-y (world-mouse w))
       (ball-racket-scene w))
      (ball-racket-scene w)))

;; ball-racket-scene: (World -> Scene) World -> Scene
;; GIVEN: a world
;; RETURNS: a scene with balls and racket only
;; EXAMPLES: see tests
;; STRATEGY: use hof of foldr, base case is empty scene with racket
;; REWRITTEN
(define (ball-racket-scene w)
  (foldr (lambda (b s) (place-ball-image b s))
         (racket-scene w)
         (world-balls w)))

;; place-ball-image: Ball Scene -> Scene
;; GIVEN: a ball and a scene
;; RETURNS: a scene with ball
;; EXAMPLE: see tests
;; STRATEGY: use template
(define (place-ball-image b s)
  (place-image BALL (ball-x b) (ball-y b) s))

;; racket-scene: World -> Scene
;; GIVEN: a world
;; RETURNS: a scene with racket only
;; EXAMPLES: see tests
;; STRATEGY: use template
(define (racket-scene w)
  (place-image
     RACKET
     (racket-x (world-racket w))
     (racket-y (world-racket w))
     (court-background (world-background w))))

;; example
(define image-of-tick-after-active-world
  (place-image
   BALL
   17 23
   (place-image
    RACKET
    303 403 (court-background COLOR-WHITE))))

(define image-of-selected-active-world-mouse-inside
  (place-image
   MOUSE-CIRCLE 305 405
   (place-image
    BALL 20 20
    (place-image
     RACKET 300 400
     (court-background COLOR-WHITE))))
  )
;; test
(begin-for-test
  (check-equal?
   (world-to-scene (world-after-tick active-world))
   image-of-tick-after-active-world)
  
  (check-equal?
   (world-to-scene
    (world-after-mouse-event
     active-world-mouse-inside 305 405 "button-down"))
   image-of-selected-active-world-mouse-inside))