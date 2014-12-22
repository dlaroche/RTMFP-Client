package 
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.media.H264VideoStreamSettings;
	import flash.media.SoundCodec;
	import flash.net.Responder;
	import flash.media.Video;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.net.NetStream;
	import flash.net.NetConnection;
	
	/**
	 * ...
	 * @author Daryl LaRoche
	 * @daryllaroche@gmail.com
	 */
	public class RtmpProtocol extends Protocol 
	{
		// NET EVENTS
		private var server : String = "";
		private var netConnection : NetConnection = null;
		private var publishStream : NetStream = null;
		// USER
		private var userId : String = "";
		private var groupName : String = "";
		// CAMERA
		private var mediaSettings : MediaSettings = null;
		private var video : Video;
		// CAMERA FUNCTIONALITY
		private var cameraEnabled : Boolean = false;
		private var microphoneEnabled : Boolean = false;
		// USER INTERFACE
		private var userInterface : UserInterface = null;
		// LIVE STREAM VIDEO FEED NAME
		private var liveStreamName : String = "";


		public function RtmpProtocol(userId:String, groupName:String, server:String, liveStreamName:String):void
		{
			this.userId = (userId && userId.length > 0) ? userId : "56789";
			this.groupName = (groupName && groupName.length > 0) ? groupName : "defaultRtmpGroup";
			this.server = (server && server.length > 0) ? "rtmp://" + server : "rtmp://localhost/";
			this.liveStreamName = (liveStreamName && liveStreamName.length > 0) ? liveStreamName : "defaultLiveClientServerStream";
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
			this.netConnection.addEventListener(NetStatusEvent.NET_STATUS, this.NetStatusHandler);
			this.netConnection.connect(this.server);
			this.netConnection.client = { onBWDone: function():void { trace("onBWDone"); } };
		}

		private function SetupStream():void
		{
			this.publishStream = new NetStream(this.netConnection);
			this.publishStream.bufferTime = 0;
			this.publishStream.addEventListener(NetStatusEvent.NET_STATUS, this.NetStatusHandler);
			this.publishStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.AsyncErrorHandler);
			this.publishStream.client = { onMetaData:function(obj:Object):void { trace("onMetaData"); } };
			
			this.Publish();
			this.CreateUserInterface();
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
					this.publishStream.attachAudio(microphone);
					microphone.codec = SoundCodec.SPEEX;
				}
			}
			
			this.publishStream.publish(this.liveStreamName, "live");
			//this.publishStream.publish(this.liveStreamName, "record"); // live stream is recorded to server
		}
		
		/****************** EVENT HANDLERS ******************/
		private function CameraUserInterfaceHandler(event:Event):void
		{
			this.cameraEnabled = (this.cameraEnabled) ? false : true;
			this.SetupStream();
		}
		
		private function MicrophoneUserInterfaceHandler(event:Event):void
		{			
			this.microphoneEnabled = (this.microphoneEnabled) ? false : true;
			this.SetupStream();
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
		
		private function NetStatusHandler(event:NetStatusEvent):void 
		{
			trace("RTMP -> " + event.info.code);
            switch (event.info.code) 
			{
                case "NetConnection.Connect.Success":
					this.SetupStream();
                    break;
				case "NetStream.Connect.Success":
					break;
				case "NetStream.Play.Start":
                    break;
				case "NetStream.Publish.BadName":
					break;
				case "NetStream.Play.StreamNotFound":
                    trace("Unable to locate video");
                    break;
				default:
					break;
            }
        }
	}
}