package 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.net.Responder;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.ObjectEncoding;
	import flash.net.NetGroup;
	import flash.net.NetGroupReceiveMode;
	import flash.net.GroupSpecifier;
	import flash.media.Video;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.media.SoundMixer;
	
	/**
	 * 
	 * @author Daryl LaRoche
	 * @daryllaroche@gmail.com
	 */
	public class RtmfpProtocol extends Protocol
	{
		// TEST FOR PEER TO PEER CONNECTION ABILITY SETTINGS
		private const connectionTimeout:int = 5000;
		private var timer:Timer = null;
		// NET EVENTS
		private var server : String = "";
		private var maxPeerConnections : int = 0;
		private var netConnection : NetConnection = null;
		private var publishStream : NetStream = null;
		private var netGroup : NetGroup = null;
		// USER
		private var userId : String = "";
		// GROUP
		private var groupName : String = "";
		private var groupId : String = "";
		// CAMERA
		private var mediaSettings : MediaSettings = null;
		private var video : Video = null;
		// CAMERA FUNCTIONALITY
		private var cameraEnabled : Boolean = false;
		private var microphoneEnabled : Boolean = false;
		// USER INTERFACE
		private var userInterface : UserInterface = null;
		// LIVE STREAM VIDEO FEED NAME
		private var liveStreamName : String = "";
		
		public function RtmfpProtocol(userId:String, groupName:String, server:String, maxPeerConnections:int, liveStreamName:String):void
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
			this.userInterface.addEventListener("CameraUserInterfaceEvent", this.CameraUserInterfaceHandler);
			this.userInterface.addEventListener("MicrophoneUserInterfaceEvent", this.MicrophoneUserInterfaceHandler);
			this.userInterface.addEventListener("CameraAndMicrophoneUserInterfaceEvent", this.CameraAndMicrophoneUserInterfaceHandler);
		}
		
		/**
		 * NOTE:
		 * Each protocol implements it's own UI due to future features
		 * may possibly change each UI drastically because rtmfp
		 * has unique capabilities.  Move to it's own concrete UI class
		 * and compose the object in the future for better maintanence.
		 */
		public override function CreateUserInterface():void
		{			
			var uiButtons:Object = this.userInterface.getCameraUserInterface(this.cameraEnabled, this.microphoneEnabled);
		
			this.addChild(uiButtons.cameraButton);
			this.addChild(uiButtons.microphoneButton);
			this.addChild(uiButtons.cameraAndMicrophoneButton);
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
			this.publishStream = new NetStream(this.netConnection, this.groupId);
			this.publishStream.addEventListener(NetStatusEvent.NET_STATUS, this.NetStatusHandler);
			this.publishStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.AsyncErrorHandler);
			this.publishStream.onPeerConnect(this.publishStream);
			this.publishStream.client = this;
		}

		protected override function Publish():void
		{
			if (this.cameraEnabled)
			{	
				var camera:Camera = Camera.getCamera("0");
				if (camera !== null)
				{
					this.publishStream.attachCamera(camera);
					this.publishStream.videoStreamSettings = mediaSettings.VideoSettings();
				}
			}
			
			if (this.microphoneEnabled)
			{	
				var microphone:Microphone = Microphone.getMicrophone();
				if (microphone !== null)
				{
					microphone.codec = SoundCodec.SPEEX;
					this.publishStream.attachAudio(microphone);
				}
			}
			
			/*
			var c:Object = new Object();
			c.onPeerConnect = function(subscriber:NetStream):Boolean
			{
			
				//trace("onPeerConnect call: " + subscriber.farID);
				return true;
			}
			this.publishStream.client = c;
			*/
			
			this.publishStream.publish(this.liveStreamName);
		}
		
		/****************** EVENT HANDLERS ******************/
		private function CameraUserInterfaceHandler(event:Event):void
		{
			this.cameraEnabled = (this.cameraEnabled) ? false : true;
			this.SetupStream(); // create new stream for each user action
		}
		
		private function MicrophoneUserInterfaceHandler(event:Event):void
		{			
			this.microphoneEnabled = (this.microphoneEnabled) ? false : true;
			this.SetupStream(); // create new stream for each user action
		}
		
		private function CameraAndMicrophoneUserInterfaceHandler(event:Event):void
		{
			// user sets either both on or off when this event fires
			// to keep in sync since user can control each individually
			if (this.cameraEnabled && this.microphoneEnabled) 
			{
				this.cameraEnabled = false;
				this.microphoneEnabled = false;
			}
			else if (this.cameraEnabled && !this.microphoneEnabled)
			{
				this.cameraEnabled = false;
				this.microphoneEnabled = true;
			}
			else if (!this.cameraEnabled && this.microphoneEnabled)
			{
				this.cameraEnabled = true;
				this.microphoneEnabled = false;
			}
			else
			{
				this.cameraEnabled = true;
				this.microphoneEnabled = true;
			}
			
			this.SetupStream(); // create new stream for each user action
		}

		private function AsyncErrorHandler(event:AsyncErrorEvent):void { trace(event.errorID); }
		private function SecurityErrorHandler(event:SecurityErrorEvent):void { trace(event.errorID); }
		
		private function RtmfpTimeoutHandler(event:TimerEvent):void
		{
			trace("RTMFP TIMER EXPIRED - CONNECTION ERROR OCCURED");
			dispatchEvent(new Event("RtmfpProtocolFailedEvent"));
			this.netConnection.close();
			this.netConnection = null;
		}

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
					this.Publish();
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
/////////////// END TESTING REMOTE PROCEDURAL CALL FROM CUMULUS //////////////////////////////////////


	}
	
}