#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <Math.au3>

; Set Options
Opt("WinTitleMatchMode", 2) ; Set window title match for any substring instead of start with

Global Const $VERSION = "0.5.0"

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



;Key Press
Global Enum $KEY_CTRL, _
            $KEY_SHIFT, _
            $KEY_Z

Global Const $KEY_ACTION[3][2] = _
            [  ["{CTRLDOWN}", "{CTRLUP}"], _
               ["{SHIFTDOWN}", "{SHIFTUP}"], _
               ["{z down}", "{z up}"]]


#include <ClickrConfig.au3>

Main()

Func Main()
   WinActivate($WINDOW)

   Local $levelingHeros = $DEFAULT_LEVELING_HEROS
   PrimaryHeroes($levelingHeros)

   ClickInKillZone()
   EnableProgression()

   Pipeline(NextPipeline())
   ;Local $pipeline[] = [AlwaysWithTheClicking, FabulousFourLeveling, SpamEarlySkills]
   ;Local $pipeline[] = [AlwaysWithTheClicking, FabulousFourLeveling, SpamEarlySkills]
   Local $tick = 0
   While RunBot() And Not Paused()
      Local $pipeline = Pipeline()
      For $step in $pipeline
         $step($tick)
      Next
      $tick += 1
   WEnd
EndFunc

Func Pipeline($p=Null)
   Static Local $pipeline
   If $p <> Null Then
      $pipeline = $p
   EndIf

   Return $pipeline
EndFunc

Func NextPipeline($restart = False)
   Static Local $index = 0
   If $restart Then
      $index = 0
   EndIf
   $p = $PIPELINE_CHAIN[$index]
   $index += 1
   Return $p
EndFunc

Func GetPipeline()
   Local $zone = GetZone()
   Local $pipeline = $PIPELINES[0]
   Local $index = 0
   For $level In $PIPELINE_LEVELS
      If $zone > $level Then
		 $pipeline =  $PIPELINES[$index]
	  Else
		 ExitLoop
      EndIf
      $index += 1
   Next

   Return $pipeline
EndFunc


; Always clicks mobs for every tick count
Func AlwaysWithTheClicking($tick)
   ClickInKillZone(40)
EndFunc

; Get/Set the primary heroes to level during late game leveling
; @param {Array<HeroEnum>} [$heroes]
; @return {Array<HeroEnum>}
Func PrimaryHeroes($heroes = Null)
   Static $primary_heroes[] = []

   If $heroes <> Null Then
      $primary_heroes = $heroes
   EndIf

   Return $primary_heroes
EndFunc

; Leveling stragegy for early game that focuses on levelling the four Page 0 heroes until all heroes are available
; @param {Int} @tick
Func FabulousFourLeveling($tick)
   If Mod($tick, 5) <> 0 Then
      Return
   EndIf

   TargetHeroLevel($CID, 150)
   TargetHeroLevel($TREEBEAST, 1000)
   TargetHeroLevel($IVAN, 1000)
   TargetHeroLevel($BRITTANY, 1000)
   
   Local $leveledAHero = False
   Local $doUpgrades = False
   Static Local $fully_targetted = False

   ;Frostleaf should be available by zone 120
   If GetZone() < 120 Then
      ;Only upgrade if it's possible we don't have all upgrades yet
      $doUpgrades = (HeroLevel($CID) <= 125 Or _
                     HeroLevel($TREEBEAST) <= 125 Or _
                     HeroLevel($IVAN) <= 125 Or _
                     HeroLevel($BRITTANY) <= 125)

      ;Loop backwards from Brittany and level towards target levels
      For $hero in Range(3, -1, -1)
         ClickInKillZone(10)
         While LevelHeroTowardTarget($hero) And Not Paused() And RunBot()
            ClickInKillZone(1)
            $leveledAHero = True
         WEnd
      Next
      If $leveledAHero And $doUpgrades And RunBot() Then
         BuyAllUpgrades()
         ScrollToPage(0)
      EndIf
      EnableProgression()
   ;After Frostleaf is available, level all heroes to their 100s area level
   ElseIf Not Every(TargetHeroLevelReached, Range($FISHERMAN, $FROSTLEAF+1)) Or Not $fully_targetted Then
      If Not $fully_targetted Then
         BindRMap(TargetHeroLevel, 125, Range($FISHERMAN, $FROSTLEAF+1))
         TargetHeroLevel($AMENHOTEP, 150)
         TargetHeroLevel($FROSTLEAF, 105)
         $fully_targetted = True
      EndIf

      ;Loop forward through the rest of heroes after Brittany, incrementing levels
      For $hero in Range($FISHERMAN, $FROSTLEAF+1)
         $leveledAHero = False
         While LevelHeroTowardTarget($hero) And Not Paused() And RunBot()
            ClickInKillZone(1)
            $leveledAHero = True
         WEnd
         ClickInKillZone(5)
         EnableProgression()
         ;Only Buy Upgrades once per page, unless working on Grant or FrostLeaf
         If $leveledAHero And (Mod($hero, 4) == 3 Or $hero == $GRANT Or $hero == $FROSTLEAF) Then
            BuyAllUpgrades()
            ClickInKillZone(5)
         EndIf
      Next
   Else
      ;Early Game leveling done, move onto to next play pipeline
      Pipeline(NextPipeline())
   EndIf
   ClickInKillZone(10)
