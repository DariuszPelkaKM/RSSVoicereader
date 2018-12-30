package pl.virtua.rss_voice_reader.controls;

import java.util.ArrayList;

import pl.virtua.rss_voice_reader.reader.RSSChannel;
import pl.virtua.rss_voice_reader.reader.RSSItem;

public class ListConverter {

	public static ArrayList<String> toStringList(ArrayList<RSSChannel> rssList)
	{
		ArrayList<String> stringList = new ArrayList<String>();
		for (RSSChannel channel : rssList)
		{
			stringList.add(channel.getName() + "#" + channel.getLink());
		}
		return stringList;
	}
	
	public static ArrayList<RSSChannel> toRSSChannelList(ArrayList<String> stringList)
	{
		String name, link;
		ArrayList<RSSChannel> rssList = new ArrayList<RSSChannel>();
		if (stringList != null)
			for (String string : stringList)
			{
				name = string.substring(0, string.indexOf("#"));
				link = string.substring(string.indexOf("#") + 1);
				rssList.add(new RSSChannel(name, link));
			}
		return rssList;
	}
	
	public static ArrayList<String> toStringListFromItem(ArrayList<RSSItem> rssList)
	{
		ArrayList<String> stringList = new ArrayList<String>();
		for (RSSItem channel : rssList)
		{
			stringList.add(channel.getTitle() + "#" + channel.getLink());
		}
		return stringList;
	}
	
	public static ArrayList<RSSItem> toRSSItemList(ArrayList<String> stringList)
	{
		ArrayList<RSSItem> rssList = new ArrayList<RSSItem>();
		if (stringList != null)
			for (String string : stringList)
			{
				RSSItem item = new RSSItem();
				item.setTitle(string.substring(0, string.indexOf("#")));
				item.setLink(string.substring(string.indexOf("#") + 1));
				rssList.add(item);
			}
		return rssList;
	}
}
