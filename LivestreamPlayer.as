package {
	
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import fl.events.SliderEvent;
	import fl.controls.Slider;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.system.SecurityDomain;
	import flash.display.DisplayObject;
	import flash.utils.setTimeout;
		
	public class LivestreamPlayer extends MovieClip
	{
		private static const API_URL:String 
			= "http://cdn.livestream.com/chromelessPlayer/v20/playerapi.swf";
		
		private static const STOP_BUTTON:String = "livestreamPlayerStopButton";
		private static const PLAY_BUTTON:String = "livestreamPlayerPlayButton";
		private static const TOGGLEPLAY_BUTTON:String = "livestreamPlayerTogglePlayButton";
		private static const FULLSCREEN_BUTTON:String = "livestreamPlayerFullscreenButton";
		private static const VOLUME_SLIDER:String = "livestreamPlayerVolumeSlider";
		
		private var mainTimeline:Object;
		private var loader:Loader;
		public var player:Object;
		
		public var _interferenceEnabled = false;
		public var _textOverlayEnabled = false;
		public var _powerButtonEnabled = false;
		public var _volumeOverlayEnabled = false;
		public var _showThumbnail = true;
		public var _showPlayButton = false;
		public var _showPauseButton = false;
		public var _showMuteButton = false;
		public var _showFullscreenButton = false;
		public var _showSpinner = true;
		public var _spinnerSize;
		public var _devKey = "KRtLfIN-QAp6QP-xq_NjOgKCB7a8C88C_1ii0H_wyS2nacWmU_8RqWY0E6ckupdJRZacjkeUb2Q-5Zo3maFhk608pUDXFNdLznD7SVyUVTcfCWsbZ5bdsEPDyBevnEX9";
		public var _autoLoad = true;
		public var _loadDelay = 0;
		public var _width = 512;
		public var _height = 384;
		
		public var _isAutoPlay:Boolean = true;
		public var _channel:String = "baiuhf";		

		public function LivestreamPlayer():void
		{
			Security.allowDomain("cdn.livestream.com");
			Security.loadPolicyFile("http://cdn.livestream.com/crossdomain.xml");
			mainTimeline = stage.getChildAt(0);
			
			loaderInfo.addEventListener(Event.COMPLETE, componentLoadedHandler);
		}
		
		private function componentLoadedHandler(event:Event):void
		{
			if (_autoLoad)
			{
				load();				
			}
			else if (_loadDelay != 0) 
			{
				setTimeout(load, _loadDelay * 1000);
			}
		}
		
		public function load():void
		{
			loader = new Loader();
			var url:URLRequest = new URLRequest(API_URL);

			addChild(loader);
			
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);

			try 
			{ // this is how we load remotely
				loader.load(url, new LoaderContext(true, ApplicationDomain.currentDomain, SecurityDomain.currentDomain));
			}
			catch (error:SecurityError)
			{ // this is how we load locally
				loader.load(url);
			}			
		}
				
		public override function get width():Number
		{
			return player ? player.width : 0;
		}
		
		public override function set width(val:Number):void
		{
			if (player)
			{
				player.width = val;
			}
		}
		
		public override function get height():Number
		{
			return player ? player.height : 0;
		}
		
		public override function set height(val:Number):void
		{
			if (player)
			{
				player.height = val;
			}
		}
				
		private function loaderCompleteHandler(event:Event):void
		{
			loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
			player = loader.content;
			player.width = _width;
			player.height = _height;
			trace('w perra:' + _width + ' h:' + _height);
			onPlayerReady();
		}
		
		private function playerErrorHandler(event:Event):void
		{
			trace('LivestreamPlayer error: ' + Object(event).message);
		}

		private function onPlayerReady():void
		{
			player.addEventListener("errorEvent", playerErrorHandler);
			
			bindClick(STOP_BUTTON, nullary(player.stop));
			bindClick(PLAY_BUTTON, nullary(player.play));
			bindClick(TOGGLEPLAY_BUTTON, nullary(player.togglePlayback));
			bindEvent(VOLUME_SLIDER, SliderEvent.CHANGE,
				function(event:SliderEvent):void { player.volume = event.value / 10; });
			
			var volumeSlider = mainTimeline.getChildByName(VOLUME_SLIDER);
			if (volumeSlider)
			{
				(volumeSlider as Slider).value = player.volume * 10;
			}
			
			player.showThumbnail = _showThumbnail;
			player.showPlayButton = _showPlayButton;
			player.showPauseButton = _showPauseButton;
			player.showMuteButton = _showMuteButton;
			player.showSpinner = _showSpinner;
			player.devKey = _devKey;

			player.load(_channel);
			if (_isAutoPlay) 
			{
				player.play();
			}
			
			dispatchEvent(new Event("ready"));
		}

		private function bindClick(instanceName:String, callback:Function):void
		{
			bindEvent(instanceName, MouseEvent.CLICK, callback);
		}

		private function bindEvent(instanceName:String, event:String, callback:Function):void
		{
			var displayObject:DisplayObject = mainTimeline.getChildByName(instanceName);
			
			if (displayObject)
			{
				trace("<LivestreamPlayer> Found object: " + instanceName + ", binding.");
				displayObject.addEventListener(event, callback);
			}
			else
			{
				trace("<LivestreamPlayer> Couldn't find object with instance name: " + instanceName + ", skipping.");
			}
		}

		private function nullary(f:Function):Function 
		{
			return function(arg:*) { f(); };
		}
		
	}
	
}
