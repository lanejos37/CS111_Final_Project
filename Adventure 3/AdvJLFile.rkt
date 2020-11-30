(require "adventure-define-struct.rkt")
(require "macros.rkt")
(require "utilities.rkt")

;;Code to check if a string is in a list
(define (ismember1? str strs) (ormap [lambda (s) (string=? s str)] strs))

;; Initial message display at the start of the game
(display "You are playing minecraft and are going through caves. You are currently in your underground room and are going to explore the cave system you just found next to your place.\nUse the actions procedure to see what actions are possible.")

;; Displays all possible actions in the game
(define (actions)
  (display "description takes an object as an input and outputs a description of the object.\n\nviewroom tells you everything within your cave.\n\ninventory will take something that has contents in it such as a chest and return a list of these outputs. No matter what room you are in you can use this function to test your player-inventory.\n\nenter takes a location as an input and allows you to leave one area and enter another.\n\napproach-creeper takes a creeper as an input and allows you to move towards the creeper"))



;;Defining the general struct object with a method that describes the object. Now all objects are objects they are just something that need a description.
(define-struct object
  (adjectives name)
  #:methods
  (define (description a)
    (if (ismember1? (object-name a) (room-viewroom currentroom))
    (object-adjectives a)
    (display "Cannot observe object that is not in your room")))
  (define(objectlist a)
    (type-name-string a)))


;;New "object" called room
(define-struct (room object)
  (viewroom))

;;allows you to view what is in the room/cave
(define (viewroom)
  (room-viewroom currentroom))

;;room you start in
(define home
  (make-room "your own underground home where your adventure begins!" "home" (list "chest" "cave1")))

;;cave you can enter
(define cave1
  (make-room "first cave in the cave system you have entered" "cave1" (list "creeper1" "netherportal")))

;;netherportal takes you take nether
(define netherportal
  (make-room "netherportal takes you to the nether" "netherportal" (list "zombie_pigman" "")))

;;initializes the value for current room
(define currentroom
  home)

;;updates current room when you enter a new room
(define (enter newroom)
  (if (ismember1? (object-name newroom) (room-viewroom currentroom))
  (set! currentroom newroom)
  (display "Cannot enter a non-adjacent room")))

;;New struct that have iterms within tem
(define-struct (container object)
  (inventory)
  #:methods
  (define (inventory c)
    (container-inventory c)))
    
 ;; remove!: container thing -> void
  ;; EFFECT: removes the thing from the container
  (define (remove! container thing)
    (set-container-contents! container
                             (remove thing
                                     (container-contents container))))
    
;; destroy!: thing -> void
;; EFFECT: removes thing from the game completely.
(define (destroy! thing)
  ; We just remove it from its current location
  ; without adding it anyplace else.
  (remove! (thing-location thing)
           thing))

 
;;One time of container that can always be accessed
(define player-inventory
  (make-container "player-inventory" "personal inventory with max storage of 10 objects" (list "map")))

;;New container that should only be accesible when in the room it is in
(define chest
  (make-container "chest" "chest with max storage of 10 different objects" (list "axe" "apple" "2 diamonds")))
  
;for taking something from the chest object and placing it into your player-inventory (code doesn't work)
(define (pick-up x y)
  (begin (set! (container-inventory y) (remove x (container-inventory y)))
        (set! (container-inventory player-inventory) (cons x (container-inventory player-inventory)))
        (display "You put a new object in your player-inventory")))

;for taking something from the player-inventory object and placing it in the chest object (code doesn't work)
(define (put-down x y)
  (begin (set! (container-inventory player-inventory) (remove x (container-inventory player-inventory)))
         (set! (container-inventory player-inventory)(cons x (container-inventory y)))
         (display "You have removed an object from your player-inventory")))

;;New struct creeper that is designed to make the player die if thet approach the creeper
(define-struct (mobs object)
  ())

;;New struct for zombie_pigman
(define-struct (zombie_pigman mobs)
()
#:methods
(define (attack_pigman a)
  (if (> (2) 0.5)
      (error "you attracted the hoard, and died")
      (begin (destroy zombie_pigman) (display "Slayed the zombie pigmen horde")))))
     

 
;;New struct creeper that is designed to make the player die if thet approach the creeper
(define-struct (creeper mobs)
  ()
  #:methods
  (define (approach-creeper c)
    (error "Creeper went boom, you are now dead.")))

;;creeper in cave1 
(define creeper1
  (make-creeper "creeper1" "makes a hissing noice when you come close"))

;;Notes: Need to make it so that objects and containers are not accesible when in different rooms.
;;Also need to get rid of creeper when it exploded.
;;Finally, if more rooms are added we need to make it so the play can only enter adjacent rooms.
