README FILE: The Lost World




DESCRIPTION
You have mistakenly made your way to the desert instead of Mt.Everest where you wanted to climb to the summit. You have to make your way there while trying to gain enough energy and strength for the final stretch. Before that, you must explore the environments around you and, if need be, return unplaced items.


--------------------------------------- 


USER COMMANDS - GENERAL
There are many useful commands you will need to reach the top. The following ones are more general and can be used in multiple rooms.


* (define-user-command (energy-oxygen-strength me) 
"Displays the current state of the player")


This is a very helpful command that should be used to keep track of the condition of the player. Keep in mind that you need a good physical condition for mountaineering and that certain things can decrease your health. But some other ones can and will help you get to the end.


* (define-user-command (touch thing) 
"Touches a `thing` - but you don't know the consequences..")


Touching something is generally harmless, but can hurt you if you are not careful.


* (define-user-command (eat food) 
"Eats something from the inventory")


In order to survive, you need food. And food gives you energy. But not everything that looks like food is meant to be eaten.


--------------------------------------- 


DESERT ENVIRONMENT
You will start in the desert. Did you know that cactuses can survive for a long time without water? That means they have to store the scarce water somewhere inside. You will need some chemistry here. What is water made of? Can you somehow use its structure to get something that is very needed for climbing Mt. Everest?


Not all doors will be open. You might need to find some misplaced items to continue with your adventure.


* (define-user-command (cut cactus)
“Cuts the cactus to reveal cactus content”)


The command will help you get the cactus contents.


* (define-user-command (dissociate thing) 
"Dissociates the `thing`")


This command can help you split something into smaller pieces.


--------------------------------------- 


SEA ENVIRONMENT
Who doesn’t like the sea? Here, you will have the chance to speak with a rare mystic creature and explore what has been washed off on the beach. Could that little dirty shell hide something? Could there be a key for another environment? Look around and ask the right questions. Look below at the //interacting with mythical beings// section on how to interact with this mythical being.


* (define-user-command (wipe shell) 
"Wipes a shell clean")


This command will help you see even the tiniest of marks on previously dirty surfaces.


* (define-user-command (sing-to! thing song) 
"Sings a song to a thing")


Your voice is lovely. Use it. And choose your song carefully. Do you want someone or something to hear you?


* (define-user-command (wear! thing) 
"Makes the `thing` invisible and increases you strength")


You might find something beautiful. It would be a shame not to wear it.


* (define-user-command (take-it-off!) 
"Takes off the item you are wearing, but it might hurt you!")


All your options are open. You might want to take something off. But it might be a bad idea for your health.


---------------------------------------


PYRAMID ROOM
This room will make or break the deal. If you are up for the challenge, stop by and check who is there (hint: a powerful mythical creature). If you are brave enough, a great prize will wait for you and you will continue your journey. Don’t forget to look for a key. Look below at the //interacting with mythical beings// section on how to interact with this mythical being.


---------------------------------------


FOREST ENVIRONMENT
Enter this dark and primeval forest if you dare. The forest floor is alive and is teeming with secrets. An imp. Channel your inner wizard and perform feats of magic, converse with an impish creature and keep your eyes open for clues. Look below at the //interacting with mythical beings// section on how to interact with this mythical being.


* (define-user-command (craft-with flask thing) 
"Makes a new thing from a flask and another magical `thing`")
Yer a wizard, Harry! Channel your inner wizard and craft a magic mushroom potion. I wonder what you’ll make… 


* (define-user-command (drink flask) 
"Drinks from the flask to gain strength")


Celebrate your magical prowess by drinking your potion. 


---------------------------------------


VOLCANO ENVIRONMENT
You’ve just accidentally stumbled into a dormant volcano (but not for much longer...) Gather your wits as you face molten lava. Keep your hands to yourself, be careful and remain alert! 


* (define-user-command (destroy lava thing) 
"Destroys the lava with the `thing`")


Don’t meet a fiery end! Destroy the lava with something in your inventory. 


* (define-user-command (fill bucket thing) 
"Fills the bucket with `thing`")


What use is an empty bucket? Look in your inventory for something to fill it with


---------------------------------------


MOUNTAIN ENVIRONMENT
You’ve made it to the base of Mt.Everest! At just over 29,000 feet, this is the highest point on Earth. Many from around the world attempt this climb, however, only those with experience and luck are in condition to make it to the summit. Do you have what it takes to reach the peak? 


* (define-user-command (fill-up oxygen-tank thing) 
"Fills up the oxygen tank with `thing`")


Climbing isn’t easy, as oxygen becomes more scarce the higher up you climb, it is important to have an oxygen tank to make it to the top and past the death zone. This procedure will allow you to fill the empty container but you must have the right materials to fill it with.


* (define-user-command (climb mountain) 
"Climbs a mountain")


Make sure you have your materials and are healthy for the climb. Unprepared climbers never reach the top.


* (define-user-command (plant leaf) 
"Plants the leaf for a win!")


Reaching the top is no easy feat, leave something behind to show where you’ve been!


---------------------------------------


INTERACTING WITH MYTHICAL BEINGS
You can interact with the mermaid, fairy & sorceress through the user command:
* (define-user-command (speak-with creature question) 
"Asks the creature a question")


These are the keywords in the questions that the mermaid will respond to:
fight, partner, key, do, lost, where, hint, shell, 


These are the keywords in the questions that the fairy will respond to:
fight, partner, who, key, do, lost, where, hint, help, scared


These are the keywords in the questions that the sorceress will respond to:
fight, partner, hello, where, lost, who, weakness, hint


In addition, you can fight the sorceress through the user command: 


* (define-user-command (attack! sorceress) 
"Attacks a sorceress.")


But be careful, you can die fighting! This is a fight to the death. You must kill the sorceress or die trying to end the fight. 


After the sorceress attacks, you can fight back by typing FoolishStrike or Strike in the prompt window (eof). There is a very special prize waiting for you if you win.
 
* (define-user-command (rub orb) 
"Rubs the orb")


The orb is special. You can talk to it, but you also might want to try initiating the spirit inside it.


---------------------------------------


GENERAL HINTS & NOTES OF ADVICE
* You should specify what water you are using (desert or sea water) for commands that involve water, such as filling up the bucket or dissociating the water. 
        
Examples:
(take (the sea water))
(dissociate (the desert water))
(fill (the bucket) (the sea water))
(destroy (the lava) (the bucket))


        


* Be open to picking up items! The purpose of some items may not be apparent but be open to thinking outside the box and using your surroundings as clues! Even the inconspicuous brick holds a greater purpose than you might think… 


* The walkthrough win includes (attack! (the sorceress)) which means you have to fight the sorceress back in the prompt window (eof). Look above in the interacting with mythical beings section for more details on how to fight back using FoolishStrike or Strike


---------------------------------------


WALKTHROUGH 
NOTE: The walkthrough win includes (attack! (the sorceress)) which means you have to fight the sorceress back in the prompt window (eof). Look above in the //interacting with mythical beings// section for more details on how to fight back using FoolishStrike or Strike






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