state("XF ExtremeFormula") {}

startup
{
	vars.GameTime = TimeSpan.FromSeconds(0);
	vars.TotalCarnivalTime = new TimeSpan(0);
	vars.PrevRTA = new TimeSpan(0);
	vars.TotalPauseTime = 0f;
	vars.TotalTime = 0f;
	vars.SplitTime = 0f;
	vars.LapSub = 0f;
	vars.DeltaTime = 0f;
	
	vars.ChalSplit = true;
	vars.PlatSplit = true;
	vars.CarniSplits = 0;

	settings.Add("SplitNRace", true, "Split when finishing Night Races");
	settings.Add("SplitOnCarn", true, "Split when entering Red Carnival races");
	settings.Add("LapSplit", false, "Split when finishing each lap. Careful if you reset a race!");
	
	Assembly.Load(File.ReadAllBytes("Components/uhara10")).CreateInstance("Main");
	vars.Uhara.AlertLoadless();
}


init
{
	var inst = vars.Uhara.CreateTool("Unity", "DotNet", "Instance");
	var jit = vars.Uhara.CreateTool("Unity", "DotNet", "JitSave");
	vars.util = vars.Uhara.CreateTool("Unity", "Utils");

	//Method flags in lieu of usable fields (seemingly prone to crashing the game! dunno why!)
	IntPtr ResetSave = jit.AddFlag("DeleteSaveDataButton", "RestartStoryMode");
	IntPtr SceneChange = jit.AddFlag("CharacterCardsInfo", "StartSceneTransition");	//only used at the end of platforming stuff
	vars.Resolver.Watch<ulong>("ResetSave", ResetSave);
	vars.Resolver.Watch<ulong>("SceneChange", SceneChange);
	jit.ProcessQueue();

	//Pause menu stuff
	inst.Watch<bool>("IsPaused1", "CarCamera", "MainCamera", "Pause", "PauseUI", "0x10", "0x46"); //if pause menu is up
	inst.Watch<bool>("IsPaused2", "CarCamera", "MainCamera", "Pause", "OnSubMenu");
	inst.Watch<float>("PauseCounter", "CarCamera", "MainCamera", "Pause", "PauseCounter");		  //realtime timer that the pause menu for some reason keeps (active even if not paused)
	inst.Watch<bool>("ResetTourney", "CarCamera", "MainCamera", "Pause", "resetTourney");		  //bool that activates when you press "restart cup" in arcade

	//Normal race stuff
	inst.Watch<bool>("RaceStarted", "RaceManager", "CurrentRaceManager", "Started");					//if the race has started (i.e. can drive, green "START" text)
	inst.Watch<float>("RaceTime", "RaceManager", "CurrentRaceManager", "RaceTime");						//time the race has been active; continues even after player finishes
	inst.Watch<float>("RaceDone", "RaceManager", "CurrentRaceManager", "Player1", "TotalRaceTime");		//time at end of race, only set then
	//inst.Watch<bool>("RaceDQ", "RaceManager", "CurrentRaceManager", "Player1", "Disqualified");		//bool for disqualification
	inst.Watch<bool>("IsNRace", "Tourney", "CurrentTourney", "IsNightRace");

	//Lap split setting stuff
	inst.Watch<int>("Laps", "RaceManager", "CurrentRaceManager", "Player1", "Race_Lap");	//# laps as whole num + current lap progress as decimal
	var funnyinst = inst.Get("RaceManager", "CurrentRaceManager", "Player1", "LapTimes");
	vars.Resolver.WatchList<float>("LapList", funnyinst.Base, funnyinst.Offsets);			//list of lap times
	inst.Watch<int>("MaxLaps", "RaceManager", "CurrentRaceManager", "Player1", "MaxLaps");	//number of laps in the race (why is this car-specific? >w>)

	//Platforming stuff
	inst.Watch<float>("StageTime", "CharacterCamera", "Main", "CharUiRefs", "Cards", "CharInt", "ActiveTime");	//Stage timer
	inst.Watch<bool>("PlatComplete", "CharacterCamera", "Main", "CharUiRefs", "Cards", "Complete");				//Stage complete flag (only sometimes used; SceneChange used for remaining stage finishes)

	//Challenge stuff
	inst.Watch<float>("ChalTime", "ProvingGrounds", "RaceTimer");
	inst.Watch<float>("ChalCountdown", "ProvingGrounds", "CountdownTimer");	//Pre-challenge countdown
	inst.Watch<float>("ChalDone", "ProvingGrounds", "endCounter");			//Weird multi-purpose timer which only uses certain values when finishing a Challenge

	//Story mode intro drive
	inst.Watch<float>("IntroTime", "IntroSceneController", "t");
	inst.Watch<float>("IntroDone", "IntroSceneController", "t_end");

	//Red Carnival setting
	inst.Watch<int>("CarnivalCurrentRace", "RedCarnivalWorld", "CurrentRace");

	//Timed car event stuff (e.g. driving to Shoe)
	inst.Watch<float>("TimedTimer", "TimedCarEvent", "CurrentTime"); //Remaining time in the event
	inst.Watch<bool>("TimedDone", "TimedCarEvent", "End");

	inst.Watch<float>("LoadRewardTimer", "LoadingScreen", "timer");
}


