;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program.  If not, see <http://www.gnu.org/licenses/>.
#include <Utils.au3>
#include <ClickrConstants.au3>
#include <BoardState.au3>
#include <Controls.au3>

InitStrategies()
Func InitStrategies()
   OnStep(LevelMonitor)
   OnStep(BossMonitor)
   OnTick(GameDataSync)
   OnAscend(ClearPrimaryHeroes)
   OnAscend(ClearStatistics)
   OnAscend(ResetGameData)
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

; Always clicks mobs for every tick count
Func AlwaysWithTheClicking($tick)
   If BossFight() Then
      ClickInKillZone(160)
   Else
      ClickInKillZone(40)
   EndIf
EndFunc

Func FabulousFour($tick)
   Static Local $fab4[] = [$BRITTANY, $IVAN, $TREEBEAST, $CID]
   If $tick == $START_TICK Then
      Dbg("             Fab Four")
      Dbg("============================================")
      PrimaryHeroes($fab4)
      ClearAllTargets()
      TargetHeroLevel($CID, 150)
      TargetHeroLevel($TREEBEAST, 1000)
      TargetHeroLevel($IVAN, 1000)
      TargetHeroLevel($BRITTANY, 1000)
   EndIf
EndFunc

; Leveling stragegy for early game that focuses on levelling the four Page 0 heroes until all heroes are available
; @param {Int} @tick
Func FabulousFourLeveling($tick)
   ;If any heroes after brittany are leveled, or level is over 120, we're past fab4
   If Any(AboveZero, Map(HeroLevel, Range($FISHERMAN, $ALL_HEROES))) Or _
      GetZone() > 120 Then
      ClearPrimaryHeroes()
      Pipeline(NextPipeline())
      Return
   EndIf

   If $tick == $START_TICK Then
      FabulousFour($tick)
      LevelingRateLimit(GlobalOrDefault("FAB_FOUR_RATE_LIMIT", 2))
   EndIf

   RotationalLeveling($tick)
EndFunc

Func AboveZero($n)
   return $n > 0
EndFunc

Func LevelingRateLimit($ticks=Null)
   Static Local $limit
   If $ticks <> Null Then
      $limit = $ticks
   EndIf
   Return $limit
EndFunc

Func RotationalLeveling($tick)
   Static Local $index = 0
   If $tick == $START_TICK Then
      $index = 0
   EndIf

   If Mod($tick, LevelingRateLimit()) <> 0 Then
      Return
   EndIf

   Local $heroes = PrimaryHeroes()
   Local $hero = $heroes[$index]

   ;Only upgrade if it's possible we don't have all upgrades yet
   Local $currentLevel = HeroLevel($hero)
   Local $needUpgrades = $currentLevel < maxUpgradeLevel($hero)

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

Func LevelsForEveryone($tick)
   If $tick == $START_TICK Then
      Dbg("             Levels For Everyone")
      Dbg("============================================")
      PrimaryHeroes(Range($ALL_HEROES))
      $heroes = PrimaryHeroes()
      Local $arg[] = [100]
      Local $levels = BindMap(_Max, $arg, Map(MaxUpgradeLevel, Range($ALL_HEROES)))

      Local $hero_levels = Zip($heroes, $levels)
      MapInvoke(TargetHeroLevel, $hero_levels)
   EndIf
EndFunc

; Leveling strategy to iteratively go down the hero ladder leveling each to their 100's max
Func LadderLeveling($tick)

   ;All Heroes should be levelled by zone 180
   If GetZone() >= GlobalOrDefault("LADDER_SKIP_ZONE", 250) Then
      Dbg("           Skipping Ladder Leveling")
      Dbg("============================================")
      ClearPrimaryHeroes()
      Pipeline(NextPipeline())
      Return
   EndIf

   If $tick == $START_TICK Then
      LevelsForEveryone($tick)
      LevelingRateLimit(1)
   EndIf

   PageLeveling($tick)

   If TargetHeroLevelReached() Then
      ;ladder leveling done, move onto to next play pipeline
      BuyAllUpgrades()
      ClearPrimaryHeroes()
      $upgrade_tick = 0
      Pipeline(NextPipeline())
   EndIf
EndFunc

Func RequiresUpgrades($hero)
   Local $level = HeroLevel($hero)
   Local $maxUpgrade = MaxUpgradeLevel($hero)
   Return $level < $maxUpgrade
EndFunc