EndFunc

Func LessThan125($n)
   Return $n < 125
EndFunc

Func SpamEarlySkills($tick)
   Send("12")
EndFunc

; Levels all Primary Heroes and ensures that progression is enabled if any were leveled
; @param {Int} $tick
Func LateGameLeveling($tick)
   If Mod($tick, 30) <> 0 Then
      Return
   EndIf

   Static Local $init = False
   If Not $init Then
      BindRMap(TargetHeroLevel, 2000, PrimaryHeroes())
   EndIf

   If TargetHeroLevelReached() Then
      Local $newLevel = Map(Plus1k, TargetHeroLevel())
      For $hero in Range($FROSTLEAF + 1)
         TargetHeroLevel($hero, $newLevel[$hero])
      Next
   EndIf

   For $hero in PrimaryHeroes()
      While LevelHeroTowardTarget($hero) And RunBot() And Not Paused()
         EnableProgression()
         ClickInKillZone(5)
      WEnd
   Next
EndFunc

Func Plus1k($n)
   Return $n + 1000
EndFunc

Func IdleLateGameLeveling($tick)
   If Mod($tick, 30) <> 0 Then
      Return
   EndIf

   Local $leveledAHero = Any(IsTrue, Map(IdleMaxLevelHero, PrimaryHeroes()))
   If $leveledAHero Then
      EnableProgression()
   EndIf
EndFunc

; Levels a hero either by 100 or 25 until they cannot be leveled anymore
; @param {HeroEnum} $hero
; @return {Boolean} If the hero was leveled
Func MaxLevelHero($hero)
   If TryToLevelBy100($hero) Or _
      TryToLevelBy25($hero) Then
      MaxLevelHero($hero)
      Return True
   EndIf
   ClickInKillZone()
   Return False
EndFunc

Func IdleMaxLevelHero($hero)
   If TryToLevelBy100($hero) Or _
      TryToLevelBy25($hero) Then
      IdleMaxLevelHero($hero)
      Return True
   EndIf
   Return False
EndFunc

Func EnhancedDarkRitual($tick)
   Local Enum  $PHASE_UNDETERMINED, _ ;Script just started
               $PHASE_NONE, _         ;Spam skills while waiting for EDR combo
               $PHASE_RELOAD, _       ;Wait for 2nd DR Reload
               $PHASE_SKILLS, _       ;Spam Skills waiting for E&R
               $PHASE_SUPER_GOLD      ;Wait for SuperGold run before restarting

   Static Local $phase = $PHASE_UNDETERMINED

   Local $skill = Map(SkillEnabled, Range(9))

   Switch $phase
      Case $PHASE_UNDETERMINED:
         If Every(IsTrue, $skill) Then
            $phase = $PHASE_NONE
         ElseIf $skill[$DARK_RITUAL] Then
            $phase = $PHASE_SKILLS
         Else
            $phase = $PHASE_RELOAD
         EndIf

      Case $PHASE_NONE
         EnableProgression()
         Send("123457")
         If $skill[$DARK_RITUAL] And _
            $skill[$ENERGIZE] And _
            $skill[$RELOAD] Then
               Send("869")
               $phase = $PHASE_RELOAD
         EndIf

      Case $PHASE_RELOAD
         If $skill[$ENERGIZE] And _
            $skill[$RELOAD] Then
               Send("89")
               $phase = $PHASE_SKILLS
         EndIf

      Case $PHASE_SKILLS
         If $skill[$ENERGIZE] And _
            $skill[$RELOAD] Then
               $phase = $PHASE_SUPER_GOLD
         Else
            EnableProgression()
            Send("123457")
         EndIf

      Case $PHASE_SUPER_GOLD
         If Every(IsTrue, $skill) Then
               $phase = $PHASE_NONE
         EndIf
   EndSwitch
