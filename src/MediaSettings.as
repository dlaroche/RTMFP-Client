package  
{
	import flash.media.Video;
	import flash.media.SoundCodec;
	import flash.media.H264VideoStreamSettings;
	import flash.media.VideoStreamSettings;
	import flash.media.H264Level;
	import flash.media.H264Profile;

	/**
	 * ...
	 * @author laroche
	 */
	public class MediaSettings
	{
		public static const CAM_BANDWIDTH : Number = 0;
		public static const CAM_QUALITY_PERCENTAGE : Number = 90;
		public static const CAM_FPS : Number = 15;
		public static const CAM_KEY_FRAME_INTERVAL : Number = 35;
		public static const CAM_WIDTH : Number = 240;
		public static const CAM_HEIGHT : Number = 220;
		
		private var filename : String = "testanotherview";
		private var camBandWidth : Number = CAM_BANDWIDTH;
		private var camQualityPercentage : Number = CAM_QUALITY_PERCENTAGE;
		private var camFPS : Number = CAM_FPS;
		private var camKeyFrameInterval : Number = CAM_KEY_FRAME_INTERVAL;
		private var camWidth : Number = CAM_WIDTH;
		private var camHeight : Number = CAM_HEIGHT;
		private var h264Settings : H264VideoStreamSettings;
		
		public function MediaSettings() 
		{
			
		}
		
		public function VideoSettings():H264VideoStreamSettings
		{
			var h264Settings:H264VideoStreamSettings = new H264VideoStreamSettings();
			h264Settings.setProfileLevel(H264Profile.BASELINE, H264Level.LEVEL_3);
			h264Settings.setQuality(this.camBandWidth, this.camQualityPercentage);
			h264Settings.setKeyFrameInterval(this.camKeyFrameInterval);
			h264Settings.setMode(this.camWidth, this.camHeight, this.camFPS);
			
			return h264Settings;
		}
		
		public function AudioSettings():void
		{
		
		}
	}

}