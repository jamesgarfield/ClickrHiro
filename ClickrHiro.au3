Global Const $VERSION = "0.6.3"


#include <ClickrConfig.au3>


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

; Clear out all primary heroes
Func ClearPrimaryHeroes()
   Static Local $none[] = []
   PrimaryHeroes($none)
EndFunc

; Leveling stragegy for early game that focuses on levelling the four Page 0 heroes until all heroes are available
; @param {Int} @tick
Func FabulousFourLeveling($tick)
   ;Frostleaf should be available by zone 120
   If GetZone() >= 120 Then
      ClearPrimaryHeroes()
      Pipeline(NextPipeline())
      Return
   EndIf

   If Mod($tick, 2) <> 0 Then
      Return
   EndIf

   Static Local $fab4[] = [$BRITTANY, $IVAN, $TREEBEAST, $CID]

   Static Local $index = 0
   
   Local $heroes = PrimaryHeroes()
   If UBound($heroes) == 1 Then
      PrimaryHeroes($fab4)
   
      ClearAllTargets()
      TargetHeroLevel($CID, 150)
      TargetHeroLevel($TREEBEAST, 1000)
      TargetHeroLevel($IVAN, 1000)
      TargetHeroLevel($BRITTANY, 1000)   

      $heroes = PrimaryHeroes()
      $index = 0
   EndIf

   Local $hero = $heroes[$index]

   ;Only upgrade if it's possible we don't have all upgrades yet
   Local $doUpgrades = (HeroLevel($CID) < 125 Or _
                        HeroLevel($TREEBEAST) <= 125 Or _
                        HeroLevel($IVAN) <= 125 Or _
                        HeroLevel($BRITTANY) <= 125)

   Local $leveled = False
   While DoLeveling($hero)
      $leveled = True
   WEnd

   $index += 1
   If $index >= UBound(PrimaryHeroes()) Then
      $index = 0
   EndIf

   If $leveled And $doUpgrades And RunBot() Then
      BuyAllUpgrades()
      ScrollToPage(0)
   EndIf

   EnableProgression()
EndFunc

; Leveling strategy to iteratively go down the hero ladder leveling each to their 100's max
Func LadderLeveling($tick)
   
   ;All Heroes should be levelled by zone 180
   If GetZone() >= 180 Then
      ClearPrimaryHeroes()
      Pipeline(NextPipeline())
      Return
   EndIf

   Static Local $upgrade_tick = 0

   Local $heroes = PrimaryHeroes()

   Static Local $index = 0

   ; Newly in pipeline, setup heroes
   If UBound($heroes) == 1 Then
      PrimaryHeroes(Range($TREEBEAST, $FROSTLEAF+1))
      $heroes = PrimaryHeroes()

      BindRMap(TargetHeroLevel, 125, $heroes)
      TargetHeroLevel($AMENHOTEP, 150)
      TargetHeroLevel($FROSTLEAF, 100)

      $upgrade_tick = 0
      $index = 0
   EndIf

   Local $hero = $heroes[$index]

   Local $leveled = False
   While DoLeveling($hero)
      $leveled = True
   WEnd
   
   $index += 1
   If $index >= UBound(PrimaryHeroes()) Then
      $index = 0
   EndIf

   If $leveled Then
      $upgrade_tick += 1
   EndIf

   ; Try to only buy upgrades once per page
   If $upgrade_tick == 4 Then
      BuyAllUpgrades()
      $upgrade_tick = 0
   EndIf

   If TargetHeroLevelReached() Then
      ;ladder leveling done, move onto to next play pipeline
      BuyAllUpgrades()
      ClearPrimaryHeroes()
      $upgrade_tick = 0
      Pipeline(NextPipeline())
   EndIf
EndFunc

Func LessThan125($n)
   Return $n < 125
EndFunc

Func SpamEarlySkills($tick)
   Send("12")
EndFunc

Func AlwaysProgress($tick)
   EnableProgression()
EndFunc

; Levels a hero towards their target level and enables progression if successful
; @param {HeroEnum} $hero
; @return {Boolean} If leveling happened
Func DoLeveling($hero)
   Static Local $index = 0


   If LevelHeroTowardTarget($hero) Then
      EnableProgression()
      Return True
   EndIf

   Return False
EndFunc

; Keep an eye on hero target levels duing late game
; @param {Int} $tick
Func LateGameLeveling($tick)
   
   If BossFight() Then
      Return
   EndIf

   Static Local $index = 0

   Static Local $do_primary = True

   If UBound(PrimaryHeroes()) == 1 Then
      PrimaryHeroes($DEFAULT_LEVELING_HEROS)
      $index = 0
   EndIf

   Local $heroes = PrimaryHeroes()

   ; If any target levels are too low, bump them up
   If Any(LessThan1k, Map(TargetHeroLevel, $heroes)) Then
      BindRMap(TargetHeroLevel, 2000, $heroes)
      $index = 0
   EndIf

   ; If all heroes are at their target level, increase everyones target
   If TargetHeroLevelReached() Then
      Local $newLevel = Map(Plus1k, TargetHeroLevel())
      For $hero in Range($FROSTLEAF + 1)
         TargetHeroLevel($hero, $newLevel[$hero])
      Next
      $index = 0
   EndIf

   ; Alternate between leveling top primary and rest of list
   Local $hero
   If $do_primary Then
      $hero = $heroes[0]
   Else
      $hero = $heroes[$index]
      $index += 1
      If $index >= UBound($heroes) Then
         $index = 0
      EndIf
   EndIf
   $do_primary = Not $do_primary

   Local $leveled = False
   While DoLeveling($hero) And Not BossFight()
      $leveled = True
   WEnd
   
   If $leveled Then
      EnableProgression()
   EndIf
EndFunc

Func LessThan1k($n)
   Return $n < 1000
EndFunc

Func Plus1k($n)
   Return $n + 1000
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

; Ensures that Amenhotep has enough levels and ascends the world
Func Ascend()
   If HeroLevel($AMENHOTEP) < 150 Then
      TargetHeroLevel($AMENHOTEP, 150)
      While LevelHeroTowardTarget($AMENHOTEP)
      WEnd
      BuyAllUpgrades()
   EndIf

   ScrollToHero($AMENHOTEP)
   Click($ASCEND_RANGE[0], $ASCEND_RANGE[1])
   Sleep(200)
   Click($CONFIRM_ASCEND_RANGE[0], $CONFIRM_ASCEND_RANGE[1])
   BindRMap(HeroLevel, 0, Range($FROSTLEAF+1))
   ClearAllTargets()
   ClearPrimaryHeroes()
   Pipeline(NextPipeline(True))
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

; Set all target hero levels to 0
Func ClearAllTargets()
   ;Clear Targets
   BindRMap(TargetHeroLevel, 0, Range($FROSTLEAF+1))
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

; Select a level incrementing strategy and try to level the provided hero
; @param {HeroEnum} $hero
; @return {Boolean} True if the hero gained levels
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


Func Toggle_Pause()
   Paused(Not Paused())
   While Paused() And RunBot()
      Sleep(100)
      ToolTip("Paused", 0, 0)
   WEnd
   ToolTip("")
   WinActivate($WINDOW)
   FindBoard(true)
   ActivateBoard()
EndFunc

Func Shut_Down()
    RunBot(false)
    ToolTip("Shutting Down")
EndFunc

