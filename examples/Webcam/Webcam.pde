import processing.video.*;
import ESCPos.*;
import processing.serial.*;

Capture cam;
Serial port;
ESCPos printer;

void setup()
{
  size(640, 480);
  frameRate(10);
  cam = new Capture(this, width, height);
  port = new Serial(this, Serial.list()[0], 9600);
  //instantiate ESCPos library
  printer = new ESCPos(this, port);
}

void draw()
{
  if ( cam.available() == true )
  {
    cam.read();
    image(cam, 0,0);
  }
}

void keyPressed()
{
  if(key == ' ')
  {
    loadPixels();
    PImage capture = createImage(width,height,RGB);
    capture.pixels = pixels;
    printImage( capture );
  }
}
