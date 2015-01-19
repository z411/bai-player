package  {
	import flash.display.Sprite;
	import flash.display.DisplayObject;
    import flash.text.TextField;
	import flash.text.TextFieldType;
    import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.system.Security;
	import flash.events.*;
	import fl.events.ComponentEvent;
	import fl.events.ListEvent;
	import fl.controls.dataGridClasses.DataGridColumn;
	import Scroller;
	import LivestreamPlayer;
	
	import fl.transitions.Tween;
	import fl.transitions.TweenEvent;
	import fl.transitions.easing.None;
	import flash.ui.Mouse;
	import flash.filters.DropShadowFilter;
	import flash.display.Loader;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	//import flash.net.URLRequest;
	//import flash.net.Socket;
	import flash.net.*;
	import flash.utils.Timer;
	import flash.system.System;
	import flash.geom.Rectangle;
	import fl.data.DataProvider;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	
	import CustomRowColors;

    public class Player extends Sprite
    {
		// Configuration load
		var xmlLoader:URLLoader = new URLLoader();
		var xmlData:XML = new XML();
		
		// Configuration variables
		var connect:Boolean = true;
		var isPanelVisible:Boolean = true;
		var isAllowedToChat:Boolean = false;
		var isFullscreen:Boolean = false;
		var isQuickChat:Boolean = false;
		var ircServer:String; // = "embyr.fyrechat.net";
		var ircPort:Number;
		var ircChannel:String; // = "#baitv0";
		var scrollStart:Number = 515;
		var scrollSize:Number = 24;
		var scrollLength:Number; // = 5;
		var scrollCompensation:Number; // = 0.001;
		var scrollSeparation:Number = 50; // = 50;
		var scrollVerticalSeparation:Number = 30; // = 50;
		var chatboxLimit:Number; // = 200;
		var floodTime:Number; // = 1000;
		var fullscreenTime:Number = 500;
		var viewersReloadTime:Number; // = 5000;
		
		// Static variables
		var chatEnabled:Boolean = false;
		var texts:Vector.<Scroller> = new Vector.<Scroller>();
		var sock:Socket;
		private var player:*;
		var ircNick:String = generateRandomString(8);
		var state:Number = 0;
		var colors:Array = new Array(0xFFFFFF, 0xFF7700, 0xFF0000, 0xFFFF00, 0x0000FF, 0x770077, 0x00FFFF, 0x00FF00);
		
		// Scrollbar and chatbox
		var bounds:Rectangle;
		var hBounds:Rectangle;
		var scrolling:Boolean = false;
		var hScrolling:Boolean = false;
		var chatbox:TextField = new TextField();
		var chatMessages:DataProvider = new DataProvider();
		var floodTimer:Timer; // = new Timer(floodTime, 1); // Anti-lag wait, msecs
		var viewersTimer:Timer; // = new Timer(viewersReloadTime);
		var fullscreenTimer:Timer;
		
        public function Player()
        {
			// Stage
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, resizeHandler);
			stage.addEventListener(Event.FULLSCREEN, onStageFullScreen);
			
			stage.dispatchEvent(new Event(Event.RESIZE));
			
			// Context menu
			var context:ContextMenu = new ContextMenu();
			context.hideBuiltInItems();
			var context1 = new ContextMenuItem("BaI Player 0.1");
			var context2 = new ContextMenuItem("http://bienvenidoainternet.org");
			context2.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function() {
									  navigateToURL(new URLRequest("http://bienvenidoainternet.org"));
									  });
			context.customItems.push(context1, context2);
			contextMenu = context;
			
			/*var listContext:ContextMenu = new ContextMenu();
			listContext.hideBuiltInItems();
			var listContext1 = new ContextMenuItem("Copiar mensaje");
			listContext.customItems.push(listContext1);*/
			
			// Chatbox columns
			var colA:DataGridColumn = new DataGridColumn("mensaje");
			colA.sortable = false;
			colA.resizable = true;
			colA.width = 215;
			colA.headerText = "Mensaje";
			chatboxList.addColumn(colA);
			var colB:DataGridColumn = new DataGridColumn("time");
			colB.sortable = false;
			colB.resizable = true;
			colB.width = 65;
			colB.headerText = "Tiempo";
			chatboxList.addColumn(colB);
			chatboxList.dataProvider = chatMessages;
			//chatboxList.contextMenu = listContext;
			chatboxList.setStyle("cellRenderer", CustomRowColors);
			chatboxList.addEventListener("itemDoubleClick", function(e:ListEvent) { System.setClipboard(chatboxList.columns[0].itemToLabel(e.item)); });
			
			// Create text box
			postBox.addEventListener(ComponentEvent.ENTER, onPostEnter);

			statusText.text = "Cargando configuración...";
			var statusFormat:TextFormat = new TextFormat();
			statusFormat.font = "Arial";
			statusFormat.size = 9;
			statusFormat.bold = true;
			statusFormat.color = 0xFFFFFF;
			statusText.setStyle("textFormat", statusFormat);
			var viewersFormat:TextFormat = new TextFormat();
			viewersFormat.font = "Arial";
			viewersFormat.size = 14;
			viewersFormat.bold = true;
			//viewersFormat.color = 0xFFFFFF;
			viewersText.setStyle("textFormat", viewersFormat);
			var errorFormat:TextFormat = new TextFormat();
			errorFormat.font = "Arial";
			errorFormat.size = 16;
			errorFormat.bold = true;
			errorFormat.color = 0xFF0000;
			chatError.setStyle("textFormat", errorFormat);
			
			// Icons
			muteButton.setStyle("icon", "unmuteIcon");
			muteButton.setStyle("selectedUpIcon", "muteIcon");
			muteButton.setStyle("selectedDownIcon", "muteIcon");
			muteButton.setStyle("selectedOverIcon", "muteIcon");
			muteButton.enabled = false;
			playButton.setStyle("icon", "playIcon");
			playButton.setStyle("selectedUpIcon", "pauseIcon");
			playButton.setStyle("selectedDownIcon", "pauseIcon");
			playButton.setStyle("selectedOverIcon", "pauseIcon");
			playButton.enabled = false;
			fullscreenButton.setStyle("icon", "fullscreenIcon");
			fullscreenButton.setStyle("selectedUpIcon", "fullscreenIcon");
			fullscreenButton.setStyle("selectedDownIcon", "fullscreenIcon");
			fullscreenButton.setStyle("selectedOverIcon", "fullscreenIcon");
			fullscreenButton.enabled = false;
			
			postButton.addEventListener(MouseEvent.CLICK, onPostHandler);
			fullscreenButton.addEventListener(MouseEvent.CLICK, onFullscreenHandler);
			
			try {
				xmlLoader.addEventListener(Event.COMPLETE, startPlayer);
				xmlLoader.load(new URLRequest("config.xml"));
			} catch(e:Error) {
				statusText.text = e.errorID + ": " + e.message;
				chatDisable("Error de configuración");
				return;
			}
			
			// Player
			livestreamPlayer.addEventListener("ready", readyHandler);
        }
		function startPlayer(e:Event) {
			// Function to start loading everything
			xmlData = new XML(e.target.data);
			//connect = Boolean(xmlData.connection.connect);
			trace(connect);
			//ircServer = xmlData.connection.irc_server;
			trace(ircServer);
			ircPort = Number(xmlData.connection.irc_port);
			trace(ircPort);
			ircChannel = xmlData.connection.irc_channel;
			trace(ircChannel);
			scrollStart = Number(xmlData.scroller.scroll_start_x);
			trace(scrollStart);
			scrollLength = Number(xmlData.scroller.scroll_length);
			trace(scrollLength);
			scrollCompensation = Number(xmlData.scroller.scroll_compensation);
			trace(scrollCompensation);
			//scrollSeparation = Number(xmlData.scroller.scroll_separation_x);
			//trace(scrollSeparation);
			chatboxLimit = Number(xmlData.misc.chatbox_limit);
			trace(chatboxLimit);
			floodTime = Number(xmlData.misc.flood_time);
			trace(floodTime);
			viewersReloadTime = Number(xmlData.misc.viewer_reload_time);
			trace(viewersReloadTime);
			
			// Flood timer
			floodTimer = new Timer(floodTime, 1);
			floodTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onFloodTimer);
			viewersTimer = new Timer(viewersReloadTime);
			viewersTimer.addEventListener(TimerEvent.TIMER, onViewersTimer);
			fullscreenTimer = new Timer(fullscreenTime, 1);
			fullscreenTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onFullscreenTimer);

			// Start conneting
			if(connect) {
				try {
					statusText.text = "Conectando...";
					// Create IRC
					sock = new Socket(ircServer, ircPort);
					sock.addEventListener(Event.CONNECT, onConnected);
					sock.addEventListener(Event.CLOSE, onClosed);
					sock.addEventListener(ProgressEvent.SOCKET_DATA, sockGet);
					sock.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecError);
				}
				catch(errObject:Error) {
				  	statusText.text = errObject.message;
				}
			}
			
		}
		function readyHandler(event:Event):void 
		{
			postBox.maxChars = 80;
			
			player = livestreamPlayer.player;
			player.addEventListener("connectionEvent", function() {
							statusText.text = "Conectado, inicializando reproducción...";
							muteButton.enabled = true;
							playButton.enabled = true;
							fullscreenButton.enabled = true;
							muteButton.addEventListener(MouseEvent.CLICK, function() { player.toggleMute(); });
							playButton.addEventListener(MouseEvent.CLICK, function() {
										if(player.isPlaying) {
											statusText.text = "Pausa";
											viewersTimer.stop();
											viewersText.text = "Viewers: N/A";
										} else {
											statusText.text = "Reinicializando reproducción...";
										}
										player.togglePlayback(); });
						});
			player.addEventListener("playbackEvent", function() {
							statusText.text = "Reproduciendo";
							viewersText.text = "Viewers: " + player.viewerCount;
							viewersTimer.start();
							if(player.isLive) statusText.text += " (VIVO)";
							trace("PLAYBACK EVENT");
						});
			player.addEventListener("isLiveEvent", function() {
							if(player.isPlaying) {
								if(player.isLive)
									statusText.text = "Reproduciendo (VIVO)";
								else
									statusText.text = "Reproduciendo";
							}
						});
			player.addEventListener("pauseClickedEvent", function() {statusText.text = "Pausa"; });
			player.addEventListener("playClickedEvent", function() {statusText.text = "Espere..."; });
			player.addEventListener("playbackCompleteEvent", function() {statusText.text = "Detenido"; });
		}
		
        private function scrollText(message:String, own:Boolean=false, color:Number=0):void 
        {
			if(showComments.selected) return;
			
			// Revisar si hay textos inutilizados
			var found:Boolean = false;
			var i:Number = 0;
			var j:Number = 0;
			for(i = 0; i < texts.length; i++) {
				// Blahblah
				if(texts[i] == null || (scrollStart - texts[i].tween.position) > (texts[i].width + scrollSeparation)) {
					found = true;
					break;
				}
			}
            var txt:Scroller = new Scroller();
            txt.x = scrollStart;
            txt.y = 0 + (i*scrollVerticalSeparation);
            //result.embedFonts=true;
			txt.selectable = false;
			var fmt:TextFormat = new TextFormat();
			fmt.font = "Arial";
			fmt.size = scrollSize; // 24
			fmt.bold = true;
			fmt.color = colors[color];
			
			if(own) {
				txt.border = true;
				txt.borderColor = 0xFFFF00;
			}
            txt.text = message;
            txt.setTextFormat(fmt);
			txt.filters = [new DropShadowFilter()]
			txt.autoSize = TextFieldAutoSize.LEFT;
            addChildAt(txt,2);

			txt.tween = new Tween(txt, "x", None.easeInOut, scrollStart, 1-txt.width, (scrollLength + (txt.width*scrollCompensation)), true);
			
			txt.tween.addEventListener(TweenEvent.MOTION_STOP,
										 function(evt:TweenEvent) { killText(txt, i); });
			texts[i] = txt;
        }
		private function killText(obj:TextField, n:Number):void {
			removeChild(obj);
			if(!texts[n].tween.isPlaying) {
				texts[n] = null;
			}
		}
		function onPostHandler(e:MouseEvent):void {
			postMessage(postBox.text);
			postBox.text = "";
			stage.focus = postBox;
		}
		function onPostEnter(e:ComponentEvent):void{
			postMessage(postBox.text);
			postBox.text = "";
			if(isQuickChat) {
				isQuickChat = false;
				fullscreenTimer.start();
			} else {
				stage.focus = postBox;
			}
		}
		function onMouse(e:MouseEvent):void {
			if(isFullscreen) {
				if(e.stageY > (stage.stageHeight-83)) {
					if(!isPanelVisible) {
						showPanel(true);
						isQuickChat = false;
					}
					fullscreenTimer.stop();
				} else {
					if(isPanelVisible) {
						fullscreenTimer.reset();
						fullscreenTimer.start();
					}
				}
				Mouse.show();
			}
		}
		function onKey(e:KeyboardEvent):void {
			trace(isFullscreen + " " + isPanelVisible + " " + isQuickChat);
			if(isFullscreen && !isPanelVisible && !isQuickChat) {
				trace("IN");
				postBox.visible = true;
				stage.focus = postBox;
				isQuickChat = true;
			}
		}
		function onStageFullScreen(e:FullScreenEvent):void {
			if(stage.displayState == StageDisplayState.NORMAL) {
				isFullscreen = false;
				showChatBox(true);
				showPanel(true);
				Mouse.show();
				fullscreenTimer.stop();
				if(isAllowedToChat) {
					postBox.enabled = true;
					postButton.enabled = true;
				}
				stage.removeEventListener("mouseMove", onMouse);
				stage.removeEventListener("keyDown", onKey);
			}
		}
		function onFullscreenHandler(e:MouseEvent):void {
			if (isFullscreen) {
				isFullscreen = false;
				try {
					stage.displayState = StageDisplayState.NORMAL;
				} catch ( error:SecurityError ) {
					trace("No fullscreen.");
				}
				resize();
				showChatBox(true);
				showPanel(true);
				Mouse.show();
				fullscreenTimer.stop();
				stage.removeEventListener("mouseMove", onMouse);
				stage.removeEventListener("keyDown", onKey);
			} else {
				isFullscreen = true;
				try {
					stage.displayState = StageDisplayState.FULL_SCREEN;
				} catch ( error:SecurityError ) {
					trace("No fullscreen.");
				}
				resize();
				showChatBox(false);
				//fullscreenTimer.reset();
				//fullscreenTimer.start();
				stage.addEventListener("mouseMove", onMouse);
				stage.addEventListener("keyDown", onKey);
			}
		}
		function showChatBox(bool:Boolean) {
			backMaskR.visible = bool;
			chatboxList.visible = bool;
			//chatDisabledMask.visible = bool;
		}
		function showPanel(bool:Boolean) {
			isPanelVisible = bool;
			backMaskD.visible = bool;
			postBox.visible = bool;
			postButton.visible = bool;
			colorBox.visible = bool;
			playButton.visible = bool;
			muteButton.visible = bool;
			livestreamPlayerVolumeSlider.visible = bool;
			showComments.visible = bool;
			fullscreenButton.visible = bool;
			statusText.visible = bool;
			backMaskS.visible = bool;
			viewersText.visible = bool;
			livestreamlog.visible = bool;
			//bailog.visible = bool;
			dividerLine.visible = bool;
		}
		
		function postMessage(str):void {
			if(str.length > 0 && state == 3) {
				chatboxNew(str);
				scrollText(str, true, colorBox.selectedIndex);
				sock.writeUTFBytes("PRIVMSG "+ircChannel+" :" + colorBox.selectedIndex + str + "\r\n");
				sock.flush();
				
				// Disable controls
				postBox.enabled = false;
				postButton.enabled = false;
				isAllowedToChat = false;
				floodTimer.start();
			}
		}
		
		// IRC
		function generateRandomString(newLength:Number):String{
		  var a:String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
		  var alphabet:Array = a.split("");
		  var randomLetter:String = "";
		  for (var i:Number = 0; i < newLength; i++){
			randomLetter += alphabet[Math.floor(Math.random() * alphabet.length)];
		  }
		  return randomLetter;
		}
		function onConnected(e:Event) {
			trace("Connected!");
			//sock.writeUTFBytes("NICK "+ircNick+"\nUSER nick1 nick2 nick3 :nick4\r\n");
			//sock.flush();
			//state = 1;
		}
		function onClosed(e:Event) {
			trace("Connection closed.");
			statusText.text = "Conexión al chat cerrada! Por favor presiona F5 (esto no debería suceder)";
			chatDisable("Error de conexión");
		}
		function sockGet(e) {
			var socketData:String = sock.readUTFBytes(sock.bytesAvailable);
			var msgs:Array = socketData.split("\n");
			trace(">>> " + socketData);
			for(var i:Number = 0; i < msgs.length; i++) {
				var msg:String = msgs[i];
				
				switch(state) {
					case 0:
						// Register
						sock.writeUTFBytes("NICK "+ircNick+"\nUSER nick1 nick2 nick3 :nick4\r\n");
						sock.flush();
						state = 1;
						//statusText.text = msg;
						break;
					case 1:
						// In server
						if(msg.search("MODE") > 0) {
							sock.writeUTFBytes("JOIN "+ircChannel+"\r\n");
							sock.flush();
							state = 2;
							//statusText.text = "Entrando a la sala...";
						}
						break;
						// 353
					case 2:
						// Waiting for room
						if(msg.search(" 353 ") > 0) { // Joined
							state = 3;
							//statusText.text = "Conectado al chat.";
							chatEnable();
						} else if(msg.search(" 474 ") > 0) { // Banned
							statusText.text = "Fuiste expulsado permanentemente del chat.";
							chatDisable("Fuiste expulsado");
						}
						break;
					case 3:
						// In channel
						if(msg.substring(0,4) == "PING") {
							var param:String = msg.substring(5);
							trace("Pong sent: :" + param);
							sock.writeUTFBytes("PONG :"+param+"\r\n");
							sock.flush();
						} else if(msg.search("PRIVMSG") > 0) {
							var nick:String = msg.match("^:(.+)!")[1];
							var line:String = msg.match("PRIVMSG "+ircChannel+" :(.*)")[1]
							var color:Number = Number(line.charAt(0));
							trace('El mensajito es: ' + msg);
							if(isNaN(color)) {
								color = 0;
								trace("Unknown color");
							} else {
								line = line.substr(1);
								chatboxNew(line);
								scrollText(line, false, color);
							}
						} else if(msg.search("KICK " + ircChannel + " " + ircNick) > 0) {
							statusText.text = "Fuiste expulsado del chat.";
							chatDisable("Fuiste expulsado");
						} else if(msg.search("KICK " + ircChannel + " ") > 0) {
							chatboxNew("Un espectador fue expulsado del chat.","r");
						}
						
						break;
				}
			}
			
		}
		function onSecError(e:SecurityErrorEvent):void {
			statusText.text = "Error de seguridad: "+e;
		}
		// Chatbox
		function chatboxNew(str:String, color:String="w") {
			var now:Date = new Date();
			var hString:String = now.hours < 10 ? "0" + now.hours : "" + now.hours;	
			var mString:String = now.minutes < 10 ? "0" + now.minutes : "" + now.minutes;
			var sString:String = now.seconds < 10 ? "0" + now.seconds : "" + now.seconds;
			
			var nowstr:String = hString + ":" + mString + ":" + sString;
			chatMessages.addItem({mensaje:str, time:nowstr, rowColor:color});
			chatboxList.getItemAt(0).color = 0xFF0000;
			if(chatMessages.length > chatboxLimit) {
				chatMessages.removeItemAt(0);
			}
			if(chatboxList.verticalScrollPosition == 0 || (chatboxList.verticalScrollPosition / chatboxList.maxVerticalScrollPosition) > 0.8) {
				chatboxList.scrollToIndex(chatboxList.length - 1);
			}
		}
		// Timer
		function onFloodTimer(e:TimerEvent) {
			postBox.enabled = true;
			postButton.enabled = true;
			isAllowedToChat = true;
		}
		function onViewersTimer(e:TimerEvent) {
			viewersText.text = "Viewers: " + player.viewerCount;
		}
		function onFullscreenTimer(e:TimerEvent) {
			showPanel(false);
			isQuickChat = false;
			Mouse.hide();
		}
		function chatEnable() {
			chatDisabledMask.visible = false;
			postBox.enabled = true;
			postButton.enabled = true;
			chatError.visible = false;
			isAllowedToChat = true;
		}
		function chatDisable(reason:String) {
			chatDisabledMask.visible = true;
			postBox.enabled = false;
			postButton.enabled = false;
			chatError.text = reason;
			chatError.visible = true;
			isAllowedToChat = false;
		}
		function resizeHandler(e:Event):void {
			if(stage.stageWidth >= 790 && stage.stageHeight >= 365) {
				chatboxList.x = stage.stageWidth - 293;
				  chatboxList.height = stage.stageHeight - 92;
				  chatDisabledMask.x = stage.stageWidth - 293;
				  chatDisabledMask.height = stage.stageHeight - 92;
				  chatError.x = stage.stageWidth - 297;
				  chatError.y = stage.stageHeight - 292;
				  backMaskR.x = stage.stageWidth - 299;
				  backMaskR.height = stage.stageHeight - 80;
				  backMaskD.y = stage.stageHeight - 83;
				  backMaskD.width = stage.stageWidth + 2;
				  bailog.x = stage.stageWidth - 111;
				  bailog.y = stage.stageHeight - 76;
				  
				  postBox.y = stage.stageHeight - 65;
				  postBox.width = stage.stageWidth - 600;
				  postButton.x = stage.stageWidth - 591;
				  postButton.y = stage.stageHeight - 65;
				  colorBox.x = stage.stageWidth - 524;
				  colorBox.y = stage.stageHeight - 65;
				  playButton.x = stage.stageWidth - 447;
				  playButton.y = stage.stageHeight - 67;
				  muteButton.x = stage.stageWidth - 415;
				  muteButton.y = stage.stageHeight - 67;
				  livestreamPlayerVolumeSlider.x = stage.stageWidth - 376;
				  livestreamPlayerVolumeSlider.y = stage.stageHeight - 60;
				  
				  statusText.y = stage.stageHeight - 28;
				  statusText.width = stage.stageWidth - 471;
				  backMaskS.y = stage.stageHeight - 32;
				  backMaskS.width = stage.stageWidth - 467;
				  showComments.x = stage.stageWidth - 454;
				  showComments.y = stage.stageHeight - 32;
				  fullscreenButton.x = stage.stageWidth - 333;
				  fullscreenButton.y = stage.stageHeight - 36;
				  
				  dividerLine.x = stage.stageWidth - 296;
				  dividerLine.y = stage.stageHeight - 78;
				  viewersText.x = stage.stageWidth - 254;
				  viewersText.y = stage.stageHeight - 57;
				  livestreamlog.x = stage.stageWidth - 255;
				  livestreamlog.y = stage.stageHeight - 32;
				  
		  		resize();
			}
		}
		function resize() {
		  if(isFullscreen) {
			scrollStart = stage.stageWidth + 1;
			livestreamPlayer.width = stage.stageWidth;
			livestreamPlayer.height = stage.stageHeight;
			scrollSize = Math.floor((stage.stageWidth + stage.stageHeight) * 0.025);
			scrollVerticalSeparation = Math.floor((stage.stageWidth + stage.stageHeight) * 0.03);
		  } else {
			scrollStart = stage.stageWidth - 295;
			livestreamPlayer.width = stage.stageWidth - 298;
			livestreamPlayer.height = stage.stageHeight - 81;
			scrollSize = Math.floor((stage.stageWidth + stage.stageHeight) * 0.02);
			scrollVerticalSeparation = Math.floor((stage.stageWidth + stage.stageHeight) * 0.024);
		  }
		}
	}
}