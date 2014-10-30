
#include <Utils.au3>
#include <ClickrConstants.au3>
#include <BoardState.au3>
#include <Controls.au3>


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

; Always clicks mobs for every tick count
Func AlwaysWithTheClicking($tick)
   ClickInKillZone(40)
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


Func SpamEarlySkills($tick)
   Send("12")
EndFunc

Func AlwaysProgress($tick)
   EnableProgression()
EndFunc


Func LessThan125($n)
   Return $n < 125
EndFunc

Func LessThan1k($n)
   Return $n < 1000
EndFunc

Func Plus1k($n)
   Return $n + 1000
EndFunc