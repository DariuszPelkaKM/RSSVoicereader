package pl.virtua.rss_voice_reader.controls;

import java.util.ArrayList;

import pl.virtua.rss_voice_reader.FeedsActivity;
import pl.virtua.rss_voice_reader.R;
import pl.virtua.rss_voice_reader.reader.RSSChannel;
import android.app.AlertDialog;
import android.app.Dialog;
import android.content.Context;
import android.content.DialogInterface;
import android.view.View;
import android.view.Window;
import android.widget.Button;
import android.widget.EditText;

public class AddChannelDialog extends Dialog {
	
	private Button okButton;
	private Button cancelButton;
	private EditText nameEdit;
	private EditText linkEdit;
	private Context context;

	public AddChannelDialog(Context context) {
		super(context);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		setContentView(R.layout.add_channel);
		
		this.context = context;
		
		okButton = (Button) findViewById(R.id.add_channel_button_ok);
		cancelButton = (Button) findViewById(R.id.add_channel_button_cancel);
		nameEdit = (EditText) findViewById(R.id.add_channel_edit_name);
		linkEdit = (EditText) findViewById(R.id.add_channel_edit_link);
		
		okButton.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				if (nameEdit.getText().toString().equalsIgnoreCase("") ||
						linkEdit.getText().toString().equalsIgnoreCase(""))
				{
					AlertDialog alertDialog;
		     		alertDialog = new AlertDialog.Builder(AddChannelDialog.this.context).create();
		     		alertDialog.setMessage(AddChannelDialog.this.context.getString(R.string.fill_fields));
		     		alertDialog.setButton("OK", new DialogInterface.OnClickListener() {
		 				
		 				public void onClick(DialogInterface dialog, int which) {
		 				}
		 			});
		     		alertDialog.show();
				}
				if (!nameEdit.getText().toString().equalsIgnoreCase("") &&
						!linkEdit.getText().toString().equalsIgnoreCase(""))
				{
					FeedsActivity.channelsList.add(new RSSChannel(nameEdit.getText().toString(), linkEdit.getText().toString()));
					PreferencesManager.setSavedPreferenceString("channels", 
							ObjectSerializer.serialize(ListConverter.toStringList(FeedsActivity.channelsList)));
					((FeedsActivity)AddChannelDialog.this.context).updateChannels();
					dismiss();
				}
			}
		});
		
		cancelButton.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				// TODO Auto-generated method stub
				dismiss();
			}
		});
	}
	
	public AddChannelDialog(Context context, final int itemIndex) {
		super(context);
		requestWindowFeature(Window.FEATURE_NO_TITLE);
		setContentView(R.layout.add_channel);
		
		okButton = (Button) findViewById(R.id.add_channel_button_ok);
		cancelButton = (Button) findViewById(R.id.add_channel_button_cancel);
		nameEdit = (EditText) findViewById(R.id.add_channel_edit_name);
		linkEdit = (EditText) findViewById(R.id.add_channel_edit_link);
		
		nameEdit.setText(FeedsActivity.channelsList.get(itemIndex).getName());
		linkEdit.setText(FeedsActivity.channelsList.get(itemIndex).getLink());
		
		okButton.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				// TODO Auto-generated method stub
				if (!nameEdit.getText().toString().equalsIgnoreCase("") &&
						!linkEdit.getText().toString().equalsIgnoreCase(""))
				{
					FeedsActivity.channelsList.get(itemIndex).setName(nameEdit.getText().toString());
					FeedsActivity.channelsList.get(itemIndex).setLink(linkEdit.getText().toString());
					PreferencesManager.setSavedPreferenceString("channels", 
							ObjectSerializer.serialize(ListConverter.toStringList(FeedsActivity.channelsList)));
					dismiss();
				}
			}
		});
		
		cancelButton.setOnClickListener(new View.OnClickListener() {
			
			@Override
			public void onClick(View v) {
				// TODO Auto-generated method stub
				dismiss();
			}
		});
	}

}