EndFunc

Func PerformCooldowns()
   Local $cd_index = 1
   Local $cooldowns_ready = Map(SkillEnabled, Range(9))

   If $cooldowns_ready[$DARK_RITUAL] Then
      Send("123457")
      If $cooldowns_ready[$ENERGIZE] And $cooldowns_ready[$RELOAD] Then
         Send("869")
      EndIf
   ElseIf $cooldowns_ready[$ENERGIZE] And $cooldowns_ready[$RELOAD] Then
      Send("89")
   EndIf
EndFunc

Func SkillEnabled($skill)
   Local $range = NewPixelRange($TOP_COOLDOWN[0], $TOP_COOLDOWN[1] + ($skill * $COOLDOWN_Y_OFFSET))
   Return Not BoardRangeContainsColor($range, $COOLDOWN_COLOR)
EndFunc

Func BuyAllUpgrades()
   ScrollToBuyUpgrades()
   Sleep(200)
   Click($BUY_UPGRADES_RANGE[0], $BUY_UPGRADES_RANGE[1], 3)
EndFunc

Func EnableProgression()
   ;Didn't find progression mode, turn it on!
   If Not ProgressionEnabled() Then
      Send("a")
   EndIf
EndFunc

Func EnableFarming()
   If ProgressionEnabled() Then
      Send("a")
   EndIf
EndFunc

Func ProgressionEnabled()
   Local $range = $PROGRESSION_PIXEL_RANGE
   Local $color = $PROGRESSION_COLOR
   Return Not BoardRangeContainsColor($range, $color, 10)
EndFunc

Func ClickInKillZone($count=1)
   Local Const $x = Int(Floor($BOARD_WIDTH/4)*3)
   Local Const $y = Int(Floor($BOARD_HEIGHT/3)*2)

   Click($x, $y, $count)
EndFunc

Func TryToLevel($hero)
   Local $levelled = False
   While CanLevel($hero)
      LevelUp($hero, 1)
      $levelled = True
   Wend

   Return $levelled
EndFunc

Func TryToLevelBy10($hero)
   Return WithKeyPress($KEY_SHIFT, TryToLevel, $hero)
EndFunc

Func TryToLevelBy25($hero)
   Return WithKeyPress($KEY_Z, TryToLevel, $hero)
EndFunc

Func TryToLevelBy100($hero)
   Return WithKeyPress($KEY_CTRL, TryToLevel, $hero)
EndFunc

Func CanLevel($hero)
   ScrollToHero($hero)
   Sleep(400)

   Local $row = $HERO_BUTTON[$hero][1]

   Local Const $SEARCH_RADIUS = 20

   Local $range = NewPixelRange( $HERO_ROW_X - $SEARCH_RADIUS, _
                              $HERO_ROW_Y[$row] - $SEARCH_RADIUS, _
                              $HERO_ROW_X + $SEARCH_RADIUS, _
                              $HERO_ROW_Y[$row] + $SEARCH_RADIUS)

   For $cannotBuyColor in $CANNOT_BUY_COLORS
      ;Found the CANNOT_BUY_COLOR, cannot buy this amount
      If BoardRangeContainsColor($range, $cannotBuyColor, 40) Then
         Return False
      EndIf
   Next


   Return True
EndFunc

Func CanLevelBy10($hero)
   Return WithKeyPress($KEY_SHIFT, CanLevel, $hero)
EndFunc

Func CanLevelBy25($hero)
   Return WithKeyPress($KEY_Z , CanLevel, $hero)
EndFunc

Func CanLevelBy100($hero)
   Return WithKeyPress($KEY_CTRL, CanLevel, $hero)
EndFunc

