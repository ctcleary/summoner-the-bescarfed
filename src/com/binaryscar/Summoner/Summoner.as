package com.binaryscar.Summoner
{
	import org.flixel.*;

	/**
	 * ...
	 * @author Connor Cleary
	 */
	//[Frame(factoryClass = "com.binaryscar.Summoner.Preloader")]
	//[SWF(width = "800", height = "480", backgroundColor = "#000000")] //Set the size and color of the Flash file
	[SWF(width = "800", height = "480", backgroundColor = "#000000")] //Set the size and color of the Flash file
	
	public class Summoner extends FlxGame
	{

		public function Summoner():void 
		{
			super(400, 240, PlayState, 2);
			FlxG.bgColor = 0xFF333333;
		}

	}

}