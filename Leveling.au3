#include-once

#include <Utils.au3>
#include <ClickrConstants.au3>
#include <BoardState.au3>
#include <Controls.au3>

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

; Set all target hero levels to 0
Func ClearAllTargets()
   ;Clear Targets
   BindRMap(TargetHeroLevel, 0, Range($FROSTLEAF+1))
EndFunc

Func ClearHeroLevels()
   BindRMap(HeroLevel, 0, Range($FROSTLEAF+1))
EndFunc

; Ensures that Amenhotep has enough levels and ascends the world
Func Ascend()
   Static Local $delay = GlobalOrDefault("ASCEND_DELAY", $DEFAULT_ASCEND_DELAY)

   ;Ensure Amenhotep has enough levels
   If HeroLevel($AMENHOTEP) < 150 Then
      TargetHeroLevel($AMENHOTEP, 150)
      While LevelHeroTowardTarget($AMENHOTEP)
      WEnd
      BuyAllUpgrades()
   EndIf

   ;Scroll to Amenhotep and click Ascend
   ScrollToHero($AMENHOTEP)
   Click($ASCEND_RANGE[0], $ASCEND_RANGE[1])
   Sleep($delay)
   
   ;Click thru the confirmation dialog
   Click($CONFIRM_ASCEND_RANGE[0], $CONFIRM_ASCEND_RANGE[1])

   ClearAllTargets()
   ClearHeroLevels()
   
   Map(Invoke, OnAscend)

   ;Reset the pipeline chain
   Pipeline(NextPipeline(True))
EndFunc

Func OnAscend($f = Null)
   Static Local $listeners[] = [Noop]
   If $f <> Null Then
      If $listeners[0] == Noop Then
         $listeners[0] = $f
      Else
         _ArrayAdd($listeners, $f)
      EndIf
   EndIf
   Return $listeners
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

Func CanLevel($hero)
   ScrollToHero($hero)
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