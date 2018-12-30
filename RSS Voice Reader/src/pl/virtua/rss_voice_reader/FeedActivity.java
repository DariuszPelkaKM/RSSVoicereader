package pl.virtua.rss_voice_reader;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.SeekBar;
import android.widget.TextView;
import android.content.Intent;
import android.graphics.Bitmap;
import android.view.*;

public class FeedActivity extends Activity 
{
    public void onCreate(Bundle icicle) 
    {
        super.onCreate(icicle);
        setContentView(R.layout.showdescription);
        
        String theStory = null;
        
        
        Intent startingIntent = getIntent();

        WebView page = (WebView) findViewById(R.id.rss_page);
        page.getSettings().setJavaScriptEnabled(true);
        page.setWebViewClient(new RSSVRWebViewClient());
        
        if (startingIntent != null)
        {
        	Bundle b = startingIntent.getBundleExtra("android.intent.extra.INTENT");
        	if (b == null)
        	{
        		theStory = "bad bundle?";
        	}
        	else
    		{
        		theStory = b.getString("title") + "\n\n" + b.getString("pubdate") + "\n\n" + b.getString("description").replace('\n',' ') + "\n\nMore information:\n" + b.getString("link");
                page.loadUrl(b.getString("link"));
    		}
        }
        else
        {
        	theStory = "Information Not Found.";
        
        }
        
        Button backbutton = (Button) findViewById(R.id.back);
        
        backbutton.setOnClickListener(new Button.OnClickListener() 
        {
            public void onClick(View v) 
            {
            	finish();
            }
        });        
    }
    
    private class RSSVRWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            view.loadUrl(url);
            return true;
        } 
    }
}
