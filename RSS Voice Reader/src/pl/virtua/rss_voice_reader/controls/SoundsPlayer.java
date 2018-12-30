package pl.virtua.rss_voice_reader.controls;

import pl.virtua.rss_voice_reader.R;
import android.content.Context;
import android.media.MediaPlayer;

public class SoundsPlayer {

	private static MediaPlayer mp;
	
	public static void playSound_Click(Context context)
	{
		if (Settings.sounds)
		{
			mp = MediaPlayer.create(context, R.raw.click2);
		    mp.start();
		    while (mp.isPlaying()) { 
		         // donothing 
		    };
		    mp.release();
		}
	}
}
