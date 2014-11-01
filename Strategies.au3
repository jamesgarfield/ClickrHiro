
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

   Static Local $max_upgrade[] = [150, 125, 150, 100]

   ;Only upgrade if it's possible we don't have all upgrades yet
   Local $needUpgrades = ( HeroLevel($hero) < $max_upgrade[$hero] )

   Local $leveled = False
   If DoLeveling($hero) Then
      $leveled = True
   Else
      $index += 1
      If $index >= UBound(PrimaryHeroes()) Then
         $index = 0
      EndIf
   EndIf
   
   Local $level = HeroLevel($hero)
   Local $upgradeLevel = ($level == 10 Or Mod($level, 25) == 0)

   If $leveled And $needUpgrades And $upgradeLevel And RunBot() Then
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
   Static Local $tick_rate = GlobalOrDefault("LATE_GAME_LEVELING_TICK_RATE", $DEFAULT_LATE_GAME_LEVELING_TICK_RATE)

   If BossFight() Or _
      Mod(GetZone(), $tick_rate) <> 0 Then
      Return
   EndIf

   Static Local $index = 0
   Static Local $do_primary = True

   Local $heroes = PrimaryHeroes()

   If UBound($heroes) == 1 Then
      PrimaryHeroes($DEFAULT_LEVELING_HEROS)
      $heroes = PrimaryHeroes()
      BindRMap(TargetHeroLevel, 4100, $heroes)
      $index = 0
   EndIf

   ; Alternate between leveling top primary and rest of list
   Local $hero
   If $do_primary Then
      $hero = $heroes[0]
   Else
      $hero = $heroes[$index]
   EndIf

   Local $leveled = False
   If DoLeveling($hero) Then
      $leveled = True
   Else
      If Not $do_primary Then
         $index += 1
         If $index >= UBound($heroes) Then
            $index = 0
         EndIf
      EndIf
      $do_primary = Not $do_primary
   EndIf
   
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

   MoveToGoldZone()
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

Func CollectGold($tick)
   MoveToGoldZone()
EndFunc

; Monitor Boss statistics to determine when to switch away from Idling
Func DynamicIdle($tick)
   
   ;How long to allow boss fights to take during idle before switching modes
   Static Local $boss_seconds = GlobalOrDefault("IDLE_BOSS_SECONDS_CUTOFF", 5)
   
   Local $boss = TimeToBeatBoss()
   Local $fails = BossFail()
   Local $zone = GetZone()

   Local $failedBoss = ($fails > 0)
   Local $tooLongToBeatBoss = ($boss > $boss_Seconds * $SECONDS)
   
   If $failedBoss Or $tooLongToBeatBoss Then
      Dbg("============================================")
      Dbg("            Idle Switch: " & $zone)
      Dbg("            Boss Fails : " & $fails)
      Dbg("            Boss Time  : " & TimeStr($boss))
      Dbg("============================================")
      Pipeline(NextPipeline())
   EndIf
EndFunc

;Monitor Boss & Level statistics to determine when to ascend
Func DynamicAscend($tick)
   
   Static Local $boss_fails_after_advance = GlobalOrDefault("ASCEND_AFTER_BOSS_FAIL", 2)
   Static Local $boss_fails_before_advance = GlobalOrDefault("ASCEND_FAILSAFE", $boss_fails_after_advance * 3)
   Static Local $seconds_per_level = GlobalOrDefault("ASCEND_AFTER_SECONDS_PER_LEVEL", 30)

   Static Local $last_ascend = 0
   Static Local $ascend_count = 0

   Local $fails = BossFail()
   Local $zone = GetZone()
   Local $level = TimeInLevel()

   ;This can happen if you start the bot in the middle of a deep run and you've lost click stacks
   Local $levelTooLong = ($level > $seconds_per_level * $SECONDS)
   ;Check for too many boss failures, but still try and get further than last play
   Local $tooManyFails = ($fails > $boss_fails_after_advance & $zone > $last_ascend)
   ;If we're still not getting anywhere, even if we haven't beaten last play
   Local $wayTooManyFails = ($fails > $boss_fails_before_advance)

   If $levelTooLong OR $tooManyFails Or $wayTooManyFails Then
      $last_ascend = $zone
      $ascend_count += 1

      ;Reset statistics
      BossFail(0)
      TimeToBeatBoss(0)
      TimeInLevel(0)

      Ascend()

      Dbg("============================================")
      Dbg("      Ascension " & $ascend_count & " @ " & $zone)
      Dbg("============================================")
   EndIf
EndFunc

; Times how long Boss Fights take, and counts failed attempts
Func BossMonitor($tick)
   Static Local $timer = Null
   Static Local $boss_zone = Null

   Local $zone = GetZone()

   ;Still on same boss
   If $zone == $boss_zone Then
      Return
   EndIf

   ;In a boss fight, start a timer
   If BossFight() Then
      $boss_zone = $zone
      $timer = TimerInit()
      Return
   EndIf

   ;No Boss set, nothing to do
   If $boss_zone == Null Then
      Return
   EndIf

   ;Beat previous boss fight, set statistics and clear local statics
   If $zone > $boss_zone Then
      Local $diff = TimerDiff($timer)
      TimeToBeatBoss($diff, $boss_zone)
      $timer = Null
      $boss_zone = Null
      BossFail(0)
      Return
   EndIf

   ;Failed Previous boss fight, increase BossFail count
   If $zone < $boss_zone Then
      BossFail(BossFail() + 1)
      Return
   EndIf
EndFunc

; Time how long levels take
Func LevelMonitor($tick)
   Static Local $timer = Null
   Static Local $last_zone = 0

   Local $zone = GetZone()

   If $zone > $last_zone Or $zone < $last_zone - 1 Then
      $last_zone = $zone
      $timer = TimerInit()
      Return
   EndIf

   Local $diff = TimerDiff($timer)

   TimeInLevel($diff)
EndFunc

; Get/Set how long the last boss fight took
Func TimeToBeatBoss($ms = Null, $boss = Null)
   Static Local $beat_time = 0
   If $ms <> Null Then
      $beat_time = Floor($ms)
      ;Dbg("To Beat " & StrPad($boss, 4, " ") & " Time: " & TimeStr($beat_time))
   EndIf
   Return $beat_time
EndFunc

;Get/Set Boss Fail Count
Func BossFail($count = Null)
   Static Local $fails = 0
   If $count <> Null Then
      $fails = $count
   EndIf
   Return $fails
EndFunc

;Get/Set how long the current level has been taking
Func TimeInLevel($ms = Null)
   Static Local $level_time = 0
   If $ms <> Null Then
      $level_time = $ms
   EndIf
   Return $level_time
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