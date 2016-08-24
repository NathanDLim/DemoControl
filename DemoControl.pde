import processing.serial.*;


DisplayController controller;
String inString;
Serial myPort;

public void settings() {
  size(2200,1000); 

  myPort = new Serial(this, myPort.list()[myPort.list().length - 1], 9600); 
  myPort.bufferUntil('\n'); 
  delay(100);
  myPort.write('0');
  controller = new DisplayController(myPort);
}

void draw(){
  //if(myPort.available() > 0){
  //   inString = myPort.readStringUntil('\n');
  //}
  //controller.update(inString);
  controller.draw();
}

void mouseReleased(){
 controller.buttonCheck(); 
}

void serialEvent (Serial myPort) {
  // get the ASCII string:
  String inString = myPort.readStringUntil('\n');
  controller.update(inString);
}

/*
 *  This class controls Demo. It has many different screens controlled by the enum DisplayScreen defined in types.java
 */
public class DisplayController{
  
  //These store the locations of the buttons
  final int EMG_BUTTONX = width*3/5;
  final int EMG_BUTTONY = height/2;
  final int ECG_BUTTONX = width/4;
  final int ECG_BUTTONY = height/2;
  final int EMG_LEARNABOUTX = width/4;
  final int EMG_LEARNABOUTY = height/2;
  final int ECG_LEARNABOUTX = width/4;
  final int ECG_LEARNABOUTY = height/2;
  final int EMG_DEMOX = width*2/4;
  final int EMG_DEMOY = height/2;
  final int ECG_DEMOX = width*2/4;
  final int ECG_DEMOY = height/2;
  final int RETURNX = 920;
  final int RETURNY = height-200;
  
  static final int REPEAT_TIME = 15; //in seconds
  
  DisplayScreen currentScreen;
  LineGraph line; //used for the ECG and EMG
  BarGraph bar;   // used only for the EMG
  PImage img1,img2, bg; //display the images for the current screen
  Serial myPort;        // The serial port
  PApplet emgGame;
  
  public DisplayController(Serial port){
    currentScreen = DisplayScreen.NONE;
    bg = loadImage("MainBackground.jpg");
    img1 = loadImage("heart.png");
    img1.resize(0,400);
    img2 = loadImage("muscle.png");
    img2.resize(0,500);
    
    myPort = port;
  }
  
  //Takes a string and adds it onto the appropriate graph.
  public void update(String in){
    switch(currentScreen){
      case ECG_DEMO:
        float inByte;
        if (in != null) {
          // trim off any whitespace:
          inString = trim(in);
          
          // If leads off detection is true notify with blue line
          if (inString.equals("!")) {
            inByte = 350;  // middle of the ADC range (Flat Line)
          }
          // If the data is good let it through
          else {
            inByte = float(inString); 
           }
           
           //Map and draw the line for new data point
           inByte = map(inByte, 0, 700, 0, height);
           
           line.update(inByte);
          
        }
        break;
      case EMG_DEMO:
      
        break;
      
    }
  }
  
