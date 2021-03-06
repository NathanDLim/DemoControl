
static final int MOBD_THRESH = 250;
static final int REFRACT_PERIOD = 40;

/*
 * This class displays data in a line graph
 * The location given becomes the bottom left corner of the Bar Graph.
 */
class LineGraph{
  
  String title;
  int x,y;
  int xLength, yLength;
  float yData[];
  float yMin, yMax;
  int currX; // the next data to be updated
  float panX[];
  float panY[];
  int beatLoc[];
  int numBeats = 0;
  
  boolean performQRSDetection,
          showMOBD;
  
   float PEAKI = 0,
        SPKI = 400,
        NPKI = 0;
  
  float THRESH1 = 0,
        THRESH2 = 0;
        
  
  
  LineGraph(int x,int y, int xLen, int yLen, int size, float yMin, float yMax, String title,boolean qrs){
    this.x = x;
    this.y = y;
    xLength = xLen;
    yLength = yLen;
    yData = new float[size];
    panX = new float[size];
    panY = new float[size];
    this.title = title;
    beatLoc = new int[400]; //shouldn't get anywhere close to 400 beats
    this.yMin = yMin;
    this.yMax = yMax;
    showMOBD = false;
    performQRSDetection = qrs;
  }
  
  void update(float newY){
   if(newY < yMin) newY = yMin;
   else if(newY > yMax) newY = yMax;
   yData[currX] = newY;
   
   if(performQRSDetection)
     panThompkins();

   if(++currX >= yData.length) currX = 0;

  }

  
  void panThompkins(){

   
   panX[currX] = yData[currX] - yData[(currX-1+yData.length)% yData.length];
   panX[currX] *= panX[currX];
   

  //moving average
   int n = 20;
   panY[currX] = 0;
   for(int j = n; j > 0; j--){
       panY[currX] += panX[(currX-j+yData.length) % yData.length]; 
    }
    panY[currX]=panY[currX]/n;
   
   
   //find the peak and threasholds based off the past 200 samples
   SPKI = 0;
   for(int i = 0; i < 200; i++){
     PEAKI = 0;
    for(int j = n; j >= 0; j--){
        if(panY[(currX-i+yData.length) % yData.length] > PEAKI)
          PEAKI = panY[(currX-i+yData.length) % yData.length];
    }
     //PEAKI /= n;
     
    if(PEAKI > THRESH1){
       SPKI = 0.125*PEAKI + 0.875*SPKI;
    }
    //else if(PEAKI > THRESH2){
    //  SPKI = 0.25*PEAKI + 0.75*SPKI;
    //}
     else
       NPKI = 0.125*PEAKI + 0.875*NPKI;
      
   }
   
   //System.out.print(THRESH1 + " ");
   //System.out.println(PEAKI);
         
     THRESH1 = NPKI + 0.5*(SPKI-NPKI);
     THRESH2 = 0.75*THRESH1;
     
   float t1=0,
       t2=0;
       
   numBeats = 0;
   boolean QRSFound;
   
   for(int i = 0; i < beatLoc.length;i++)
     beatLoc[i]=0;
   int c = 0;
   int refract = 0;
   
   //Detection algorithm (based off Pan Thompkins)
    for(int i = 0; i < yData.length;i+= 100){
      QRSFound = false;
      for(int j =0; j < 100; j++){
        t2 = t1;
        t1 = panY[(i+j+yData.length) % yData.length];
        if(t2 < THRESH1 && t1 > THRESH1 && refract == 0){
          numBeats++;
          beatLoc[c++] = i+j;
          QRSFound = true;
          refract = REFRACT_PERIOD; //There can't be two heart beats very close to eachother, so we make a refract period.
        }
        refract = refract ==0? refract: refract -1;
      }
      if(!QRSFound){
       for(int j =0; j < 100; j++){
         t2 = t1;
         t1 = panY[(i+j+yData.length) % yData.length];
         if(t2 < THRESH2 && t1 > THRESH2 && refract == 0){
           numBeats++;
           beatLoc[c++] = i+j;
           QRSFound = true;
           refract = REFRACT_PERIOD;
         }
         refract = refract ==0? refract: refract -1;
       }
      }
   }
  }
  
  void draw(){
    stroke(0);
    fill(0xff,240);
    rect(x-15,y+15,xLength+30,-yLength-80,20);
    
    fill(0);
    stroke(0);
    textSize(20);
    text(title,x+xLength/2,y-yLength-40);
    //Show some of the lines
    //line(x,y,x+xLength,y);
    //line(x,y-THRESH1,x+xLength,y-THRESH1);
    //line(x,y-THRESH2,x+xLength,y-THRESH2);
    //line(x+currX-100, 0,x+currX-100, height);
    
    //draw a box around where the algorithm thinks the heart beats are
    noStroke();
    fill(0, 102, 153, 30);
    for(int i = 0; i < beatLoc.length;i++){
      if(beatLoc[i]==0) continue;
      rect(x+int((beatLoc[i]-8)*SCALING),y,16*SCALING,-yLength+100);
    }

    //can either show the raw signal or the processed signal for detecting the QRS curve
    stroke(0);
    if(!showMOBD){    
     for(int i=0; i< yData.length-1; ++i){
       if(i<(currX-25+xLength)%xLength || i > currX)
         line(x+(xLength/yData.length)*i,y - map(yData[i],yMin,yMax,0,yLength), x+(xLength/yData.length)*(i+1),y - map(yData[i+1],yMin,yMax,0,yLength));
     }
    }else{
     for(int i=0; i< yData.length-1; ++i){
       line(x+(xLength/yData.length)*i,y - panY[i], x+(xLength/yData.length)*(i+1),y - panY[i+1]);
     }
    }

  }
  
  int getNumBeats(){
    return numBeats;
  }
  
  void toggleMOBD(){
    showMOBD = !showMOBD;
  }
}