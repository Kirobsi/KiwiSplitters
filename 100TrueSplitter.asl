state("100% True") {
	double DelSaveIncr : 0x7583B8, 0xF0, 0x1B0;	//counter which increments upon deleting any save file
	//double RoomLoads : 0x7583B8, 0xF0, 0x1C0;	//counter which increments upon initiating a mid-level load
	bool IsLoading : 0x7583B8, 0xF0, 0x216;		//bool for the loading screen
	bool IsPaused : 0x7583B8, 0xF0, 0x836;		//bool for having the pause menu up. Only relevant for run start?
	//bool InGame : 0x7583B8, 0xF0, 0x206;
	
	bool HlevelIntroAnim : 0x741358; //No idea what this is but it's true while Hlev is flying out of the limo at the start of a run, which allows me to do run start >w>
	
	// Input handler stuff, since 'first input' decides when the run starts
	bool MoveLeft : 0x763388, 0x280, 0x718, 0x470, 0x10D6;
	bool MoveRight : 0x763388, 0x280, 0x718, 0x80, 0xC96;
	bool JumpButton : 0x763388, 0x280, 0x718, 0x80, 0x476;
	bool DashButton : 0x763388, 0x280, 0x718, 0x470, 0x8B6;
	bool CameraButton : 0x763388, 0x280, 0x718, 0x80, 0x276;

	uint RoomID : 0xA05048; //Internal GM room ID (I think? certainly seems to function that way hehe)
	/* ROOM ID REF (to make it easier to find in future patches) (although it didn't change from 1.1.12 -> 1.1.16 so maybe I don't need to find it again)
	Menu		-	34
	Results		-	4
	1-1 room 1	-	5
	*/
}


startup
{
    vars.CanStartTimer = false;

	settings.Add("ResultsPause", true, "Pause loadless timer during end-of-level results screen");
}


isLoading
{
	if (current.IsLoading) {return true;}	// pause timer during loads
	else if (current.RoomID == 4 && settings["ResultsPause"]) {return true;} // pause timer during level end screen
	else {return false;}
}


start
{
	if (current.RoomID == 5) {
		if (current.HlevelIntroAnim) {vars.CanStartTimer = true;}
		
		if (vars.CanStartTimer && !current.HlevelIntroAnim && !current.IsPaused)
		{
			if ((current.CameraButton && current.CameraButton != old.CameraButton) || (current.MoveRight != current.MoveLeft) || (current.JumpButton && current.JumpButton != old.JumpButton) || (current.DashButton && current.DashButton != old.DashButton))
			{
				vars.CanStartTimer = false;
				return true;
			}
		}
	}
}


split
{
	if (current.RoomID == 4 && current.RoomID != old.RoomID && old.RoomID != 150) {return true;}
	else if (current.RoomID == 154 && old.RoomID != current.RoomID) {return true;}
}


reset
{
	if (current.DelSaveIncr > old.DelSaveIncr) {return true;}
}


onReset
{
	vars.CanStartTimer = false;
}