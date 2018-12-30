package pl.virtua.rss_voice_reader;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.StatFs;
import android.view.*;
import android.view.ContextMenu.ContextMenuInfo;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.EditText;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.ListView;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.AdapterView.OnItemClickListener; 
import android.widget.ViewFlipper;
import android.util.Log;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import loquendo.tts.engine.TTSConst;
import loquendo.tts.engine.TTSEvent;
import loquendo.tts.wrapper.LTTSWrapper;
import loquendo.tts.wrapper.LTTSWrapper.ErrorListener;
import loquendo.tts.wrapper.LTTSWrapper.EventListener;
import loquendo.tts.wrapper.LTTSWrapper.InitListener;
import loquendo.tts.wrapper.LTTSWrapper.SpeechCompletedListener;

import org.xml.sax.InputSource;

import org.xml.sax.XMLReader;

import com.slideme.slidelock.License.Rights;

import pl.virtua.rss_voice_reader.controls.AddChannelDialog;
import pl.virtua.rss_voice_reader.controls.Decompress;
import pl.virtua.rss_voice_reader.controls.FeedOptionsDialog;
import pl.virtua.rss_voice_reader.controls.ListConverter;
import pl.virtua.rss_voice_reader.controls.ObjectSerializer;
import pl.virtua.rss_voice_reader.controls.PageExtractor;
import pl.virtua.rss_voice_reader.controls.PreferencesManager;
import pl.virtua.rss_voice_reader.controls.Settings;
import pl.virtua.rss_voice_reader.controls.SoundsPlayer;
import pl.virtua.rss_voice_reader.reader.RSSChannel;
import pl.virtua.rss_voice_reader.reader.RSSFeed;
import pl.virtua.rss_voice_reader.reader.RSSHandler;
import pl.virtua.rss_voice_reader.reader.RSSItem;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Bitmap;
import android.graphics.Typeface;

public class FeedsActivity extends Activity implements OnItemClickListener
{
	private static final int MENU_EDIT = 0;
	private static final int MENU_REMOVE = 1;
	private static final int MENU_BACK = 2;

	public class ChannelAdapter extends ArrayAdapter<RSSChannel> {

		public ChannelAdapter(Context context, int textViewResourceId, ArrayList<RSSChannel> objects) 
		{
			super(context, textViewResourceId, objects);
		}
	
		@Override
		public View getView(int position, View convertView, ViewGroup parent) 
		{
			LayoutInflater inflater=getLayoutInflater();
			View row=inflater.inflate(R.layout.channel_row, parent, false);
			TextView namelabel=(TextView)row.findViewById(R.id.channel_name);
			int unread = getUnreadNewsInChannel(channelsList.get(position));
			namelabel.setText(channelsList.get(position).toString() + " (" + unread + ")");
			TextView linklabel=(TextView)row.findViewById(R.id.channel_link);
			linklabel.setText(channelsList.get(position).getLink());
			
			return row;
		}
	}
	
	public class FeedAdapter extends ArrayAdapter<RSSItem> {

		public FeedAdapter(Context context, int textViewResourceId, ArrayList<RSSItem> objects) 
		{
			super(context, textViewResourceId, objects);
		}
	
		@Override
		public View getView(int position, View convertView, ViewGroup parent) 
		{
			LayoutInflater inflater=getLayoutInflater();
			View row=inflater.inflate(R.layout.feed_row, parent, false);
			TextView namelabel=(TextView)row.findViewById(R.id.feed_row_name);
			namelabel.setText(feed.getAllItems().get(position).getTitle());
			if (!readNews.contains(feed.getItem(position)))
				namelabel.setTypeface(null, Typeface.BOLD);
			
			return row;
		}
	}
	
	private ViewFlipper switcher;
	private WebView page;
	private Button buttonAddChannel;
	private Button button_page_options;
	private Button button_page_prev;
	private Button button_page_next;
	private Button button_feeds_refresh;
	private TextView label_channel_name;
	private ListView channels;
	private ListView itemlist;
	public static ArrayList<RSSChannel> channelsList;
	
	private Button button_play_channels;
	private Button button_play_feeds;
	private Button button_play_page;
	private Button button_stop_channels;
	private Button button_stop_feeds;
	private Button button_stop_page;
	private static SeekBar seekbar_channels;
	private static SeekBar seekbar_feeds;
	private static SeekBar seekbar_page;
	private EditText editText_page;
	
	public final String tag = "RSSReader";
	private RSSFeed feed = null;
	private int selectedChannel;
	private int selectedFeed;
	
	private Settings settings;
	private ArrayList<String> speechQueue;
	private VoiceUpdate voiceUpdate = null;// inner class
	private VoiceError voiceError = null;// inner class
	private EventReceiver eventReceiver = null;// inner class
	private SpeechCompletedReceiver speechCompletedReceiver = null;// inner
    private final Handler mHandler = new Handler();
	private boolean interruptDownload = false;
    private int downloadProgress = 0;
    private String downloadText = "";
    private String errorString = "";
	private ProgressDialog progressDialog;
	private String textToTalk = "";

