#include-once

#include <Utils.au3>

; Set Options
Opt("WinTitleMatchMode", 2) ; Set window title match for any substring instead of start with


Global Const $WINDOW = "Clicker Heroes"

;Pixels Go Here
   ;Game area
   Global Const $BOARD_WIDTH = 1133
   Global Const $BOARD_HEIGHT = 639

   ;Top of scroll bar, under up arrow
   Global Const $SCROLL_TOP[] = [547, 201]

   ;Bottom of scroll bar, above down arrow
   Global Const $SCROLL_BOTTOM = NewPixelRange(550, 605)

   ;Page scrolling postions (4 heroes per page), final page is for Buy All Upgrades
   Global Const $PAGE_SCROLL[] = [201, 304, 359, 418, 474, 529, 559, 605]

   ; Cooldowns Position
   Global Const $TOP_COOLDOWN[] = [607, 169]
   Global Const $COOLDOWN_Y_OFFSET = 51.75

   ;Level Button Positioning
   Global Const $HERO_ROW_X = 91
   Global Const $HERO_ROW_Y[] = [224, 330, 436, 542]

   ;Farm Mode Positioning
   Global Const $PROGRESSION_PIXEL_RANGE = NewPixelRange(1104, 200, 1115, 208)

   ;Buy All Upgrades
   Global Const $BUY_UPGRADES_RANGE = NewPixelRange(250, 550)

   ;Ascend
   Global Const $ASCEND_RANGE = NewPixelRange(300, 560)
   Global Const $CONFIRM_ASCEND_RANGE = NewPixelRange(490, 415)

   ;Gold Zone
   Global Const $GOLD_ZONE = NewPixelRange(745, 400, 945, 450)
;End of Pixels

;Used to find the game board within the browser window
Global Const $LEFT_EDGE_COLOR = 0x875508
Global Const $TOP_EDGE_COLOR = 0xBB7A19
Global Const $TOP_OFFSET = -3

Global Const $CANNOT_BUY_COLORS[] = [0xFE8743, 0x7E4321]
Global Const $PROGRESSION_COLOR = 0xFF0000
Global Const $COOLDOWN_COLOR = 0xFFFFFF

;HeroEnum
Global Enum $CID, _
            $TREEBEAST, _
            $IVAN, _
            $BRITTANY, _
            $FISHERMAN, _
            $BETTY, _
            $SAMURAI, _
            $LEON, _
            $SEER, _
            $ALEXA, _
            $NATALIA, _
            $MERCEDES, _
            $BOBBY, _
            $BROYLE, _
            $GEORGE, _
            $MIDAS, _
            $REFRI, _
            $ABADON, _
            $MAZHU, _
            $AMENHOTEP, _
            $BEASTLORD, _
            $ATHENA, _
            $APHRODITE, _
            $SHINATOBE, _
            $GRANT, _
            $FROSTLEAF

;Hero Page/Row combos
Global Const $HERO_BUTTON[26][2] = _
            [  [0,0], [0,1], [0,2], [0,3], _    ;Cid, Tree, Ivan, Brit
               [1,0], [1,1], [1,2], [1,3], _    ;Fish, Betty, Sam, Leon
               [2,0], [2,1], [2,2], [2,3], _    ;Seer, Alexa, Nat, Merc
               [3,0], [3,1], [3,2], [3,3], _    ;Bobby, Broyle, George, Midas
               [4,0], [4,1], [4,2], [4,3], _    ;Refri, Abadon, MaZhu, Amen
               [5,0], [5,1], [5,2], [5,3], _    ;Beast, Ahtena, Aphro, Shina
                             [6,2], [6,3]]      ;Grant, FrostLeaf

;Skills Enum
Global Enum $CLICKSTORM, _
            $POWERSURGE, _
            $LUCKY_STRIKES, _
            $METAL_DETECTOR, _
            $GOLDEN_CLICKS, _
            $DARK_RITUAL, _
            $SUPER_CLICKS, _
            $ENERGIZE, _
            $RELOAD

Global Const $SECONDS = 1000
Global Const $MINUTES = $SECONDS * 60

;Overide with $PAGE_SCROLL_DELAY
Global Const $DEFAULT_PAGE_SCROLL_DELAY = 300

;Overide with $CLICK_DELAY
Global Const $DEFAULT_CLICK_DELAY = 2

;Overide with $ASCEND_DELAY
Global Const $DEFAULT_ASCEND_DELAY = 500

;Overide with $LATE_GAME_LEVELING_TICK_RATE
Global Const $DEFAULT_LATE_GAME_LEVELING_TICK_RATE = 4

