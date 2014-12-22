package 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.net.Responder;
	import flash.utils.Timer;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.ObjectEncoding;
	import flash.net.NetGroup;
	import flash.net.NetGroupReceiveMode;
	import flash.net.GroupSpecifier;
	import flash.media.Video;
	import flash.media.SoundTransform;
	
	/**
	 * 
	 * @author Daryl LaRoche
	 * @daryllaroche@gmail.com
	 */
	public class RtmfpProtocolSubscriber extends Protocol
	{
		// RTMFP TEST CONNECTION SETTINGS
		private const connectionTimeout:int = 5000;
		private var timer:Timer = null;
		// NET EVENTS
		private var server : String = "";
		private var maxPeerConnections : int = 0;
		private var netConnection : NetConnection = null;
		private var subscribeStream : NetStream = null;
		private var netGroup : NetGroup = null;
		// USER
		private var userId : String = "";
		// GROUP
		private var groupName : String = "";
		private var groupId : String = "";
		// CAMERA
		private var mediaSettings : MediaSettings = null;
		private var video : Video = null;
		private var camWidth : int = 320;
		private var camHeight : int = 240;
		private var soundEnabled : Boolean = true;
		private var soundVolumeLevel : Number = 0.5; // 0.0 - 1.0 range
		// USER INTERFACE
		private var userInterface : UserInterface = null;
		// LIVE STREAM VIDEO FEED NAME
		private var liveStreamName : String = "";
		
		public function RtmfpProtocolSubscriber(userId:String, groupName:String, server:String, maxPeerConnections:int, liveStreamName:String):void
		{
			this.userId = (userId && userId.length > 0) ? userId : "01234";
			this.groupName = (groupName && groupName.length > 0) ? groupName : "defaultRtmfpGroup";
			this.server = (server && server.length > 0) ? "rtmfp://" + server : "rtmfp://";
			this.maxPeerConnections = (maxPeerConnections && maxPeerConnections > 0) ? maxPeerConnections : 16;
			this.liveStreamName = (liveStreamName && liveStreamName.length > 0) ? liveStreamName : "defaultLivePeerStream";
			super(this.userId);
			
			this.Connection();
		}
		
		public override function SetupProtocolDependencies(userInterface:UserInterface, mediaSettings:MediaSettings):void
		{
			this.userInterface = userInterface;
			this.mediaSettings = mediaSettings;
			
			// create UI events
			this.userInterface.addEventListener("SoundUserInterfaceEvent", this.SoundUserInterfaceHandler);
		}
		
		/**
		 * NOTE:
		 * Each protocol implements it's own UI due to future features
		 * may possibly change each UI drastically because rtmfp
		 * has unique capabilities.  Move to it's own concrete UI class
		 * and compose the object in the future for better maintanence.
		 */
		public override function CreateUserInterface():void
		{	/*	
			var uiButtons:Object = this.userInterface.getDisplayUserInterface(this.soundEnabled);

			this.addChild(uiButtons.soundButton);
			*/
		}
		
		private function Connection():void
		{		
			this.netConnection = new NetConnection();
			this.netConnection.objectEncoding = ObjectEncoding.AMF3;
			this.netConnection.maxPeerConnections = this.maxPeerConnections;			
			this.netConnection.client = this;
			this.netConnection.addEventListener(NetStatusEvent.NET_STATUS, this.NetStatusHandler);
			this.netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.SecurityErrorHandler);
			this.netConnection.connect(this.server, this.userId, this.groupName); // this is the param order on cumulus
			
			// Determine connection status without waiting default time of 90 seconds
			this.timer = new Timer(this.connectionTimeout, 1);
			this.timer.addEventListener(TimerEvent.TIMER_COMPLETE, this.RtmfpTimeoutHandler);
			this.timer.start();			
		}

		private function SetupGroup():void
		{
			var groupSpecifier:GroupSpecifier = new GroupSpecifier(this.groupName);
			//groupSpecifier.ipMulticastMemberUpdatesEnabled = true;
			//groupSpecifier.addIPMulticastAddress("225.225.0.1:30000"); // multicast address for peer discovery in same subnet
			//groupSpecifier.postingEnabled = true; // posting to entire group
			groupSpecifier.multicastEnabled = true;
			groupSpecifier.routingEnabled = true; // posting to individual peer
			groupSpecifier.serverChannelEnabled = true;
			var groupspecID:String = groupSpecifier.groupspecWithoutAuthorizations();
			this.groupId = groupspecID;
			
			this.netGroup = new NetGroup(this.netConnection, this.groupId);
			this.netGroup.addEventListener(NetStatusEvent.NET_STATUS, this.NetStatusHandler);
		}
		
		private function SetupStream():void
		{
			this.subscribeStream = new NetStream(this.netConnection, this.groupId);
			this.subscribeStream.addEventListener(NetStatusEvent.NET_STATUS, this.NetStatusHandler);
			this.subscribeStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.AsyncErrorHandler);
			this.subscribeStream.onPeerConnect(this.subscribeStream);
			this.subscribeStream.client = this;
		}
		
		private function Subscribe():void
		{
			var transform:SoundTransform = new SoundTransform(0, this.soundVolumeLevel);
			transform.volume = this.soundVolumeLevel;
			
			this.video = new Video(this.camWidth, this.camHeight);
			this.video.attachNetStream(this.subscribeStream);
			this.subscribeStream.play(this.liveStreamName);
			this.addChild(video);
		}
		
		private function ModifySoundVolumeLevel():void
		{
			var transform:SoundTransform = new SoundTransform();
			if (this.soundEnabled)
				transform.volume = 1.0;// this.soundVolumeLevel;
			else transform.volume = 0.0;
			this.subscribeStream.soundTransform = transform;
		}
		
		private function RtmfpTimeoutHandler(event:TimerEvent):void
		{
			trace("RTMFP TIMER EXPIRED - CONNECTION ERROR OCCURED");
			dispatchEvent(new Event("RtmfpProtocolFailedEvent"));
			this.netConnection.close();
			this.netConnection = null;
		}
		
		private function SoundUserInterfaceHandler(event:Event):void
		{
			this.soundEnabled = (this.soundEnabled) ? false : true;
			this.CreateUserInterface();
			this.ModifySoundVolumeLevel();
		}

		private function AsyncErrorHandler(event:AsyncErrorEvent):void { trace(event.errorID); }
		private function SecurityErrorHandler(event:SecurityErrorEvent):void { trace(event.errorID); }
		
		private function NetStatusHandler(event:NetStatusEvent):void
		{
			if (this.timer) 
			{ 
				this.timer.stop(); 
				this.timer = null;
			}
			
			trace("RTMFP -> " + event.info.code);
			switch (event.info.code)
			{
				case "NetConnection.Connect.Success":
					this.SetupGroup();
                    break;
				case "NetGroup.Connect.Success":
					this.SetupStream();
					break;
				case "NetGroup.Neighbor.Connect":
					break;
				case "NetGroup.Neighbor.Disconnect":
					trace(" ---> NetGroup Neighbor Count = " + this.netGroup.neighborCount);
					break;
				case "NetGroup.SendTo.Notify":
					break;
				case "NetGroup.MulticastStream.PublishNotify":
					trace(" ---> Multicast Publish Notify ---> " + event.info.name);
					break;
				case "NetGroup.Posting.Notify":
					break;
				case "NetStream.Connect.Success":
					this.CreateUserInterface();
					this.Subscribe();
					//this.netConnection.call("getParticipants", new Responder(onResult, onStatus), "symfonyControllerTestGroupNew");
					break;
				case "NetStream.Play.Start":
                    break;
				default:
					break;
			}
		}
		
		///////////// RPC CALLS /////////////
		public function participantChanged():void
		{
			//trace("inside participant Changed");
			//rtmfpConnection.call("getParticipants", new Responder(onResult, onStatus), this.groupName);
			//rtmfpConnection.call("sendMessage", new Responder(onResult, onStatus), this.groupName, 9876543, "test message");
			
		}
		
		public function onMessage(id:int, message:String):void
		{
			//trace("inside onMessage" + " :id: " + id + " :message: " + message);
		}
		
		
		