    private Dialog d;
	private Button dialogButton;
	private SeekBar dialogBar;

	private int animationStep = 1;
	private boolean animate = false;
	private Animation animation;
	private boolean startPlaying = false;
	private boolean stopPressed = false;
	private RefreshThread refreshThread;
	
	private ArrayList<RSSItem> readNews = new ArrayList<RSSItem>();
	private ArrayList<RSSItem> autoplayList = new ArrayList<RSSItem>();
	
	private static boolean startApp = true;
	
	/** Called when the activity is first created. */

    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.feed_switcher);
        
        switcher = (ViewFlipper) findViewById(R.id.feed_switcher);
        page = (WebView) findViewById(R.id.rss_page);
        Button backbutton = (Button) findViewById(R.id.back);
        Button channelsButton = (Button) findViewById(R.id.backchannels);
        channels = (ListView) findViewById(R.id.channellist);
        itemlist = (ListView) findViewById(R.id.itemlist);
        buttonAddChannel = (Button) findViewById(R.id.channels_add);
        button_page_options = (Button) findViewById(R.id.button_options);
        button_page_prev = (Button) findViewById(R.id.button_prev_article);
        button_page_next = (Button) findViewById(R.id.button_next_article);
        button_feeds_refresh = (Button) findViewById(R.id.refreshchannels);
        label_channel_name = (TextView) findViewById(R.id.channel_name);
        button_play_channels = (Button) findViewById(R.id.button_play_channels);
        button_play_feeds = (Button) findViewById(R.id.button_play_feeds);
        button_play_page = (Button) findViewById(R.id.button_play_page);
        button_stop_channels = (Button) findViewById(R.id.button_stop_channels);
        button_stop_feeds = (Button) findViewById(R.id.button_stop_feeds);
        button_stop_page = (Button) findViewById(R.id.button_stop_page);
        seekbar_channels = (SeekBar) findViewById(R.id.seekbar_channels);
        seekbar_feeds = (SeekBar) findViewById(R.id.seekbar_feeds);
        seekbar_page = (SeekBar) findViewById(R.id.seekbar_page);
        editText_page = (EditText) findViewById(R.id.editText_page);
  
		page.getSettings().setJavaScriptEnabled(true);
		page.setWebViewClient(new RSSVRWebViewClient());
		
		//switcher.setInAnimation(AnimationUtils.loadAnimation(this, R.anim.flipin));
		//switcher.setOutAnimation(AnimationUtils.loadAnimation(this, R.anim.flipout));
		
		PreferencesManager.initPreferences(this);
		
		Settings.myTts = new LTTSWrapper();
		settings = new Settings();

		Settings.sounds = Settings.getSavedPreferenceBool("sounds");
		Settings.autoPlay = Settings.getSavedPreferenceBool("autoplay");
		Settings.refreshTime = Settings.getSavedPreferenceInt("refreshtime");
		
		readNews = ListConverter.toRSSItemList(
				(ArrayList<String>) ObjectSerializer.deserialize(
						PreferencesManager.getSavedPreferenceString("readNews")));
		speechQueue = new ArrayList<String>();

		FavoritesActivity.favsList = ListConverter.toRSSChannelList(
				(ArrayList<String>) ObjectSerializer.deserialize(
						PreferencesManager.getSavedPreferenceString("favorites")));
		if (FavoritesActivity.favsList == null)
			FavoritesActivity.favsList = new ArrayList<RSSChannel>();
		
		channelsList = ListConverter.toRSSChannelList(
				(ArrayList<String>) ObjectSerializer.deserialize(
						PreferencesManager.getSavedPreferenceString("channels")));
		if (channelsList == null)
			channelsList = new ArrayList<RSSChannel>();
		if (!Settings.getSavedPreferenceBool("notfirstrun"))
		{
			Settings.setSavedPreferenceBool("notfirstrun", true);
			if (Locale.getDefault().getLanguage().equalsIgnoreCase("pl"))
	    	{
				channelsList.add(new RSSChannel("Nasze newsy z serwisu", "http://rss-voice-reader.com/rss_pl"));
	    	}
			else
			{
				channelsList.add(new RSSChannel("Our service news", "http://rss-voice-reader.com/rss_eng"));
			}
			PreferencesManager.setSavedPreferenceString("channels", 
	  				 ObjectSerializer.serialize(ListConverter.toStringList(channelsList)));
		}
        ChannelAdapter adapter = new ChannelAdapter(this.getApplicationContext(),
        		android.R.layout.simple_list_item_1, channelsList);

        channels.setAdapter(adapter);
        
        channels.setOnItemClickListener(new AdapterView.OnItemClickListener() {

			@Override
			public void onItemClick(AdapterView<?> arg0, View arg1, int arg2,
					long arg3) {
				
				SoundsPlayer.playSound_Click(FeedsActivity.this);
				
				selectedChannel = arg2;
		        feed = getFeed(channelsList.get(arg2).getLink());
		        label_channel_name.setText(channelsList.get(selectedChannel).getName());

		        UpdateDisplay();
		        Settings.myTts.stop();
		        switcher.showNext();
			}
		});
        
        channels.setSelection(0);
        
        backbutton.setOnClickListener(new Button.OnClickListener() 
        {
            public void onClick(View v) 
            {
            	stopPressed = true;
            	Settings.myTts.stop();
				SoundsPlayer.playSound_Click(FeedsActivity.this);
            	animate = false;
            	UpdateDisplay();
            	switcher.showPrevious();
            }
        }); 
        
        channelsButton.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				SoundsPlayer.playSound_Click(FeedsActivity.this);
				ChannelAdapter adapter = new ChannelAdapter(FeedsActivity.this.getApplicationContext(),
		        		android.R.layout.simple_list_item_1, channelsList);

		        channels.setAdapter(adapter);
				Settings.myTts.stop();
				switcher.showPrevious();
			}
		});
        
        buttonAddChannel.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				SoundsPlayer.playSound_Click(FeedsActivity.this);
				AddChannelDialog dialogAdd = new AddChannelDialog(FeedsActivity.this);
				dialogAdd.show();
			}
		});
        
        button_page_next.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (feed.getAllItems().size() > (selectedFeed + 1))
				{
					stopPressed = true;
					startPlaying = false;
					SoundsPlayer.playSound_Click(FeedsActivity.this);
					selectedFeed++;
					editText_page.setText(feed.getAllItems().get(selectedFeed).getLink());
					page.loadUrl(feed.getAllItems().get(selectedFeed).getLink());
				}
			}
		});
        
        button_page_prev.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (selectedFeed > 0)
				{
					stopPressed = true;
					startPlaying = false;
					SoundsPlayer.playSound_Click(FeedsActivity.this);
					selectedFeed--;
					editText_page.setText(feed.getAllItems().get(selectedFeed).getLink());
					page.loadUrl(feed.getAllItems().get(selectedFeed).getLink());
				}
			}
		});
        
        button_page_options.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				SoundsPlayer.playSound_Click(FeedsActivity.this);
				FeedOptionsDialog fod = new FeedOptionsDialog(FeedsActivity.this, channelsList.get(selectedChannel).getName(), 
						feed.getAllItems().get(selectedFeed).getTitle(), feed.getAllItems().get(selectedFeed).getLink());
				fod.show();
			}
		});
        
        button_feeds_refresh.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				SoundsPlayer.playSound_Click(FeedsActivity.this);
				feed = getFeed(channelsList.get(selectedChannel).getLink());
		        UpdateDisplay();
			}
		});
        
        button_play_channels.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				textToTalk = "";
				for (RSSChannel chan : channelsList)
				{
					textToTalk += chan.getName() + ". ";
				}
				progressDialog = ProgressDialog.show(FeedsActivity.this, "", "");
				new SpeakThread().start();
			}
		});
        
        button_play_feeds.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				textToTalk = "";
				for (RSSItem item : feed.getAllItems())
				{
					textToTalk += item.getTitle() + ". ";
				}
				progressDialog = ProgressDialog.show(FeedsActivity.this, "", "");
				new SpeakThread().start();
			}
		});
        
        button_play_page.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (!animate)
				{
					progressDialog = ProgressDialog.show(FeedsActivity.this, "", "");
					new SpeakThread().start();
				}
			}
		});
        
        button_stop_channels.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (Settings.myTts.isSpeaking())
				{
					Settings.myTts.stop();
					Settings.state = Settings.TTSState.IDLE;
					setPlayButtonString(R.string.play);
					setPlayButtonImage(R.drawable.play_bg);
				}
			}
		});

		button_stop_feeds.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (Settings.myTts.isSpeaking())
				{
					Settings.myTts.stop();
					Settings.state = Settings.TTSState.IDLE;
					setPlayButtonString(R.string.play);
					setPlayButtonImage(R.drawable.play_bg);
				}
			}
		});

		button_stop_page.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (Settings.myTts.isSpeaking())
				{
					stopPressed = true;
					Settings.myTts.stop();
					Settings.state = Settings.TTSState.IDLE;
					setPlayButtonString(R.string.play);
					setPlayButtonImage(R.drawable.play_bg);
				}
			}
		});
		
		seekbar_channels.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			
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
				setSpeed(progress);
				SettingsActivity.setSpeed(progress);
				FavoritesActivity.setSpeed(progress);
				AboutActivity.setSpeed(progress);
			}
		});
		
		seekbar_feeds.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			
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
				setSpeed(progress);
				SettingsActivity.setSpeed(progress);
				FavoritesActivity.setSpeed(progress);
				AboutActivity.setSpeed(progress);
			}
		});
		
		seekbar_page.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
			
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
				setSpeed(progress);
				SettingsActivity.setSpeed(progress);
				FavoritesActivity.setSpeed(progress);
				AboutActivity.setSpeed(progress);
			}
		});
        
        registerForContextMenu(channels);
        
        d = new Dialog(FeedsActivity.this);
		downloadText = getString(R.string.downloading_resources);
		d.setTitle("          " + downloadText + "          ");
		d.setContentView(R.layout.progress_message);
		d.setCancelable(false);
		
		dialogButton = (Button) d.findViewById(R.id.progress_button);
		dialogBar = (SeekBar) d.findViewById(R.id.progress_seek);
		
		dialogButton.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				interruptDownload = true;
				d.dismiss();
			}
		});
		
        File SDCardRoot = Environment.getExternalStorageDirectory();
		File folder = new File(SDCardRoot + "/RSSVRLoquendoTTS/"); 
        
		boolean noLicense = true;
		// licencjonowanie
		com.slideme.slidelock.License myLicense = new com.slideme.slidelock.License(
				"RSS Voice Reader License", 
				"wbihs9uwlnvsiou4wp5vsihj91fiu8",
                this);

		try{
			myLicense.digest(myLicense.fetch());
		} catch(Exception ioe){
		// license couldn't initialize. Handle this
		}
		
		Rights someRights = myLicense.getFullRights();

		if(someRights != null){
			Log.i("mobiks", "MAM PRAWA");
			noLicense = false;
		} else {
			Log.i("mobiks", "NIE MAM PRAW");
		}
		
		if (noLicense)
		{
			AlertDialog alertDialog;
			alertDialog = new AlertDialog.Builder(FeedsActivity.this).create();
			alertDialog.setMessage(getString(R.string.license));
			alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
				
				public void onClick(DialogInterface dialog, int which) {
					FeedsActivity.this.finish();
				}
			});
			alertDialog.show();
		}
		
        if (!folder.exists()) // nie istnieje folder z g³osami, pobraæ zipa
        {
	    	AlertDialog alertDialog;
			alertDialog = new AlertDialog.Builder(FeedsActivity.this).create();
			alertDialog.setMessage(getString(R.string.will_download));
			alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
				
				public void onClick(DialogInterface dialog, int which) {
					new DownloadThread().start();
				}
			});
			alertDialog.show();
        } else {
        	new DownloadThread().start();
        }
        
		animation = new Animation();
		animation.start();
		
		refreshThread = new RefreshThread();
		refreshThread.start();
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

    	if (!startApp)
    	{
			Settings.myTts.setOnErrorListener(ttsErrorListener);
			Settings.myTts.setOnEventListener(ttsEventListener);
			Settings.myTts.setOnSpeechCompletedListener(speechCompletedListener);
    	}
		
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
		
		if (startApp)
			startApp = false;
    }
    
    public void updateChannels()
    {
    	ChannelAdapter adapter = new ChannelAdapter(this.getApplicationContext(),
        		android.R.layout.simple_list_item_1, channelsList);

        channels.setAdapter(adapter);
    }
    
    private int getUnreadNewsInChannel(RSSChannel channel)
    {
    	RSSFeed feedTemp = getFeed(channel.getLink());
    	int unread = 0;
    	if (feedTemp != null)
	    	for (RSSItem item : feedTemp.getAllItems())
	    	{
	    		if (!readNews.contains(item))
	    			unread++;
	    	}
    	return unread;
    }
    
    public static void setSpeed(int speed)
    {
    	seekbar_channels.setProgress(speed);
    	seekbar_feeds.setProgress(speed);
    	seekbar_page.setProgress(speed);
    }
    
    private class RSSVRWebViewClient extends WebViewClient {
        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
			editText_page.setText(url);
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
    }

    public Dialog getDialog()
    {
    	return d;
    }
    
    public SeekBar getDialogBar()
    {
    	return dialogBar;
    }
    
    public Handler getHandler() 
    {
    	return mHandler;
    }
    
    private RSSFeed getFeed(String urlToRssFeed)
    {
    	try
    	{
    		// setup the url
    	   URL url = new URL(urlToRssFeed);

           // create the factory
           SAXParserFactory factory = SAXParserFactory.newInstance();
           // create a parser
           SAXParser parser = factory.newSAXParser();

           // create the reader (scanner)
           XMLReader xmlreader = parser.getXMLReader();
           // instantiate our handler
           RSSHandler theRssHandler = new RSSHandler();
           // assign our handler
           xmlreader.setContentHandler(theRssHandler);
           // get our data via the url class
           String file = "xmlPage.txt";
           PageExtractor.exportPageToFile(this, urlToRssFeed, file);
           
           InputSource is = new InputSource(openFileInput(file));
           // perform the synchronous parse  
           
           xmlreader.parse(is);
           // get the results - should be a fully populated RSSFeed instance, or null on error
           return theRssHandler.getFeed();
    	}
    	catch (Exception ee)
    	{
    		// if we have a problem, simply return null
    		Log.i("mobiks", "ERROR: " + ee.toString());
    		return null;
    	}
    }
    public boolean onCreateOptionsMenu(Menu menu) 
    {
    	super.onCreateOptionsMenu(menu);
    	
    	menu.add(0,0,Menu.NONE,"Choose RSS Feed");
    	menu.add(0,1,Menu.NONE,"Refresh");
    	Log.i(tag,"onCreateOptionsMenu");
    	return true;
    }
    
    public boolean onOptionsItemSelected(MenuItem item){
        switch (item.getItemId()) {
        case 0:
        	
        	Log.i(tag,"Set RSS Feed");
            return true;
        case 1:
        	Log.i(tag,"Refreshing RSS Feed");
            return true;
        }
        return false;
    }
    
    
    private void UpdateDisplay()
    {
  
        
        if (feed == null)
        {
        	feed = new RSSFeed();
        	AlertDialog.Builder builder = new AlertDialog.Builder(this);
        	builder.setTitle(getString(R.string.error_channel_title) + " " + channelsList.get(selectedChannel).getName());
        	builder.setMessage(getString(R.string.error_channel_body));
        	AlertDialog alert = builder.create();
        	alert.setButton("OK", new DialogInterface.OnClickListener() {
				
				@Override
				public void onClick(DialogInterface dialog, int which) {
				}
			});
        	alert.show();
        }


        FeedAdapter adapter = new FeedAdapter(this.getApplicationContext(),
        		android.R.layout.simple_list_item_1, feed.getAllItems());

        itemlist.setAdapter(adapter);
        
        itemlist.setOnItemClickListener(this);
        
        itemlist.setSelection(0);
        
        ChannelAdapter chadapter = new ChannelAdapter(this.getApplicationContext(),
        		android.R.layout.simple_list_item_1, channelsList);

        channels.setAdapter(chadapter);
        
    }
    
    
     public void onItemClick(AdapterView parent, View v, int position, long id)
     {
    	 SoundsPlayer.playSound_Click(FeedsActivity.this);
    	 selectedFeed = position;
    	 startPlaying = false;
         
    	 if (!readNews.contains(feed.getItem(position)))
    	 {
    		 readNews.add(feed.getItem(position));
    		 PreferencesManager.setSavedPreferenceString("readNews", 
	  				 ObjectSerializer.serialize(ListConverter.toStringListFromItem(readNews)));
    	 }
    	 
    	 Bundle b = new Bundle();
    	 b.putString("title", feed.getItem(position).getTitle());
    	 b.putString("description", feed.getItem(position).getDescription());
    	 b.putString("link", feed.getItem(position).getLink());
    	 b.putString("pubdate", feed.getItem(position).getPubDate());
    	 String theStory = null;
    	 if (b == null)
     	 {
     		 theStory = "bad bundle?";
     	 }
     	 else
 		 {
     	 	 theStory = b.getString("title") + "\n\n" + b.getString("pubdate") + "\n\n" + b.getString("description").replace('\n',' ') + "\n\nMore information:\n" + b.getString("link");
     		 editText_page.setText(b.getString("link"));
             page.loadUrl(b.getString("link"));
 		 }
    	 
		 if (Settings.autoPlay && position < (feed.getItemCount() - 1))
		 {
			 autoplayList.clear();
			 for (int i = position + 1; i < feed.getItemCount(); i++)
			 {
				 if (!readNews.contains(feed.getItem(i)))
				 autoplayList.add(feed.getItem(i));
			 }
		 }
    	 
    	 Settings.myTts.stop();
    	 switcher.showNext();
     }
    
     @Override
     public void onCreateContextMenu(ContextMenu menu, View v, ContextMenuInfo menuInfo) {
  	   if (v.getId()==R.id.channellist) {
  		   AdapterView.AdapterContextMenuInfo info = (AdapterView.AdapterContextMenuInfo)menuInfo;
  		   if (channelsList.size() > info.position)
  		   {
  			   menu.setHeaderTitle(channelsList.get(info.position).getName());

  			   menu.add(Menu.NONE, MENU_EDIT, MENU_EDIT, getString(R.string.edit));
  			   menu.add(Menu.NONE, MENU_REMOVE, MENU_REMOVE, getString(R.string.remove));
  			   menu.add(Menu.NONE, MENU_BACK, MENU_BACK, getString(R.string.back));
  		   }
  	   }
     }
     
     @Override
     public boolean onContextItemSelected(MenuItem item) {
	     AdapterView.AdapterContextMenuInfo info = (AdapterView.AdapterContextMenuInfo)item.getMenuInfo();
	     RSSChannel node = channelsList.get(info.position);
	
	  	 switch (item.getItemId())
	  	 {
		  	 case MENU_EDIT:
		  		 AddChannelDialog dialogAdd = new AddChannelDialog(FeedsActivity.this, info.position);
				 dialogAdd.show();
		  		 break;
		  	 case MENU_REMOVE:
		  		 channelsList.remove(info.position);
		  		 PreferencesManager.setSavedPreferenceString("channels", 
		  				 ObjectSerializer.serialize(ListConverter.toStringList(FeedsActivity.channelsList)));
		  		channels.setAdapter(new ChannelAdapter(this.getApplicationContext(),
		        		android.R.layout.simple_list_item_1, channelsList));
		  		 break;
		  	 case MENU_BACK:
		  		 break;
	  	 }
	     return true;
     }
     
 	@Override
 	protected void onDestroy() {
 		animation.interrupted = true;
 		interruptDownload = true;
 		refreshThread.interrupt();
 		try {
 			unregisterReceiver(voiceUpdate);
 			unregisterReceiver(voiceError);
 			unregisterReceiver(eventReceiver);
 			unregisterReceiver(speechCompletedReceiver);
 			if (Settings.myTts != null)
 			{
 				Settings.myTts.close();
 				Settings.myTts = null;
 			}
 		} catch (Exception e) {}
 		Settings.state = Settings.TTSState.UNINITIALIZED;
 		super.onDestroy();
 	}
     
     /**
      * klasy i metody Loquendo
      */
     
     private InitListener ttsInitListener = new InitListener() {
 		public void onInit(int version) {

 			if (Settings.state == Settings.TTSState.UNINITIALIZED) {
 	
 				Settings.myTts.setParam("TextEncoding", "utf-8");
 				Settings.myTts.enableEvent(TTSConst.TTSEVT_BOOKMARK, true);

 				loadVoiceNames();
 				
 				Settings.state = Settings.TTSState.IDLE;
 			}
 		}
 	};

 	private ErrorListener ttsErrorListener = new ErrorListener() {
 		public void onError(String msg) {
 			if (msg.contains("Voice") || msg.contains("Language")) {
 				Intent intent = new Intent(Settings.VOICE_ERROR);
 				FeedsActivity.this.sendBroadcast(intent);
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
 				FeedsActivity.this.sendBroadcast(intent);
 			} else if (event.getReason().equals(TTSConst.TTSEVT_AUDIOSTART)) {
 				Settings.state = Settings.TTSState.SPEAKING;
 				mHandler.post(hideProgressDialog);
 			}
 		}
 	};

 	private SpeechCompletedListener speechCompletedListener = new SpeechCompletedListener() {
 		public void onSpeechCompleted() {
 			Intent intent = new Intent(Settings.SPEECH_COMPLETED);
 			FeedsActivity.this.sendBroadcast(intent);
 			Settings.state = Settings.TTSState.IDLE;
 			
 			if (Settings.autoPlay && autoplayList.size() > 0 && !stopPressed)
 			{
 				startPlaying = true;
 				selectedFeed = feed.getAllItems().indexOf(autoplayList.get(0));
 				readNews.add(autoplayList.get(0));
 	    		PreferencesManager.setSavedPreferenceString("readNews", 
 		  			 ObjectSerializer.serialize(ListConverter.toStringListFromItem(readNews)));
 				page.loadUrl(autoplayList.get(0).getLink());
 				autoplayList.remove(0);
 			}
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
 				setPlayButtonImage(R.drawable.play_bg);
 			}
 		}
 	};
 	
 	private void setPlayButtonImage(int resId)
 	{
 		switch (switcher.getDisplayedChild())
 		{
	 		case 0:
	 			button_play_channels.setBackgroundResource(resId);
	 			break;
	 		case 1:
	 			button_play_feeds.setBackgroundResource(resId);
	 			break;
	 		case 2:
	 			button_play_page.setBackgroundResource(resId);
	 			break;
 		}
 	}
 	
 	private void setPlayButtonString(int resId)
 	{
 		switch (switcher.getDisplayedChild())
 		{
	 		case 0:
	 			if (!button_play_channels.getText().toString().equalsIgnoreCase(getString(resId)))
	 				button_play_channels.setText(resId);
	 			break;
	 		case 1:
	 			if (!button_play_feeds.getText().toString().equalsIgnoreCase(getString(resId)))
	 				button_play_feeds.setText(resId);
	 			break;
	 		case 2:
	 			if (!button_play_page.getText().toString().equalsIgnoreCase(getString(resId)))
	 				button_play_page.setText(resId);
	 			break;
 		}
 	}

 	public class VoiceError extends BroadcastReceiver {
 		@Override
 		public void onReceive(Context context, Intent intent) {

         	AlertDialog alertDialog;
     		alertDialog = new AlertDialog.Builder(FeedsActivity.this).create();
     		alertDialog.setMessage("B³¹d g³osu");
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

 	private void loadVoiceNames() {
 		SettingsActivity.voices = new ArrayList<String>();
 		SettingsActivity.texts = new ArrayList<String>();
 		String[] myVoices = Settings.myTts.queryVoices();
 		if (myVoices == null) {
 			return;
 		}
 		String[] textRes = this.getResources().getStringArray(R.array.demotext);
 		String[] voiceRes = this.getResources().getStringArray(R.array.voices);
 		for (int j = 0; j < voiceRes.length; j++) {
 			for (int i = 0; i < myVoices.length; i++) {
 				if (voiceRes[j].startsWith(myVoices[i])) {
 					SettingsActivity.voices.add(voiceRes[j]);
 					SettingsActivity.texts.add(textRes[j]);
 					break;
 				}
 			}
 		}
 	}
 	
 	/**
 	 * pobieranie zasobów
 	 */
 	
 	private class DownloadThread extends Thread
    {
    	public void run() {
    		try {
    	        File SDCardRoot = Environment.getExternalStorageDirectory();
    	        File folder = new File(SDCardRoot + "/RSSVRLoquendoTTS/"); 

    	        if (!folder.exists()) // nie istnieje folder z g³osami, pobraæ zipa
    	        {
	    	        URL url = new URL("http://rss-voice-reader.com/Loquendo.zip");
	    	        HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
	    	        urlConnection.setRequestMethod("GET");
	    	        urlConnection.setDoOutput(true);
	
	    	        urlConnection.connect();
	
	    	        File file = new File(SDCardRoot,"somefile.zip");
	    	        
	    	        int totalSize = urlConnection.getContentLength();
	    	        
	    	        if (bytesAvailable(SDCardRoot) > 2*totalSize) // 2* bo zip i rozpakowany folder (podobnych rozmiarów)
	    	        {
	    	        	mHandler.post(showProgressDialog);
		    	        FileOutputStream fileOutput = new FileOutputStream(file);
		    	        InputStream inputStream = urlConnection.getInputStream();
	
		    	        int downloadedSize = 0;
		
		    	        byte[] buffer = new byte[1024];
		    	        int bufferLength = 0;
		
		    	        while (!interruptDownload && (bufferLength = inputStream.read(buffer)) > 0 ) {
		    	                fileOutput.write(buffer, 0, bufferLength);
		    	                downloadedSize += bufferLength;
		    	                downloadProgress = (int)((double)((double)downloadedSize / (double)totalSize) * 100);
		    	                mHandler.post(updateProgress);
		    	                
		    	        }
	    	        
		    	        fileOutput.close();
		    	        
		    	        if (!interruptDownload)
		    	        {
			    	        downloadText = getString(R.string.decompressing_files);
			    	        mHandler.post(updateProgress);
			    	        
			    	        Decompress dec = new Decompress(file.getAbsolutePath(), SDCardRoot + "/RSSVRLoquendoTTS/", FeedsActivity.this);
			    	        dec.unzip();
		    	        }
		    	        else // wyœwietliæ informacjê o niepobranym pliku 
		    	        {
		    	        	errorString = getString(R.string.file_not_downloaded);
		    	        	mHandler.post(showError);
		    	        }
	    	        }
	    	        else // wyœwietliæ informacjê o braku miejsca na dysku 
	    	        {
	    	        	errorString = getString(R.string.not_enough_space);
	    	        	Log.i("browser", errorString);
	    	        	mHandler.post(showError);
	    	        }
    	        }
    	        
    	        // inicjalizacja g³osów
    			settings.initResFiles();

    			Settings.myTts.init(ttsInitListener);
    			Settings.myTts.setOnErrorListener(ttsErrorListener);
    			Settings.myTts.setOnEventListener(ttsEventListener);
    			Settings.myTts.setOnSpeechCompletedListener(speechCompletedListener);
    			
    			settings.volume = Settings.getSavedPreferenceInt("volume");
    			Settings.myTts.setVolume(settings.volume);
    			settings.speed = Settings.getSavedPreferenceInt("speed");
    			Settings.myTts.setSpeed(settings.speed);
    			
    			seekbar_channels.setProgress(Settings.speed);
    			seekbar_feeds.setProgress(Settings.speed);
    			seekbar_page.setProgress(Settings.speed);
    			
    			Thread loadVoice = (new Thread(new Settings.LoadVoiceThread(
    					Settings.getSavedPreferenceString("voice"), FeedsActivity.this)));
    			loadVoice.setPriority(Thread.MIN_PRIORITY);
    			loadVoice.start();
    			
    	        mHandler.post(updateEnd);
	    	} catch (MalformedURLException e) {
	    	        e.printStackTrace();
	    	} catch (IOException e) {
	    	        e.printStackTrace();
	    	        // wyœwietliæ info o b³êdzie pobierania
    	        	errorString = getString(R.string.download_error);
    	        	mHandler.post(showError);
	    	}
    	}
    }
    
    public static float bytesAvailable(File f) {
        StatFs stat = new StatFs(f.getPath());
        long bytesAvailable = (long)stat.getBlockSize() * (long)stat.getAvailableBlocks();
        return bytesAvailable;
    }
    
    /**
     * w¹tki Runnable
     */
    
    private Runnable showProgressDialog = new Runnable() {
    	public void run() {
    		d.show();
    	}
    };
    
    private Runnable hideProgressDialog = new Runnable() {
    	public void run() {
    		if (progressDialog != null)
    		{
	    		progressDialog.dismiss();
	    		if (Settings.myTts.isSpeaking()) {
					setPlayButtonString(R.string.play);
	 				setPlayButtonImage(R.drawable.play_bg);
				} else {
					setPlayButtonString(R.string.pause);
	 				setPlayButtonImage(R.drawable.pause);
				}
    		}
    	}
    };
    
    private Runnable showError = new Runnable() {
    	public void run() {
            AlertDialog alertDialog;
    		alertDialog = new AlertDialog.Builder(FeedsActivity.this).create();
    		alertDialog.setMessage(errorString);
    		alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
				
				public void onClick(DialogInterface dialog, int which) {
				}
			});
    		alertDialog.show();
    	}
    };
    
    private Runnable showErrorEndApp = new Runnable() {
    	public void run() {
        	AlertDialog alertDialog;
     		alertDialog = new AlertDialog.Builder(FeedsActivity.this).create();
     		alertDialog.setMessage(errorString);
     		alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
 				
 				public void onClick(DialogInterface dialog, int which) {
 					finish();
 				}
 			});
     		alertDialog.show();
    	}
    };
    
    private Runnable setPlayButtonImage = new Runnable() {
		
    	private boolean wasAnimation = false;
    	
		@Override
		public void run() {
			
			if (animate)
    		{
				wasAnimation = true;
				setPlayButtonString(R.string.wait);
	    		switch (animationStep) {
	    			case 1:
	    			{
	    				setPlayButtonImage(R.drawable.wait1);
	    				animationStep = 2;
	    			}
	    			break;
	    			case 2:
	    			{
	    				setPlayButtonImage(R.drawable.wait2);
	    				animationStep = 3;
	    			}
	    			break;
	    			case 3:
	    			{
	    				setPlayButtonImage(R.drawable.wait3);
	    				animationStep = 4;
	    			}
	    			break;
	    			case 4:
	    			{
	    				setPlayButtonImage(R.drawable.wait4);
	    				animationStep = 5;
	    			}
	    			case 5:
	    			{
	    				setPlayButtonImage(R.drawable.wait5);
	    				animationStep = 6;
	    			}
	    			break;
	    			case 6:
	    			{
	    				setPlayButtonImage(R.drawable.wait6);
	    				animationStep = 7;
	    			}
	    			break;
	    			case 7:
	    			{
	    				setPlayButtonImage(R.drawable.wait7);
	    				animationStep = 8;
	    			}
	    			break;
	    			case 8:
	    			{
	    				setPlayButtonImage(R.drawable.wait8);
	    				animationStep = 1;
	    			}
	    			break;
	    		}
	    	} else {
	    		if (Settings.state == Settings.TTSState.SPEAKING)
	    		{
					setPlayButtonString(R.string.pause);
	    			setPlayButtonImage(R.drawable.pause);
	    		}
	    		else {
					setPlayButtonString(R.string.play);
	    			setPlayButtonImage(R.drawable.play_bg);
	    			if (Settings.autoPlay && wasAnimation && startPlaying)
	    			{
	    				progressDialog = ProgressDialog.show(FeedsActivity.this, "", "");
						new SpeakThread().start();
	    			}
	    		}
	    		wasAnimation = false;
	    	}
		}
	};
	
	private Runnable updateProgress = new Runnable() {
		public void run() {
			d.setTitle(downloadText);
			dialogBar.setProgress(downloadProgress);
		}
	};
	
	private Runnable updateEnd = new Runnable() {
		public void run() {
			d.dismiss();
		}
	};
    
    private class Animation extends Thread {

    	public boolean interrupted = false;
    	
    	public void run() {

    		while(!interrupted)
    		{
	    		mHandler.post(setPlayButtonImage);
	    		try {
	    			Thread.sleep(500);
	    		} catch (Exception e) {}
    		}
    	}
		
    };
    
    private class SpeakThread extends Thread {

    	public void run() 
    	{
    		stopPressed = false;
			if (Settings.state == Settings.TTSState.SPEAKING) {
				Settings.myTts.pause();
				Settings.state = Settings.TTSState.PAUSED;
				mHandler.post(hideProgressDialog);
			} 
			else if (Settings.state == Settings.TTSState.IDLE)
			{
				if (switcher.getDisplayedChild() == 2)
					textToTalk = PageExtractor.getPageHTML(FeedsActivity.this, feed.getItem(selectedFeed).getLink());
				if (!textToTalk.equalsIgnoreCase(""))
					Settings.myTts.speak(textToTalk);
				else
					mHandler.post(hideProgressDialog);
			}
			else if (Settings.state == Settings.TTSState.PAUSED)
			{
				Settings.myTts.resume();
				Settings.state = Settings.TTSState.SPEAKING;
				mHandler.post(hideProgressDialog);
			}
    	}
	}
    
    private Runnable refreshChannels = new Runnable() {
		
		@Override
		public void run() {
	        ChannelAdapter adapter = new ChannelAdapter(FeedsActivity.this.getApplicationContext(),
	        		android.R.layout.simple_list_item_1, channelsList);

	        channels.setAdapter(adapter);
		}
	};
    
    private class RefreshThread extends Thread {
    	
    	private Date lastCheckDate;
    	
    	public RefreshThread() {
    		lastCheckDate = new Date();
    	}
    	
    	public void run()
    	{
    		while (!animation.interrupted)
    		{
	    		Date now = new Date();
	    		long diff = now.getTime() - lastCheckDate.getTime();
	    		long minutes = diff / (1000 * 60);
	    		if (Settings.refreshTime > 0 && minutes >= Settings.refreshTime)
	    		{
	    			lastCheckDate = now;
	    			mHandler.post(refreshChannels);
	    		}
	    		try
	    		{
	    			Thread.sleep(60000);
	    		} catch (Exception e) {}
    		}
    	}
    }
}