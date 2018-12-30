package pl.virtua.rss_voice_reader.controls;

import android.content.Context;
import android.content.SharedPreferences;

public class PreferencesManager {

	public static SharedPreferences sharedPreferences;
	
	public static void initPreferences(Context context)
	{
        sharedPreferences = context.getSharedPreferences("rssvr_settings", 0);
	}

    public static String getSavedPreferenceString(String key)
    {
    	String str = sharedPreferences.getString(key, "");
    	return sharedPreferences.getString(key, "");
    }
    
    public static void setSavedPreferenceString(String key, String value)
    {
    	SharedPreferences.Editor editor = sharedPreferences.edit();
    	editor.putString(key, value);
    	editor.commit();
    }
}
