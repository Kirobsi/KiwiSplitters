state("100% True") {
	double DelSaveIncr : 0x7583B8, 0xF0, 0x1B0;				 //counter which increments upon deleting any save file
	bool IsLoading : 0x7583B8, 0xF0, 0x216;					 //bool for the loading screen
	bool IsPaused : 0x7583B8, 0xF0, 0x836;					 //bool for having the pause menu up. Only relevant for run start?
	double LevelTime : 0x7583B8, 0xF0, 0x1F0; //IGT frame count for current level
	double Trueness : 0x748720, 0x4C8, 0xF10, 0x968, 0x370;	 //current 'rank' in a level, e.g. 52% True
	
	bool HlevelIntroAnim : 0x741358; //No idea what this is but it's true while Hlev is flying out of the limo at the start of a run, which allows me to do run start >w>
	
	// Input handler stuff, since 'first input' decides when the run starts
	bool MoveLeft : 0x748720, 0x318, 0xFC8, 0xA70, 0x350, 0x3E6;
	bool MoveRight : 0x778728, 0xF08, 0x1B8, 0x80, 0xDD6;
	bool JumpButton : 0x778728, 0xF08, 0x1B8, 0x80, 0x486;
	bool DashButton : 0x778728, 0xF08, 0x1B8, 0x80, 0x9C6;
	bool CameraButton : 0x778728, 0xF08, 0x1B8, 0x80, 0x66;

	uint RoomID : 0xA05048; //Internal GM room ID (I think? certainly seems to function that way hehe)
	/* ROOM ID REF (to make it easier to find in future patches) (although it didn't change from 1.1.12 -> 1.1.16 so maybe I don't need to find it again)
	Menu		-	34
	Results		-	4
	1-1 room 1	-	5
	*/
}


startup
{
    settings.Add("HundoMode", false, "Prevent split unless level was 100% True");
	settings.Add("ILMode", false, "IL Mode (super disallowed for full-game lol)");
	
	vars.CanStartTimer = false;
}


isLoading
{
	if (settings["ILMode"]) {return true;}		// prevent timer from running for IL mode so it just uses IGT instead
	else if (current.IsLoading) {return true;}	// pause timer during loads
	else {return false;}
}


gameTime
{
	if (settings["ILMode"]) {return TimeSpan.FromSeconds(current.LevelTime / 60);}
}


start
{
	if (current.RoomID == 5) { //If starting 1-1,
		if (current.HlevelIntroAnim) {vars.CanStartTimer = true;} //allow starting if the intro 'crash' animation happens
		
		if (vars.CanStartTimer && !current.HlevelIntroAnim && !current.IsPaused) //and actually do it when not paused, the animation's over, and Hlev presses any relevant button
		{
			if ((current.CameraButton && current.CameraButton != old.CameraButton) || (current.MoveRight != current.MoveLeft) || (current.JumpButton && current.JumpButton != old.JumpButton) || (current.DashButton && current.DashButton != old.DashButton))
			{
				vars.CanStartTimer = false;
				return true;
			}
		}
	}

	else if (old.LevelTime == 0 && current.LevelTime > 0 && settings["ILMode"]) {return true;}
}


split
{
	if (current.RoomID == 4 && current.RoomID != old.RoomID && old.RoomID != 150 && old.RoomID != 152)		//Finishing levels
	{
		if (settings["HundoMode"] && current.Trueness < 100) {return false;}
		else {return true;}
	}	
	else if (current.RoomID > 152 && current.RoomID < 155 && old.RoomID != current.RoomID) {return true;}	//On entering credits/Peka cutscene
}


reset
{
	if (current.DelSaveIncr > old.DelSaveIncr) {return true;}	//Reset when a file is deleted
}


onReset
{
	vars.CanStartTimer = false;
}