  public void draw(){
    background(bg);
    textSize(28);
    //textFont(
    switch(currentScreen){
      
      case NONE:
        fill(0xff, 150);

        
        image(img1,ECG_BUTTONX-400,height/2-220);
        image(img2,EMG_BUTTONX-100,height/2-240);
        
        ellipse(ECG_BUTTONX, height/2, 400, 400);
        ellipse(EMG_BUTTONX, height/2, 400, 400);
        
        fill(0);
        textAlign(CENTER);
        text("Electromyography", EMG_BUTTONX,height/2);
        text("Electrocardiography", ECG_BUTTONX,height/2);
        break;
        
      case EMG:
        image(img1,20,20);
        fill(0xff);
        ellipse(EMG_LEARNABOUTX,EMG_LEARNABOUTY, 300, 300);
        ellipse(EMG_DEMOX, EMG_DEMOY, 300, 300);
        ellipse(RETURNX, RETURNY, 100, 100);
        
        fill(0);
        textAlign(CENTER);
        text("Learn about EMG", EMG_LEARNABOUTX,EMG_LEARNABOUTY);
        text("EMG Demo", EMG_DEMOX,EMG_DEMOY);
        text("Return", RETURNX,RETURNY);
        
        break;
      case EMG_DEMO:
        bar.draw();
        line.draw();
        
 
        
        fill(0xff);
        ellipse(RETURNX, RETURNY, 100, 100);
        fill(0);
        text("Return", RETURNX,RETURNY);
        break;
      case ECG:
        image(img1,20,20);
        fill(0xff);
        ellipse(ECG_LEARNABOUTX, ECG_LEARNABOUTY, 300, 300);
        ellipse(ECG_DEMOX, ECG_DEMOY, 300, 300);
        ellipse(RETURNX, RETURNY, 100, 100);
        
        fill(0);
        textAlign(CENTER);
        text("Learn about ECG", ECG_LEARNABOUTX, ECG_LEARNABOUTY);
        text("ECG Demo", ECG_DEMOX, ECG_DEMOY);
        text("Return", RETURNX,RETURNY);
        
        break;
        
      case ECG_DEMO:
        background(0xff);
        line.draw();
        fill(0xff);
        ellipse(RETURNX, RETURNY, 100, 100);
        fill(0);
        text("Return", RETURNX,RETURNY);
        stroke(0);
        
        textSize(32);
        fill(0, 102, 153, 51);
        text(line.getNumBeats()*60/REPEAT_TIME + " BPM", 100, 35);  // Specify a z-axis value
        
        

        break;
    }
    
  }
 
  
  private void switchTo(DisplayScreen ds){
     switch(ds){
      case NONE:
        img1 = loadImage("heart.png");
        img1.resize(0,400);
        img2 = loadImage("muscle.png");
        img2.resize(0,500);
        
        line = null;
        bar = null;
        currentScreen = DisplayScreen.NONE;
        
        myPort.write('0');
        break;
      case EMG:
        img1 = loadImage("lightbulb.png");
        currentScreen = DisplayScreen.EMG;
        
        myPort.write('0');
        break;
      case EMG_DEMO:
        bar = new BarGraph(450,height-40, 200, 1000,350,TriggerType.RISING_EDGE);
        line = new LineGraph(20,height-20,500,400,400,-90,600,false);
        
        emgGame =  new FlappyRaven();
        runSketch( new String[] { "--display=1",
                          "--location=0,0",
                          "--sketch-path=" + sketchPath(),
                          "" },
          emgGame);
        currentScreen = DisplayScreen.EMG_DEMO;
        break;
      case ECG:
        img1 = loadImage("lightbulb.png");
        currentScreen = DisplayScreen.ECG;
        
        myPort.write('0');
        break;
      case ECG_DEMO:
        bar = null;
        line = new LineGraph(100,height/2,REPEAT_TIME*100,400,REPEAT_TIME*100,0, 700,true);
        currentScreen = DisplayScreen.ECG_DEMO;
        
        myPort.write('1');
        break;
     }
  }
   
  public void buttonCheck(){
       switch(currentScreen){
      case NONE:
        if((mouseX-EMG_BUTTONX)*(mouseX-EMG_BUTTONX) + (mouseY- EMG_BUTTONY)*(mouseY- EMG_BUTTONY) <= 150*150){
          println("you clicked EMG");
          switchTo(DisplayScreen.EMG);  
        }else if((mouseX-ECG_BUTTONX)*(mouseX-ECG_BUTTONX) + (mouseY- ECG_BUTTONY)*(mouseY-ECG_BUTTONY) <= 150*150){
          println("you clicked ECG");
          switchTo(DisplayScreen.ECG);          
        }
        break;
      case EMG:
        if((mouseX-EMG_LEARNABOUTX)*(mouseX-EMG_LEARNABOUTX) + (mouseY- EMG_LEARNABOUTY)*(mouseY- EMG_LEARNABOUTY) <= 150*150){
          println("you clicked to Learn about EMG");
          //currentScreen = DisplayScreen.EMG;
        }else if((mouseX-EMG_DEMOX)*(mouseX-EMG_DEMOX) + (mouseY- EMG_DEMOY)*(mouseY- EMG_DEMOY) <= 150*150){
          println("you clicked EMG Demo");
          switchTo(DisplayScreen.EMG_DEMO);
        }else if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= 50*50){
          println("you clicked Return");
          switchTo(DisplayScreen.NONE);
        }else if(bar.insideGraph(mouseX,mouseY)){
          //myPort.write("THRSH:" + str(bGraph.getTT()) + ":" + str(bGraph.getThreshold()));
          bar.setThreshold(mouseY);
          println("THRSH:" + str(bar.getTT()) + ":" + str(bar.getThreshold()));
        }
        break;
      case EMG_DEMO:
        if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= 50*50){
          println("you clicked Return");
          //emgGame.exit();
          switchTo(DisplayScreen.EMG);
        }
        break;
      case ECG:
        if((mouseX-ECG_LEARNABOUTX)*(mouseX-ECG_LEARNABOUTX) + (mouseY- ECG_LEARNABOUTY)*(mouseY- ECG_LEARNABOUTY) <= 150*150){
          println("you clicked to Learn about ECG");
          //currentScreen = DisplayScreen.EMG;
        }else if((mouseX-ECG_DEMOX)*(mouseX-ECG_DEMOX) + (mouseY- ECG_DEMOY)*(mouseY- ECG_DEMOY) <= 150*150){
          println("you clicked ECG Demo");
          switchTo(DisplayScreen.ECG_DEMO);
        }else if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= 50*50){
          println("you clicked Return");
          switchTo(DisplayScreen.NONE);
        }
        break;
      case ECG_DEMO:
        if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= 50*50){
          println("you clicked Return");
          switchTo(DisplayScreen.ECG);
        }
        break;
    }
  }
  
}