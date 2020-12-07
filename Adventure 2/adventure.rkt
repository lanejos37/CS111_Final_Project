;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-advanced-reader.ss" "lang")((modname |adventure final|) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #t #t none #f () #f)))
(require "adventure-define-struct.rkt")
(require "macros.rkt")
(require "utilities.rkt")

;;;
;;; OBJECT
;;; Base type for all in-game objects
;;;

(define-struct object
  ;; adjectives: (listof string)
  ;; List of adjectives to be printed in the description of this object
  (adjectives)
  
  #:methods
  ;; noun: object -> string
  ;; Returns the noun to use to describe this object.
  (define (noun o)
    (type-name-string o))

  ;; description-word-list: object -> (listof string)
  ;; The description of the object as a list of individual
  ;; words, e.g. '("a" "red" "door").
  (define (description-word-list o)
    (add-a-or-an (append (object-adjectives o)
                         (list (noun o)))))
  ;; description: object -> string
  ;; Generates a description of the object as a noun phrase, e.g. "a red door".
  (define (description o)
    (words->string (description-word-list o)))
  
  ;; print-description: object -> void
  ;; EFFECT: Prints the description of the object.
  (define (print-description o)
    (begin (printf (description o))
           (newline)
           (void))))

;;;
;;; CONTAINER
;;; Base type for all game objects that can hold things
;;;

(define-struct (container object)
  ;; contents: (listof thing)
  ;; List of things presently in this container
  (contents)
  
  #:methods
  ;; container-accessible-contents: container -> (listof thing)
  ;; Returns the objects from the container that would be accessible to the player.
  ;; By default, this is all the objects.  But if you want to implement locked boxes,
  ;; rooms without light, etc., you can redefine this to withhold the contents under
  ;; whatever conditions you like.
  (define (container-accessible-contents c)
    (container-contents c))
  
  ;; prepare-to-remove!: container thing -> void
  ;; Called by move when preparing to move thing out of
  ;; this container.  If the object is static, it cannot be moved.
  (define (prepare-to-remove! container thing)
    (if (= (length (object-adjectives thing)) 0)
        (void)
        (if (or (string=? (last (object-adjectives thing)) "static")
                (creature? thing)
                (door? thing)
                (environment? thing)
                (room? thing)
                (person? thing)
                (sorceress? thing))
            (error "You cannot take this object.")
            (void))
        ))
  
  ;; prepare-to-add!: container thing -> void
  ;; Called by move when preparing to move thing into
  ;; this container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-add! container thing)
    (void))
  
  ;; remove!: container thing -> void
  ;; EFFECT: removes the thing from the container
  (define (remove! container thing)
    (set-container-contents! container
                             (remove thing
                                     (container-contents container))))
  
  ;; add!: container thing -> void
  ;; EFFECT: adds the thing to the container.  Does not update the thing's location.
  (define (add! container thing)
    (set-container-contents! container
                             (cons thing
                                   (container-contents container))))

  ;; describe-contents: container -> void
  ;; EFFECT: prints the contents of the container
  (define (describe-contents container)
    (begin (local [(define other-stuff (remove me (container-accessible-contents container)))]
             (if (empty? other-stuff)
                 (printf "There's nothing here.~%")
                 (begin (printf "You see:~%")
                        (for-each print-description other-stuff))))
           (void))))

;; move!: thing container -> void
;; Moves thing from its previous location to container.
;; EFFECT: updates location field of thing and contents
;; fields of both the new and old containers.
(define (move! thing new-container)
  (begin
    (prepare-to-remove! (thing-location thing)
                        thing)
    (prepare-to-add! new-container thing)
    (prepare-to-move! thing new-container)
    (remove! (thing-location thing)
             thing)
    (add! new-container thing)
    (set-thing-location! thing new-container)))

;; destroy!: thing -> void
;; EFFECT: removes thing from the game completely.
(define (destroy! thing)
  ; We just remove it from its current location
  ; without adding it anyplace else.
  (remove! (thing-location thing)
           thing))

;;;
;;; ENVIRONMENT
;;; Base type for rooms and outdoor areas
;;;

(define-struct (environment container)
  ())

