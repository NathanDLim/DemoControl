import processing.serial.*;


DisplayController controller;
String inString;
Serial myPort;


public void settings() {
  //size(2200,1000); 
  fullScreen();

  
  if(myPort.list().length >= 3){
    myPort = new Serial(this, myPort.list()[myPort.list().length - 1], 9600); 
    myPort.bufferUntil('\n'); 
    delay(100);
    myPort.write("NONE");
  }else{
    println("No Arduino Connected");
    exit();
    myPort = null; 
  }

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
  final int EMG_BUTTONX = displayWidth*3/4;
  final int EMG_BUTTONY = displayHeight/2;
  final int ECG_BUTTONX = displayWidth/4;
  final int ECG_BUTTONY = displayHeight/2;
  final int BUTTONSIZE_1 = 400;
  final int BUTTONSIZE_2 = 100;
  
  final int LEARNX = displayWidth/3;
  final int LEARNY = displayHeight/2;
  final int LEARN_SIZEY = 800;
  final int LEARN_SIZEX = 900;
  final int ECG_LEARNABOUTX = displayWidth/4;
  final int ECG_LEARNABOUTY = displayHeight/2;
  final int EMG_DEMOX = displayWidth*3/4;
  final int EMG_DEMOY = displayHeight/2;
  final int ECG_DEMOX = displayWidth*3/4;
  final int ECG_DEMOY = displayHeight/2;
  final int RETURNX = displayWidth-100;
  final int RETURNY = displayHeight-100;
  
  final int FLAPPYX = 400;
  final int FLAPPYY = 100;
  
  static final int REPEAT_TIME = 15; //in seconds
  
  DisplayScreen currentScreen;
  LineGraph line; //used for the ECG and EMG
  BarGraph bar;   // used only for the EMG
  PImage heartImg, 
         muscleImg, 
         lightbulbImg,
         emgSigImg,
         ecgSigImg,
         bg; //display the images for the current screen
  
  Serial myPort;        // The serial port
  FlappyRaven emgGame;
  
  String ECGInfo = "",
         EMGInfo= "";
  
  public DisplayController(Serial port){
    currentScreen = DisplayScreen.NONE;
    bg = loadImage("MainBackground.jpg");
    heartImg = loadImage("heart3.png");
    heartImg.resize(0,300);
    muscleImg = loadImage("muscle.png");
    muscleImg.resize(0,400);
    lightbulbImg = loadImage("lightbulb.png");
    lightbulbImg.resize(0,100);
    emgSigImg = loadImage("emgSignal.png");
    ecgSigImg = loadImage("ecgSignal.png");
    ecgSigImg.resize(0,150);
    
    String[] t = loadStrings("ECG.txt");
    for(int i = 0; i < t.length; i++){
      ECGInfo += t[i] + "\n";
    }
    
    t = loadStrings("EMG.txt");
    for(int i = 0; i < t.length; i++){
      EMGInfo += t[i] + "\n";
    }
    
    myPort = port;
  }
  
  //Takes a string and adds it onto the appropriate graph.
  public void update(String in){
    
    if(in == null)
      return;
    
    
    String inString = trim(in);
    
    switch(currentScreen){
      case ECG_DEMO:
        float inByte;
          
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

        break;
      case EMG_DEMO:

           
         // Parses the data on spaces, converts to floats, and puts each number into the array
         float[] floatArray;
         floatArray = float(split(inString, " "));
         
         // Make sure the array is at least 2 strings long.   
         if (floatArray.length >= 2) {
           // Assign the two numbers to variables so they can be drawn
           line.update(floatArray[0]);
           bar.update(floatArray[1]);
           // You could do the drawing down here in the serialEvent, but it would be choppy
         }
         
        break;
      
    }
  }
  
  
  /*
   * The draw function draws depending on which screen is currently being displayed
   */
  public void draw(){
    image(bg,0,0);
    textSize(38);
    textAlign(CENTER, CENTER);
    strokeWeight(3);
    
    switch(currentScreen){

      //This is the starting screen, two options, EMG or ECG
      case NONE:
        fill(0xff,180);
        strokeWeight(0);        
        rect(displayWidth*0.07, displayHeight*0.07, displayWidth*0.86, displayHeight*0.86, 250);
        strokeWeight(3);
        rect(displayWidth*0.0625, displayHeight*0.0625, displayWidth*0.875, displayHeight*0.875, 250);
        
        textSize(38);
        fill(0);
        text("Choose an option to Demo", displayWidth/2, displayHeight*0.125);
        
        fill(0xff,180);
        textSize(28);
        image(heartImg,ECG_BUTTONX-200,height/2+70);
        image(muscleImg,EMG_BUTTONX-20,height/2);
        
        ellipse(ECG_BUTTONX, height/2, BUTTONSIZE_1, BUTTONSIZE_1);
        ellipse(EMG_BUTTONX, height/2, BUTTONSIZE_1, BUTTONSIZE_1);
        
        fill(0);
        
        text("Electromyography", EMG_BUTTONX,height/2);
        text("Electrocardiography", ECG_BUTTONX,height/2);
        break;
        
      //This is the EMG screen. It displays information about what EMG is and has two buttons: EMG Demo and Return
      case EMG:
        
        fill(0xff,240);

        ellipse(EMG_DEMOX, EMG_DEMOY, BUTTONSIZE_1, BUTTONSIZE_1);
        ellipse(RETURNX, RETURNY, BUTTONSIZE_2, BUTTONSIZE_2);
        
        //Info Container
        //fill(0xff);
        rect(LEARNX - LEARN_SIZEX/2,LEARNY - LEARN_SIZEY/2, LEARN_SIZEX, LEARN_SIZEY,40);
        fill(0);
        
        textSize(28);
        text("What is Electromyography?",LEARNX,LEARNY - LEARN_SIZEY*3/8);
        
        textSize(18);
        text(EMGInfo,LEARNX - LEARN_SIZEX*3/8,LEARNY - LEARN_SIZEY*3/8, LEARN_SIZEX*0.75,LEARN_SIZEY*0.75);
        image(lightbulbImg,LEARNX-LEARN_SIZEX/2+20,LEARNY-LEARN_SIZEY/2+20);
        image(emgSigImg,LEARNX-LEARN_SIZEX/2+100,LEARNY+180);
        
        textSize(28);
        text("EMG Demo", EMG_DEMOX,EMG_DEMOY);
        
        textSize(20);
        text("Return", RETURNX,RETURNY);
        
        break;
        
      //This is the EMG Demo. It shows the EMG raw data and the enveloped data in a bar graph. It has a Return button
      case EMG_DEMO:
        strokeWeight(1);
        bar.draw();
        line.draw();
        
        emgGame.draw();
        
        
        textAlign(CENTER, CENTER);
        stroke(0);
        strokeWeight(3);
        fill(0xff,240);
        ellipse(RETURNX, RETURNY, BUTTONSIZE_2, BUTTONSIZE_2);
        fill(0);
        textSize(20);
        text("Return", RETURNX,RETURNY);
        
        break;
        
      //This is the ECG screen. It displays information about what ECG is and has two buttons: ECG Demo and Return
      case ECG:
        
        fill(0xff, 240);
        ellipse(ECG_DEMOX, ECG_DEMOY, BUTTONSIZE_1, BUTTONSIZE_1);
        ellipse(RETURNX, RETURNY, BUTTONSIZE_2, BUTTONSIZE_2);
        
        //ECG Info container
        //fill(0xff);
        rect(LEARNX - LEARN_SIZEX/2,LEARNY - LEARN_SIZEY/2, LEARN_SIZEX, LEARN_SIZEY,40);
        fill(0);
        textSize(28);
        text("What is Electrocardiography?",LEARNX,LEARNY - LEARN_SIZEY*3/8);
        
        textSize(18);
        text(ECGInfo,LEARNX - LEARN_SIZEX*3/8,LEARNY - LEARN_SIZEY*3/8, LEARN_SIZEX*0.75,LEARN_SIZEY*0.75);
        image(lightbulbImg,LEARNX-LEARN_SIZEX/2+20,LEARNY-LEARN_SIZEY/2+20);
        image(ecgSigImg,LEARNX - LEARN_SIZEX*3/8+100,LEARNY+230);
        
        textSize(28);
        text("ECG Demo", ECG_DEMOX, ECG_DEMOY);
        textSize(20);
        text("Return", RETURNX,RETURNY);
        
        break;
      
      //This is the ECG Demo screen. It has a line graph showing the ECG signal and has a Return button too
      case ECG_DEMO:
        strokeWeight(1);
        line.draw();
        
        strokeWeight(3);
        fill(0xff,240);
        ellipse(RETURNX, RETURNY, BUTTONSIZE_2, BUTTONSIZE_2);
        fill(0);
        textSize(20);
        text("Return", RETURNX,RETURNY);
        stroke(0);
        
        textSize(32);
        fill(0, 102, 153, 51);
        text(line.getNumBeats()*60/REPEAT_TIME + " BPM", 250, 280);  // Specify a z-axis value
        
        break;
    }
  }
 
  /*
   * This function is called to switch between screens. It is responsible for sending data to the Arduino to tell it to switch modes too. It creates the graphs and game for the demo.
   */
  private void switchTo(DisplayScreen ds){
     switch(ds){
      case NONE:
        
        line = null;
        bar = null;
        currentScreen = DisplayScreen.NONE;
        
        
        break;
      case EMG:
        if(currentScreen == DisplayScreen.EMG_DEMO){
          myPort.write("NONE");
          myPort.clear(); 
        }
        currentScreen = DisplayScreen.EMG;
        
        
        break;
      case EMG_DEMO:
        bar = new BarGraph(450,height-40, 200, 1000,350,"Enveloped Signal");
        line = new LineGraph(60,height-40,350,350,350,-150,150,"Raw Signal",false);
        emgGame =  new FlappyRaven(400,100);

        currentScreen = DisplayScreen.EMG_DEMO;
        myPort.write("EMG");
        myPort.clear();
        break;
      case ECG:
        if(currentScreen == DisplayScreen.ECG_DEMO){
          myPort.write("NONE");
          myPort.clear(); 
        }
        currentScreen = DisplayScreen.ECG;

        break;
      case ECG_DEMO:
        bar = null;
        line = new LineGraph(200,700,REPEAT_TIME*100,400,REPEAT_TIME*100,0, 1100,"ECG Data",true);
        currentScreen = DisplayScreen.ECG_DEMO;
        
        myPort.write("ECG");
        myPort.clear();
        break;
     }
  }
   
   
   
  /*
   * This function is called whenever the mouse is clicked. It specifies regions where the buttons will take effect. It calls the switchTo() function
   */
  public void buttonCheck(){
       switch(currentScreen){
      case NONE:
        if((mouseX-EMG_BUTTONX)*(mouseX-EMG_BUTTONX) + (mouseY- EMG_BUTTONY)*(mouseY- EMG_BUTTONY) <= BUTTONSIZE_1/2*BUTTONSIZE_1/2){
          switchTo(DisplayScreen.EMG);  
        }else if((mouseX-ECG_BUTTONX)*(mouseX-ECG_BUTTONX) + (mouseY- ECG_BUTTONY)*(mouseY-ECG_BUTTONY) <= BUTTONSIZE_1/2*BUTTONSIZE_1/2){
          switchTo(DisplayScreen.ECG);          
        }
        break;
      case EMG:
        if((mouseX-LEARNX)*(mouseX-LEARNX) + (mouseY- LEARNY)*(mouseY- LEARNY) <= BUTTONSIZE_1/2*BUTTONSIZE_1/2){
          //currentScreen = DisplayScreen.EMG;
        }else if((mouseX-EMG_DEMOX)*(mouseX-EMG_DEMOX) + (mouseY- EMG_DEMOY)*(mouseY- EMG_DEMOY) <= BUTTONSIZE_1/2*BUTTONSIZE_1/2){
          switchTo(DisplayScreen.EMG_DEMO);
        }else if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= BUTTONSIZE_2/2*BUTTONSIZE_2/2){
          switchTo(DisplayScreen.NONE);
        }
        break;
      case EMG_DEMO:
        if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= BUTTONSIZE_2/2*BUTTONSIZE_2/2){
          switchTo(DisplayScreen.EMG);
        }else if(bar.insideGraph(mouseX,mouseY)){
          bar.setThreshold(mouseY);
          myPort.write("THRSH:" + str(bar.getThreshold()));
          //println("THRSH:" + str(bar.getThreshold()));
        }else if(mouseX > FLAPPYX && mouseX < FLAPPYX + 1000 && mouseY > FLAPPYY && mouseY < FLAPPYY + 500){
          emgGame.mouseClicked(); 
        }
        break;
      case ECG:
        if((mouseX-LEARNX)*(mouseX-LEARNX) + (mouseY- LEARNY)*(mouseY- LEARNY) <= BUTTONSIZE_1/2*BUTTONSIZE_1/2){
          println("you clicked to Learn about ECG");
          //currentScreen = DisplayScreen.EMG;
        }else if((mouseX-ECG_DEMOX)*(mouseX-ECG_DEMOX) + (mouseY- ECG_DEMOY)*(mouseY- ECG_DEMOY) <= BUTTONSIZE_1/2*BUTTONSIZE_1/2){
          switchTo(DisplayScreen.ECG_DEMO);
        }else if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= BUTTONSIZE_2/2*BUTTONSIZE_2/2){
          switchTo(DisplayScreen.NONE);
        }
        break;
      case ECG_DEMO:
        if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= BUTTONSIZE_2/2*BUTTONSIZE_2/2){
          switchTo(DisplayScreen.ECG);
        }
        break;
    }
  }
  
}