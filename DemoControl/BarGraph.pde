
/*
 * This class creates a bar graph of a given size which can trigger upon certain events (Rising/Falling edge, etc.)
 * The location given becomes the bottom left corner of the Bar Graph.
 */
 
 
final static boolean hideNumbers = false;
 
class BarGraph{
  String title;
  int x,y; //base x and y coordinates of the graph
  int barWidth;
  int size; //size of bar graph
  //Expecting a value between 0 and valMax;
  float val,valMax; //current value and the max value
  float threshold; //the value at which the trigger event takes place
  boolean triggered; //bool to check if a trigger has happened
  
  /*
   * 
   */
  BarGraph(int x, int y, int thresh,int valMax, int gsize, String title){
    this.x = x;
    this.y = y;
    this.valMax = valMax;
    this.title = title;
    if(gsize < 200)
      gsize = 200;
    size = gsize;
    barWidth = size/3;
    threshold = thresh;
  }
  
  //Default size is 200
  BarGraph(int x, int y, int thresh, int valMax){
    this.x = x;
    this.y = y;
    this.valMax = valMax;
    size = 200;
    barWidth = size/3;
    threshold = thresh;
  }
  
  void update(float v){
    
    //determine the state of the trigger
    if(val < threshold && v >= threshold)
      triggered = true;
    
    //update the current val
    val = v;
    if(val>valMax) val = valMax;
    else if(val<0) val =0;
  }
  
  void draw(){    
    fill(0xff,240);
    rect(x-15,y+15,size+30, -size-80,20);
    
    fill(0);
    stroke(0);
    textSize(20);
    
    text(title,x+size/2,y-size-40);

    textSize(16);
    //draw the bar graph axes
    line(x+50,y,x+50,y-size-5);
    line(x+25,y,x+size,y);
    
    //draw y axis ticks and numbers
    if(!hideNumbers){
      text(nf(valMax,3,0), x+18, y-size-2);
      text(nf(valMax*3/4,3,0), x+18, y-size*3/4-2);
      text(nf(valMax/2,3,0), x+18, y-size/2-2);
      text(nf(valMax*1/4,3,0), x+18, y-size*1/4-2);
    }
    
    line(x+45,y-size,x+55,y-size);
    line(x+45,y-size*3/4,x+55,y-size*3/4);
    line(x+45,y-size/2,x+55,y-size/2);
    line(x+45,y-size*1/4, x+55, y-size*1/4);
    
    
    //draw the threshold line
    float normThresh = map(threshold,0,valMax,0,size);
    stroke(162,11,11);
    fill(119,11,11);
    line(x+45,y-normThresh,x+size,y-normThresh);
    text("threshold",x+size-75,y-normThresh-10);
    if(!hideNumbers)
      text(nf(threshold,3,0),x+size-20,y-normThresh-10);
    
    
    
    if(val < threshold){
      fill(0);
      stroke(0);
    }
    //draw the bar
    float normVal = map(val,0,valMax,0,size);
    rect(x+size/3,y,barWidth,-normVal);
    if(!hideNumbers)
      text(nf(val,3,0),x+size/3+20,y-normVal-10);
    
  }
  
  float getVal(){
    return val;
  }
  
  float getThreshold(){
    return threshold; 
  }
  
  boolean insideGraph(int x1,int y1){
    return (x1>x && x1 < x+size && y1<y && y1 > y-size);
  }
  
  //newT should be the y value of the desired point of threshold on the GUI (absolute y value, not relative)
  void setThreshold(int newT){
     threshold = int(map(y-newT,0,size,0,valMax));
  }
  
  boolean foundTrigger(){
    boolean t = triggered;
    triggered = false;
    return t;
  }
  
}