Func GetZone()
   Local $title = WinGetTitle($WINDOW)
   Return Int(StringRegExpReplace($title, "[^0-9]", ""))
EndFunc

; See a specific hero, or all heroes, have reached their target level
; @param {HeroEnum} [@hero] If omitted, returns if all targets are reached
; @return {Boolean}
Func TargetHeroLevelReached($hero = Null)
   If $hero == Null Then
      For $i In Range($FROSTLEAF+1)
         If Not TargetHeroLevelReached($i) Then
            Return False
         EndIf
      Next
      Return True
   Else
      Local $target = TargetHeroLevel($hero)
      Local $level = HeroLevel($hero)
      Return $level >= $target
   EndIf
EndFunc

Func LevelHeroTowardTarget($hero)
   Local $level = HeroLevel($hero)
   Local $target = TargetHeroLevel($hero)

   If $level >= $target Then
      Return False
   EndIf

   Local $diff = $target - $level
   Switch $level
      Case 0 To 50   
         If GetZone() < 100 Then
            Return LevelForTargetBy25Max($hero)
         Else
            Return LevelForTargetBy100Max($hero)
         EndIf

      Case 50 To 200
         Return LevelForTargetBy25Or100($hero)

      Case 200 To 1000
         Return LevelForTargetBy100($hero)

      Case Else
         Return LevelForTargetBy25Or100($hero)
   EndSwitch

   Return False
EndFunc

; Leveling strategy that increments by 25 or 10
; @param {HeroEnum} @hero
; @return {Boolean} If the hero was leveled
Func LevelForTargetBy25Max($hero)
   Local $level = HeroLevel($hero)
   Local $target = TargetHeroLevel($hero)
   Local $diff = $target - $level

   If $diff >= 25 And Mod($level, 25) == 0 And CanLevelBy25($hero) Then
      LevelUp($hero, 25)
      Return True
   ElseIf $diff >= 10 And Mod($level, 10) == 0 And CanLevelBy10($hero) Then
      LevelUp($hero, 10)
      Return True
   ElseIf (Mod($diff, 5) <> 0 Or $diff < 10) And CanLevel($hero) Then
      LevelUp($hero, 1)
      Return True
   EndIf
   Return False
EndFunc

; Leveling strategy that increments by 100, 25, or 10
; @param {HeroEnum} @hero
; @return {Boolean} If the hero was leveled
Func LevelForTargetBy100Max($hero)
   Local $level = HeroLevel($hero)
   Local $target = TargetHeroLevel($hero)
   Local $diff = $target - $level

   If $diff >= 100 And Mod($level, 100) == 0 And CanLevelBy100($hero) Then
      LevelUp($hero, 100)
      Return True
   ElseIf $diff >= 25 And Mod($level, 25) == 0 And CanLevelBy25($hero) Then
      LevelUp($hero, 25)
      Return True
   ElseIf $diff >= 10 And Mod($level, 10) == 0 And CanLevelBy10($hero) Then
      LevelUp($hero, 10)
      Return True
   ElseIf (Mod($diff, 5) <> 0 Or $diff < 10) And CanLevel($hero) Then
      LevelUp($hero, 1)
      Return True
   EndIf
   Return False
EndFunc

; Leveling strategy that prefers leveling in increments of 100 or 25
; @param {HeroEnum} @hero
; @return {Boolean} If the hero was leveled
Func LevelForTargetBy25Or100($hero)
   Local $level = HeroLevel($hero)
   Local $target = TargetHeroLevel($hero)
   Local $diff = $target - $level

   If $diff >= 100 And Mod($level, 100) == 0 And CanLevelBy100($hero) Then
      LevelUp($hero, 100)
      Return True
   ElseIf $diff >= 25 And Mod($level, 25) == 0 And CanLevelBy25($hero) Then
      LevelUp($hero, 25)
      Return True
   ElseIf $diff >= 10 And Mod($level, 25) <> 0 And CanLevelBy10($hero) Then
      ;Handles scnearios where the current level is not a proper multiple
      LevelUp($hero, 10)
      Return True
   ElseIf (Mod($diff, 5) <> 0 Or $diff < 10)  And CanLevel($hero) Then
      ;Handles scnearios where the current level is not a proper multiple
      LevelUp($hero, 1)
      Return True
   EndIf
   Return False
EndFunc