Func PageLeveling($tick)
   If Mod($tick, LevelingRateLimit()) <> 0 Then
      Return
   EndIf

   Static Local $upgrade_tick = 0
   Static Local $index = 0

   Local $heroes = PrimaryHeroes()

   ; Newly in pipeline, setup heroes
   If $tick == $START_TICK Then
      $upgrade_tick = 0
      $index = 0
   EndIf

   Local $hero = $heroes[$index]

   Local $leveled = False
   If DoLeveling($hero) Then
      $leveled = True
   Else
      $upgrade_tick += 1
      $index += 1
      If $index >= UBound(PrimaryHeroes()) Then
         $index = 0
      EndIf
   EndIf

   ; Try to only buy upgrades once per page
   If $upgrade_tick == 4 Then
      BuyAllUpgrades()
      $upgrade_tick = 0
   EndIf
EndFunc


Func BringOutTheBigGuns($tick)
   If $tick == $START_TICK Then
      PrimaryHeroes($DEFAULT_LEVELING_HEROS)
      TargetPrimaryHeroes($MAX_HERO_LEVEL)
   EndIf
EndFunc

; Set all Primary Heroes target level
; @param {Int} $level
Func TargetPrimaryHeroes($level)
   Return SetHeroesTarget(PrimaryHeroes(), $level)
EndFunc

Func SetHeroesTarget($heroes, $level)
   Local $arg[] = [$level]
   Return BindRMap(TargetHeroLevel, $arg, $heroes)
EndFunc

; Keep an eye on hero target levels duing late game
; @param {Int} $tick
Func LateGameLeveling($tick)

   If BossFight() Then
      Return
   EndIf

   If $tick == $START_TICK Then
      BringOutTheBigGuns($tick)
      LevelingRateLimit(GlobalOrDefault("LATE_GAME_RATE_LIMIT", 3))
   EndIf

   RotationalLeveling($tick)
   EndGame($tick)
EndFunc

Func EndGame($tick)
   Static Local $endgame_count = 0
   Static Local $previous_zone = 0
   Static Local $is_endgame = False
   Static Local $alternates
   Static Local $alt_index = 0

   Local $zone = GetZone()

   ;As soon as any hero is above 4k, enter endgame
   If Any(Over4000, HeroLevel()) And Not $is_endgame Then
      $is_endgame = True

      Local $superSayan = Filter(HeroOver4000, Range($ALL_HEROES))
      Local $names = _ArrayToString(Map(HeroName, $superSayan), ", ")
      $endgame_count += 1
      Dbg("             End Game : " & $endgame_count)
      Dbg("             Zone     : " & $zone)
      Dbg("             Previous : " & $previous_zone)
      Dbg("             Heroes   : " & $names)
      Dbg("============================================")

      ;Alternates are all non primary heroes
      $alternates = Filter(NotPrimary, Range($TREEBEAST, $ALL_HEROES))
      $alt_index = 0

      SetHeroesTarget($alternates, $MAX_HERO_LEVEL)

      $previous_zone = $zone
   ElseIf $is_endgame And $zone >= $previous_zone Then
      ;Only do endgame leveling after normal leveling
      If Mod($tick, LevelingRateLimit()) <> 1 And LevelingRateLimit() <> 1 Then
         Return
      EndIf
      Local $hero = $alternates[$alt_index]
      If Not DoLeveling($hero) Then
         $alt_index += 1
         If $alt_index >= UBound($alternates) Then
            $alt_index = 0
         EndIf
      EndIf
   ElseIf $is_endgame And $zone < $previous_zone Then
      ; Potentially ascended, reset
      $is_endgame = False
      $alternates = Null
   EndIf
EndFunc

Func Over4000($n)
   Return $n >= 4000
EndFunc

Func HeroOver4000($hero)
   Return Over4000(HeroLevel($hero))
EndFunc

Func IsPrimary($hero)
   Return (_ArraySearch(PrimaryHeroes(), $hero) <> -1)
EndFunc

Func NotPrimary($hero)
   Return Not IsPrimary($hero)
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

   Static Local $last_idle = 0

   Local $boss = TimeToBeatBoss()
   Local $level = TimeInLevel()
   Local $fails = BossFail()
   Local $zone = GetZone()


   Local $failedBoss = ($fails > 0)

   Local $tooLongToBeatBoss = ( $boss > ($boss_seconds * $SECONDS) )
   Local $tooLongInLevel = ( $level > ($boss_seconds * $SECONDS * 2) )


   If $failedBoss Or $tooLongToBeatBoss Or $tooLongInLevel Then
      Dbg("            Idle Switch: " & $zone)
      Dbg("            Previous   : " & $last_idle)
      Dbg("            Boss Fails : " & $fails & " (" & $failedBoss & ")")
      Dbg("            Boss Time  : " & TimeStr($boss) & " (" & $tooLongToBeatBoss & ")")
      Dbg("            Level Time : " & TimeStr($level) & " (" & $tooLongInLevel & ")")
      Dbg("============================================")

      $last_idle = $zone
      Pipeline(NextPipeline())
   EndIf

