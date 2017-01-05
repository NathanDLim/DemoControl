import processing.serial.*;


DisplayController controller;
String inString;
Serial myPort;

static final int TIMEOUT = 60*240; //How long the application should wait with no interaction before closing. 60 frames per second * 240 seconds (3 minutes)
int timer; //counter for timeout

final static boolean Debug = true; //Debug should be true when no arduino is attached

public void settings() {
  //size(2200,1000); 
  fullScreen();

  
  timer = 0;
  
  if(myPort.list().length >= 3){
    myPort = new Serial(this, myPort.list()[myPort.list().length - 1], 9600); 
    myPort.bufferUntil('\n'); 
    delay(100);
    myPort.write("NONE");
  }else{
    println("No Arduino Connected");
    if(!Debug) //If not in debug mode, then arduino should be connected to work
      exit();
    myPort = null; 
  }

  controller = new DisplayController(myPort);
}

void draw(){

  timer++;
  if (timer >= TIMEOUT)
    exit();
  
  controller.draw();
}

void mouseReleased(){
 timer= 0; //reset timer when mouse is clicked & released
 controller.buttonCheck(); 
}

void mouseMoved(){
 timer = 0;  //reset timer when mouse is moved
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
  
  /* This is for Portrait Mode */
  final int EMG_BUTTONX = displayWidth*3/4;
  final int EMG_BUTTONY = displayHeight/2;
  final int ECG_BUTTONX = displayWidth/4;
  final int ECG_BUTTONY = displayHeight/2;
  final int BUTTONSIZE_1 = 400;
  final int BUTTONSIZE_2 = 100; //return button
  final int BUTTONSIZE_3 = 70; //home button
  
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
  final int HOMEX = displayWidth-100;
  final int HOMEY = displayHeight-200;
  
  final int FLAPPYX = (displayWidth - 1000)/2;
  final int FLAPPYY = (displayHeight - 500)/2;
  final int EMG_BARX = displayWidth/2-100;
  final int EMG_BARY = displayHeight-40;
  final int EMG_LINEX = displayWidth/2-500;
  final int EMG_LINEY = displayHeight-40;
  final int EMG_INFOX = displayWidth*5/100;
  final int EMG_INFOY = displayHeight*1/10;
  final int EMG_STEPSX = displayWidth*6/10;
  final int EMG_STEPSY = displayHeight*1/10;
  

  
  /* This is for Landscape Mode */
  //final int EMG_BUTTONX = displayWidth*3/4;
  //final int EMG_BUTTONY = displayHeight/2;
  //final int ECG_BUTTONX = displayWidth/4;
  //final int ECG_BUTTONY = displayHeight/2;
  //final int BUTTONSIZE_1 = 400;
  //final int BUTTONSIZE_2 = 100; //return button
  //final int BUTTONSIZE_3 = 70; //home button
  
  //final int LEARNX = displayWidth/3;
  //final int LEARNY = displayHeight/2;
  //final int LEARN_SIZEY = 800;
  //final int LEARN_SIZEX = 900;
  //final int ECG_LEARNABOUTX = displayWidth/4;
  //final int ECG_LEARNABOUTY = displayHeight/2;
  //final int EMG_DEMOX = displayWidth*3/4;
  //final int EMG_DEMOY = displayHeight/2;
  //final int ECG_DEMOX = displayWidth*3/4;
  //final int ECG_DEMOY = displayHeight/2;
  //final int RETURNX = displayWidth-100;
  //final int RETURNY = displayHeight-100;
  //final int HOMEX = displayWidth-100;
  //final int HOMEY = displayHeight-200;
  
  //final int FLAPPYX = 400;
  //final int FLAPPYY = 100;
  //final int EMG_BARX = width/2-100;
  //final int EMG_BARY = height-40;
  //final int EMG_LINEX = width/2-500;
  //final int EMG_LINEY = height-40;
  
  static final int REPEAT_TIME = 15; //in seconds
  
  DisplayScreen currentScreen;
  LineGraph line; //used for the ECG and EMG
  BarGraph bar;   // used only for the EMG
  PImage heartImg, 
         muscleImg, 
         lightbulbImg,
         emgSigImg,
         ecgSigImg,
         returnImg,
         homeImg,
         bg; //display the images for the current screen
  
  Serial myPort;        // The serial port
  FlappyRaven emgGame;
  
  String ECGInfo = "",
         EMGInfo= "";
  boolean ECGOpen;
  
  public DisplayController(Serial port){
    currentScreen = DisplayScreen.NONE;
    bg = loadImage("Portrait.png");
    heartImg = loadImage("heart3.png");
    heartImg.resize(0,300);
    muscleImg = loadImage("muscle.png");
    muscleImg.resize(0,400);
    lightbulbImg = loadImage("lightbulb.png");
    lightbulbImg.resize(0,100);
    emgSigImg = loadImage("emgSignal.png");
    ecgSigImg = loadImage("ecgSignal.png");
    ecgSigImg.resize(0,150);
    returnImg = loadImage("return.png");
    returnImg.resize(0,50);
    homeImg = loadImage("home.png");
    homeImg.resize(0,50);
    
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
            ECGOpen = true;
            inByte = 350;  // middle of the ADC range (Flat Line)
          }
          // If the data is good let it through
          else {
            inByte = float(inString); 
            ECGOpen = false;
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
        rect(displayWidth*0.07, displayHeight*0.135, displayWidth*0.86, displayHeight*0.79, 250);
        strokeWeight(3);
        rect(displayWidth*0.0625, displayHeight*0.12, displayWidth*0.875, displayHeight*0.82, 250);
        
        textSize(38);
        fill(0);
        text("Choose an option to Demo", displayWidth/2, displayHeight*0.19);
        
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
        image(emgSigImg,LEARNX-LEARN_SIZEX/2+200,LEARNY+180);
        
        textSize(10);
        text("(R. Merletti and P. Parker, Electromyography. [2004])", LEARNX - LEARN_SIZEX*3/8+530,LEARNY+155);
        text("Konrad, P. The ABC of EMG. Noraxon Inc. [2006]", LEARNX - LEARN_SIZEX*3/8+420,LEARNY+380);
        
        textSize(28);
        text("EMG Demo", EMG_DEMOX,EMG_DEMOY);
        
        image(returnImg,RETURNX-16,RETURNY-20);
        
        
        break;
        
      //This is the EMG Demo. It shows the EMG raw data and the enveloped data in a bar graph. It has a Return button
      case EMG_DEMO:
        strokeWeight(1);
        bar.draw();
        line.draw();
        
        emgGame.draw();
        
        fill(0xff,240);
        textAlign(LEFT, CENTER);
        stroke(0);
        strokeWeight(3);
        rect(EMG_STEPSX,EMG_STEPSY,400,400,40);
        rect(EMG_INFOX,EMG_INFOY,320,200,40);
        ellipse(RETURNX, RETURNY, BUTTONSIZE_2, BUTTONSIZE_2);
        ellipse(HOMEX, HOMEY, BUTTONSIZE_3, BUTTONSIZE_3);
        
        fill(0);
        textSize(18);
        text("Step 1: Place your arm inside the Y Brace\n\nStep 2: Clench fist and watch Mean Absolute Value increase\n\nStep 3: Click on the Mean Absolute Value graph to set the desired threshold. When the bar rises above the threshold, a mouse click is generated\n\nStep 4: Move mouse to Flappy Raven screen and clench fist to begin",EMG_STEPSX + 15,EMG_STEPSY,380,400);
        textAlign(CENTER, CENTER);
        textSize(22);
        text("If you squeeze harder the amplitude will rise!",EMG_INFOX + 15,EMG_INFOY,290,200);
       
        image(returnImg,RETURNX-16,RETURNY-20);
        image(homeImg,HOMEX-23,HOMEY-26);
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
        image(ecgSigImg,LEARNX - LEARN_SIZEX*3/8+230,LEARNY+220);
        
        textSize(10);
        text("(American Heart Association [2015])", LEARNX - LEARN_SIZEX*3/8+550,LEARNY+200);
        text("ekg.academy [2014]", LEARNX - LEARN_SIZEX*3/8+320,LEARNY+380);
        
        textSize(28);
        text("ECG Demo", ECG_DEMOX, ECG_DEMOY);
        textSize(20);
        image(returnImg,RETURNX-16,RETURNY-20);
        
        break;
      
      //This is the ECG Demo screen. It has a line graph showing the ECG signal and has a Return button too
      case ECG_DEMO:
        strokeWeight(1);
        line.draw();
        
        strokeWeight(3);
        fill(0xff,240);
        ellipse(RETURNX, RETURNY, BUTTONSIZE_2, BUTTONSIZE_2);
        ellipse(HOMEX, HOMEY, BUTTONSIZE_3, BUTTONSIZE_3);
        fill(0);
        image(returnImg,RETURNX-16,RETURNY-20);
        image(homeImg,HOMEX-23,HOMEY-26);
        stroke(0);
        
        textSize(32);
        fill(0, 102, 153, 51);
        text(line.getNumBeats()*60/REPEAT_TIME + " BPM", 290, 270);  // Specify a z-axis value
        
        fill(0xff,240);
        rect( width/4 - 50,height*3/4, 1100, 200,30);
        fill(0);
        textSize(18);
        textAlign(CENTER,CENTER);
        text("Place your hands on the bar with palms touching the front electrode and tips of the fingers touching the back electrode. Your ECG will be displayed on the graph above, to find an accurate Beats Per Minute (BPM), hold the bar for 20 seconds. A detection algorithm is used to identify when the beats occur, highlighted in blue. Try jogging on the spot to increase your heart rate and watch the difference.", width/4,height*3/4, 1000, 200);
        
        if(ECGOpen){
          textSize(38);
          text("Place your hands on the bar to display your ECG",width/2,height/2);
        }
        
        break;
    }
  }
 
  /*
   * This function is called to switch between screens. It is responsible for sending data to the Arduino to tell it to switch modes too. It creates the graphs and game for the demo.
   */
  private void switchTo(DisplayScreen ds){
    
    if(!Debug){
      if(currentScreen == DisplayScreen.EMG_DEMO || currentScreen == DisplayScreen.ECG_DEMO){ //if returning from the EMG demo, tell the arduino to change states
        myPort.write("NONE");
        myPort.clear(); 
      }
    }
    
     switch(ds){
      case NONE:
        
        line = null;
        bar = null;
        currentScreen = DisplayScreen.NONE;
        
        
        break;
      case EMG:

        currentScreen = DisplayScreen.EMG;
        
        
        break;
      case EMG_DEMO:
        bar = new BarGraph(EMG_BARX,EMG_BARY, 200, 1000,350,"Amplified, Rectified, Integrated Signal");
        line = new LineGraph(EMG_LINEX,EMG_LINEY,350,350,350,-150,150,"EMG Signal",false);
        emgGame =  new FlappyRaven(FLAPPYX,FLAPPYY);

        currentScreen = DisplayScreen.EMG_DEMO;
        if(!Debug){
          myPort.write("EMG");
          myPort.clear();
        }
        break;
      case ECG:
        currentScreen = DisplayScreen.ECG;

        break;
      case ECG_DEMO:
        bar = null;
        line = new LineGraph(200,700,REPEAT_TIME*100,400,REPEAT_TIME*100,0, 1100,"ECG Data",true);
        currentScreen = DisplayScreen.ECG_DEMO;
        
        if(!Debug){
          myPort.write("ECG");
          myPort.clear();
        }
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
        if(emgGame.gameInProgress() == true){
          emgGame.mouseClicked(); 
        }else if((mouseX-RETURNX)*(mouseX-RETURNX) + (mouseY- RETURNY)*(mouseY- RETURNY) <= BUTTONSIZE_2/2*BUTTONSIZE_2/2){
          switchTo(DisplayScreen.EMG);
        }else if((mouseX-HOMEX)*(mouseX-HOMEX) + (mouseY- HOMEY)*(mouseY- HOMEY) <= BUTTONSIZE_3/2*BUTTONSIZE_3/2){
          switchTo(DisplayScreen.NONE);
        }else if(bar.insideGraph(mouseX,mouseY)){
          bar.setThreshold(mouseY);
          if(!Debug)
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
        }else if((mouseX-HOMEX)*(mouseX-HOMEX) + (mouseY- HOMEY)*(mouseY- HOMEY) <= BUTTONSIZE_3/2*BUTTONSIZE_3/2){
          switchTo(DisplayScreen.NONE);
        }
        break;
    }
  }
  
}