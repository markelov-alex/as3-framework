package napalm.framework.managers
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.Dictionary;
	
	import napalm.framework.log.Channel;
	import napalm.framework.resource.AssetManagerExt;
	import napalm.framework.utils.ArrayUtil;
	import napalm.framework.utils.ObjectUtil;
	
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.utils.AssetManager;

//todo make AudioEvent to make it work for IDE
	[Event(name="audioVolumeChange", type="starling.events.Event")]
	[Event(name="musicVolumeChange", type="starling.events.Event")]
	[Event(name="soundVolumeChange", type="starling.events.Event")]
	[Event(name="audioOnChange", type="starling.events.Event")]
	[Event(name="musicOnChange", type="starling.events.Event")]
	[Event(name="soundOnChange", type="starling.events.Event")]
	[Event(name="musicPlay", type="starling.events.Event")]
	[Event(name="soundPlay", type="starling.events.Event")]
	[Event(name="musicStop", type="starling.events.Event")]
	[Event(name="soundStop", type="starling.events.Event")]
	[Event(name="stopAll", type="starling.events.Event")]

	/**
	 * AudioManager.
	 * 
	 * Here we have one music channel (MUSIC_CHANNEL), all other channels - are sounds.
	 * 
	 * Note: On removeAssetManager() all audio from that assetManager will be stopped. 
	 * (Hence you should not use multiple sound files with same names to avoid stopping 
	 * audio which have been just started by next screen, for example).	
	 * @author alex.panoptik@gmail.com
	 */
	public class AudioManager extends BaseManager
	{
		
		// Class constants

		public static const AUDIO_VOLUME_CHANGE:String = "audioVolumeChange";
		public static const MUSIC_VOLUME_CHANGE:String = "musicVolumeChange";
		public static const SOUND_VOLUME_CHANGE:String = "soundVolumeChange";
		public static const AUDIO_ON_CHANGE:String = "audioOnChange";
		public static const MUSIC_ON_CHANGE:String = "musicOnChange";
		public static const SOUND_ON_CHANGE:String = "soundOnChange";
		public static const MUSIC_PLAY:String = "musicPlay";
		public static const SOUND_PLAY:String = "soundPlay";
		public static const MUSIC_STOP:String = "musicStop";
		public static const SOUND_STOP:String = "soundStop";
		public static const STOP_ALL:String = "stopAll";
		
		private static const MUSIC_CHANNEL:String = "musicChannel";
		private static const DEFAULT_SOUND_CHANNEL:String = "defaultSoundChannel";
		
		// Class variables
		
		// Class methods
		
		// Variables
		
		// (Set in your overridden Main.initializeManagers)
		public var defaultFadeInTimeSec:Number = 0.5;
		public var defaultFadeOutTimeSec:Number = 0.5;
		public var isDisableOnStageDeactivate:Boolean = true;
		
		private var resourceManager:ResourceManager;
		private var assetManagerArray:Array = [];
		
		// Currently playing audio items
		private var audioItemArray:Array = [];
		// Audio items queue to be played next
		private var audioItemQueueByChannelName:Dictionary = new Dictionary();
		// To restore music no musicOn=true
		private var currentMusicAudioItem:AudioItem;
		// To stop all related sounds on removeAssetManager()
		private var audioNameArrayByAssetManagerLookup:Dictionary = new Dictionary();
		// To stop all fading tweens on removeAssetManager()
		private var fadeTweenByAudioItemLookup:Dictionary = new Dictionary();
		
		private var isAudioOnPrev:Boolean = true;
		
		// Properties

		private var _isEnabled:Boolean = true;
		public function get isEnabled():Boolean
		{
			return _isEnabled;
		}
		public function set isEnabled(value:Boolean):void
		{
			if (_isEnabled === value)
			{
				return;
			}

			log.log(Channel.AUDIO, this, "(set-isEnabled)", "value:", value, "prev:", _isEnabled);
			_isEnabled = value;

			if (!value)
			{
				isAudioOnPrev = isAudioOn;
			}
			isAudioOn = value ? isAudioOnPrev : false;
		}

		private var _isAudioOn:Boolean = true;
		public function get isAudioOn():Boolean
		{
			return _isAudioOn;
		}
		public function set isAudioOn(value:Boolean):void
		{
			if (_isAudioOn === value)
			{
				return;
			}

			log.log(Channel.AUDIO, this, "(set-audioOn)", "value:", value, "prev:", _isAudioOn);
			_isAudioOn = value;
			refreshVolume();

			// Dispatch
			dispatchEventWith(AUDIO_ON_CHANGE);
		}

		private var _isMusicOn:Boolean = true;
		public function get isMusicOn():Boolean
		{
			return _isMusicOn;
		}
		public function set isMusicOn(value:Boolean):void
		{
			if (_isMusicOn === value)
			{
				return;
			}

			log.log(Channel.AUDIO, this, "(set-musicOn)", "value:", value, "prev:", _isMusicOn);
			_isMusicOn = value;
			refreshVolume();

			// Dispatch
			dispatchEventWith(MUSIC_ON_CHANGE);
		}

		private var _isSoundOn:Boolean = true;
		public function get isSoundOn():Boolean
		{
			return _isSoundOn;
		}
		public function set isSoundOn(value:Boolean):void
		{
			if (_isSoundOn === value)
			{
				return;
			}

			log.info(Channel.AUDIO, this, "(set-soundOn)", "value:", value, "prev:", _isSoundOn);
			_isSoundOn = value;
			refreshVolume();
			
			// Dispatch
			dispatchEventWith(SOUND_ON_CHANGE);
		}

		private var _audioVolume:Number = 1;
		public function get audioVolume():Number
		{
			return _audioVolume;
		}
		public function set audioVolume(value:Number):void
		{
			if (_audioVolume === value)
			{
				return;
			}

			log.info(Channel.AUDIO, this, "(set-audioVolume)", "value:", value, "prev:", _audioVolume);
			_audioVolume = value;
			refreshVolume();

//DevNote: don't sent any value in Event.data. It's better to let user get it by audioManager reference
			// Dispatch
			dispatchEventWith(AUDIO_VOLUME_CHANGE);
		}

		private var _musicVolume:Number = 1;
		public function get musicVolume():Number
		{
			return _musicVolume;
		}
		public function set musicVolume(value:Number):void
		{
			if (_musicVolume === value)
			{
				return;
			}

			log.info(Channel.AUDIO, this, "(set-musicVolume)", "value:", value, "prev:", _musicVolume);
			_musicVolume = value;
			refreshVolume();

			// Dispatch
			dispatchEventWith(MUSIC_VOLUME_CHANGE);
		}

		private var _soundVolume:Number = 1;
		public function get soundVolume():Number
		{
			return _soundVolume;
		}
		public function set soundVolume(value:Number):void
		{
			if (_soundVolume === value)
			{
				return;
			}

			log.info(Channel.AUDIO, this, "(set-soundVolume)", "value:", value, "prev:", _soundVolume);
			_soundVolume = value;
			refreshVolume();

			// Dispatch
			dispatchEventWith(SOUND_VOLUME_CHANGE);
		}

		private function get currentSoundVolume():Number
		{
			return isAudioOn && isSoundOn ? audioVolume * soundVolume : 0;
		}
		
		private function get currentMusicVolume():Number
		{
			return isAudioOn && isMusicOn ? audioVolume * musicVolume : 0;
		}

		public function get currentMusicName():String
		{
			var audioItem:AudioItem = getAudioItemByChannelName(MUSIC_CHANNEL);
			return audioItem ? audioItem.audioName : null;
		}
		
		// Constructor
		
		public function AudioManager()
		{
		}
		
		// Methods
		
		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);

			resourceManager = systemManager.resourceManager;
			
			var stage:Stage = systemManager.stage;
			if (stage)
			{
				stage.addEventListener(Event.ACTIVATE, stage_activateHandler);
				stage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler);
			}

			log.info(Channel.AUDIO, this, "(initialize)", "stage:", stage);
			log.log(Channel.AUDIO, this, " (initialize) audioOn, musicOn, soundOn:",isAudioOn, isMusicOn, isSoundOn, 
				"audioVolume, musicVolume, soundVolume:", audioVolume, musicVolume, soundVolume);
		}
		
		override public function dispose():void
		{
			log.log(Channel.AUDIO, this, "(dispose)");
			stopAll();
			
			var stage:Stage = systemManager.stage;
			if (stage)
			{
				stage.removeEventListener(Event.ACTIVATE, stage_activateHandler);
				stage.removeEventListener(Event.DEACTIVATE, stage_deactivateHandler);
			}

			for (var i:int = 0; i < assetManagerArray.length; i++)
			{
				removeAssetManager(assetManagerArray[i] as AssetManager);
			}
			
			resourceManager = null;
			
			super.dispose();
		}

		public function addAssetManager(assetManager:AssetManager):void
		{
			if (!assetManager)
			{
				return;
			}

			log.log(Channel.AUDIO, this, "(addAssetManager)", "assetManager:", assetManager, "assetManagerArray:", assetManagerArray);
			assetManagerArray[assetManagerArray.length] = assetManager;//ArrayUtil.pushUnique(assetManagerArray, assetManager);
			
			// Listeners
			assetManager.addEventListener(AssetManagerExt.POST_LOAD_COMPLETE, assetManager_postLoadCompleteHandler);
		}

		public function removeAssetManager(assetManager:AssetManager):void
		{
			if (!assetManager)
			{
				return;
			}

			log.log(Channel.AUDIO, this, "(removeAssetManager)", "assetManager:", assetManager, "assetManagerArray:", assetManagerArray);
			// Listeners
			assetManager.removeEventListener(AssetManagerExt.POST_LOAD_COMPLETE, assetManager_postLoadCompleteHandler);

			ArrayUtil.removeItem(assetManagerArray, assetManager);

			// Stop all audio from this assetManager
			if (assetManagerArray.indexOf(assetManager) == -1)
			{
				var audioNameArray:Array = audioNameArrayByAssetManagerLookup[assetManager] as Array;
				stopByAudioNameArray(audioNameArray);
				delete audioNameArrayByAssetManagerLookup[assetManager];
			}
		}

		/**
		 * If another music is playing it will be stopped.
		 * 
		 * @param musicName
		 * @param isLoop
		 * @param onComplete
		 */
		public function playMusic(musicName:String, isLoop:Boolean = true, onComplete:Function = null, 
								  fadeInTimeSec:Number = -1):SoundChannel
		{
			log.info(Channel.AUDIO, this, "(playMusic) musicName:", musicName, "isLoop:", isLoop, "currentMusicVolume:", currentMusicVolume);

			var soundChannel:SoundChannel = playAudio(musicName, MUSIC_CHANNEL, isLoop ? 10000 : 0, onComplete, fadeInTimeSec);
			return soundChannel;
		}
		
		public function playOrEnqueueMusic(musicName:String, isLoop:Boolean = true, onComplete:Function = null,
		                                   fadeInTimeSec:Number = -1):SoundChannel
		{
			log.info(Channel.AUDIO, this, "(playOrEnqueueMusic) musicName:", musicName, "isLoop:", isLoop);

			if (checkEnqueueAudio(musicName, MUSIC_CHANNEL, isLoop ? 10000 : 0, onComplete, fadeInTimeSec))
			{
				return null;
			}

			return playMusic(musicName, isLoop, onComplete, fadeInTimeSec);
		}

		public function playSound(soundName:String, channelName:String = null, onComplete:Function = null, 
								  fadeInTimeSec:Number = -1):SoundChannel
		{
			log.info(Channel.AUDIO, this, "(playSound) soundName:", soundName, "channelName:", channelName, "currentSoundVolume:", currentSoundVolume);

			var soundChannel:SoundChannel = playAudio(soundName, channelName || DEFAULT_SOUND_CHANNEL, 0, onComplete, fadeInTimeSec);
			return soundChannel;
		}

		public function playOrEnqueueSound(soundName:String, channelName:String = null, onComplete:Function = null, 
										   fadeInTimeSec:Number = -1):SoundChannel
		{
			log.info(Channel.AUDIO, this, "(playOrEnqueueSound) soundName:", soundName, "channelName:", channelName);

			if (checkEnqueueAudio(soundName, channelName || DEFAULT_SOUND_CHANNEL, 0, onComplete, fadeInTimeSec))
			{
				return null;
			}

			return playSound(soundName, channelName, onComplete, fadeInTimeSec);
		}

		/**
		 * Stop music by name.
		 * 
		 * @param musicName			stop current music if null
		 * @param fadeOutTimeSec	set 0 to stop without fading, set -1 to use default fadeOut value
		 */
		public function stopMusic(musicName:String = null, fadeOutTimeSec:Number = -1):void
		{
			log.info(Channel.AUDIO, this, "(stopMusic) musicName:", musicName);

			if (currentMusicAudioItem && currentMusicAudioItem.audioName == musicName)
			{
				currentMusicAudioItem.dispose();
				currentMusicAudioItem = null;
			}

			// Stop all music
			if (!musicName)
			{
				stopChannel(MUSIC_CHANNEL);
				return;
			}

			// Stop specified music
			stopAudioItem(musicName, MUSIC_CHANNEL, fadeOutTimeSec);
		}

		/**
		 * Stop sound by name.
		 * 
		 * stopSound("name") - stop sound "name"
		 * stopSound() - stop all sound
		 * 
		 * @param soundName			stop all sounds if null
		 * @param fadeOutTimeSec	set 0 to stop without fading, set -1 to use default fadeOut value
		 */
		public function stopSound(soundName:String = null, channelName:String = null, fadeOutTimeSec:Number = -1):void
		{
			log.info(Channel.AUDIO, this, "(stopSound) soundName:", soundName);
			
			// Stop all sounds
			if (!soundName)
			{
				stopChannel(DEFAULT_SOUND_CHANNEL, true);
				return;
			}
			
			// Stop specified sound
			stopAudioItem(soundName, channelName || DEFAULT_SOUND_CHANNEL, fadeOutTimeSec);
		}

		public function stopChannel(channelName:String, isAllExceptThis:Boolean = false):Boolean
		{
			log.info(Channel.AUDIO, this, "(stopChannel)", "channelName:", channelName, "isAllExceptThis:", isAllExceptThis);
			var isAnyStopped:Boolean = false;
			for each (var audioItem:AudioItem in audioItemArray)
			{
				if ((audioItem.channelName == channelName && !isAllExceptThis) || 
					(audioItem.channelName != channelName && isAllExceptThis))
				{
					// Stop
					if (stopAudioItem(audioItem, null, defaultFadeOutTimeSec))
					{
						isAnyStopped = true;
					}
				}
			}
			return isAnyStopped;
		}
		
		/**
		 * Stop all audio: music and all sounds.
		 */
		public function stopAll():void
		{
			log.info(Channel.AUDIO, this, "(stopAll) <dispatch-STOP_ALL>");

			if (currentMusicAudioItem)
			{
				currentMusicAudioItem.dispose();
				currentMusicAudioItem = null;
			}
			
			// Stop
			for each (var audioItem:AudioItem in audioItemArray)
			{
				stopAudioItem(audioItem);
			}
			
			// Dispatch
			dispatchEventWith(STOP_ALL);
		}
		
		private function playAudio(audioName:String, channelName:String, loopCount:int = 0, 
								   onComplete:Function = null, fadeInTimeSec:Number = -1):SoundChannel
		{
			var sound:Sound = getSoundObject(audioName);
			log.info(Channel.AUDIO, this, "(playAudio)", "audioName:", audioName, "channelName:", channelName, "loopCount:", loopCount,
					"onComplete:", onComplete, "fadeInTimeSec:", fadeInTimeSec, "sound:", sound);
			
			var isMusic:Boolean = channelName == MUSIC_CHANNEL;
			var audioItem:AudioItem;
			
			if (!sound)
			{
				audioItem = new AudioItem(audioName, channelName, null, loopCount, onComplete);
				if (isMusic)
				{
					currentMusicAudioItem = audioItem;
				}
				log.info(Channel.AUDIO, this, " (playAudio) no-sound-asset <return-null> saved-currentMusicAudioItem:", currentMusicAudioItem);
				return null;
			}
			
			// Check currently playing
			var currentAudioItem:AudioItem = getAudioItemByChannelName(channelName);
			if (currentAudioItem)
			{
				if (currentAudioItem.audioName == audioName)
				{
					if (currentAudioItem.isFadingOut)
					{
						log.info(Channel.AUDIO, this, " (playAudio) isFadingOut <fadeAudioItem-In;return-current>", 
								"audioName:", audioName, "currentAudioItem:", currentAudioItem);
						fadeAudioItem(currentAudioItem, true, fadeInTimeSec);
						return currentAudioItem.soundChannel;
					}
					
					log.info(Channel.AUDIO, this, " (playAudio) <return-null>", "audioName:", audioName, 
							"currentAudioItem:", currentAudioItem);
					return null;
				}
				else
				{
					doStopAudioItem(currentAudioItem);
				}
			}

			var volume:Number = isMusic ? currentMusicVolume : currentSoundVolume;
			
			if (volume)
			{
				// Play
				var soundTransform:SoundTransform = new SoundTransform(volume);
				var soundChannel:SoundChannel = sound.play(0, loopCount, soundTransform);
				// Listeners
				soundChannel.addEventListener(Event.SOUND_COMPLETE, soundChannel_soundCompleteHandler);
			}
			
			// Add
			audioItem = new AudioItem(audioName, channelName, soundChannel, loopCount, onComplete);
			if (isMusic)
			{
				currentMusicAudioItem = audioItem.copy();
			}
			if (volume)
			{
				audioItemArray[audioItemArray.length] = audioItem;
			}
			
			if (soundChannel)
			{
				// Fade in
				fadeAudioItem(audioItem, true, fadeInTimeSec);
				
				// Dispatch
				dispatchEventWith(isMusic ? MUSIC_PLAY : SOUND_PLAY, false, soundChannel);
			}
			
			return soundChannel;
		}

		private function checkEnqueueAudio(audioName:String, channelName:String = null, loopCount:int = 0, onComplete:Function = null, fadeInTimeSec:Number = -1):Boolean
		{
			log.info(Channel.AUDIO, this, "(checkEnqueueAudio) audioName:", audioName, "channelName:", channelName, "loopCount:", loopCount);

			var currentAudioItem:AudioItem = getAudioItemByChannelName(channelName);
			if (currentAudioItem)
			{
				var enqueueAudioItem:AudioItem = new AudioItem(audioName, channelName, null, loopCount, onComplete, fadeInTimeSec);
				enqueueAudioItem.loopCount = loopCount;
				ObjectUtil.pushToPropertyArray(audioItemQueueByChannelName, channelName, enqueueAudioItem);
				return true;
			}

			return false;
		}

		private function playNextByChannelName(channelName:String):SoundChannel
		{
			log.info(Channel.AUDIO, this, "(playNextByChannelName)", "channelName:", channelName,
					"current-in-channel:", getAudioItemByChannelName(channelName), "queue:", audioItemQueueByChannelName[channelName]);
			// Check the channel is free
			if (getAudioItemByChannelName(channelName))
			{
				return null;
			}

			// Get queue
			var audioItemQueue:Array = audioItemQueueByChannelName[channelName] as Array;
			if (!audioItemQueue || !audioItemQueue.length)
			{
				return null;
			}

			// Play next
			var audioItem:AudioItem = audioItemQueue.shift() as AudioItem;
			var soundChannel:SoundChannel = playAudio(audioItem.audioName, audioItem.channelName, 
					audioItem.loopCount, audioItem.onComplete, audioItem.fadeInTimeSec);
			audioItem.dispose();
			return soundChannel;
		}
		
		private function stopAudioItem(audio:*, channelName:String = null, fadeTimeSec:Number = -1):Boolean
		{
			var audioName:String = audio as String;
			var audioItem:AudioItem = audio as AudioItem || getAudioItemByAudioAndChannelName(audioName, channelName);
			log.info(Channel.AUDIO, this, "(stopAudioItem)", "audio:", audio, "channelName:", channelName, "(audioName:", audioName, 
					"audioItem:", audioItem + ")", "fadeTimeSec:", fadeTimeSec);
			
//			if (currentMusicAudioItem && currentMusicAudioItem.audioName == audioName)
//			{
//				currentMusicAudioItem.dispose();
//				currentMusicAudioItem = null;
//			}
			
			if (!audioItem)
			{
				return false;
			}
			
			// Clear queue
			delete audioItemQueueByChannelName[audioItem.channelName];
			
			if (fadeTimeSec != 0)
			{
				// Fade out
				return fadeAudioItem(audioItem, false, fadeTimeSec);
			}
			
			// Stop
			return doStopAudioItem(audioItem);
		}

		private function stopByAudioNameArray(audioNameArray:Array):void
		{
			log.info(Channel.AUDIO, this, "(stopByAudioNameArray)", "audioNameArray:", audioNameArray);
			if (!audioNameArray)
			{
				return;
			}

			for each (var audioName:String in audioNameArray)
			{
				// (Note: Audio with the same name could be played on more than one channels)
				for each (var audioItem:AudioItem in audioItemArray)
				{
					if (audioItem.audioName == audioName)
					{
						stopAudioItem(audioItem);
					}
				}
			}
		}

		private function doStopAudioItem(audioItem:AudioItem):Boolean
		{
			log.info(Channel.AUDIO, this, "(doStopAudioItem)", "audioItem:", audioItem, "audioItem.soundChannel:", audioItem && audioItem.soundChannel);
			if (!audioItem || !audioItem.soundChannel)
			{
				return false;
			}

			// Stop
			stopFadeByAudioItem(audioItem);
			if (audioItem.soundChannel)
			{
				var soundChannel:SoundChannel = audioItem.soundChannel;
				soundChannel.stop();
			}

			// Remove
			var isRemoved:Boolean = ArrayUtil.removeItem(audioItemArray, audioItem) != -1;
			log.info(Channel.AUDIO, this, " (doStopAudioItem)", "audioItem:", audioItem, "isRemoved:", isRemoved);

			// Dispatch
			if (isRemoved && soundChannel)
			{
				dispatchEventWith(audioItem.channelName == MUSIC_CHANNEL ? MUSIC_STOP : SOUND_STOP, false, audioItem.audioName);
			}

			// Dispose
			audioItem.dispose();

			return isRemoved;
		}

		private function getSoundObject(audioName:String):Sound
		{
			for each (var assetManager:AssetManager in assetManagerArray)
			{
				var sound:Sound = assetManager.getSound(audioName);
				if (!sound)
				{
					var soundClass:Class = resourceManager.getDefinition(audioName);
					sound = soundClass ? new soundClass() as Sound : null;
				}
				if (sound)
				{
					ObjectUtil.pushToPropertyArray(audioNameArrayByAssetManagerLookup, assetManager, audioName, true);
					return sound;
				}
			}
			return null;
		}

		private function getAudioItemByAudioAndChannelName(audioName:String, channelName:String = null):AudioItem
		{
			for each (var audioItem:AudioItem in audioItemArray)
			{
				if (audioItem.audioName == audioName && (!channelName || audioItem.channelName == channelName))
				{
					return audioItem;
				}
			}
			return null;
		}
		private function getAudioItemByChannelName(channelName:String):AudioItem
		{
			return ArrayUtil.getItemByProperty(audioItemArray, "channelName", channelName) as AudioItem;
		}
		private function getAudioItemBySoundChannel(soundChannel:SoundChannel):AudioItem
		{
			return ArrayUtil.getItemByProperty(audioItemArray, "soundChannel", soundChannel) as AudioItem;
		}

		private function refreshVolume():void
		{
			var currentSoundVolume:Number = this.currentSoundVolume;
			var currentMusicVolume:Number = this.currentMusicVolume;
			log.info(Channel.AUDIO, this, "(refreshVolume) currentSoundVolume:", currentSoundVolume, "currentMusicVolume:", currentMusicVolume, "audioItemArray:", audioItemArray);

			// Restore music on musicOn|audioOn=true
			refreshPlayingMusic();
			
			// Update all playing audio
			for each (var audioItem:AudioItem in audioItemArray)
			{
				var isOff:Boolean = !checkChannelIsPlayable(audioItem.channelName);
				if (isOff)
				{
					// Stop
					stopAudioItem(audioItem);
				}
				else if (soundChannel)
				{
					var isMusic:Boolean = audioItem.channelName == MUSIC_CHANNEL;
					var soundChannel:SoundChannel = audioItem.soundChannel;

					// Update volume
					var soundTransform:SoundTransform = soundChannel.soundTransform;
					soundTransform.volume = isMusic ? currentMusicVolume : currentSoundVolume;
					soundChannel.soundTransform = soundTransform;
				}
			}
		}

		private function refreshPlayingMusic():void
		{
			var musicAudioItem:AudioItem = getAudioItemByChannelName(MUSIC_CHANNEL);
			log.info(Channel.AUDIO, this, "(refreshPlayingMusic)", "isMusicOn:", isMusicOn, "saved-currentMusicAudioItem:", currentMusicAudioItem, "playing-musicAudioItem:", musicAudioItem);
			if (isMusicOn && currentMusicAudioItem && (!musicAudioItem || musicAudioItem.isFadingOut))//
			{
				playMusic(currentMusicAudioItem.audioName, currentMusicAudioItem.loopCount > 0, currentMusicAudioItem.onComplete);
			}
		}

		private function checkChannelIsPlayable(channelName:String):Boolean
		{
			if (!isAudioOn)
			{
				return false;
			}

			var isMusic:Boolean = channelName == MUSIC_CHANNEL;
			return (isMusic && isMusicOn) || (!isMusic && isSoundOn);
		}
		
		private function fadeAudioItem(audioItem:AudioItem, isFadeIn:Boolean, fadeTimeSec:Number = -1):Boolean
		{
			if (fadeTimeSec == -1)
			{
				fadeTimeSec = isFadeIn ? defaultFadeInTimeSec : defaultFadeOutTimeSec;
			}

			if (fadeTimeSec <= 0 || !audioItem || !audioItem.soundChannel)
			{
				return false;
			}
			
			//trace(this,"(fadeAudioItem) isFadingIn,isFadingOut:", audioItem.isFadingIn, audioItem.isFadingOut, "isFadeIn:", isFadeIn);
			if ((audioItem.isFadingIn && isFadeIn) || (audioItem.isFadingOut && !isFadeIn))
			{
				return true;
			}
			
			// Stop current fading
			var isFadingBefore:Boolean = stopFadeByAudioItem(audioItem);
			
			log.info(Channel.AUDIO, this, "(fadeAudioItem) <fadeTween.animate>", "audioItem:", audioItem, "isFadeIn:", isFadeIn, "fadeTimeSec:", fadeTimeSec);
			
			var soundTransform:SoundTransform = audioItem.soundChannel.soundTransform;
			var currentVolume:Number = soundTransform.volume;
			if (isFadeIn && !isFadingBefore)
			{
				soundTransform.volume = 0;
				audioItem.soundChannel.soundTransform = soundTransform;
			}

			audioItem.isFadingIn = isFadeIn;
			audioItem.isFadingOut = !isFadeIn;

			var valueObject:Object = isFadeIn ? {ratio: 0} : {volume: currentVolume};
			
			var fadeTween:Tween = new Tween(valueObject, fadeTimeSec);
			if (isFadeIn)
			{
				fadeTween.animate("ratio", 1);
			}
			else
			{
				fadeTween.animate("volume", 0);
			}
			fadeTween.onUpdate = fadeTween_onUpdate;
			fadeTween.onUpdateArgs = [audioItem, valueObject];
			fadeTween.onComplete = isFadeIn ? stopFadeByAudioItem : doStopAudioItem;
			fadeTween.onCompleteArgs = [audioItem];
			
			fadeTweenByAudioItemLookup[audioItem] = fadeTween;
			Starling.juggler.add(fadeTween);
			
			return true;
		}
		
		private function stopFadeByAudioItem(audioItem:AudioItem):Boolean
		{
			if (audioItem)
			{
				audioItem.isFadingIn = false;
				audioItem.isFadingOut = false;
			}
			
			var fadeTween:Tween = fadeTweenByAudioItemLookup[audioItem] as Tween;
			if (fadeTween)
			{
//				log.info(Channel.AUDIO, this, "(stopFadeByAudioItem)", "audioItem:", audioItem, "fadeTween:", fadeTween, new Error().getStackTrace());
				Starling.juggler.remove(fadeTween);
				fadeTween.reset(null, 0);
				
				delete fadeTweenByAudioItemLookup[audioItem];
				return true;
			}
			return false;
		}
		
		// Event handlers
		
		private function fadeTween_onUpdate(audioItem:AudioItem, valueObject:Object):void
		{
			var soundChannel:SoundChannel = audioItem ? audioItem.soundChannel : null;
			if (soundChannel && valueObject)
			{
				// Get volume
				var isMusic:Boolean = audioItem.channelName == MUSIC_CHANNEL;
				var volume:Number;
				if (valueObject.hasOwnProperty("ratio"))
				{
					var ratio:Number = valueObject.ratio;
					var currentVolume:Number = isMusic ? currentMusicVolume : currentSoundVolume;
					volume = ratio * currentVolume;
					//log.info(Channel.AUDIO, this, "(fadeTween_onUpdate)", "audioItem:", audioItem, "volume:", volume, 
					//		"ratio:", ratio, "currentVolume:", currentVolume, "isMusic:", isMusic);
				}
				else
				{
					volume = valueObject.volume;
					//log.info(Channel.AUDIO, this, "(fadeTween_onUpdate)", "audioItem:", audioItem, "volume:", volume);
				}
				
				// Apply volume
				var soundTransform:SoundTransform = soundChannel.soundTransform;
				soundTransform.volume = volume;
				soundChannel.soundTransform = soundTransform;
			}
		}
		
		private function soundChannel_soundCompleteHandler(event:Event):void
		{
			var audioItem:AudioItem = getAudioItemBySoundChannel(event.target as SoundChannel);
			log.info(Channel.AUDIO, this, "(soundChannel_soundCompleteHandler)", "audioItem:", audioItem, "event.target:", event.target);
			if (!audioItem)
			{
				log.warn(Channel.AUDIO, this, " (soundChannel_soundCompleteHandler) <return> There is no audioItem in getAudioItemBySoundChannel()!");
//				return;
			}
			
			var channelName:String = audioItem.channelName;
			
			var isMusic:Boolean = channelName == MUSIC_CHANNEL;
			if (isMusic && currentMusicAudioItem)
			{
				currentMusicAudioItem.dispose();
				currentMusicAudioItem = null;
			}
			
			// onComplete
			if (audioItem.onComplete != null)
			{
				audioItem.onComplete();
			}
			
			// Remove
			doStopAudioItem(audioItem);
			
			// Play next
			playNextByChannelName(channelName)
		}

		private function stage_activateHandler(event:Event):void
		{
			log.log(Channel.AUDIO, this, "+(stage_activateHandler) <isEnabled=true>");
			isEnabled = true;
		}

		private function stage_deactivateHandler(event:Event):void
		{
			log.log(Channel.AUDIO, this, "-(stage_deactivateHandler) <isEnabled=false?>", "isDisableOnStageDeactivate:", isDisableOnStageDeactivate);
			if (isDisableOnStageDeactivate)
			{
				isEnabled = false;
			}
		}

		private function assetManager_postLoadCompleteHandler(event:*):void
		{
			refreshPlayingMusic();
		}
		
	}
}

