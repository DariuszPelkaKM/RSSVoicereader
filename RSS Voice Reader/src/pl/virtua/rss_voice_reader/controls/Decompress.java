package pl.virtua.rss_voice_reader.controls;

import android.util.Log; 
import java.io.File; 
import java.io.FileInputStream; 
import java.io.FileOutputStream; 
import java.util.zip.ZipEntry; 
import java.util.zip.ZipInputStream; 

import pl.virtua.rss_voice_reader.FeedsActivity;
import pl.virtua.rss_voice_reader.R;
 
/** 
 * 
 * @author jon 
 */ 
public class Decompress { 
  private String _zipFile; 
  private String _location; 
  private FeedsActivity tba;
  private int sumRead;
  private long fileSize;
  private String fileName;
 
  public Decompress(String zipFile, String location, FeedsActivity tba) { 
	    _zipFile = zipFile; 
	    _location = location; 
	    this.tba = tba;
	 
	    _dirChecker(""); 
  } 
 
  public void unzip() { 
    try  { 
    	FileInputStream fin = new FileInputStream(_zipFile); 
    	ZipInputStream zin = new ZipInputStream(fin); 
    	ZipEntry ze = null; 
    	while ((ze = zin.getNextEntry()) != null) { 
    		Log.v("browser", "Unzipping " + ze.getName()); 
    		fileName = ze.getName();
        if(ze.isDirectory()) { 
        	_dirChecker(ze.getName()); 
        } else { 
        	FileOutputStream fout = new FileOutputStream(_location + ze.getName()); 
        	fileSize = ze.getSize();
        	byte[] buffer = new byte[1024];
        	int read;
        	sumRead = 0;
        	while((read = zin.read(buffer)) != -1)
        	{
        		fout.write(buffer, 0, read);
        		sumRead += read;
        		tba.getHandler().post(refreshDialog);
        	}
 
        	zin.closeEntry(); 
        	fout.close(); 
        } 
         
      } 
      zin.close(); 
      
      File zip = new File(_zipFile);
      zip.delete();
    } catch(Exception e) { 
      Log.e("Decompress", "unzip", e); 
    } 
 
  } 
 
  private void _dirChecker(String dir) { 
    File f = new File(_location + dir); 
 
    if(!f.isDirectory()) { 
      f.mkdirs(); 
    } 
  } 
  
  private Runnable refreshDialog = new Runnable() {
	  public void run()
	  {
		  tba.getDialog().setTitle(tba.getString(R.string.decompressing) +  " " + fileName);
		  tba.getDialogBar().setProgress((int)((double)((double)sumRead / (double)fileSize) * 100));
	  }
  };
} 
