package pl.virtua.rss_voice_reader;

import android.app.ActivityGroup;
import android.content.Intent;
import android.content.res.Resources;
import android.os.Bundle;
import android.view.Window;
import android.widget.TabHost;
import android.widget.TabHost.TabSpec;

public class RSSVoiceReaderActivity extends ActivityGroup {
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.main);
        Resources res = getResources();

	    TabHost tab_host = (TabHost) findViewById(android.R.id.tabhost); 

	    tab_host.setup(this.getLocalActivityManager());

	    TabSpec ts1 = tab_host.newTabSpec("TAB_DATE"); 
	    ts1.setIndicator(getString(R.string.channels), res.getDrawable(R.drawable.icon_rss));
	    ts1.setContent(new Intent(this, FeedsActivity.class)); 
	    tab_host.addTab(ts1); 

	    TabSpec ts2 = tab_host.newTabSpec("TAB_GEO"); 
	    ts2.setIndicator(getString(R.string.favorite), res.getDrawable(R.drawable.icon_favorites)); 
	    ts2.setContent(new Intent(this, FavoritesActivity.class)); 
	    tab_host.addTab(ts2); 

	    TabSpec ts3 = tab_host.newTabSpec("TAB_TEXT"); 
	    ts3.setIndicator(getString(R.string.settings), res.getDrawable(R.drawable.icon_settings)); 
	    ts3.setContent(new Intent(this, SettingsActivity.class)); 
	    tab_host.addTab(ts3); 

	    TabSpec ts4 = tab_host.newTabSpec("TAB_ABOUT"); 
	    ts4.setIndicator(getString(R.string.about), res.getDrawable(R.drawable.icon_info)); 
	    ts4.setContent(new Intent(this, AboutActivity.class)); 
	    tab_host.addTab(ts4); 

	    tab_host.setCurrentTab(0);  
    }
}