package pl.virtua.rss_voice_reader;

import android.app.Activity; //import android.app.Dialog;
import android.os.Bundle;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.PopupWindow;
import android.widget.SeekBar;
import android.widget.Spinner;
import android.widget.ArrayAdapter;
import android.widget.AdapterView;
import android.widget.ToggleButton;
import android.util.Log;

import loquendo.tts.wrapper.LTTSWrapper;

import java.util.ArrayList;
import java.util.Locale;

import pl.virtua.rss_voice_reader.controls.PreferencesManager;
import pl.virtua.rss_voice_reader.controls.Settings;

import android.graphics.drawable.ColorDrawable;

public class SettingsActivity extends Activity {
	
	public static Settings settings;
	
	public static ArrayList<String> voices;
	public static ArrayList<String> texts;
	
	private int voicePosition = -1;
	private Activity self = this;
	private Spinner voiceSpinner;
	private Spinner refreshSpinner;
	private SeekBar volumeSeek;
	private Button button_restore;
	private static SeekBar speedSeek;
	private ToggleButton buttonSounds;
	private ToggleButton buttonAutoplay;
	private PopupWindow pwLoading = null;
	private PopupWindow pwError = null;
	private PopUpListener pwListener = null;
																	// class
	private ColorDrawable container = null;
	
	private VoiceUpdate voiceUpdate = null;// inner class
    
	@Override
	protected void onActivityResult(int requestCode, int resultCode, Intent data) {
		Log.d("LTTSDemo: onActivityResult", "IN - requestCode=" + requestCode);
	}

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		System.setProperty("log.tag."+LTTSWrapper.LOGTAG, "INFO");
		setContentView(R.layout.settings);
		voiceSpinner = (Spinner) findViewById(R.id.list);
		refreshSpinner = (Spinner) findViewById(R.id.refreshList);
		volumeSeek = (SeekBar) findViewById(R.id.volume);
		speedSeek = (SeekBar) findViewById(R.id.speed);
		buttonSounds = (ToggleButton) findViewById(R.id.settings_sounds);
		buttonAutoplay = (ToggleButton) findViewById(R.id.settings_autoplay);
		button_restore = (Button) findViewById(R.id.button_restore);

		self = this;
		
		buttonSounds.setChecked(Settings.sounds);
		buttonAutoplay.setChecked(Settings.autoPlay);
		
		pwLoading = new PopupWindow(self.getLayoutInflater().inflate(
				R.layout.loading, null), 240, 90, false);

		pwError = new PopupWindow(self.getLayoutInflater().inflate(
				R.layout.error, null), 240, 90, false);
		pwListener = new PopUpListener();
		pwError.setTouchInterceptor(pwListener);
		pwError.setTouchable(true);
		container = new ColorDrawable();
		pwError.setBackgroundDrawable(container);

		voiceUpdate = new VoiceUpdate();
		IntentFilter intentFilter = new IntentFilter(Settings.VOICE_UPDATE);
		registerReceiver(voiceUpdate, intentFilter);
		

		String[] myLangs = voices.toArray(new String[0]);
		ArrayAdapter<CharSequence> adapt = new ArrayAdapter<CharSequence>(self,
				R.layout.my_spinner_style, myLangs);
		voiceSpinner.setAdapter(adapt);
		for (int i = 0; i < myLangs.length; i++)
		{
			if (myLangs[i].equalsIgnoreCase(Settings.voice))
				voicePosition = i;
		}
		if (voicePosition >= 0)
			voiceSpinner.setSelection(voicePosition);
		voiceSpinner.setOnItemSelectedListener(listListener);
		if (Settings.myTts.isSpeaking())
			voiceSpinner.setClickable(false);
		
		switch (Settings.refreshTime)
		{
			case 0: // 0 minut
				refreshSpinner.setSelection(0);
				break;	
			case 1: // 1 minuta
				refreshSpinner.setSelection(1);
				break;
			case 5: // 5 minut
				refreshSpinner.setSelection(2);
				break;
			case 10: // 10 minut
				refreshSpinner.setSelection(3);
				break;
			case 15: // 15 minut
				refreshSpinner.setSelection(4);
				break;
			case 30: // 30 minut
				refreshSpinner.setSelection(5);
				break;
			case 60: // 60 minut
				refreshSpinner.setSelection(6);
				break;
		}
		refreshSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
			public void onItemSelected(AdapterView<?> parent, View view,
					int position, long id) {
				switch (position)
				{
					case 0: // 0 minut
						Settings.refreshTime = 0;
						break;	
					case 1: // 1 minuta
						Settings.refreshTime = 1;
						break;
					case 2: // 5 minut
						Settings.refreshTime = 5;
						break;
					case 3: // 10 minut
						Settings.refreshTime = 10;
						break;
					case 4: // 15 minut
						Settings.refreshTime = 15;
						break;
					case 5: // 30 minut
						Settings.refreshTime = 30;
						break;
					case 6: // 60 minut
						Settings.refreshTime = 60;
						break;
				}
				Settings.setSavedPreferenceInt("refreshtime", Settings.refreshTime);
			}