import flash.media.SoundChannel;

internal class AudioItem
{
	
	// Class constants
	// Class variables
	// Class methods
	
	// Variables
	
	public var audioName:String;
	public var channelName:String;
	public var soundChannel:SoundChannel;
	public var onComplete:Function;
	public var fadeInTimeSec:Number = -1;
	
	public var loopCount:int = 0;
	
	public var isFadingIn:Boolean = false;
	public var isFadingOut:Boolean = false;

	// Properties
	
	// Constructor

	public function AudioItem(audioName:String, channelName:String, soundChannel:SoundChannel, loopCount:int, onComplete:Function = null, fadeInTimeSec:Number = -1)
	{
		this.audioName = audioName;
		this.channelName = channelName;
		this.soundChannel = soundChannel;
		this.onComplete = onComplete;
		this.fadeInTimeSec = fadeInTimeSec;
		this.loopCount = loopCount;
	}

	// Methods

	public function toString():String
	{
		return "[AudioItem name:" + audioName + " channel:" + channelName + 
				" sound:" + (soundChannel ? "+" : "-") + 
				(isFadingIn ? " isFadingIn" : "") + (isFadingOut ? " isFadingOut" : "") + "]";
		// + " onComplete:" + (onComplete != null ? "+" : "-")
	}

	public function dispose():void
	{
		audioName = null;
		channelName = null;
		soundChannel = null;
		onComplete = null;
		fadeInTimeSec = -1;
	}

	public function copy():AudioItem
	{
		var audioItem:AudioItem = new AudioItem(audioName, channelName, null, loopCount, onComplete, fadeInTimeSec);
		audioItem.loopCount = loopCount;
		return audioItem;
	}
	
	// Event handlers
	
}
