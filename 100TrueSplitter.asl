state("100% True") {
	double DelSaveIncr : 0x7583B8, 0xF0, 0x1B0;	//counter which increments upon deleting any save file
	//double RoomLoads : 0x7583B8, 0xF0, 0x1C0;	//counter which increments upon initiating a mid-level load
	bool IsLoading : 0x7583B8, 0xF0, 0x216;		//bool for the loading screen
	bool IsPaused : 0x7583B8, 0xF0, 0x836;		//bool for having the pause menu up. Only relevant for run start?
	//bool InGame : 0x7583B8, 0xF0, 0x206;
	
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