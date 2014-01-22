package com.binaryscar.Summoner.Entity 
{
	import com.binaryscar.Summoner.FiniteStateMachine.StateMachine;
	import org.flixel.FlxEmitter;
	import org.flixel.FlxGroup;
	import org.flixel.FlxSprite;
	
	/**
	 * Begin Entity refactoring to use this base class for both PC and NPC entities.
	 * 
	 * Concept: Entity a FlxSprite with an attached EntityGroup:FlxGroup which contains
	 * all the extra stuff like: HealthBar, StatusController, and in the case of the PC: arms and stuff.
	 * 
	 * This way we have the FlxSprite/FlxObject interface like velocity and hurt() and such
	 * but we can also easily affix the FlxGroup's sprites onto the main Entity.
	 * 
	 * @author Connor Cleary
	 */
	public class Entity extends FlxSprite
	{
		[Embed(source = "../../../../../art/shitty-redblock-enemy1.png")]public var ph_redblock:Class;
		[Embed(source = "../../../../../art/smokey-gibs1.png")]public var gibsImg_smoke:Class;
		
		public static const TYPE_DEFAULT:String = "default";
		public static const TYPE_ENEMY:String = "enemy";
		public static const TYPE_NEUTRAL:String = "neutral";
		public static const TYPE_PLAYER:String = "player";
		public static const TYPE_SUMMONED:String = "summoned";
		
		public var type:String = TYPE_DEFAULT;
		
		protected var entityExtrasGrp:EntityExtrasGroup; // This is where extras will be stores, i.e. HealthBar,
													 // Status Effects, extra sprite pieces
		
		// TODO Off-screen-kill bounds.
		
		// Raw stats
		protected var _HP:int = 3; 				// Hit Points.
		protected var _MP:int = 10; 			// Magic Points. So far: Unused.
		protected var _STR:int = 1;			 	// Attack Strength
		protected var _MSPD:int = 50;			// Base Speed, (this*1.2 for X) (this*0.8 for Y)
		protected var _ASPD:int = 5;			// Figure out equation for this.
		
		// Current status (affected by Status Effects, hurt, etc)
		public var curHP:int = HP;
		public var curMP:int = MP;
		public var curSTR:int = STR;
		public var curSPD:int = MSPD;
		
		// Calculated stats
		protected var ATTACK_DELAY:Number = 10 - ASPD; // Should be between 1-10, make a more interesting equation
		
		protected var allyGrp:FlxGroup;
		protected var oppGrp:FlxGroup;			// "_opp" for "Opposition"
		// protected var _neutralGrp:FlxGroup;  // is this needed for walls and obstacles and hazards?
	
		protected var gibs_smoke:FlxEmitter;
		
		// protected var ATTACK_DELAY:Number = 2;		// _cooldownTimer resets to this number.
		
		protected var _cooldownTimer:Number;			// When this reaches 0: Can attack.

		public var targetedBy:Array = [];		// Can be targeted by multiple opposition entities.
		
		public function Entity(ofType:String, X:Number = 0, Y:Number = 0)
		{
			super(X, Y);
			type = ofType;
			loadGraphic(ph_redblock, false, false, 32, 32, false);
			entityExtrasGrp = new EntityExtrasGroup(this);
		}
		
		override public function update():void {
			
		}
		
		// HP Setters / Getters
		public function set HP(value:int) {
			if (curHP == _HP) { // Reset current value if currently at max;
				curHP = value;
			} else { // Otherwise, add/subtract the difference;
				// If (HP == 3 && curHP == 2 && 
				// and setHP sets it to 5,
				// new curHP = 2 + (5 - 3);
				curHP = curHP + (value - _HP);
			}
			_HP = value;
		}
		public function get HP():int {
			return _HP;
		}
		
		// MP Setters / Getters
		public function set MP(value:int) {
			if (curMP == _MP) { // Reset current value if currently at max;
				curMP = value;
			} else { // Otherwise, add/subtract the difference
				curMP = curMP + (value - _MP);
			}
			_MP = value;
		}
		public function get MP():int {
			return _MP;
		}
		
		// STR Setters / Getters
		public function set STR(value:int) {
			// Todo, add more in future.
			STR = value;
		}
		public function get STR():int {
			return _STR;
		}
		
		// ASPD Setters / Getters
		public function set ASPD(value:int) {
			_ASPD = value;
			ATTACK_DELAY = 10 - ASPD; // TODO make more interesteing.
		}
		public function get ASPD():int {
			return _ASPD;
		}
		
		// MSPD Setters / Getters
		public function set MSPD(value:int):void {
			_MSPD = value;
			drag.x = (MSPD_X) * 6;
			drag.y = (MSPD_Y) * 4;
			maxVelocity.x = MSPD_X;
			maxVelocity.y = MSPD_Y;
		}
		public function get MSPD():int {
			return _MSPD;
		}
		public function get MSPD_X():Number {
			return _MSPD * 1.2;
		}
		public function get MSPD_Y():Number {
			return _MSPD * 0.8;
		}
		
	}

}