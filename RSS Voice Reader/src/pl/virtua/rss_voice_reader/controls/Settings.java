package pl.virtua.rss_voice_reader.controls;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.Locale;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Environment;
import android.util.Log;
import loquendo.tts.wrapper.LTTSWrapper;

public class Settings {

	public static LTTSWrapper myTts = null;
	public static TTSState state = TTSState.UNINITIALIZED;
	public static int volume = 50;
	public static int speed = 50;
	public static String voice = "Zosia [pl]";
	public static String startPage = "http://google.com";
	public static boolean filesCopied = false;
	public static boolean sounds = false;
	public static boolean autoPlay = false;
	public static int refreshTime = 0;

	public static enum TTSState {
		UNINITIALIZED, IDLE, SPEAKING, PAUSED
	}

	public static final String TEXT_PATH = "/sdcard/RSSVRLoquendoTTS/Text/";
	public static final String VOICE_UPDATE = "loquendo.tts.lttsdemo.VOICE_UPDATE";
	public static final String VOICE_ERROR = "loquendo.tts.lttsdemo.VOICE_ERROR";
	public static final String SPEECH_COMPLETED = "loquendo.tts.lttsdemo.SPEECH_COMPLETED";
	public static final String TTSEVT_SENTENCE = "loquendo.tts.lttsdemo.TTSEVT_SENTENCE";
    
    public static String getSavedPreferenceString(String key)
    {
    	if (Locale.getDefault().getLanguage().equalsIgnoreCase("pl"))
    		return PreferencesManager.sharedPreferences.getString(key, "Zosia [pl]");
    	else
    		return PreferencesManager.sharedPreferences.getString(key, "Simon [en-GB]");
    }
    
    public static String getSavedPreferenceAddressString(String key)
    {
    	if (Locale.getDefault().getLanguage().equalsIgnoreCase("pl"))
    		return PreferencesManager.sharedPreferences.getString(key, "http://google.pl");
    	else
    		return PreferencesManager.sharedPreferences.getString(key, "http://google.com");
    }
    
    public static void setSavedPreferenceString(String key, String value)
    {
    	SharedPreferences.Editor editor = PreferencesManager.sharedPreferences.edit();
    	editor.putString(key, value);
    	editor.commit();
    }
    
    public static boolean getSavedPreferenceBool(String key)
    {
    	return PreferencesManager.sharedPreferences.getBoolean(key, false);
    }
    
    public static void setSavedPreferenceBool(String key, boolean value)
    {
    	SharedPreferences.Editor editor = PreferencesManager.sharedPreferences.edit();
    	editor.putBoolean(key, value);
    	editor.commit();
    }
    
    public static int getSavedPreferenceInt(String key)
    {
    	return PreferencesManager.sharedPreferences.getInt(key, 50);
    }
    
    public static void setSavedPreferenceInt(String key, int value)
    {
    	SharedPreferences.Editor editor = PreferencesManager.sharedPreferences.edit();
    	editor.putInt(key, value);
    	editor.commit();
    }
    
	/**
	 * Set up configuration files. _IMPORTANT_
	 */
	public void initResFiles() {
		String packName = "pl.virtua.rss_voice_reader";
		String dataDirStr = Environment.getExternalStorageDirectory().getAbsolutePath() + "/RSSVRLoquendoTTS/data";
		String licDirStr = Environment.getExternalStorageDirectory().getAbsolutePath() + "/RSSVRLoquendoTTS/pl.virtua.talkingBrowser";
		String[] defSessData = new String[6];
		
		File dataDir = new File(dataDirStr);
		if (dataDir.exists())
			defSessData[0] = "\"DataPath\" = \""+dataDirStr+"\"";
		else
			defSessData[0] = "\"DataPath\" = \"/RSSVRLoquendoTTS/data\"";

		/*
		 * config file default.session must be put into
		 * the private application folder. License code file into the SD card 
		 */
		File defSessFile = new File("/data/data/" + packName
				+ "/default.session");

		defSessData[1] = "\"LibraryPath\" = \"/data/data/" + packName
				+ "/lib\"";
		defSessData[2] = "\"LicenseFile\" = \""+licDirStr+"/LicenseCode.txt\"";
		defSessData[3] = "\"LogFile\" = " + Environment.getExternalStorageDirectory().getAbsolutePath() + "\"/RSSVRLoquendoTTS/error_log.txt\"";
		//defSessData[4]="\"TraceFile\" = \"/sdcard/LoquendoTTS/trace_log.txt\"";
		defSessData[4] = "\"TraceFile\" = \"\"";
		defSessData[5]="\"TextFormat\" = \"autodetect\"";

		File licDir = new File(licDirStr);
		File defSessDir = new File(defSessFile.getParent());
		try {
			licDir.mkdir();
			defSessDir.mkdir();
			if (!defSessFile.createNewFile()) {
				defSessFile.delete();
				defSessFile.createNewFile(); // create from scratch
			}
			PrintWriter pw = new PrintWriter(defSessFile);
			for (int i = 0; i < defSessData.length; i++) {
				pw.println(defSessData[i]);
			}
			pw.close();

		} catch (IOException e) {
			e.printStackTrace();
			Log.i("mobiks", e.getMessage());
		} catch (SecurityException se) {
			se.printStackTrace();
			Log.i("mobiks", se.getMessage());
		}

	}
	


	public static class LoadVoiceThread implements Runnable {
		String voiceLabel = "";
		Activity parent;

		public LoadVoiceThread(String label, Activity parent) {
			voiceLabel = label;
			this.parent = parent;
		}

		public void run() {
			try {
				String myVoice = voiceLabel.substring(0, voiceLabel
						.indexOf(" "));
				String languageCode = voiceLabel.substring(voiceLabel
						.indexOf("[") + 1, voiceLabel.length() - 1);
				if (myVoice == null)
					return;
				voice = voiceLabel;
				setSavedPreferenceString("voice", voice);
				Log.d("LTTSDemo,LoadVoiceThread", "setVoice(" + myVoice + ")");
				Settings.myTts.setVoice(myVoice);

				Settings.myTts.setLanguage(languageCode);

				Intent intent = new Intent(VOICE_UPDATE);
				parent.sendBroadcast(intent);

			} catch (Exception e) {
			}
		}
	};
}
