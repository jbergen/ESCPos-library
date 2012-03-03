// printImage( brightnessArray, width, height, characterWidth, brightnessAdjustment, grid );

// printer settings
//small BIX STP-103 is 384 dots wide
// STP-350plus is 528 dots wide
int printWidth = 384; // in dots. should match the printer
int gridSpacing = 24; // 0 = no grid, 23 = roughly square on the BIX
int brightnessAdjustment = -12; // darker < 0 < lighter

 // 0 = 8 dot single density (square pixels)
 // 1 = 8 dot double density (1x3 pixels | vertical)
 // 32 = 24 dot single density
 // 33 = 24 dot double density (1x1 square pixels)
int printMode = 33;

int ditherMode = 1; // 0 = Floyd Steinberg, 1 = Atkinson

void printImage(PImage f)
{
  PImage img = makePrintable(f);
  int[] bytes = parseImageToBytes(img);
  printToThermal( bytes );
}

/**********

adjusts the image before printing
resizes if needed

**********/
PImage makePrintable(PImage img)
{
  float r = (float) img.height / (float)img.width;
  int widthInDots = ( printMode == 0 || printMode == 32) ? printWidth / 2 : printWidth;
  float verticalStretch = ( printMode == 0 || printMode == 1 ) ? 1.0/3.0 : 1;
  int scaledHeight = (int) ( ( verticalStretch * ( printWidth * r ) ) );
  
  img.loadPixels();  
  img.resize( widthInDots , scaledHeight );
  return img;
}

/**********

includes dithering logic

**********/
int[] parseImageToBytes(PImage img)
{
  int numBytes = ceil(img.height/8.0 ) * img.width;
  int[] bytes = new int[ numBytes ];
  String[] binaryStringArray = new String[ numBytes ];
  
  for(int j = 0 ; j < binaryStringArray.length ; j++){ binaryStringArray[j] = "";}
  img.loadPixels();
  
  // make img.pixels array into value of brightness
  float[] imgBrightness = new float[img.pixels.length];
  for( int i = 0 ; i < img.pixels.length ; i++ )
  {
    imgBrightness[i] = brightness( img.pixels[i] ) + brightnessAdjustment;
  }
  
  
  
  int grey = 126; //threshold grey
  
  for( int y = 0 ; y < img.height ; y ++)
  {
    for( int x = 0 ; x < img.width ; x++)
    { 
      float oldPixel = imgBrightness[ img.width * y + x ];
      float newPixel = (oldPixel < grey) ? 0 : 255;
      
     imgBrightness[ img.width * y + x ] = newPixel;
     float quantError = oldPixel - newPixel;     
     
     if(ditherMode == 1)
     {
       //
       // Atkinson
       // http://verlagmartinkoch.at/software/dither/index.html
       //
       //        *   1/8  1/8
       //  1/8  1/8  1/8
       //       1/8
       
       if( (x % img.width) < img.width-1 ) imgBrightness[ img.width * y + (x+1) ] += ( 1.0/8.0 * quantError );
       if( (x % img.width) < img.width-2 ) imgBrightness[ img.width * y + (x+2) ] += ( 1.0/8.0 * quantError );

       if( (x % img.width) > 0 && y < img.height-1 ) imgBrightness[ img.width * (y+1) + (x-1) ] += 1.0/8.0 * quantError;
       if( y < img.height-1 ) imgBrightness[ img.width * (y+1) + (x) ] += 1.0/8.0 * quantError;
       if( (x % img.width) < (img.width - 1) && y < (img.height - 1) ) imgBrightness[ img.width * (y+1) + (x+1) ] += 1.0/8.0 * quantError;

       if( y < img.height-2 ) imgBrightness[ img.width * (y+2) + (x) ] += 1.0/8.0 * quantError;
     }
     else
     {
       //
       // Floyd Steinberg
       // http://en.wikipedia.org/wiki/Floyd%E2%80%93Steinberg_dithering
       //
       //          *   7/16
       //  3/16  5/16  1/16
       
       if( (x % img.width) < img.width-1 ) imgBrightness[ img.width * y + (x+1) ] += ( 7.0/16.0 * quantError );
       
       if( (x % img.width) > 0 && y < img.height-1 ) imgBrightness[ img.width * (y+1) + (x-1) ] += 3.0/16.0 * quantError;
       if( y < img.height-1 ) imgBrightness[ img.width * (y+1) + (x) ] += 5.0/16.0 * quantError;
       if( (x % img.width) < (img.width - 1) && y < (img.height - 1) ) imgBrightness[ img.width * (y+1) + (x+1) ] += 1.0/16.0 * quantError;
      }
     //////
     if(printMode == 0)
     {
       //if(y == 15 || y == 16) println(x +":"+y +" - "+ ( (int) floor(y / 8.0)*img.width + (x % img.width) ) );
       binaryStringArray[ (int) floor(y / 8.0)*img.width + (x % img.width) ] += (newPixel == 0 ) ? "1" : "0";
     }
     else if(printMode == 1)
       binaryStringArray[ (int) floor(y / 8.0)*img.width + (x % img.width) ] += (newPixel == 0 ) ? "1" : "0";
     else if(printMode == 32 || printMode == 33)
       binaryStringArray[ (x % img.width) * 3 + floor(y % 24 / 8.0) + floor(y/24) * (3*img.width) ] += (newPixel == 0 ) ? "1" : "0";          //////

  //make sure there isn't a weird gap in the last row
      if( y == img.height-1 && img.height % 8 != 0)
      {
        String filler = "";
        for( int i = 0 ; i < 8 - binaryStringArray[ (int) floor(y / 8.0)*img.width + (x % img.width) ].length() ; i++ )
        {
          filler += "0";
        }
        binaryStringArray[ (int) floor(y / 8.0)*img.width + (x % img.width) ] += filler;
      }
    
    }
  }
  
  for(int i  = 0 ; i < binaryStringArray.length ; i++)
  {
    if( binaryStringArray[i].length() == 0 ) println(binaryStringArray[i]);
  }
  
  
  for( int i = 0 ; i < bytes.length ; i++)
  {
    int space = (printMode == 0 || printMode == 32) ? floor(gridSpacing/2) : gridSpacing;
    if(printMode == 32 || printMode == 33)
      bytes[i] = ( space != 0 && ( i % (3 * space) == 0 || i % ( 3 * space) == 1 || i % ( 3 * space) == 2 ) ) ? 0 : unbinary( binaryStringArray[i] );
    else
      bytes[i] = ( space != 0 && i % space == 0 ) ? 0 : unbinary( binaryStringArray[i] );
    
  }

  return bytes;
}


void printToThermal(int[] bytes )
{
  
  int characterWidth = 8; // set here. printer freaks out if this is much larger
  int d = ( printMode == 32 || printMode == 33 ) ? 3 : 1;
  int widthInDots = ( printMode == 0 || printMode == 32 ) ? printWidth / 2 : printWidth;
  
  for( int i = 0 ; i < bytes.length ; i+= characterWidth * d )
  {
    if( i % ( widthInDots * d ) == 0 && i != 0 ) printer.printStorage();
    
    int[] customCharacterBytes = new int[characterWidth * d];
    arrayCopy( bytes, i , customCharacterBytes , 0 , characterWidth * d);
    printer.storeCustomChar( customCharacterBytes, printMode );
  }
  
  printer.printStorage();
}


