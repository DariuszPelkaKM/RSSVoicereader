package pl.virtua.rss_voice_reader;

import java.util.ArrayList;
import java.util.Locale;

import loquendo.tts.engine.TTSConst;
import loquendo.tts.engine.TTSEvent;
import loquendo.tts.wrapper.LTTSWrapper.ErrorListener;
import loquendo.tts.wrapper.LTTSWrapper.EventListener;
import loquendo.tts.wrapper.LTTSWrapper.SpeechCompletedListener;

import pl.virtua.rss_voice_reader.controls.PageExtractor;
import pl.virtua.rss_voice_reader.controls.Settings;
import pl.virtua.rss_voice_reader.controls.SoundsPlayer;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;
import android.view.animation.Animation;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.ViewFlipper;

public class AboutActivity extends Activity {

	private TextView link;
	private LinearLayout main;
	private ViewFlipper switcher;
	private WebView page;
	private Button buttonBack;
	private static SeekBar seekbar_speed;
	private Button button_stop;
	private Button button_play;
	
	private VoiceUpdate voiceUpdate = null;// inner class
	private VoiceError voiceError = null;// inner class
	private EventReceiver eventReceiver = null;// inner class
	private SpeechCompletedReceiver speechCompletedReceiver = null;// inner
	
	private String textToTalk = "";
    private final Handler handler = new Handler();
	private ProgressDialog progressDialog;
	
	private int animationStep = 1;
	private boolean animate = false;
	private Animation animation;
	private ArrayList<String> speechQueue;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
	    super.onCreate(savedInstanceState);
	    setContentView(R.layout.about);
        
        main = (LinearLayout) findViewById(R.id.about_main);
        link = (TextView) findViewById(R.id.about_link);
        
        switcher = (ViewFlipper) findViewById(R.id.about_switcher);
        page = (WebView) findViewById(R.id.rss_page);
        buttonBack = (Button) findViewById(R.id.back);
        seekbar_speed = (SeekBar) findViewById(R.id.seekbar_about);
        button_stop = (Button) findViewById(R.id.button_stop_about);
        button_play = (Button) findViewById(R.id.button_play_about);
        
        page.getSettings().setJavaScriptEnabled(true);
		page.setWebViewClient(new RSSVRWebViewClient());
		
		speechQueue = new ArrayList<String>();
		
		seekbar_speed.setProgress(Settings.speed);
        
        if (Locale.getDefault().getLanguage().equalsIgnoreCase("pl"))
        	main.setBackgroundResource(R.drawable.about_pl);
        