update
{
	vars.Uhara.Update();
	current.ActiveScene = vars.util.GetActiveSceneName() ?? current.ActiveScene;
	current.LoadingScene = vars.util.GetLoadingSceneName() ?? current.LoadingScene;

	if (current.ChalDone == 0f) {vars.ChalSplit = true;}
	if (current.StageTime < 1f) {vars.PlatSplit = true;}
	if (current.RaceTime < 1f) {vars.LapSub = 0f;}

	//setting up RTA time thingy for the bits that need it (copied from Spark 3 splitter)
	TimeSpan? RawRTA = timer.CurrentTime.RealTime;
	TimeSpan CurrentRTA = new TimeSpan(0);
	if (RawRTA.HasValue) {
		CurrentRTA = new TimeSpan(0).Add(RawRTA.Value);
	}

	if (old.RaceTime > 1f && current.RaceTime == 0f && vars.SplitTime > 0f) 
	{
		vars.TotalTime += vars.SplitTime;
		vars.SplitTime = 0f;
	}

	current.DeltaTime = current.RaceTime - old.RaceTime;
	if (current.DeltaTime > 0f && current.DeltaTime < 1f && current.RaceDone == 0f)
	{
		if (current.Laps > old.Laps && settings["LapSplit"])
		{
			//alt calculation to ensure 'split on lap' times are perfect
			vars.SplitTime = current.LapList[current.Laps - 1];
			vars.LapSub += vars.SplitTime;
		}
		else
		{
			vars.SplitTime = current.RaceTime - vars.LapSub;
		}
	}

	else if (current.RaceDone > old.RaceDone)
	{
		vars.SplitTime = current.RaceDone - vars.LapSub;
	}

	else if (current.ChalCountdown >= 4f) {
		current.DeltaTime = current.ChalTime - old.ChalTime;
		if (current.DeltaTime > 0f && current.DeltaTime < 1f) {
			vars.SplitTime += current.DeltaTime;
		}
	}

	else if (!current.TimedDone && current.TimedTimer > 0f) {
		current.DeltaTime = old.TimedTimer - current.TimedTimer;
		if (current.DeltaTime > 0f && current.DeltaTime < 1f) {
			vars.SplitTime += current.DeltaTime;
		}
	}

	else if (current.IntroDone == 0f && current.IntroTime > 0f) {
		current.DeltaTime = current.IntroTime - old.IntroTime;
		if (current.DeltaTime > 0f && current.DeltaTime < 1f) {
			vars.SplitTime = current.IntroTime;
		}
	}

	else if (!current.PlatComplete && vars.PlatSplit) {
		current.DeltaTime = current.StageTime - old.StageTime;
		if (current.DeltaTime > 0f && current.DeltaTime < 1f) {
			vars.SplitTime = current.StageTime;
		}
	}

	if (current.IsPaused1 || current.IsPaused2) {
		current.DeltaTime = current.PauseCounter - old.PauseCounter;
		if (current.DeltaTime > 0f && current.DeltaTime < 1f) {
			vars.TotalPauseTime += current.DeltaTime;
		}
	}

	else if (current.ActiveScene == "STORY EVENT - Red Carnival World" && current.CarnivalCurrentRace == -1 && vars.CarniSplits < 3) {
		vars.TotalCarnivalTime = vars.TotalCarnivalTime.Add(CurrentRTA - vars.PrevRTA);
	}

	vars.PrevRTA = new TimeSpan(CurrentRTA.Ticks);
}



isLoading
{
	return true;
}


start
{
	if (current.ActiveScene == "STORY EVENT - Intro Drive" && old.ActiveScene != current.ActiveScene) {return true;} //Story mode start
	else if (current.ChalTime > 0 && old.ChalTime == 0) {return true;}			//Proving Grounds/Challenge start
	else if (current.StageTime > 0f && current.StageTime < 0.5f) {return true;}	//Platforming ILs
	else if (current.RaceStarted && !old.RaceStarted) {return true;}			//Race or Tourney start
}


onStart
{
	vars.TotalTime = 0f;
	vars.TotalPauseTime = 0f;
	vars.SplitTime = 0f;
	vars.LapSub = 0f;
	vars.PrevRTA = new TimeSpan(0);
	vars.TotalCarnivalTime = new TimeSpan(0);

	vars.ChalSplit = true;
	vars.PlatSplit = true;
	vars.CarniSplits = 0;
}


split
{
	if (current.RaceDone > old.RaceDone && (!current.IsNRace || settings["SplitNRace"])) {return true;}
	else if (current.ChalDone > 0.03f && current.ChalDone < 5f && vars.ChalSplit) {
		vars.ChalSplit = false;
		return true;
	}
	else if (settings["LapSplit"] && (!current.IsNRace || settings["SplitNRace"]) && current.Laps > old.Laps && current.Laps < current.MaxLaps) {return true;}
	else if (current.PlatComplete && !old.PlatComplete) {return true;}
	else if (current.SceneChange > old.SceneChange && current.ActiveScene != "NOMAD - ProvingGrounds Outside") {
		vars.PlatSplit = false;
		return true;
	}
	else if (current.CarnivalCurrentRace > old.CarnivalCurrentRace)
	{
		vars.CarniSplits++;
		return settings["SplitOnCarn"];
	}
	else if (current.TimedDone != old.TimedDone && current.TimedDone) {return true;}
	else if (current.IntroDone > 0 && old.IntroDone == 0) {return true;}
}

onSplit
{
	//print(vars.TotalTime.ToString() + ", " + vars.SplitTime.ToString());
	vars.TotalTime += vars.SplitTime;
	vars.SplitTime = 0f;
	//print(vars.TotalTime.ToString() + ", " + vars.SplitTime.ToString());
}


reset
{
	if (current.ResetSave > old.ResetSave) {return true;}
	else if (current.ResetTourney && !old.ResetTourney) {return true;}
}


onReset
{

}


gameTime
{
	return TimeSpan.FromSeconds(vars.TotalTime + vars.SplitTime + vars.TotalPauseTime) + vars.TotalCarnivalTime;
}

exit
{
	
}

shutdown
{
	
}