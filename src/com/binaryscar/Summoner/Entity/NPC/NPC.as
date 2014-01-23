package com.binaryscar.Summoner.Entity.NPC
{
	import com.binaryscar.Summoner.Entity.Entity;
	import com.binaryscar.Summoner.Entity.EntityStatus.HealthBar;
	import com.binaryscar.Summoner.Entity.EntityStatus.StatusEffectsController;
	import com.binaryscar.Summoner.FiniteStateMachine.State;
	import com.binaryscar.Summoner.FiniteStateMachine.StateMachine;
	import com.binaryscar.Summoner.PlayState;
	import com.binaryscar.Summoner.Player.Player;
	
	import org.flixel.FlxEmitter;
	import org.flixel.FlxG;
	import org.flixel.FlxGroup;
	import org.flixel.FlxObject;
	import org.flixel.FlxPoint;
	import org.flixel.FlxSprite;
	
	/**
	 * 
	 * All Summoned and Enemy entities extend this NPC Class.
	 * 
	 */
	
	public class NPC extends Entity	
	{
		[Embed(source = "../../../../../../art/poison-gibs1.png")]public var gibsImg_poison:Class;
		
		protected var FSM:StateMachine;
		protected var defaultInitState:String;
		protected var _state:State;

		protected var _player:Player;
		protected var _playState:PlayState;
		
		protected var AVOID_DELAY:Number = 0.15;	// _avoidTimer resets to this number
		private var _avoidTimer:Number;			    // When this reaches 0: Stops "avoiding" state.
		
		public var _target:NPC;					// Can only have one active fighting-target.
		public var _pursueTarget:NPC;			// Can only be pursuing one target.
		
		public function NPC(entityType:String, myGrp:FlxGroup, oppGrp:FlxGroup, player:Player, playState:PlayState, X:Number=0, Y:Number=0, face:uint = RIGHT, initState:String = null)
		{
			super(entityType, myGrp, oppGrp, playState, X, Y);
			
			facing = face;
			
			allyGrp = myGrp;
			oppGrp = oppGrp;;
			_player = player;
			_playState = playState;
			
			_cooldownTimer = 0; 		// These reset to *null* when not in use.
			_avoidTimer = 0;			// " "
			
			drag.x = (MSPD_X) * 6;
			drag.y = (MSPD_Y) * 4;
			maxVelocity.x = MSPD_X;
			maxVelocity.y = MSPD_Y;
			
			height = 32;
			offset.y = 0;
			width = 16;
			offset.x = 8;
			
			health = HP;
			elasticity = 1.5;
			
			//gibs_smoke = new FlxEmitter(x, y, 10);
			//gibs_smoke.setXSpeed(-30,30);
			//gibs_smoke.setYSpeed(-30,30);
			//gibs_smoke.setRotation(0, 360);
			//gibs_smoke.gravity = 1.5;
			//gibs_smoke.makeParticles(gibsImg_smoke, 10, 8, true, 0);
			//gibs_smoke.bounce = 0.5;
			//_playState.add(gibs_smoke);
			
			// Make dynamically when statuses added?
			//_poisonTimer = 0;
			//gibs_poison = new FlxEmitter(x, y, 4);
			//gibs_poison.setXSpeed(-15,15);
			//gibs_poison.setYSpeed( -15, 15);
			//gibs_poison.lifespan = 0.4;
			//gibs_poison.setRotation(0, 180);
			//gibs_poison.gravity = -10;
			//gibs_poison.makeParticles(gibsImg_poison, 4, 8, true, 0);
			//for each (var gib:FlxSprite in gibs_poison.members) {
				//gib.alpha = 0.8;
			//}
			//_playState.add(gibs_poison);
			
//			hBar = new FlxSprite(x, y);
//			hBar.makeGraphic(width, 2, 0xFFFF0000);
//			stamp(hBar, x, y);
			
			//hBar = new HealthBar(this, -4, -8);
			
			FSM = new StateMachine();
			FSM.id = "[NPC]";
			initializeStates(FSM);
			if (initState != null && FSM.getStateByName(initState)) {
				defaultInitState = initState;
			} else {
				defaultInitState = "idle";
			}
			// This is necessary so the Subclass can
			// create and run animations properly.
			FSM.initialState = "idle";
			
			//TODO CLEANUP
			//sem = new Object;
			//_initializeStatusEffectMachine(sem, _semExecute);
			
			//sec = new StatusEffectsController(this, playState);
			//sec.addStatusEffect("poison");
			
			//statusEffectsCount = 0;
			
		}
		
		override public function update():void {
			_state = FSM.getStateByName(FSM.state); // Actual obj:State, not name:String.
			
			if (!alive) {
				exists = false;
				x = y = -20;
				return;
			}
			
			super.update();

			FlxG.collide(this, allyGrp, avoidAlly);
			FlxG.overlap(this, allyGrp, bounceAgaintAlly);
			
			//FlxG.collide(this, _player, hurtPlayer);
			
			FSM.update(); // Finite State Machine Update
			//sec.update();
			
			//if (sem.statusEffects.length > 0) {
			//	sem.update(); // Status Effect Machine Update
			//}
			
			if (getScreenXY().x < -64 || getScreenXY().x > (FlxG.width + 64)) { // It's off-screen.
				trace('Kill off-screen :: ' + this.toString());
				kill();
			}
		}
		
		
		override public function kill():void {
			FSM.changeState("dead");
			if (_target != null) {
				_target = null; // You dead, you not targetin' anybody.
			}
			if (targetedBy.length > 0) {
				targetedBy = [];
			}
			super.kill();
		}
		
		public function get target():NPC {
			if (_target != null) {
				return _target;
			} else {
				return null;
			}
		}
		public function set target(oppNPC:NPC):void {
			if (oppNPC != null) {
				_target = oppNPC;
				FSM.changeState("fighting");
			} else {
				_target = null;
			}
		}
		
		public function get onCooldown():Boolean {
			if (_cooldownTimer == 0 || _cooldownTimer <= 0) {
				return false;
			}
			if (_cooldownTimer > 0) { // Timer needs to go longer than attackCooldown.
				_cooldownTimer -= FlxG.elapsed;
				return true; // onCooldown, no attacking.
			} else {
				_cooldownTimer = ATTACK_DELAY; // Attack and reset timer.
				return false; // !onCooldown, attack!
			}
		}
		
		public function set onCooldown(bool:Boolean):void {
			if (bool) {
				_cooldownTimer = ATTACK_DELAY;
			} else {
				_cooldownTimer = 0;
			}
		}
		
		public function get hitPoints():int {
			return HP;
		}
		
		public function set hitPoints(newHP:int):void {
			HP = newHP;
		}
		
		
		public function stopMoving():void {
			velocity.x = velocity.y = acceleration.x = acceleration.y = 0;
		}
		
		public function lose():void {
			FSM.changeState("idle");
		}
		
		public function startFight(me:NPC, oppNPC:NPC):void {
//			if (_target == null) {
				
//				trace(this.toString() + " START FIGHT WITH " + oppNPC.toString());
//				
//				target = oppNPC;
//				oppNPC.addAttacker(me);
//				FSM.changeState("fighting");
//			}
		}
		
		public function addAttacker(attacker:NPC):void {
			targetedBy.push(attacker);
		}
		
		public function removeAttacker(attacker:NPC):void {
			var index:int = targetedBy.indexOf(NPC);
			if (index) {
				targetedBy.splice(index,1);
			}
		}
		
		public function attack():void { //en:Enemy):void {
			if (_target == null) {
				return;
			}
			
			_target.hurt(STR);
			onCooldown = true;
			
			if (_target.health <= 0) {
				_target = null;
			}
		}
		
		public function hurtPlayer(me:NPC, player:Player):void {
			player.hurt(STR); //TODO This is a problem.
		}
		
		private function initializeStates(FSM:StateMachine):void {
			
			FSM.addState("idle", 
				{
					enter: function():void {
						stopMoving();
						play("idle");
					}
				});
			
			
			FSM.addState("moving", 
				{
					enter: function():void {
						play("walking");
						_cooldownTimer = 0;
						target = null;
					}
				});
			FSM.addState("walking", 
				{
					parent: "moving",
					enter: function():void {
						if (facing === RIGHT) {
							acceleration.x = drag.x;
						} else {
							acceleration.x = -drag.x;
						}
					},
					execute: function():void {
						searchForPursueTargets(oppGrp); // Does passing in the group ensure it's updated every time?
					}
				});
			FSM.addState("pursuing",
				{
					parent: "moving",
					enter: function():void {
						//if (_pursueTarget == null) {
							//FSM.changeState("walking");
						//}
					},
					execute: function():void {
						if (_pursueTarget == null) {
							//FSM.changeState("walking");
							return;
						}
						
						updatePursueTarget();
					},
					exit: function():void {
						angle = 0;
						acceleration.y = 0;
						_pursueTarget = null;
					}
				});
			
			// TODO add "Evading" for trying to get away from oppNPC
			FSM.addState("avoiding",
				{
					parent: "moving",
					from: ["moving", "walking", "sprinting", "idle"], // Not fighting.
					enter: function():void {
						trace(FSM.id + ' Enter avoid!');
						_avoidTimer = AVOID_DELAY;
					},
					execute: function():void {
					}
				});
			FSM.addState("avoidingDown", 
				{
					parent: "avoiding",
					enter: function():void {
						angle = 20;
						acceleration.y = MSPD_Y*10;
					},
					execute: function():void {
						angle = (angle > 0) ? angle - (FlxG.elapsed*5) : 0;
						acceleration.y = (acceleration.y > 0) ? acceleration.y - (MSPD_Y*(FlxG.elapsed*5)) : 0;
						
						_avoidTimer -= FlxG.elapsed;
						if (_avoidTimer <= 0) {
							_avoidTimer = 0;
							FSM.changeState("walking");
						}
					},
					exit: function():void {
						angle = acceleration.y = 0;
					}
				});
			FSM.addState("avoidingUp",
				{
					parent: "avoiding",
					enter: function():void {
						angle = -20;
						acceleration.y = -MSPD_Y*10;
					},
					execute: function():void {
						angle = (angle < 0) ? angle + FlxG.elapsed : 0;
						acceleration.y = (acceleration.y < 0) ? acceleration.y + (MSPD_Y*FlxG.elapsed) : 0;
						
						_avoidTimer -= FlxG.elapsed;
						if (_avoidTimer <= 0) {
							_avoidTimer = 0;
							FSM.changeState("walking");
						}
					},
					exit: function():void {
						angle = acceleration.y = 0;
					}
				});
			
			
			FSM.addState("fighting", 
				{
					enter: function():void {
						stopMoving();
						immovable = true;
						_cooldownTimer = 0;
					},
					execute: function():void {
						//trace('fighting execute');
						if (!onCooldown) {
							FSM.changeState("attacking");
						} else {
							FSM.changeState("cooldown");
						}
					},
					exit: function():void {
						_cooldownTimer = 0;
						immovable = false;
					}
				});
			FSM.addState("cooldown", 
				{
					from: ["fighting", "attacking"],
					parent: "fighting",
					enter: function():void  {
						if (finished) {
							play("fightingIdle");
						}
					},
					execute: function():void {
						if (_target.health <= 0 || !_target.alive) {
							_target = null;
						}
						if (_target == null) {
							FSM.changeState("walking");
							return;
						} else if (!onCooldown) {
							FSM.changeState("attacking");
							return;
						}
						if (finished) {
							play("fightingIdle");
						}
					}
				});
			FSM.addState("attacking", 
				{
					from: ["fighting", "cooldown"],
					parent: "fighting",
					enter: function():void {
						if (_target == null) {
							FSM.changeState("walking");
							return;
						}
						play("attacking");
						attack();
						if(_target == null) {
							FSM.changeState("walking");
							return;
						}
						FSM.changeState("cooldown");
					}
				});
			
			
			FSM.addState("dead", 
				{
					enter: function():void  {
						//gibs_smoke.at(this);
						//gibs_smoke.start(true, 0.25, 0.1, 20);
						exists = false;
						solid = false;
						
						if (flickering) {
							flicker(0);
						}
						
						stopMoving();
						x = -20; // Move off screen;
						y = -20; 
					},
					execute: function():void {
						if (alive) {
							FSM.changeState(defaultInitState);
						}
					},
					exit: function():void {
						exists = true;
						solid = true;
						
					}
				});
		}
		
		private function searchForPursueTargets(_oppGrp:FlxGroup):void {
			var pursueOptions:Array = [];
			var distanceLimit:int = 4500;
			
			if (_pursueTarget == null && _oppGrp != null && _oppGrp.members.length > 0) {
				for each (var curr:NPC in _oppGrp.members) {
					if ((facing == RIGHT && curr.x < x) || (facing == LEFT && curr.x > x)) { // Skip processing if oppNPC is behind me. 
						return;
					}
					// Enemy center point.
					var centerPoint:FlxPoint = new FlxPoint( (Math.round(curr.x + (curr.width/2))), (Math.round(curr.y + (curr.height/2))) );
					
					var xDist:Number = centerPoint.x - x;
					
					var yDist:Number = centerPoint.y - y;
					var sqDist:Number = yDist * yDist + xDist * xDist;
					if ( sqDist < distanceLimit ) {
						//pursueOptions.push({oppNPC: curr as NPC, dist: sqDist}); // Add an entity if it's within range.
						//distanceLimit = sqDist; // Set a new limit on search range
						_pursueTarget = curr;
						FSM.changeState("pursuing");
						break;
					}
				}
				
				// TODO Figure out why the performance is inconsistent.
//				if (pursueOptions.length > 0) {
//					trace(pursueOptions.toString());
//					if (pursueOptions.length == 1) {
//						_pursueTarget = pursueOptions[0].oppNPC;
//						FSM.changeState("pursuing");
//					} else if (pursueOptions.length > 1) {
//						pursueOptions.sort(function(A, B) {
//							if (A.dist < B.dist) {
//								return -1;
//							} else if (A.dist == B.dist) {
//								return 0;
//							} else {
//								return 1;
//							}
//						});
//						// Choose closest target.
//						_pursueTarget = pursueOptions[0].oppNPC;
//						FSM.changeState("pursuing");
//					}
//				}
			} else {
				_pursueTarget = null;
			}
		}
		
		private function _initializeStatusEffectMachine(sem:Object, executeFunc:Function = null):void {
			
			sem.statusEffects = [];	//
			//sem.statusEmitters = []; // TODO ? Figure out how to link these three
									// Add them all together inside .statuseffects?
									// [{ effect: "poison", emitter: new FlxEmitter, timer: new Number}]
			//sem.statusTimers = [];	//
			sem.update = executeFunc;
			// TODO add sem.emitters, FlxEmitter[]
		}
		
		private function updatePursueTarget():void {
			if (_pursueTarget == null || !_pursueTarget.alive) {
				_pursueTarget = null; // In case it just died.
				if (FSM.state != "walking") {
					FSM.changeState("walking");
				}
				return;
			} else if ( (facing == RIGHT && _pursueTarget.x < x) 
				|| (facing == LEFT && _pursueTarget.x > x)) {
				// Lose pursuit on targets behind me.
				_pursueTarget = null;
				if (FSM.state != "walking") {
					FSM.changeState("walking");
				}
				return;
			} else { // We still have a target, move toward it.
				var yDiff:int = (_pursueTarget.y + (_pursueTarget.height/2)) - (this.y + (this.height/2));
				if ( (acceleration.y > 0 && yDiff <= 0) // Moving downward && pursueTarget is above 
					|| (acceleration.y < 0 && yDiff >= 0) ) { // Moving upward && pursueTarget is below
					//yDiff += yDiff;
					acceleration.y = 0;
				}
				acceleration.y += yDiff;
			}
		}
		
		
		private function avoidAlly(thisNPC:NPC, otherNPC:NPC):void {
			
			var compareY:Boolean = thisNPC.y <= otherNPC.y;
			var compareX:Boolean = thisNPC.x == otherNPC.x;
			
			if (thisNPC.FSM.state != "avoidingDown" && thisNPC.FSM.state != "avoidingUp" && !thisNPC.immovable) {
				//trace("this is what happens when summons collide :: THIS :: " + thisSumm.FSM.state);
				if (compareY) {
					thisNPC.FSM.changeState("avoidingUp");
				} else {
					thisNPC.FSM.changeState("avoidingDown");
				}
			} else if (thisNPC.FSM.state == "avoidingDown" || thisNPC.FSM.state == "avoidingUp") {
				acceleration.y += Math.random() * 5 + 1;
				thisNPC._avoidTimer += FlxG.elapsed*2; // Reset timer so the summoned keeps moving in same direction.
			}
			
			if (compareX && (FSM.state != "avoidingDown" && FSM.state != "avoidingUp")) {
				thisNPC.acceleration.y += Math.random() * 5 + 1;
			}
			
			//			// TODO - May be problematic if we want *FSM* to be private?
			//			if (otherNPC.FSM.state != "avoidingDown" && otherNPC.FSM.state != "avoidingUp" && !otherNPC.immovable) {
			//				//trace("this is what happens when summons collide :: OTHER :: " + otherSumm.FSM.state);
			//				if (compareY) {
			//					otherNPC.FSM.changeState("avoidingUp");
			//				} else {
			//					otherNPC.FSM.changeState("avoidingDown");
			//				}
			//			} else if (otherNPC.FSM.state == "avoidingDown" || otherNPC.FSM.state == "avoidingUp") {
			//				otherNPC._avoidTimer += FlxG.elapsed*2;
			//			}
		}
		private function bounceAgaintAlly(thisNPC:NPC, otherNPC:NPC):void {
			
			var compareX:Boolean = thisNPC.x <= otherNPC.x;
			
			if (compareX) {
				velocity.x -= Math.random()*10;
			}
		}
		
		
	}
}