EndFunc

;Monitor Boss & Level statistics to determine when to ascend
Func DynamicAscend($tick)

   Static Local $boss_fails_after_advance = GlobalOrDefault("ASCEND_AFTER_BOSS_FAIL", 2)
   Static Local $boss_fails_before_advance = GlobalOrDefault("ASCEND_FAILSAFE", $boss_fails_after_advance * 3)
   Static Local $seconds_per_level = GlobalOrDefault("ASCEND_AFTER_SECONDS_PER_LEVEL", 75)

   Static Local $last_ascend = 0
   Static Local $ascend_count = 0

   Local $fails = BossFail()
   Local $zone = GetZone()
   Local $level = TimeInLevel()

   ;This can happen if you start the bot in the middle of a deep run and you've lost click stacks
   Local $levelTooLong = ($level > $seconds_per_level * $SECONDS)
   ;Check for too many boss failures, but still try and get further than last play
   Local $tooManyFails = ($fails > $boss_fails_after_advance) And ($zone > $last_ascend)
   ;If we're still not getting anywhere, even if we haven't beaten last play
   Local $wayTooManyFails = ($fails > $boss_fails_before_advance)

   If $levelTooLong Or $tooManyFails Or $wayTooManyFails Then

      Dbg("            Ascend     : " & $ascend_count)
      Dbg("            Zone       : " & $zone)
      Dbg("            Previous   : " & $last_ascend)
      Dbg("            Boss Fails : " & $fails)
      Dbg("            Level Time : " & TimeStr($level))
      Dbg("============================================")

      $last_ascend = $zone
      $ascend_count += 1

      Ascend()
   EndIf
EndFunc

Func GameDataSync($tick)
   Static Local $timer = TimerInit()
   Static Local $sync_minutes = GlobalOrDefault("DATA_SYNC_MINUTES", $DEFAULT_DATA_SYNC_MINUTES) * $MINUTES

   If BossFight() Then
      Return
   EndIf

   Local $diff = TimerDiff($timer)

   If $diff > $sync_minutes Then
      ResetGameData()
      $timer = TimerInit()
   EndIf
EndFunc

; Times how long Boss Fights take, and counts failed attempts
Func BossMonitor($tick)
   Static Local $timer = Null
   Static Local $boss_zone = Null

   Local $zone = GetZone()

   If $tick == $START_TICK Then
      BossFail(0)
      TimeToBeatBoss(0)
      $boss_zone = 0
      $timer = TimerInit()
   EndIf

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

   ;Not a fail, possible ascension, possible manual level reset
   If $zone < ($boss_zone - 1) Then
      ;Can't trust anything
      $timer = Null
      $boss_zone = Null
      Return
   EndIf

   ;No Boss set, nothing to do
   If $boss_zone == Null Then
      Return
   EndIf

   ;Skipped over next zone, maybe paused
   If $zone > ($boss_zone + 1) Then
      $timer = Null
      $boss_zone = Null
      BossFail(0)
      TimeToBeatBoss(0)
      Return
   EndIf

   ;Beat previous boss fight, set statistics and clear local statics
   If $zone > $boss_zone Then
      Local $diff = TimerDiff($timer)
      TimeToBeatBoss($diff, $boss_zone)
      $timer = Null
      $boss_zone = Null
      BossFail(0)
      TimeToBeatBoss(0)
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

   If $tick == $START_TICK Then
      TimeInLevel(0)
      $last_zone = 0
      $timer = TimerInit()
      Return
   EndIf

   ;Happens when pausing
   If $zone > ($last_zone + 1) Then
      $last_zone = $zone
      $timer = TimerInit()
      Return
   EndIf

   Local $diff = TimerDiff($timer)
   TimeInLevel($diff)

   If $zone <> $last_zone Then
      $last_zone = $zone
      $timer = TimerInit()
      Return
   EndIf
EndFunc

Func ClearStatistics()
   TimeToBeatBoss(0)
   BossFail(0)
   TimeInLevel(0)
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