			@Override
			public void onNothingSelected(AdapterView<?> arg0) {
			}
		});
		
		volumeSeek.setProgress(Settings.volume);
		volumeSeek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			
			@Override
			public void onStopTrackingTouch(SeekBar seekBar) {
			}
			
			@Override
			public void onStartTrackingTouch(SeekBar seekBar) {
			}
			
			@Override
			public void onProgressChanged(SeekBar seekBar, int progress,
					boolean fromUser) {
				Settings.myTts.setVolume(progress);
				Settings.volume = progress;
				Settings.setSavedPreferenceInt("volume", progress);
			}
		});
		
		speedSeek.setProgress(Settings.speed);
		speedSeek.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			
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
				FavoritesActivity.setSpeed(progress);
				AboutActivity.setSpeed(progress);
			}
		});
		
		buttonSounds.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
			
			@Override
			public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
				Settings.sounds = isChecked;
				Settings.setSavedPreferenceBool("sounds", isChecked);
			}
		});
		
		buttonAutoplay.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
			
			@Override
			public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
				Settings.autoPlay = isChecked;
				Settings.setSavedPreferenceBool("autoplay", isChecked);
			}
		});
		
		button_restore.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				buttonAutoplay.setChecked(false);
				Settings.autoPlay = false;
				Settings.setSavedPreferenceBool("autoplay", false);
				buttonSounds.setChecked(false);
				Settings.sounds = false;
				Settings.setSavedPreferenceBool("sounds", false);
				speedSeek.setProgress(50);
				Settings.myTts.setSpeed(50);
				Settings.speed = 50;
				Settings.setSavedPreferenceInt("speed", 50);
				FeedsActivity.setSpeed(50);
				FavoritesActivity.setSpeed(50);
				AboutActivity.setSpeed(50);
				volumeSeek.setProgress(50);
				Settings.myTts.setVolume(50);
				Settings.volume = 50;
				Settings.setSavedPreferenceInt("volume", 50);
				refreshSpinner.setSelection(0);
				Settings.refreshTime = 0;
				Settings.setSavedPreferenceInt("refreshtime", 0);
		    	if (Locale.getDefault().getLanguage().equalsIgnoreCase("pl"))
		    	{
		    		voicePosition = voices.indexOf("Zosia [pl]");
		    		voiceSpinner.setSelection(voicePosition);
		    		Settings.setSavedPreferenceString("voice", "Zosia [pl]");
		    	}
		    	else
		    	{
		    		voicePosition = voices.indexOf("Simon [en-GB]");
		    		voiceSpinner.setSelection(voicePosition);
		    		Settings.setSavedPreferenceString("voice", "Simon [en-GB]");
		    	}
			}
		});
	}
	
	public static void setSpeed(int speed)
	{
		if (speedSeek != null)
			speedSeek.setProgress(speed);
	}


	public class PopUpListener implements View.OnTouchListener {
		public boolean onTouch(View v, MotionEvent event) {
			if (event.getAction() == MotionEvent.ACTION_DOWN) {
				pwError.dismiss();
				return true;
			}
			return false;
		}
	}

	private AdapterView.OnItemSelectedListener listListener = new AdapterView.OnItemSelectedListener() {
		public void onItemSelected(AdapterView<?> parent, View view,
				int position, long id) {
			
			voicePosition = position;
			enableViews(false);

			Thread loadVoice = (new Thread(new Settings.LoadVoiceThread(
					voiceSpinner.getSelectedItem().toString(), SettingsActivity.this)));
			loadVoice.setPriority(Thread.MIN_PRIORITY);
			loadVoice.start();
		}

		public void onNothingSelected(AdapterView<?> parent) {
		}
	};

	public class VoiceUpdate extends BroadcastReceiver {
		@Override
		public void onReceive(Context context, Intent intent) {
			enableViews(true);
		}
	};

	private void enableViews(boolean isEnabled) {
		voiceSpinner.setClickable(isEnabled);

		if (isEnabled) {
			pwLoading.dismiss();
		} else {
			setTheme(android.R.style.Theme_Translucent);
			pwLoading.showAsDropDown(voiceSpinner, 15, -45);
		}
	}

	@Override
	protected void onDestroy() {
		unregisterReceiver(voiceUpdate);
		super.onDestroy();
	}
}
