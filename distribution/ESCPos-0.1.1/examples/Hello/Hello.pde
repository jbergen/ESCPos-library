import ESCPos.*;
import processing.serial.*;

Serial port;
ESCPos printer;

void setup(){
  //output a list of available serial ports
  //println(Serial.list());
  
  //start Serial connection
  port = new Serial(this, Serial.list()[0], 9600);
  //instantiate ESCPos library
  printer = new ESCPos(this, port);
  
  printer.printAndFeed("Hello World",4);
  
  //printer.printSampler();
  
  exit();
}

void draw(){
  
}