; Leveling strategy that prefers incrementing by 100
; @param {HeroEnum} @hero
; @return {Boolean} If the hero was leveled
Func LevelForTargetBy100($hero)
   Local $level = HeroLevel($hero)
   Local $target = TargetHeroLevel($hero)
   Local $diff = $target - $level

   If $diff >= 100 And Mod($level, 100) == 0 And CanLevelBy100($hero) Then
      LevelUp($hero, 100)
      Return True
   ElseIf $diff >= 25 And Mod($level, 100) <> 0 And CanLevelBy25($hero) Then
      LevelUp($hero, 25)
      Return True
   ElseIf (Mod($diff, 5) <> 0 Or $diff < 10) And CanLevel($hero) Then
      ;Handles scnearios where the current level is not a proper multiple
      LevelUp($hero, 1)
      Return True
   EndIf
   Return False
EndFunc


; LevelUp a Hero a given number of levels
; @param {HeroEnum} $hero
; @param {Int} [$levels]
Func LevelUp($hero, $levels=1)
   If $levels <= 0 Then
      Return
   EndIf

   ScrollToHero($hero)

   Local $row = $HERO_BUTTON[$hero][1]
   ClickHeroRow($row, $levels)
   HeroLevel($hero, HeroLevel($hero) + $levels)
EndFunc

; Get/Set a hero's level
; @param {HeroEnum} [@hero] If omitted, return is all hero levels as array
; @param {Int} [@level] Sets the hero level. If omitted return is current hero level
; @return {Int|Array<Int>}
Func HeroLevel($hero = Null, $level = Null)
   Local Static $hero_level[$FROSTLEAF+1]

   If $hero == Null Then
      Return $hero_level
   EndIf

   If $level <> Null Then
      $hero_level[$hero] = $level
   EndIf

   Return $hero_level[$hero]
EndFunc

; Get/Set a hero's target (desired) level
; @param {HeroEnum} [@hero] If omitted, return is all target levels as array
; @param {Int} [@level] Sets the target level. If omitted return is current target level
; @return {Int|Array<Int>}
Func TargetHeroLevel($hero = Null, $level = Null)
   Local Static $target_level[$FROSTLEAF+1]

   If $hero == Null Then
      Return $target_level
   EndIf

   If $level <> Null Then
      $target_level[$hero] = $level
   EndIf

   Return $target_level[$hero]
EndFunc

; Send a given number of clicks to a hero row
; @param {Int} $row
; @param {Int} [$count]
Func ClickHeroRow($row, $count=1)
   If $count <= 0 Then
      Return
   EndIf

   If $count >= 100 Then
      Send("{CTRLDOWN}")
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], 1)
      Send("{CTRLUP}")
      Return ClickHeroRow($row, $count-100)
   ElseIf $count >= 25 Then
      Send("{z down}")
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], 1)
      Send("{z up}")
      Return ClickHeroRow($row, $count-25)
   ElseIf $count >= 10 Then
      Send("{SHIFTDOWN}")
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], 1)
      Send("{SHIFTUP}")
      Return ClickHeroRow($row, $count-10)
   Else
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], $count)
   EndIf
EndFunc

; Scroll to a given hero page
; @param {Int} $page
Func ScrollToPage($p)
   Static Local $current_page = -1
   If $current_page <> $p Then
      ;Pages at the end get really close together, rescroll to top to ensure a good click
      If $current_page >= 5 And $p >= 5 Then
         Click($SCROLL_TOP[0], $PAGE_SCROLL[0])
      EndIf
      Click($SCROLL_TOP[0], $PAGE_SCROLL[$p])
      Sleep(600)
      $current_page = $p
   EndIf
EndFunc

Func ScrollToHero($hero)
   Local $page = $HERO_BUTTON[$hero][0]
   ScrollToPage($page)
EndFunc

Func ScrollToBuyUpgrades()
   ScrollToPage(7)
EndFunc

; Click on the game board a given number of times.
; Performs x,y coordinate translations from board x,y to screen x,y
; @param {Int} $row
Func Click($x, $y, $count=1)
   Local $board = FindBoard()
   For $i = 0 To $count-1
     MouseClick("left", $x + $board[0], $y + $board[1], 1, $MOUSE_SPEED)
     Sleep($CLICK_DELAY)
   Next
