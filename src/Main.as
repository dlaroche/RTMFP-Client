package 
{
	
	import flash.display.Bitmap;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.display.LoaderInfo;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	
	/**
	 * 
	 * @author Daryl LaRoche
	 * @daryllaroche@gmail.com
	 */
	[SWF(backgroundColor="0x071019" , width="320" , height="280")]
	public class Main extends Sprite 
	{
		private var userId : String = "";// "Daryl";
		private var groupName : String = "";// "symfonyControllerTestGroupNew";
		private var rtmfpServer : String = "";// "192.168.1.248/";
		private var rtmpServer : String = "";// "192.168.1.248/oflaDemo/test/";
		private var maxConnections : int = 16; // for rtmfp group size
		private var rtmfpLiveStreamName : String = "";// "darylLivePeerStream";
		private var rtmpLiveStreamName : String = "";// "darylLiveClientServerStream";
		private var rtmfpProtocol : RtmfpProtocol = null;
		private var rtmfpProtocolSubscriber : RtmfpProtocolSubscriber = null;
		private var rtmpProtocol : RtmpProtocol = null;

		public function Main():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// Get vars from webpage
			var flashVars : Object = LoaderInfo(this.stage.loaderInfo).parameters;
			this.userId = flashVars.userId;
			this.groupName = flashVars.groupName;
			this.rtmfpServer = flashVars.rtmfpServer;
			this.rtmpServer = flashVars.rtmpServer;
			this.rtmfpLiveStreamName = flashVars.rtmfpLiveStreamName;
			this.rtmpLiveStreamName = flashVars.rtmpLiveStreamName;
			
			
			
			this.Connect();
			
			
			
			/////////////////////////////
			// JUST FOR TESTING RTMP
			//this.rtmpProtocol = new RtmpProtocol(this.userId, this.groupName, this.rtmpServer, this.rtmpLiveStreamName);
			//this.rtmpProtocol.SetupProtocolDependencies(new UserInterface(), new MediaSettings());
			//this.addChild(this.rtmpProtocol);
			/////////////////////////////
			
			
			
		}
		
		private function Connect():void
		{	
			this.rtmfpProtocol = new RtmfpProtocol(this.userId, this.groupName, this.rtmfpServer, this.maxConnections, this.rtmfpLiveStreamName);
			this.rtmfpProtocol.addEventListener("RtmfpProtocolFailedEvent", this.RtmfpProtocolFailedEventHandler);
			this.rtmfpProtocol.SetupProtocolDependencies(new UserInterface(), new MediaSettings());
			this.addChild(this.rtmfpProtocol);
			
			
			this.rtmfpProtocolSubscriber = new RtmfpProtocolSubscriber(this.userId, this.groupName, this.rtmfpServer, this.maxConnections, this.rtmfpLiveStreamName);
			this.rtmfpProtocolSubscriber.addEventListener("RtmfpProtocolFailedEvent", this.RtmfpProtocolFailedEventHandler);
			this.rtmfpProtocolSubscriber.SetupProtocolDependencies(new UserInterface(), new MediaSettings());
			this.addChild(this.rtmfpProtocolSubscriber);
		}
		
		public function RtmfpProtocolFailedEventHandler(event:Event):void
		{
			// RTMFP FAILED - TRY RTMP
			this.rtmfpProtocol = null;
			var rtmpProtocol:RtmpProtocol = new RtmpProtocol(this.userId, this.groupName, this.rtmpServer, this.rtmpLiveStreamName);
			this.rtmpProtocol.SetupProtocolDependencies(new UserInterface(), new MediaSettings());
			this.addChild(this.rtmpProtocol);
		}

		
		private function UserInterfaceEventHandler(uiButtons:Object):void
		{

		}
		

	}
	
}