;; new-environment: string -> environment
;; Makes a new room with the specified adjectives
(define (new-environment adjectives)
  (make-environment (string->words adjectives)
                    '()))

;;;
;;; THING
;;; Base type for all physical objects that can be inside other objects such as rooms
;;;

(define-struct (thing container)
  ;; location: container
  ;; What room or other container this thing is presently located in.
  (location)
  
  #:methods
  (define (go thing)
    (error "You cannot go there!"))

  (define (examine thing)
    (print-description thing))

  ;; prepare-to-move!: thing container -> void
  ;; Called by move when preparing to move thing into
  ;; container.  Normally, this does nothing, but
  ;; if you want to prevent the object from being moved,
  ;; you can throw an exception here.
  (define (prepare-to-move! container thing)
    (void)))

;; initialize-thing!: thing -> void
;; EFFECT: adds thing to its initial location
(define (initialize-thing! thing)
  (add! (thing-location thing)
        thing))

;; new-thing: string container -> thing
;; Makes a new thing with the specified adjectives, in the specified location,
;; and initializes it.
(define (new-thing adjectives location)
  (local [(define thing (make-thing (string->words adjectives)
                                    '() location))]
    (begin (initialize-thing! thing)
           thing)))

;;;
;;; DOOR
;;; A portal from one room to another
;;; To join two rooms, you need two door objects, one in each room
;;;

(define-struct (door thing)
  ;; destination: container
  ;; The place this door leads to
  (destination)
  
  #:methods
  ;; go: door -> void
  ;; EFFECT: Moves the player to the door's location and (look)s around.

  (define (go door)
    (begin (move! me (door-destination door))
           (look))))


;; join: room string room string
;; EFFECT: makes a pair of doors with the specified adjectives
;; connecting the specified rooms.
(define (join! room1 adjectives1 room2 adjectives2)
  (local [(define r1->r2 (make-door (string->words adjectives1)
                                    '() room1 room2))
          (define r2->r1 (make-door (string->words adjectives2)
                                    '() room2 room1))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))


;;;
;;; PERSON
;;; A character in the game.  The player character is a person.
;;;

(define-struct (person thing)
  ;; factors that desribe the condition of the person
  (energy oxygen strength)

  #:methods
  ;; procedure that increases or decreases the energy of the person
  (define (change-energy who what)
    (set-person-energy! who (+ (person-energy who) (food-energy-value what))))

  
  ;; procedure that increases the oxygen level of the person
  (define (change-oxygen who what)
    (begin
      (set-person-oxygen! who (+ (person-oxygen who) (oxygen-tank-oxygen-value what)))
      (printf "Your oxygen level is ~a%. ~n" (person-oxygen who))))

  ;; procedure that increases the strength
  (define (increase-strength who what)
    (if (< (+ (person-strength who) (good-power what)) 100)
        (set-person-strength! who (+ (person-strength who) (good-power what)))
        (error "Your strength level cannot surpass 100%.")))
  
  ;; prodecure that decreases the strength of the person
  (define (decrease-strength who what)
    (if (<= (+ (person-strength who) (enemy-disenergy what)) 0)
        (begin (error "You are already dead.")
               (start-game))
        (set-person-strength! who (+ (person-strength who) (enemy-disenergy what)))))
  
  ;; it prints the current state of the person
  (define (energy-oxygen-strength who)
    (begin
      (printf "Your energy level is ~a%. ~n" (person-energy who))
      (printf "Your oxygen level is ~a%. ~n" (person-oxygen who))
      (printf "Your strength is ~a%. ~n" (person-strength who))))
  )


;; initialize-person: person -> void
;; EFFECT: do whatever initializations are necessary for persons.
(define (initialize-person! p)
  (initialize-thing! p))

;; new-person: string container -> person
;; Makes a new person object and initializes it.
(define (new-person adjectives location)
  (local [(define person
            (make-person (string->words adjectives)
                         '()
                         location
                         10
                         10
                         10))]
    (begin (initialize-person! person)
           person)))

;; This is the global variable that holds the person object representing
;; the player.  This gets reset by (start-game)
(define me empty)

;;;
;;; PROP
;;; A thing in the game that doesn't serve any purpose other than to be there.
;;;

(define-struct (prop thing)
  (;; noun-to-print: string
   ;; The user can set the noun to print in the description so it doesn't just say "prop"
   noun-to-print
   ;; examine-text: string
   ;; Text to print if the player examines this object
   examine-text
   )
  
  #:methods
  (define (noun prop)
    (prop-noun-to-print prop))

  (define (examine prop)
    (display-line (prop-examine-text prop))))

;; new-prop: string container -> prop
;; Makes a new prop with the specified description.
(define (new-prop description examine-text location)
  (local [(define words (string->words description))
          (define noun (last words))
          (define adjectives (drop-right words 1))
          (define prop (make-prop adjectives '() location noun examine-text))]
    (begin (initialize-thing! prop)
           prop)))

;;;
;;; ------------------------------ ADD YOUR TYPES HERE! ------------------------------
;;;

;; ROOM
;; a subtype of environment for spaces that are smaller and more specific
(define-struct (room environment)
  ())

(define (new-room adjectives)
  (make-room (string->words adjectives)
             '()))

;; SPECIAL-DOOR
;; a locked door that connects two environments/rooms
(define-struct (special-door door)
  (key)

  #:methods
  ;; a different go method for the locked doors in order to have both types of doors
  (define (go special-door)
    (cond [(have? (special-door-key special-door))
           (begin (move! me (door-destination special-door))
                  (look))]
          [else (error "Dangerous zone. Do you have the key that belongs to this room?")])))

;; procedure that joins two locked doors
(define (join-locked-door! room1 adjectives1 room2 adjectives2 key)
  (local [(define r1->r2 (make-special-door (string->words adjectives1)
                                            '() room1 room2
                                            key))
          (define r2->r1 (make-special-door (string->words adjectives2)
                                            '() room2 room1
                                            key))]
    (begin (initialize-thing! r1->r2)
           (initialize-thing! r2->r1)
           (void))))

;; CREATURE
;; it is a subtype of person, a magical creature that is not the main player
(define-struct (creature person)
  (vocab))

;; TODO might need to uncomment
;(define (new-creature vocab adjectives location)
;  (local [(define person
;            (make-creature (adjectives)
;                           '()
;                           location
;                           vocab))]
;    (begin (initialize-person! person)
;           person)))

;; procedure that allows you to "speak with" a magical creature (ask quaestions)
(define (speak-with creature question)
  (for-each (λ (x)
              (local [(define coresp
                        (assoc x
                               (creature-vocab creature)))]
                (when (list? coresp)
                  (display-line (second coresp)))))
            (string->words question)))

;; MERMAID
;; subtype of creature, can give hints for further clues
(define-struct (mermaid creature)
  ())

(define (new-mermaid vocab adjectives location)
  (local [(define person
            (make-mermaid (string->words adjectives)
                          '()
                          location
                          '()
                          '()
                          '()
                          vocab))]
    (begin (initialize-person! person)
           person)))

;; FAIRY
;; subtype of creature, can give hints for further clues
(define-struct (fairy creature)
  ())

(define (new-fairy vocab adjectives location)
  (local [(define fairy
            (make-fairy (string->words adjectives)
                        '()
                        location
                        '()
                        '()
                        '()
                        vocab))]
    (begin (initialize-person! fairy)
           fairy)))

;; FOOD
;; subtype of thing, needed to get energy to win the game
(define-struct (food thing)
  (energy-value))

;; subtype of food, found in the sea environment
(define-struct (coconut food)
  ())

(define (new-coconut location)
  (local [(define coconut
            (make-coconut '("ripe")
                          '()
                          location
                          20))]
    (begin (initialize-thing! coconut)
           coconut)))

;; subtype of food, found in TODO
(define-struct (berry food)
  ())

(define (new-berry location)
  (local [(define berry
            (make-berry '("fresh")
                        '()
                        location
                        30))]
    (begin (initialize-thing! berry)
           berry)))

;; procedures needed to determine if the specificed thing is a food
(define (all-food-list)
  '("coconut" "berry"))

(define (is-a-food? thing)
  (empty? (filter (λ (x) (is-a? thing x))
                  (all-food-list))))

;; eat procedure that increases energy
(define (eat food)
  (if (have? food)
      (if (not (is-a-food? food))
          (if (and (< (+ (person-energy me) (food-energy-value food)) 100)
                   (> (+ (person-energy me) (food-energy-value food)) 0))
              (begin
                (change-energy me food)
                (printf "Your energy level has increased to ~a%!" (person-energy me))
                (destroy! food))
              (error "You might die if you eat that."))
          (error "This item is not food."))
      (error "Are you sure this is in your inventory?")))

;; ENEMY
;; subtype of thing, these are items that could kill the player
(define-struct (enemy thing)
  (disenergy))

;; procedures needed to determine whether a specified thing is an enemy  
(define (all-enemy-list)
  '("cactus" "lava"))

(define (is-not-an-enemy? thing)
  (empty? (filter (λ (x) (is-a? thing x))
                  (all-enemy-list))))

;; touch procedure that will decrease strength or kill you if you touch it
(define (touch thing)
  (if (is-not-an-enemy? thing)
      (void)
      (if (<= (+ (person-strength me) (enemy-disenergy thing)) 0)
          (begin (error "You are dead.")
                 (start-game))
          (begin
            (decrease-strength me thing)
            (display-line "Why did you touch this?")
            (printf "Your strength level has decreased to ~a%!" (person-strength me))))))


;; CACTUS
;; subtype of enemy, needed to get water in order to win the game
(define-struct (cactus enemy)
  ()

  #:methods
  ;; will need to cut cactus to get water for dissociation for the oxygen tank
  (define (cut cactus)
    (if (and (is-a? cactus "cactus")
             (not (string=? (first (object-adjectives cactus)) "cut")))
        (begin
          (set-object-adjectives! cactus '("cut" "prickly" "static"))
          (display-line "What is water composed of? Can you split it into smaller pieces? This new thing might come in handy for your journey: ")
          (new-water '("desert") (here)))
        (error "You cannot cut this."))))

(define (new-cactus location)
  (local [(define cactus
            (make-cactus '("tall" "prickly" "static")
                         '()
                         location
                         -5))]
    (begin (initialize-thing! cactus)
           cactus)))

;; LAVA
;; subtype of enemy
(define-struct (lava enemy)
  ()

  #:methods
  (define (destroy lava thing)
    (if (> (person-strength me) 50)
        (if
         (and (is-a? thing "bucket")
              (string=? (first (object-adjectives thing)) "water"))
         (begin
           (display-line "You destroyed the lava!")
           (destroy! thing)
           (destroy! lava)
           (set-person-energy! me (+ (person-energy me) 20))
           (printf "Your energy has increased to ~a%." (person-energy me)))
         (error "You can't destroy the lava with no water."))
         (error "You don't have enough strength to destroy the lava."))))
             
  
(define (new-lava location)
  (local [(define lava
            (make-lava '("fiery" "static")
                       '()
                       location
                       -50))]
    (begin (initialize-thing! lava)
           lava)))

;; TODO: check if you can destroy static lava

;; GOOD
;; subtype of thing, increase the player strength
(define-struct (good thing)
  (power))

;; BRACELET
;; one of the items needed to win the game
(define-struct (bracelet good)
  ())

(define (new-bracelet location)
  (local [(define bracelet
            (make-bracelet '("pearl")
                           '()
                           location
                           +30))]
    (begin (initialize-thing! bracelet)
           bracelet)))


;; SHELL
;; it is a magical thing in the sea that unlocks the bracelet you need to win the game
(define-struct (shell thing)
  (song)

  #:methods
  (define (examine shell)
    (if (not (member? "clean" (object-adjectives shell)))
        (display-line "This is a dusty shell. Try wiping it.")
        (display-line "A beautiful clean shell.")))

  (define (wipe shell)
    (if (have? shell)
        (begin
          (set-object-adjectives! shell '("clean"))
          (display-line "The shell has a small, barely visible engravement:")
          (display-line "Sing the shell song."))
        (error "You do not have the shell."))))



; sing procedure; upon singing the shell song, the player receives a pearl bracelet.
; The player must have a `clean shell` in order to sing.
(define (sing-to! thing song)
  (if (string=? (noun thing) "shell")
      (if (and (string=? (first (object-adjectives thing)) "clean") (string=? song (shell-song thing)))
          (begin
            (destroy! thing)
            (display-line "Like a shell upon a beach, just another pretty piece, I was difficult to see. But you picked me.")
            (display-line "The shell is shining. It reveals: ")
            (new-bracelet (here)))
          (error "I do not like that song. You are missing something (Capitalization Is Key!)."))
      (error "You can only sing to a small sea item.")))


(define (new-shell location)
  (local [(define shell
            (make-shell '("dusty")
                        '()
                        location
                        "The Shell Song"))]
    (begin (initialize-thing! shell)
           shell)))

;; global variable to hide stuff
(define storage #f)

;; procedures related to BRACELET
;; procedure that will raise the strength so you can climb the mountain
(define (wear! thing)
  (if (have? thing)
      (if (is-a? thing "bracelet")
          (begin
            (move! thing storage)
            (increase-strength me thing)
            (display-line "You are wearing the pearl bracelet.")
            (printf "Your strength level has increased to ~a%!" (person-strength me)))
          (error "You cannot wear that."))
      (error "You do not have the thing.")))

;; procedure that will decrease your strength and make you unable to climb the mountain
(define (take-it-off!)
  (if (empty? (remove storage (container-accessible-contents storage)))  
      (error "You are not wearing the bracelet.")
      (begin (display-line "Are you sure you are not making a mistake? You took the bracelet off.")
             (new-bracelet me)
             (set-person-strength! me (- (person-strength me) 30))
             (printf "Your strength level has decreased to ~a%!" (person-strength me))
             (set-container-contents! storage empty)
             )))

;; TODO check if it will become empty

;; WATER
;; subtype of thing, will need it for lava and for oxygen tank
(define-struct (water thing)
  (molecules)

  #:methods
  (define (examine water)
    (if (not (member? "desert" (object-adjectives water)))
        (display-line "Water. Mildly salty. Might come in handy")
        (display-line "Desert water. Look at those H2O molecules. Hmm."))))

(define (new-water adjectives location)
  (local [(define water
            (make-water adjectives
                        '()
                        location
                        '()))]
    (begin (initialize-thing! water)
           water)))

;; MUSHROOM
;; subtype of thing, needed for the magic potion
(define-struct (mushroom thing)
  ())
 
(define (new-mushroom location)
  (local [(define mushroom
            (make-mushroom '("magic")
                           '()
                           location))]
    (begin (initialize-thing! mushroom)
           mushroom)))

  
;; FLASK
;; subtype of good, also needed for magic potion
(define-struct (flask good)
  (ingredient)

  #:methods
  ;; procedures needed for crafting
  (define (craft-with flask thing)
    (if (is-a? thing "mushroom")
        (if (have? (flask-ingredient flask))
            (begin
              (display-line "You have created the Potion of Invincibility!")
              (set-object-adjectives! flask '("Potion of Invincibility"))
              (destroy! thing))
            (error "You don't have the ingredients to create a potion."))
        (error "You can't craft a potion with this.")))

  (define (drink flask)
    (if (string=? (first (object-adjectives flask)) "Potion of Invincibility")
        (begin
          (increase-strength me flask)
          (display-line "You drank the potion of invincibility.")
          (printf "Your strength has increased to ~a%." (person-strength me))
          (destroy! flask))
        ((error "You don't have a potion to drink.")))))


(define (new-flask ingredient location)
  (local [(define flask
            (make-flask '("empty potion")
                        '()
                        location
                        +30
                        ingredient))]
    (begin (initialize-thing! flask)
           flask)))


;; BUCKET
;; subtype of thing, needed to destroy the lava
(define-struct (bucket thing)
  (water)

  #:methods
  (define (fill bucket thing)
    (if (and (is-a? thing "water")
             (string=? (first (object-adjectives thing)) "sea"))
        (if (have? (bucket-water bucket))
            (begin
              (display-line "You have filled the bucket with water. You now have a water bucket.")
              (set-object-adjectives! bucket '("water"))
              (destroy! thing))
            (error "You have no water to fill the bucket with."))
        (error "That is not water!"))))

(define (new-bucket water location)
  (local [(define bucket
            (make-bucket '("empty")
                         '()
                         location
                         water))]
    (begin (initialize-thing! bucket)
           bucket)))


;; OXYGEN CONTAINER
;; subtype of thing, needed to fill it up for climbing Mt. Everest
(define-struct (oxygen-tank thing)
  (oxygen-value)

  #:methods
  (define (fill-up oxygen-tank thing)
    (if (and (have? thing)
             (have? oxygen-tank))
        (if (is-a? thing "oxygen")
            (begin (set-object-adjectives! oxygen-tank '("full"))
                   (destroy! thing)
                   (change-oxygen me oxygen-tank))
            (display-line "You can't fill up the tank with this substance."))
        (display-line "Are you sure you have everything?"))))

  
(define (new-oxygen-tank location)
  (local [(define oxygen-tank
            (make-oxygen-tank '("empty")
                              '()
                              location
                              80))]
    (begin (initialize-thing! oxygen-tank)
           oxygen-tank)))

;; OXYGEN
;; subtype of water, needed for climbing Mt.Everest
(define-struct (oxygen water)
  ())
 
(define (new-oxygen location)
  (local [(define oxygen
            (make-oxygen '("molecule of")
                         '()
                         location
                         '()))]
    (begin (initialize-thing! oxygen)
           oxygen)))

;; procedure to get oxygen
(define (dissociate thing)
  (if (and (is-a? thing "water") (string=? (first (object-adjectives thing)) "desert"))
      (if (have? thing)
          (begin (destroy! thing)
                 (display-line "You will need this later on:")
                 (new-oxygen (here)))
          (error "Are you sure you have that?"))
      (error "Why are you trying to separate this? Try again.")))

  
;; LEAF
;; it is one of the winning items, the flag
(define-struct (leaf thing)
  ()
  #:methods
  (define (plant leaf)
    (if (and (have? leaf) (is-a? leaf "leaf"))
        (begin (display-line "This leaf works as an excellent flag! Congratulations, you are at the peak of your game! You win!")
               (start-game))
        (error "You cannot plant that."))))

(define (new-leaf location)
  (local [(define leaf
            (make-leaf '("green")
                       '()
                       location
                       ))]
    (begin (initialize-thing! leaf)
           leaf)))
                      

;; MOUNTAIN
;; the final destination, you need to climb it
(define-struct (mountain thing)
  (leaves)
  
  #:methods
  (define (climb mountain)
    (if (and (have? (mountain-leaves mountain))
             (> (person-energy me) 70)
             (> (person-oxygen me) 80)
             (> (person-strength me) 70))
        (display-line "You have reached the top of Mt.Everest! Plant your green flag to leave your mark.")
        (error "You need a green object and a good physical condition before you climb to the top."))))


(define (new-mountain leaves location)
  (local [(define mountain
            (make-mountain '("high")
                           '()
                           location
                           leaves
                           ))]
    (begin (initialize-thing! mountain)
           mountain)))


;; PYRAMID GAME

;; ORB
;; subtype of creature, it can talk and will give strength
(define-struct (orb creature)
  ()
  
  #:methods
  (define (rub orb)
    (if (is-a? orb "orb")
        (begin
          (set-person-strength! me (+ (person-strength me) 30))
          (printf "Congratulations! Your strength has increased to ~a%!" (person-strength me))
          (destroy! orb))
        (error "You cannot rub that..."))))
        

(define (new-orb vocab adjectives location)
  (local [(define orb
            (make-orb adjectives
                      '()
                      location
                      '()
                      '()
                      '()
                      vocab))]
    (begin (initialize-person! orb)
           orb)))

;; ABILITY
;; new type needed to fight the sorceress
(define-struct ability
  (name manacost effects description)

  #:methods
  (define (cast! abi person caster)
    (begin
      (apply-effects! abi person)
      (display-line (ability-description abi))))

  (define (apply-effects! abi person)
    (for-each (lambda (eff) (eff person)) (ability-effects abi)))
  )

;; Creates a new ability
;; int -> (player -> void) -> ability
(define (new-ability name cost effects desc)
  (make-ability name cost effects desc))

;; SORCERESS
; Represents an enemy that can engage in combat.
(define-struct (sorceress creature)
  (
   hp
   abilities
   mana
   )

  #:methods
  (define (dec-hp! sorc amount)
    (set-sorceress-hp! sorc (- (sorceress-hp sorc) amount)))

  (define (let-cast! enemy target)
    (local [(define abi (list-ref (sorceress-abilities enemy)
                                  (random (length (sorceress-abilities enemy)))))]
      (begin
        (if (>= (- (sorceress-mana enemy) (ability-manacost abi)) 0)
            (begin 
              (set-sorceress-mana! enemy
                                   (- (sorceress-mana enemy) (ability-manacost abi)))
              (cast! abi target enemy))
            void))))
  )

;; prcedures needed for the fight with the sorceress
(define (process-spell name)
  (cond
    [(string=? name "FoolishStrike")
     (new-ability "FoolishStrike" 0 (list (lambda (t) (dec-hp! t 8)))
                  "You spin around like a madman. It's super effective!")]
    [(string=? name "Strike")
     (new-ability "Strike" 0 (list (lambda (t) (dec-hp! t 1)))
                  "You attack valiantly, dealing only minor damage.")]
    [else (void)]))

(define (prompt-spell target)
  (begin
    (display-line "Cast a spell (`FoolishStrike`/`Strike`): ")
    (local [(define abi (process-spell (symbol->string (read))))] ; Just why?
      (begin
        (if (void? abi)
            (display-line "You do not know that ability!")
            (cast! abi target me))))))

(define (initialize-sorceress! enemy)
  (initialize-person! enemy))

(define (new-sorceress adjectives location vocab abilities mana)
  (local [(define enemy
            (make-sorceress adjectives
                            '() location
                            10 '() '() vocab
                            10 abilities mana))]
    (begin (initialize-sorceress! enemy) enemy)))

;; procedure that if winning the fight, will give you the orb in inventory
(define (handle-sorc-combat-victory sorc)
  (new-orb
   '(("purpose" "Your purpose is to climb the tallest mountain.")
     ("hello" "The orb shimmers excitedly."))
   '("blue") me))

(define (attack! sorc)
  (cond
    [(<= (sorceress-hp sorc) 0)
     (begin
       (display-line "You have bested the elven sorceress! She gives you:")
       (destroy! sorc)
       (handle-sorc-combat-victory sorc))]
    [(<= (sorceress-mana sorc) 0)
     (begin
       (display-line "The sorceress ran out of mana, giving you:")
       (destroy! sorc)
       (handle-sorc-combat-victory sorc))]
    [(<= (person-strength me) 0)
     (begin
       (error "You ran out of power. Game over! Restarting")
       (start-game))]
    [else 
     (begin
       (let-cast! sorc me)
       (prompt-spell sorc)
       (attack! sorc))]))

;; procedure that decreases the player's strength
(define (player-reduce-health-by! value)
  (set-person-strength! me (- (person-strength me) value)))

;;;
;;; USER COMMANDS
;;;

(define (look)
  (begin (printf "You are in ~A.~%"
                 (description (here)))
         (describe-contents (here))
         (void)))

(define-user-command (look) "Prints what you can see in the room")

(define (inventory)
  (if (empty? (my-inventory))
      (printf "You don't have anything.~%")
      (begin (printf "You have:~%")
             (for-each print-description (my-inventory)))))

(define-user-command (inventory)
  "Prints the things you are carrying with you.")

(define-user-command (examine thing)
  "Takes a closer look at the thing")

(define (take thing)
  (move! thing me))

(define-user-command (take thing)
  "Moves thing to your inventory")

(define (drop thing)
  (move! thing (here)))

(define-user-command (drop thing)
  "Removes thing from your inventory and places it in the room")

(define (put thing container)
  (move! thing container))

(define-user-command (put thing container)
  "Moves the thing from its current location and puts it in the container.")

(define (help)
  (for-each (λ (command-info)
              (begin (display (first command-info))
                     (newline)
                     (display (second command-info))
                     (newline)
                     (newline)))
            (all-user-commands)))

(define-user-command (help)
  "Displays this help information")

(define-user-command (go door)
  "Go through the door to its destination")

(define (check condition)
  (if condition
      (display-line "Check succeeded")
      (error "Check failed!!!")))

(define-user-command (check condition)
  "Throws an exception if condition is false.")

;;;
;;; ADD YOUR COMMANDS HERE!
;;;

; User commands
(define-user-command (attack! sorceress) "Attacks a sorceress.")
(define-user-command (sing-to! thing song) "Sings a song to a thing")
(define-user-command (cut cactus) "Cuts cactus to reveal cactus content")
(define-user-command (wipe shell) "Wipes a shell clean")
(define-user-command (rub orb) "Rubs the orb")
(define-user-command (speak-with creature question) "Asks the creature a question")
(define-user-command (dissociate thing) "Dissociates the `thing`")
(define-user-command (eat food) "Eats something from the inventory")
(define-user-command (fill-up oxygen-tank thing) "Fills up the oxygen tank with `thing`")
(define-user-command (wear! thing) "Makes the `thing` invisible and increases you strength")
(define-user-command (fill bucket thing) "Fills the bucket with `thing`")
(define-user-command (craft-with flask thing) "Makes a new thing from a flask and another magical `thing`")
(define-user-command (drink flask) "Drinks from the flask to gain strength")
(define-user-command (destroy lava thing) "Destroys the lava with the `thing`")
(define-user-command (climb mountain) "Climbs a mountain")
(define-user-command (plant leaf) "Plants the leaf for a win!")
(define-user-command (take-it-off!) "Takes off the item you are wearing, but it might hurt you!")
(define-user-command (touch thing) "Touches a `thing` - but you don't know the consequences..")
(define-user-command (energy-oxygen-strength me) "Displays the current state of the player")

;;;
;;; THE GAME WORLD - FILL ME IN
;;;


;; start-game: -> void
;; Recreate the player object and all the rooms and things.
(define (start-game)
  ;; Fill this in with the rooms you want
  (local [(define starting-env (new-environment "dry desert"))
          (define sea-env (new-environment "wavy sea"))
          (define forest-env (new-environment "fresh forest"))
          (define volcano-env (new-environment "volcano"))
          (define mountain-env (new-room "Mt.Everest"))
          (define pyramid-room (new-room "pyramid"))]
    (begin (set! me (new-person "" starting-env))
           (set! storage (new-room "storage"))
           ;; Add join commands to connect your rooms with doors
           (join-locked-door! starting-env "pyramid" pyramid-room "dry desert"
                              (new-prop "brick" "It's a heavy brick."
                                        sea-env))
           (join! starting-env "wavy sea" sea-env "dry desert")
           (join-locked-door! starting-env "fresh forest" forest-env "dry desert"
                              (new-prop "branch" "It's a weird branch."
                                        pyramid-room))
           (join! forest-env "volcano" volcano-env "fresh forest")
           (join! forest-env "windy Mt.Everest" mountain-env "fresh forest")
           ;; Add code here to add things to your rooms
           (new-mermaid '(("fight" "Are you sure? I will kill you.")
                          ("partner" "I do not have a partner, I am a lone wolf")
                          ("key" "What is the object you want to enter made of? Think.")
                          ("do" "Calm down and think. It's all in your head.")
                          ("lost" "Are you sure? Look around.")
                          ("where" "We are in the wavy sea environment. Do you need a hint?")
                          ("hint" "The Ancient Egyptians were great sailors and builders. Do you like all the shells here?")
                          ("shell" "Isn't it dirty? You might want to clean it a bit."))
                        "magnificent"  sea-env)
           (new-fairy '(("fight" "Are you sure? I will kill you.")
                        ("partner" "I do not have a partner, I am a lone fairy")
                        ("who" "I am a fairy, obviously")
                        ("key" "Try to be like a fairy. Crafty.")
                        ("do" "That mushroom looks like it could be useful")
                        ("lost" "One can never be lost. All you need is faith, trust & a little pixie-dust")
                        ("where" "We are in the fresh forest environment.")
                        ("hint" "Only magic can help you survive the next environment. That mushroom is not edible.")
                        ("help" "Those mushrooms look magical.")
                        ("scared" "Don't be scared. Here you have everything you need. Can you make something with that mushroom?")
                        )
                      "mischievous" forest-env)
           (new-prop "dry static sand-dune"
                     "Ouch, it's hot!"
                     starting-env)
           ;(new-bucket (new-prop "water" "this is water" sea-env) volcano-env)
           (new-bucket (new-water '("sea") sea-env) volcano-env)
           (new-flask (new-mushroom forest-env) forest-env)
           (new-shell sea-env)
           (new-mountain (new-leaf forest-env) mountain-env)
           (new-cactus starting-env)
           (new-coconut sea-env)
           (new-berry forest-env)
           (new-lava volcano-env)
           (new-oxygen-tank mountain-env)
           (new-sorceress '("elven")
                          pyramid-room
                          '(("fight" "Selama Ashal'anore!")
                            ("partner" "Do you require aid, human?")
                            ("hello" "Bal'a dash, malanore.")
                            ("where" "This world is a prison.")
                            ("lost" "I don't remember casting slow on you.")
                            ("who" "Maybe you should get a strategy guide.")
                            ("weakness" "I do not suffer fools easily.")
                            ("hint" "The flows of magic are whimsical today."))
                          (list (new-ability "Arcane Blast" 1
                                             (list (lambda (player) (player-reduce-health-by! 5)))
                                             "The Sorceress strikes you with an [Arcane Blast], it's very effective!")
                                (new-ability "Polymorph" 1
                                             (list (lambda (player) (player-reduce-health-by! 1)))
                                             "The Sorceress turns you into a sheep! Baaa! It's not very effective since your're basically a sheep anyways.")
                                (new-ability "Arcane Barrage" 1
                                             (list (lambda (player) (player-reduce-health-by! 3)))
                                             "The Sorceress strikes you with an [Arcane Barrage], it's mildly effective!"))
                          8)
           (check-containers!)
           (void))))

;;;
;;; PUT YOUR WALKTHROUGHS HERE
;;;
(define-walkthrough win
  (cut (the cactus))
  (take (the water))
  (dissociate (the water))
  (take (the oxygen))
  (go (the sea door))
  (take (the brick))
  (take (the coconut))
  (eat (the coconut))
  (speak-with (the mermaid) "Where am I?")
  (speak-with (the mermaid) "Can you give me a hint")
  (take (the shell))
  (wipe (the shell))
  (sing-to! (the shell) "The Shell Song")
  (take (the sea water))
  (take (the bracelet))
  (wear! (the bracelet))
  (go (the door))
  (go (the pyramid door))
  (speak-with (the elven sorceress) "who are you")
  (attack! (the sorceress)) ; you need to do this to actually WIN but it's interactive
  (take (the branch))
  (rub (the orb))
  (go (the door))
  (go (the forest door))
  (take (the berry))
  (eat (the berry))
  (speak-with (the fairy) "I am scared")
  (speak-with (the fairy) "Can you give me a hint")
  (take (the leaf))
  (take (the flask))
  (take (the mushroom))
  (craft-with (the flask) (the mushroom))
  (drink (the flask))
  (go (the volcano door))
  (take (the bucket))
  (fill (the bucket) (the sea water))
  (destroy (the lava) (the bucket))
  (go (the door))
  (go (the Mt.Everest door))
  (take (the oxygen-tank))
  (fill-up (the oxygen-tank) (the oxygen))
  (climb (the mountain))
  (plant (the leaf))
  )


;;;
;;; UTILITIES
;;;

;; here: -> container
;; The current room the player is in
(define (here)
  (thing-location me))

;; stuff-here: -> (listof thing)
;; All the stuff in the room the player is in
(define (stuff-here)
  (container-accessible-contents (here)))

;; stuff-here-except-me: -> (listof thing)
;; All the stuff in the room the player is in except the player.
(define (stuff-here-except-me)
  (remove me (stuff-here)))

;; my-inventory: -> (listof thing)
;; List of things in the player's pockets.
(define (my-inventory)
  (container-accessible-contents me))

;; accessible-objects -> (listof thing)
;; All the objects that should be searched by find and the.
(define (accessible-objects)
  (append (stuff-here-except-me)
          (my-inventory)))

;; have?: thing -> boolean
;; True if the thing is in the player's pocket.
(define (have? thing)
  (eq? (thing-location thing)
       me))

;; have-a?: predicate -> boolean
;; True if the player as something satisfying predicate in their pocket.
(define (have-a? predicate)
  (ormap predicate
         (container-accessible-contents me)))

;; find-the: (listof string) -> object
;; Returns the object from (accessible-objects)
;; whose name contains the specified words.
(define (find-the words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (accessible-objects)))

;; find-within: container (listof string) -> object
;; Like find-the, but searches the contents of the container
;; whose name contains the specified words.
(define (find-within container words)
  (find (λ (o)
          (andmap (λ (name) (is-a? o name))
                  words))
        (container-accessible-contents container)))

;; find: (object->boolean) (listof thing) -> object
;; Search list for an object matching predicate.
(define (find predicate? list)
  (local [(define matches
            (filter predicate? list))]
    (case (length matches)
      [(0) (error "There's nothing like that here")]
      [(1) (first matches)]
      [else (error "Which one?")])))

;; everything: -> (listof container)
;; Returns all the objects reachable from the player in the game
;; world.  So if you create an object that's in a room the player
;; has no door to, it won't appear in this list.
(define (everything)
  (local [(define all-containers '())
          ; Add container, and then recursively add its contents
          ; and location and/or destination, as appropriate.
          (define (walk container)
            ; Ignore the container if its already in our list
            (unless (member container all-containers)
              (begin (set! all-containers
                           (cons container all-containers))
                     ; Add its contents
                     (for-each walk (container-contents container))
                     ; If it's a door, include its destination
                     (when (door? container)
                       (walk (door-destination container)))
                     ; If  it's a thing, include its location.
                     (when (thing? container)
                       (walk (thing-location container))))))]
    ; Start the recursion with the player
    (begin (walk me)
           all-containers)))

;; print-everything: -> void
;; Prints all the objects in the game.
(define (print-everything)
  (begin (display-line "All objects in the game:")
         (for-each print-description (everything))))

;; every: (container -> boolean) -> (listof container)
;; A list of all the objects from (everything) that satisfy
;; the predicate.
(define (every predicate?)
  (filter predicate? (everything)))

;; print-every: (container -> boolean) -> void
;; Prints all the objects satisfying predicate.
(define (print-every predicate?)
  (for-each print-description (every predicate?)))

;; check-containers: -> void
;; Throw an exception if there is an thing whose location and
;; container disagree with one another.
(define (check-containers!)
  (for-each (λ (container)
              (for-each (λ (thing)
                          (unless (eq? (thing-location thing)
                                       container)
                            (error (description container)
                                   " has "
                                   (description thing)
                                   " in its contents list but "
                                   (description thing)
                                   " has a different location.")))
                        (container-contents container)))
            (everything)))

;; is-a?: object word -> boolean
;; True if word appears in the description of the object
;; or is the name of one of its types
(define (is-a? obj word)
  (let* ((str (if (symbol? word)
                  (symbol->string word)
                  word))
         (probe (name->type-predicate str)))
    (if (eq? probe #f)
        (member str (description-word-list obj))
        (probe obj))))

;; display-line: object -> void
;; EFFECT: prints object using display, and then starts a new line.
(define (display-line what)
  (begin (display what)
         (newline)
         (void)))

;; words->string: (listof string) -> string
;; Converts a list of one-word strings into a single string,
;; e.g. '("a" "red" "door") -> "a red door"
(define (words->string word-list)
  (string-append (first word-list)
                 (apply string-append
                        (map (λ (word)
                               (string-append " " word))
                             (rest word-list)))))

;; string->words: string -> (listof string)
;; Converts a string containing words to a list of the individual
;; words.  Inverse of words->string.
(define (string->words string)
  (string-split string))

;; add-a-or-an: (listof string) -> (listof string)
;; Prefixes a list of words with "a" or "an", depending
;; on whether the first word in the list begins with a
;; vowel.
(define (add-a-or-an word-list)
  (local [(define first-word (first word-list))
          (define first-char (substring first-word 0 1))
          (define starts-with-vowel? (string-contains? first-char "aeiou"))]
    (cons (if starts-with-vowel?
              "an"
              "a")
          word-list)))

;;
;; The following calls are filling in blanks in the other files.
;; This is needed because this file is in a different langauge than
;; the others.
;;
(set-find-the! find-the)
(set-find-within! find-within)
(set-restart-game! (λ () (start-game)))
(define (game-print object)
  (cond [(void? object)
         (void)]
        [(object? object)
         (print-description object)]
        [else (write object)]))

(current-print game-print)
   
;;;
;;; Start it up
;;;

(start-game)
(look)