EndFunc

; Create a Pixel Range array
; @param {Int} $left
; @param {Int} $top
; @param {Int} [$right]
; @param {Int} [$bottom]
; @return {Array<Int x1, Int y1, Int x2, Int y2>}
Func NewPixelRange($left, $top, $right=Null, $bottom=Null)
   If $right == Null Then
      $right = $left
   EndIf
   If $bottom == Null Then
      $bottom = $top
   EndIf
   Local $range[] = [$left, $top, $right, $bottom]
   Return $range
EndFunc

; Tests if a color exists in a given board pixel range
; @param {Array<Int x1, Int y1, Int x2, Int y2>} $range
; @param {Hex|Int} $color
; @param {Int} [$variance]
; @return {Boolean}
Func BoardRangeContainsColor($range, $color, $variance=0)
   Local $coord = BoardSearch($range[0], $range[1], $range[2], $range[3], $color, $variance)
   Return IsArray($coord)
EndFunc

; Search the game board for a color in a given pixel range
; @param {Int} $left
; @param {Int} $top
; @param {Int} $right
; @param {Int} $bottom
; @param {Int|Hex} $color
; @param {Int} [$variance]
;
; @return {Array<Int,Int>}
Func BoardSearch($left, $top, $right, $bottom, $color, $variance=0)
   Local $topLeft       = TranslateCoords($left, $top)
   Local $bottomRight   = TranslateCoords($right, $bottom)

   $left    = $topLeft[0]
   $top     = $topLeft[1]
   $right   = $bottomRight[0]
   $bottom  = $bottomRight[1]

   Return ColorSearch($left, $top, $right, $bottom, $color, $variance)
EndFunc

; Find the game board within the browser window
; @return {Array<Int,Int>}
Func FindBoard()

   Static Local $lastLeftX = 0
   Static Local $lastTopY = 0
   Static Local $lastWidth = 0
   Static Local $lastHeight = 0
   Static Local $lastCoord[] = [0, 0]

   Local $poz = WinGetPos($WINDOW)

   Local $boardLeftX = $poz[0]
   Local $boardTopY = $poz[1]
   Local $width = $poz[2]
   Local $height = $poz[3]

   If $boardLeftX = $lastLeftX And _
      $boardTopY  = $lastTopY And _
      $width      = $lastWidth And _
      $height     = $lastHeight Then
      Return $lastCoord
   EndIf

   $lastLeftX = $boardLeftX
   $lastTopY = $boardTopY
   $lastWidth = $width
   $lastHeight = $height

   Local $leftCutoff =  $boardLeftX + Int($width/2)
   Local $topCutoff =  $boardTopY + Int($height/2)

   Local $leftYSearchPos = $boardTopY + Floor($height/2)
   Local $topXSearchPos = $boardLeftX + Floor($width/2 - $BOARD_WIDTH/4)

   Local $left = ColorSearch($boardLeftX, $leftYSearchPos, $leftCutoff, $leftYSearchPos, $LEFT_EDGE_COLOR, 20)
   Local $top = ColorSearch($topXSearchPos, $boardTopY, $topXSearchPos, $topCutoff, $TOP_EDGE_COLOR, 20)

   $lastCoord[0] = $left[0]
   $lastCoord[1] = $top[1] + $TOP_OFFSET
   Return $lastCoord
EndFunc

; Search for a color in a given pixel range
; @param {Int} $left
; @param {Int} $top
; @param {Int} $right
; @param {Int} $bottom
; @param {Int|Hex} $color
; @param {Int} [$variance]
;
; @return {Array<Int,Int>}
Func ColorSearch($left, $top, $right, $bottom, $color, $variance=0)
   If $DEBUG Then
     Local $d[] = ["ColorSearch", $left, $top, $right, $bottom, $color, $variance]
     Dbg($d)
   EndIf

   Return PixelSearch($left, $top, $right, $bottom, $color, $variance)
EndFunc

Func TranslateCoords($x, $y)
   Local $board = FindBoard()
   Local $coords[] = [$x+$board[0], $y+$board[1]]
   Return $coords
EndFunc

Func WithKeyPress($key, $f, $arg = Null)
   Local $result

   Send($KEY_ACTION[$key][0])
   Sleep(600)  ;Sometimes you need the delay to be sure the color has changed
   If $arg == Null Then
    $result = $f()
   Else
      $result = Call(FuncName($f), $arg)
   EndIf

   Send($KEY_ACTION[$key][1])

   Return $result