        link.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				SoundsPlayer.playSound_Click(AboutActivity.this);
	     		page.loadUrl(link.getText().toString());
		    	switcher.showNext();
			}
		});
        
        Typeface tf = Typeface.createFromAsset(getAssets(), "fonts/League_Gothic.ttf");
        link.setTypeface(tf);
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
        		LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
        lp.setMargins(20, getWindowManager().getDefaultDisplay().getHeight() * 93 / 128, 0, 0);
        link.setLayoutParams(lp);
        
        buttonBack.setOnClickListener(new Button.OnClickListener() 
        {
            public void onClick(View v) 
            {
            	Settings.myTts.stop();
				SoundsPlayer.playSound_Click(AboutActivity.this);
            	switcher.showPrevious();
            }
        }); 

		button_stop.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (Settings.myTts.isSpeaking())
				{
					Settings.myTts.stop();
					Settings.state = Settings.TTSState.IDLE;
	    			setPlayButtonString(R.string.play);
					button_play.setBackgroundResource(R.drawable.play_bg);
				}
			}
		});
        
        button_play.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (!animate)
				{
					progressDialog = ProgressDialog.show(AboutActivity.this, "", "");
					new SpeakThread().start();
				}
			}
		});
        
        seekbar_speed.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			
			@Override
			public void onStopTrackingTouch(SeekBar seekBar) {
				
			}
			
			@Override
			public void onStartTrackingTouch(SeekBar seekBar) {
				
			}
			
			@Override
			public void onProgressChanged(SeekBar seekBar, int progress,
					boolean fromUser) {
				Settings.myTts.setSpeed(progress);
				Settings.speed = progress;
				Settings.setSavedPreferenceInt("speed", progress);
				FeedsActivity.setSpeed(progress);
				SettingsActivity.setSpeed(progress);
				FavoritesActivity.setSpeed(progress);
			}
		});
        
		animation = new Animation();
		animation.start();
	}
    
    @Override
    protected void onPause()
    {
    	super.onPause();
    	Settings.myTts.stop();
    	Settings.state = Settings.TTSState.IDLE;
 			unregisterReceiver(voiceUpdate);
 			unregisterReceiver(voiceError);
 			unregisterReceiver(eventReceiver);
 			unregisterReceiver(speechCompletedReceiver);
    }
    
    @Override
    protected void onResume()
    {
    	super.onResume();

		Settings.myTts.setOnErrorListener(ttsErrorListener);
		Settings.myTts.setOnEventListener(ttsEventListener);
		Settings.myTts.setOnSpeechCompletedListener(speechCompletedListener);

		voiceUpdate = new VoiceUpdate();
		IntentFilter intentFilter = new IntentFilter(Settings.VOICE_UPDATE);
		registerReceiver(voiceUpdate, intentFilter);

		voiceError = new VoiceError();
		IntentFilter errorFilter = new IntentFilter(Settings.VOICE_ERROR);
		registerReceiver(voiceError, errorFilter);

		eventReceiver = new EventReceiver();
		IntentFilter eventFilter = new IntentFilter(Settings.TTSEVT_SENTENCE);
		registerReceiver(eventReceiver, eventFilter);

		speechCompletedReceiver = new SpeechCompletedReceiver();
		IntentFilter scFilter = new IntentFilter(Settings.SPEECH_COMPLETED);
		registerReceiver(speechCompletedReceiver, scFilter);
    }

 	private ErrorListener ttsErrorListener = new ErrorListener() {
 		public void onError(String msg) {
 			if (msg.contains("Voice") || msg.contains("Language")) {
 				Intent intent = new Intent(Settings.VOICE_ERROR);
 				AboutActivity.this.sendBroadcast(intent);
 			} else {
 				Settings.state = Settings.TTSState.IDLE;
 			}
 		}
 	};

 	private EventListener ttsEventListener = new EventListener() {
 		public void onEvent(TTSEvent event) {
 			String msg = event.getReason().toString();
 			Object data = event.getData();
 			if(data != null) msg += " data="+data.toString();
 			if (event.getReason().equals(TTSConst.TTSEVT_SENTENCE)) {
 				Intent intent = new Intent(Settings.TTSEVT_SENTENCE);
 				AboutActivity.this.sendBroadcast(intent);
 			} else if (event.getReason().equals(TTSConst.TTSEVT_AUDIOSTART)) {
 				Settings.state = Settings.TTSState.SPEAKING;
 				handler.post(hideFavProgressDialog);
 			}
 		}
 	};

 	private SpeechCompletedListener speechCompletedListener = new SpeechCompletedListener() {
 		public void onSpeechCompleted() {
 			Intent intent = new Intent(Settings.SPEECH_COMPLETED);
 			AboutActivity.this.sendBroadcast(intent);
 			Settings.state = Settings.TTSState.IDLE;
 		}
 	};

 	public class VoiceError extends BroadcastReceiver {
 		@Override
 		public void onReceive(Context context, Intent intent) {

         	AlertDialog alertDialog;
     		alertDialog = new AlertDialog.Builder(AboutActivity.this).create();
     		alertDialog.setMessage("B��d g�osu");
     		alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
 				
 				public void onClick(DialogInterface dialog, int which) {
 				}
 			});
     		alertDialog.show();
 		}
 	};

 	public class VoiceUpdate extends BroadcastReceiver {
 		@Override
 		public void onReceive(Context context, Intent intent) {
 		}
 	};

 	public class EventReceiver extends BroadcastReceiver {
 		@Override
 		public void onReceive(Context context, Intent intent) {
 		}

 		private int findSentence(String myText, int position) {
 			int iStop = myText.indexOf(".", position);
 			if (iStop < 0) {
 				iStop = myText.length();
 			} else
 				while (iStop == position + 1) {
 					position++;
 					iStop = myText.indexOf(".", position);
 				}
 			int iQst = myText.indexOf("?", position);
 			while (iQst == position + 1) { 
 				position++;
 				iQst = myText.indexOf("?", position);
 			}
 			if (iQst > 0 && iQst < iStop)
 				iStop = iQst;

 			int iExcl = myText.indexOf("!", position);
 			while (iExcl == position + 1) {
 				position++;
 				iExcl = myText.indexOf("!", position);
 			}
 			if (iExcl > 0 && iExcl < iStop)
 				iStop = iExcl;

 			int iSCol = myText.indexOf(";", position);
 			if (iSCol > 0 && iSCol < iStop)
 				iStop = iSCol;

 			int iCol = myText.indexOf(":", position);
 			if (iCol > 0 && iCol < iStop)
 				iStop = iCol;

 			if (iStop == position) {
 				iStop = findSentence(myText, ++iStop);
 			}
 			++iStop;
 			if (iStop > myText.length() || iStop < 0)
 				iStop = myText.length();
 			return iStop;
 		}
 	};
 	
 	public class SpeechCompletedReceiver extends BroadcastReceiver {
 		@Override
 		public void onReceive(Context context, Intent intent) {
 			Log.d("browser", "speechQueue.size="
 					+ speechQueue.size());
 			if (speechQueue.size() > 0) {
 				String myText = speechQueue.get(0);
 				speechQueue.remove(0);
 				synchronized (this) { 
 					try {
 						wait(10);
 					} catch (InterruptedException e) {
 						e.printStackTrace();
 					}
 				}
 				Settings.myTts.speak(myText);
 			} else {
 				Settings.state = Settings.TTSState.IDLE;
    			setPlayButtonString(R.string.play);
 				button_play.setBackgroundResource(R.drawable.play_bg);
 			}
 		}
 	};
	
	public static void setSpeed(int speed)
	{
		if (seekbar_speed != null)
			seekbar_speed.setProgress(speed);
	}
	
	private class RSSVRWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return true;
        } 
        
        @Override
        public void onPageStarted(WebView view, String url, Bitmap favIcon)
        {
        	Settings.myTts.stop();
        	animate = true;
        }
        
        @Override  
        public void onPageFinished(WebView view, String url)  
        {  
        	animate = false;
        } 
    }private class SpeakThread extends Thread {

    	public void run() 
    	{
			if (Settings.state == Settings.TTSState.SPEAKING) {
				Settings.myTts.pause();
				Settings.state = Settings.TTSState.PAUSED;
				handler.post(hideFavProgressDialog);
			} 
			else if (Settings.state == Settings.TTSState.IDLE)
			{
				textToTalk = PageExtractor.getPageHTML(AboutActivity.this, page.getUrl());
				if (!textToTalk.equalsIgnoreCase(""))
					Settings.myTts.speak(textToTalk);
				else
					handler.post(hideFavProgressDialog);
			}
			else if (Settings.state == Settings.TTSState.PAUSED)
			{
				Settings.myTts.resume();
				Settings.state = Settings.TTSState.SPEAKING;
				handler.post(hideFavProgressDialog);
			}
    	}
	}
    
    private Runnable hideFavProgressDialog = new Runnable() {
    	public void run() {
    		progressDialog.dismiss();
    		if (Settings.myTts.isSpeaking()) {
    			setPlayButtonString(R.string.play);
 				button_play.setBackgroundResource(R.drawable.play_bg);
			} else {
    			setPlayButtonString(R.string.pause);
				button_play.setBackgroundResource(R.drawable.pause);
			}
    	}
    };
    
    public void test() {}
    
    private class Animation extends Thread {

    	public boolean interrupted = false;
    	
    	public void run() {

    		while(!interrupted)
    		{
	    		handler.post(setPlayButtonImage);
	    		try {
	    			Thread.sleep(500);
	    		} catch (Exception e) {}
    		}
    	}
		
    };
 	
 	private void setPlayButtonString(int resId)
 	{
	 	if (!button_play.getText().toString().equalsIgnoreCase(getString(resId)))
	 		button_play.setText(resId);
 	}
    
    private Runnable setPlayButtonImage = new Runnable() {
		
		@Override
		public void run() {
			if (animate)
    		{
				setPlayButtonString(R.string.wait);
	    		switch (animationStep) {
	    			case 1:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait1);
	    				animationStep = 2;
	    			}
	    			break;
	    			case 2:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait2);
	    				animationStep = 3;
	    			}
	    			break;
	    			case 3:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait3);
	    				animationStep = 4;
	    			}
	    			break;
	    			case 4:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait4);
	    				animationStep = 5;
	    			}
	    			case 5:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait5);
	    				animationStep = 6;
	    			}
	    			break;
	    			case 6:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait6);
	    				animationStep = 7;
	    			}
	    			break;
	    			case 7:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait7);
	    				animationStep = 8;
	    			}
	    			break;
	    			case 8:
	    			{
	    				button_play.setBackgroundResource(R.drawable.wait8);
	    				animationStep = 1;
	    			}
	    			break;
	    		}
	    	} else {
	    		if (Settings.state == Settings.TTSState.SPEAKING)
	    		{
	    			setPlayButtonString(R.string.pause);
	    			button_play.setBackgroundResource(R.drawable.pause);
	    		}
	    		else {
	    			setPlayButtonString(R.string.play);
	    			button_play.setBackgroundResource(R.drawable.play_bg);
	    		}
	    	}
		}
	};
}
