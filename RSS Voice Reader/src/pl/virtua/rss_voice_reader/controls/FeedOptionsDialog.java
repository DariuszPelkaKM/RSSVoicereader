package pl.virtua.rss_voice_reader.controls;

import pl.virtua.rss_voice_reader.FavoritesActivity;
import pl.virtua.rss_voice_reader.FeedsActivity;
import pl.virtua.rss_voice_reader.R;
import pl.virtua.rss_voice_reader.reader.RSSChannel;
import android.app.Dialog;
import android.content.Context;
import android.text.ClipboardManager;
import android.view.View;
import android.view.Window;
import android.widget.Button;

public class FeedOptionsDialog extends Dialog {

	private Button buttonCopy;
	private Button buttonFav;
	private Button buttonCancel;
	
	private String channel, name, link;
	
	public FeedOptionsDialog(Context context, String channel, String name, String link) {
		super(context);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		setContentView(R.layout.feed_options);
		
		this.channel = channel;
		this.name = name;
		this.link = link;
		
		buttonCopy = (Button) findViewById(R.id.options_copy);
		buttonFav = (Button) findViewById(R.id.options_add);
		buttonCancel = (Button) findViewById(R.id.options_cancel);
		
		buttonCopy.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				ClipboardManager clipboard = 
				      (ClipboardManager) FeedOptionsDialog.this.getContext().getSystemService("clipboard"); 

				clipboard.setText(FeedOptionsDialog.this.link);
				dismiss();
			}
		});

		buttonFav.setOnClickListener(new Button.OnClickListener() {
	
			@Override
			public void onClick(View v) {
				int feedIndex = FavoritesActivity.favsList.indexOf(new RSSChannel(FeedOptionsDialog.this.name, 
						FeedOptionsDialog.this.link));
				if (feedIndex == -1)
				{
					int headerIndex = FavoritesActivity.favsList.indexOf(new RSSChannel(FeedOptionsDialog.this.channel, "#!#"));
					if (headerIndex == -1)
					{
						FavoritesActivity.favsList.add(new RSSChannel(FeedOptionsDialog.this.channel, "#!#"));
						FavoritesActivity.favsList.add(new RSSChannel(FeedOptionsDialog.this.name, FeedOptionsDialog.this.link));
					}
					else
					{
						FavoritesActivity.favsList.add(headerIndex + 1,
								new RSSChannel(FeedOptionsDialog.this.name, FeedOptionsDialog.this.link));
					}
					PreferencesManager.setSavedPreferenceString("favorites", 
			  				 ObjectSerializer.serialize(ListConverter.toStringList(FavoritesActivity.favsList)));
				}
				dismiss();
			}
		});

		buttonCancel.setOnClickListener(new Button.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				dismiss();
			}
		});
	}

	
}