EndFunc

; Map a function over an array
; @param {function} $f
; @param {Array} $a
Func Map($f, ByRef $a)
   Local $len = UBound($a)
   Local $result[$len]

   For $i = 0 To $len-1 Step 1
     $result[$i] = $f($a[$i])
   Next

   Return $result
EndFunc

; Bind arguments to a given function and map it over an array
; @param {function} $f
; @param {Array} $arg
; @param {Array} $a
Func BindMap($f, ByRef $arg, ByRef $a)
   Local $funcName = FuncName($f)
   Local $len = UBound($a)
   Local $result[$len]

   Local $size = UBound($arg)+2
   Local $mapArg = $size-1


   Local $bindArg[] = ["CallArgArray"]

   _ArrayAdd($bindArg, $arg)
   ReDim $bindArg[UBound($bindArg) + 1]

   For $i = 0 To $len-1 Step 1
     $bindArg[$mapArg] = $a[$i]
     $result[$i] = Call($funcName, $bindArg)
   Next

   Return $result
EndFunc

; Bind arguments to the right side of a given function and map it over an array
; @param {function} $f
; @param {Array} $arg
; @param {Array} $a
Func BindRMap($f, ByRef $arg, ByRef $a)
   Local $funcName = FuncName($f)
   Local $len = UBound($a)
   Local $result[$len]

   Local $size = UBound($arg)+2
   Local $bindArg[2]

   Local $mapArg = 1

   $bindArg[0] = "CallArgArray"
   _ArrayAdd($bindArg, $arg, 2)


   For $i = 0 To $len-1 Step 1
     $bindArg[$mapArg] = $a[$i]
     $result[$i] = Call($funcName, $bindArg)
   Next

   Return $result
EndFunc

; Returns true if the provided function returns true for Every element of the array
Func Every($f, ByRef $a)
   Local $len = UBound($a)

   For $i = 0 To $len-1 Step 1
      If Not $f($a[$i]) Then
         Return False
      EndIf
   Next
   Return True
EndFunc

; Returns true if the provided function returns true for Any element of the array
Func Any($f, ByRef $a)
   Local $len = UBound($a)

   For $i = 0 To $len-1 Step 1
      If $f($a[$i]) Then
         Return True
      EndIf
   Next
   Return False
EndFunc



Func IsTrue($b)
   Return $b == True
EndFunc

; Create a range of numbers
; @param {Int} $start
; @param {Int} [$end]
; @param {Int} [$step]
Func Range($start, $end=Null, $step = 1)
   If $end = Null Then
     $end = $start
     $start = 0
   EndIf

   Local $max = _Max($start, $end)
   Local $min = _Min($start, $end)
   Local $size = Abs(Int(Ceiling(($max - $min)/$step)))
   Local $r[$size]
   Local $index = 0
   Local $i = $start
   Do
      $r[$index] = $i
      $index += 1
      $i += $step
   Until $i == $end

   Return $r
EndFunc

Func Paused($pause=Null)
   Static Local $is_paused = False

   If $pause == Null Then
      Return $is_paused
   EndIf

   $is_paused = $pause
   Return $is_paused
EndFunc

Func Toggle_Pause()
   Paused(Not Paused())
   While Paused() And RunBot()
      Sleep(100)
      ToolTip("Paused", 0, 0)
   WEnd
   ToolTip("")
   WinActivate($WINDOW)
   $g_page = -1
EndFunc

Func RunBot($run=Null)
   Static Local $is_running = True

   If $run == Null Then
      Return $is_running
   EndIf

   $is_running = $run
   Return $is_running
EndFunc

Func Shut_Down()
    RunBot(false)
    ToolTip("Shutting Down")
EndFunc

Func HexStr($h)
   Return String("0x" & hex($h,6))
EndFunc

Func Pop($msg)
   MsgBox($MB_SYSTEMMODAL, "", $msg)
EndFunc

Func Dbg($msg)
   If IsArray($msg) Then
     ConsoleWrite(_ArrayToString($msg, ", ") & @CR)
   Else
     ConsoleWrite($msg & @CR)
   EndIf
EndFunc
