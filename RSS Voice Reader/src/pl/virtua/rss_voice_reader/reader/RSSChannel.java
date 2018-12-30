package pl.virtua.rss_voice_reader.reader;

public class RSSChannel {

	private String name;
	private String link;
	
	public RSSChannel(String name, String link)
	{
		this.name = name;
		this.link = link;
	}
	
	public String getName()
	{
		return name;
	}
	
	public void setName(String name)
	{
		this.name = name;
	}
	
	public String getLink()
	{
		return link;
	}
	
	public void setLink(String link)
	{
		this.link = link;
	}
	
	@Override
	public String toString()
	{
		return name;
	}
	
	@Override
	public boolean equals(Object o)
	{
		RSSChannel channel = (RSSChannel) o;
		if (this.name.equalsIgnoreCase(channel.getName()) &&
				this.link.equalsIgnoreCase(channel.getLink()))
			return true;
		return false;
	}
}