//################################################################################################
////////////////////////////////// TESTING RPC FROM CUMULUS //////////////////////////////////////

		
		//private function close():void { rtmfpConnection.close() }
		private function onStatus(status:Object):void { }//trace("-- status is: " + status.description); }
		private function onResult(response:Object):void 
		{
			/*
			var userNamePublishing : String = "daryl";	
			trace("-- length is: " + response.length);
			
			var totalParticipants:int = response.length;
			trace("---------------------------");
			trace("------ USERS IN GROUP ------");
			for (var i:int = 0; i < totalParticipants; i++)
			{
				var test:Object = response[i];
				if (this.userNamePublishing == test.userName) this.peerId = test.farID;
				//this.peerId = test.farID;
				
				trace("-- GROUP " + test.meeting + " --");
				trace("---------------------------");
				trace("-- array index is: " + i);
				trace("-- response username is: " + test.userName);
				trace("-- response meeting is: " + test.meeting);
				trace("-- response server farID / client nearID is: " + test.farID);
				trace("---------------------------");
				
				
			}
			*/

			
			///////////////////////////////////////////////////////////////////////
			var ui:UserInterface = new UserInterface();
			var nearIdLabel:Sprite = ui.createLabel("nearId is: " + this.netConnection.nearID, 50, 50, 0, 100);
			var groupIdLabel:Sprite = ui.createLabel("gID: " + this.groupId + "\n", 150, 50, 200, 50);
			this.addChild(nearIdLabel);
			this.addChild(groupIdLabel);
			///////////////////////////////////////////////////////////////////////
			
		}
//################################################################################################


	}
	
}