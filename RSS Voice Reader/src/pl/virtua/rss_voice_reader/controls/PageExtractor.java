package pl.virtua.rss_voice_reader.controls;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.util.ArrayList;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;

import android.content.Context;
import android.util.Log;

public class PageExtractor {

	private static final int MIN_CHARS_IN_TEXT = 50;
	
	
	public static void exportPageToFile(Context context, String url, String fileName) {
		try
    	{
	    	HttpClient client = new DefaultHttpClient();
	    	HttpGet request = new HttpGet(url);
	    	HttpResponse response = client.execute(request);
	
	    	InputStream in = response.getEntity().getContent();
	    	StringBuilder str = new StringBuilder();

	    	BufferedOutputStream fos = new BufferedOutputStream(context.openFileOutput(fileName, context.MODE_WORLD_WRITEABLE));//new BufferedOutputStream(new FileOutputStream(file, false)); 
            byte buf[] = new byte[1024]; 
            int numBytesRead; 
            do 
            { 
                    numBytesRead = in.read(buf); 
                    if (numBytesRead > 0) 
                    { 
                    	for (int i =0; i < numBytesRead; i++)
                    		if (buf[i] == (byte)0xA9)
                    			buf[i] = (byte)0x63;

                        fos.write(buf, 0, numBytesRead); 

                    } 
            } while (numBytesRead > 0); 
	    	fos.flush(); 
            fos.close(); 
	    	in.close();
    	} catch (Exception e) {}
	}
	
	public static String getPageHTML(Context context, String url) {
    	String html = "";
    	try
    	{
	    	HttpClient client = new DefaultHttpClient();
	    	HttpGet request = new HttpGet(url);
	    	HttpResponse response = client.execute(request);
	
	    	InputStream in = response.getEntity().getContent();
	    	StringBuilder str = new StringBuilder();

	    	BufferedOutputStream fos = new BufferedOutputStream(context.openFileOutput("tekst.txt", context.MODE_WORLD_WRITEABLE));//new BufferedOutputStream(new FileOutputStream(file, false)); 
            byte buf[] = new byte[1024]; 
            int numBytesRead; 
            do 
            { 
                    numBytesRead = in.read(buf); 
                    if (numBytesRead > 0) 
                    { 
                    	
                        fos.write(buf, 0, numBytesRead); 

                    } 
            } while (numBytesRead > 0); 
	    	fos.flush(); 
            fos.close(); 
	    	in.close();
	    	
	    	try {
	    	    // open the file for reading
	    	    InputStream instream = context.openFileInput("tekst.txt");
	    	 
	    	    // if file the available for reading
	    	    if (instream != null) {
	    	      // prepare the file for reading
	    	      InputStreamReader inputreader = new InputStreamReader(instream);
	    	      BufferedReader buffreader = new BufferedReader(inputreader);
	    	 
	    	      String line2;
	    	      
	    	      do {
	    	    	  line2 = buffreader.readLine();
	    	    	  str.append(line2);
	    	      } while (line2 != null);

	    	      buffreader.close(); 
	    	      inputreader.close(); 
	    	    }
	    	 
	    	    // close the file again
	    	    instream.close();
	    	  } catch (Exception e) {
	    	    // do something if the myfilename.txt does not exits
	    		  Log.i("mobiks", e.getMessage());
	    	  } 
	    	  
	    	html = getStringToRead(str.toString());
    	} catch (Exception en) {Log.i("mobiks", "cosik nie tak: " + en.getMessage());}
    	return html;
    }
    
    private static String getStringToRead(String page)
    {
    	String result = "";
    	int begIndex, endIndex;
    	result = page.replaceAll("\n", "");
    	result = result.replaceAll("\r", "");
    	result = result.replaceAll("&nbsp;", "");
    	do {
    		begIndex = result.indexOf("<script");
    		if (begIndex > 0)
    		{
    			endIndex = result.indexOf("</script>");
    			result = result.substring(0, begIndex) + result.substring(endIndex + 9);
    		}
    	} while (begIndex > 0);
    	do {
    		begIndex = result.indexOf("<style");
    		if (begIndex > 0)
    		{
    			endIndex = result.indexOf("</style>");
    			result = result.substring(0, begIndex) + result.substring(endIndex + 8);
    		}
    	} while (begIndex > 0);
    	do {
    		begIndex = result.indexOf("<!--");
    		if (begIndex > 0)
    		{
    			endIndex = result.indexOf("-->");
    			result = result.substring(0, begIndex) + result.substring(endIndex + 3);
    		}
    	} while (begIndex > 0);
    	do {
    		begIndex = result.indexOf("<iframe");
    		if (begIndex > 0)
    		{
    			endIndex = result.indexOf("iframe>");
    			result = result.substring(0, begIndex) + result.substring(endIndex + 7);
    		}
    	} while (begIndex > 0);
    	
    	ArrayList<HTMLChunk> usefulChunks = new ArrayList<HTMLChunk>();

    	ArrayList<String> lines = new ArrayList<String>();
    	String[] allLines;
    	
    	allLines = result.split("</.*?>");
        //lines should not be longer than 1000 bytes
    	for (String arrayLine : allLines)
    	{
    		if (arrayLine.length() > 1000)
    		{
    			while (arrayLine.length() > 1000)
    			{
    				lines.add(arrayLine.substring(0, 1000));
    				arrayLine = arrayLine.substring(1001);
    			}
    		}
    		lines.add(arrayLine);
    	}
    	
    	for (String arrayLine : lines)
    	{
    		arrayLine = arrayLine.trim();
    		
    		String text = "";
            boolean inMarkup = false;
            float numCharsMarkup = 0;
            float numCharsText = 0;

            for(int i=0; i<arrayLine.length(); ++i)
            {
                char ch = arrayLine.charAt(i);
                if(ch == '<')
                {
                    inMarkup = true;
                }
                else if(ch == '>')
                {
                    inMarkup = false;
                }
                else
                {
                    if(inMarkup)
                        numCharsMarkup += 1;
                    else
                        text += ch;
                }
            }
            
            String chunkText = text.trim();
            if(chunkText.length() >= MIN_CHARS_IN_TEXT)
            {
                float density = (numCharsText+1) / (numCharsMarkup+numCharsText+1);
                
                HTMLChunk chunk = new HTMLChunk(text, density, true);
                usefulChunks.add(chunk);
            }
    	}
    	
    	result = "";
    	for(HTMLChunk chunk : usefulChunks)
        	result += chunk.getChunkString();
        
    	return result.trim();
    }
    
    static class HTMLChunk
    {
        String chunkString;
        float density;
        boolean keep;
        
        public HTMLChunk(String text, float density, boolean keep)
        {
        	this.chunkString = text;
        	this.density = density;
        	this.keep = keep;
        }
        
        public String getChunkString()
        {
        	return chunkString;
        }
    }
}
