Global Const $DEBUG = False

HotKeySet("^{PAUSE}", "Toggle_Pause")     ;Ctrl+Pause
HotKeySet("+!{END}", "Shut_Down")         ;Alt+Shift+End

Global Const $CLICK_DELAY = 3
Global Const $MOUSE_SPEED = 3

Global Const $DEFAULT_LEVELING_HEROS[] = [$BRITTANY, $IVAN, $TREEBEAST, $SEER, $SAMURAI]


Global Const $CLICKSTARTER_PIPELINE[] = [AlwaysProgress, StartBuying, AlwaysWithTheClicking]
Global Const $FAB_FOUR_PIPELINE[] = [FabulousFourLeveling]
Global Const $LADDER_PIPELINE[] = [LadderLeveling]
Global Const $IDLE_PIPELINE[] = [LateGameLeveling, EnhancedDarkRitual, TransitionPipelineAtIdleCutoff]
Global Const $ACTIVE_PIPELINE[] = [AlwaysWithTheClicking, LateGameLeveling, EnhancedDarkRitual, AscendAtInflection]


Global Const $PIPELINE_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $ACTIVE_PIPELINE]

Global Const $INFLECTION_LEVEL = 760

Global Const $IDLE_CUTOFF_LEVEL = 575

Func AscendAtInflection($tick)
	Static Local $ascensions = 0

	If GetZone() >= $INFLECTION_LEVEL Then
		$ascensions += 1
		Dbg("Ascension " & $ascensions)
		Dbg(HeroLevel())
		Ascend()
	EndIf
EndFunc

Func StartBuying($tick)
	If CanLevelBy10($TREEBEAST) Then
		Local $zone = GetZone()
		Dbg("Start buying @ zone " & $zone)
		LevelUp($TREEBEAST, 10)
		Pipeline(NextPipeline())
	EndIf
EndFunc

Func TransitionPipelineAtIdleCutoff($tick)
	If GetZone() >= $IDLE_CUTOFF_LEVEL Then
		Pipeline(NextPipeline())
	EndIf
EndFunc