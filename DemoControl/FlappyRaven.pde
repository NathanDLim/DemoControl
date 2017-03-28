import java.util.Random;

/*
 * The main class for a flappy raven game. 
 */
public class FlappyRaven{
  int bgGroundLevel = 60;
  PImage bg;
  Game game;
  int flappyX,flappyY;
  int xLen,yLen;
  
  public FlappyRaven(int x, int y) {
    this.flappyX = x;
    this.flappyY = y;
    xLen = int(1000*SCALING);
    yLen = int(500*SCALING);
    game = new Game();
    bg = loadImage("Background.png");
    bg.resize(xLen,yLen);
  }
  
  
  void draw() 
  {
    image(bg,flappyX,flappyY);

    game.update();
    game.draw();
    
    //Draw some borders for the game
    fill(0);
    noStroke();
    rect(flappyX-10,flappyY,10,yLen);
    rect(flappyX+xLen,flappyY,10,yLen);
    rect(flappyX-10,flappyY-10,xLen+20,10);
    rect(flappyX-10,flappyY+yLen,xLen+20,10);
  }
  
  void triggerEvent(){
    game.jump();
  }
  
  public boolean gameInProgress(){
      return !game.getGameOver();
    }

  /*
   * The model for the flappy bird game. It has a list of bars, and the bird.
   */
  class Game{
    ArrayList<Bar> bars = new ArrayList<Bar>();
    Bird bird = new Bird();
    long time;
    int difficulty;
    Random r;
    boolean gameOver,
            showOpeningInfo;
    int score;
    TextDisplay td;
    
    public Game(){
     r = new Random();
     startGame();
     gameOver = true;
     showOpeningInfo = true;
    }
    
    /*
     * This function is called every cycle. It updates the bars and the bird, adding more bars whenever necessary
     */
    public void update(){
      if(showOpeningInfo){
        td.update("Welcome to Flappy Raven!\nPlace your arm in the brace and squeeze to see the bar graph increase. Click the bar graph to set the threshold. When it passes the red line, the mouse will click. \n\nClick inside the game to start");
        td.setCenter(true);
      }else if(!gameOver){
      
        
      if(bars.size() > 0 && bars.get(bars.size()-1).getX() < flappyX+xLen-300*SCALING+12*difficulty){
        bars.add(makeBar(flappyX+xLen));
      }
        
        
        
        for(int i = 0; i < bars.size(); i++){
            bars.get(i).update();
            if(!bars.get(i).checkBounds()){
              bars.remove(i);
              difficulty = difficulty > 10? difficulty: difficulty+1;
              score++;
            }
            
        }
        
        if(bars.size() > 0 && bars.get(0).collision(bird))
              gameOver();
        
        bird.update();
        if(bird.getY() > (flappyY+yLen)-bgGroundLevel)
           gameOver();
        
        td.update("Score: " + score);
      }else{
         td.update("Game Over! You had a total score of " + score + "\nClick to start again"); 
         td.setCenter(true);
      }
    }
    
    private void gameOver(){
      gameOver = true;
      time = millis();
    }
    
    private void startGame(){
     difficulty = 1;
     bars.clear();
     bars.add(makeBar(flappyX+xLen - int(300*SCALING)));
     bars.add(makeBar(flappyX+xLen));
     bird = new Bird();
     score =0;
     gameOver = false;
     showOpeningInfo = false;
     td = new TextDisplay("Score: 0");
     td.setCenter(false);
    }
    
    /*
     * Makes a new bar at the x location. The size of the gap is a function of difficulty, the position of the gap is a random distribution
     */
    private Bar makeBar(int x){
      int size = 300-difficulty*12;
      int pos = (int)r.nextInt(((yLen)-size-bgGroundLevel-5));
      
      if(pos<25) pos = 25;
      if(pos > (yLen-size-65)) pos = yLen-size-bgGroundLevel-int(5*SCALING);
      return new Bar(x,size,pos);
    }
    
    /*
     * This function tells each of the components of the game to draw themselves.
     */
    public void draw(){
      strokeWeight(1);
      for(int i = 0; i < bars.size(); i++){
          bars.get(i).draw();
      }
      bird.draw();
      td.draw();
    }
    
    /*
     * Some interaction was noted. Either jump, or restart the game
     */
    public void jump(){
      if(!gameOver){
        bird.jump();
      }else if(millis() - time > 1000){ //Wait 1 second before stating the game again
        startGame();
      }
    }
    
    public boolean getGameOver(){
      return gameOver;
    }
  }
  
  /*
   * This is the bird class. It has an x, y, and instantaneous acceleration.
   */
  class Bird{
    int x;
    int y;
    float accel;
    
    public Bird(){
     x = int(80*SCALING)+flappyX;
     y = flappyY+yLen/2;
    }
    
    // This increases acceleration towards the ground up to a maximum
    public void update(){
      y += accel;
      if(y < flappyY+20)
        y = flappyY+20;
      accel = accel > 3*SCALING? accel: accel + 0.07*SCALING;
    }
    
    public void jump(){
       accel = -1.8*SCALING;
    }
    
    public int getY(){
      return y;
    }
    
    public int getX(){
      return x;
    }
    
    public void draw(){
      pushMatrix();
      
  
      
      translate(x,y);
      rotate(accel/3.5-0.3);
      
      fill(0);
      ellipse(0,0,35*SCALING,30*SCALING); //body
      fill(108);
      ellipse(15*SCALING,0,20*SCALING,8*SCALING); //beak
      
      
      fill(40);
      ellipse(-12,0,25*SCALING,(accel*8/3 -4)*SCALING); //wing. using the current accel makes it look like it is flapping
      popMatrix();
      
      
      pushMatrix();
      translate(x,y);
      rotate(accel/3.5-0.8);
      fill(0xff);
      ellipse(16*SCALING,-2,9*SCALING,12*SCALING); //eye
      
      fill(0);
      ellipse(17*SCALING,0,3*SCALING,3*SCALING); //pupil
      popMatrix();
      
      
    }
  }
  
  /*
   * The bar class has a bar width, x position, size of break, and the position of the break.
   */
  class Bar{
    int barWidth;
    int x;
    int breakSize;
    int breakPosition;
    
    public Bar(int x, int size, int pos){
      this.x = x;
      this.breakSize = size;
      this.breakPosition = pos;
      barWidth = int(40*SCALING);
    }
    
    public int getX(){
      return x;
    }  
    
    
    public void draw(){
      
      fill(99,209,62); //Mario Tube green
      
      //cut off the tubes when on the sides
      int start = x;
      int size = barWidth;
      if(x < flappyX){
        start = flappyX;
        size -= (start-x);
      }else if( x+ barWidth > flappyX+xLen){
        size = (flappyX+xLen-x); 
      }
      
      
      
      //Top tube
      rect(start,flappyY,size,breakPosition);
      //bottom tube
      rect(start,flappyY+breakPosition+breakSize,size, yLen - (breakPosition+breakSize) - 40*SCALING); 
      
      //tube openings
      rect(start-10,flappyY+breakPosition-20,(size + 20),20*SCALING);
      rect(start-10,flappyY+breakPosition+breakSize,(size + 20),20*SCALING); 
    }
    
    //This function changes the x position of the bar, moving them leftwards 
    public void update(){
      x = x- int(1.5*SCALING);
    }
    
    // This checks if the bar has left the screen
    public boolean checkBounds(){
     if(x < flappyX-barWidth)
       return false;
     return true;
    }
    
    //checks if the bar collides with the bird
    public boolean collision(Bird b){
      if(b.getX() + 17 >= x && b.getX() - 17 < x + barWidth){
          
        if(!(b.getY() - 15 > flappyY+breakPosition && b.getY() + 15 < flappyY+breakPosition+breakSize))
         return true;
      }
      
      return false;
    }
  }
  
  /* This class is to show the necessary text during the game. Score, Game Over, Click to start. */
  class TextDisplay{
    float x;
    float y;
    String text;
    int size;
    boolean centerText;
    
    public TextDisplay(String t){
       text = t;
       size = 28;
       centerText = false;
    }
    
    public void draw(){
      
      textFont(createFont("Georgia", size));
      textAlign(CENTER, CENTER);
      
      if(!centerText){
        fill(0xff,160);
        ellipse(x,y,((size-5)*text.length()+8),45);
        fill(0);
        text(text,x,y-2);
      }else{
        fill(0xff,160);
        ellipse(x,y,800*SCALING,400*SCALING);
        fill(0);
        
        text(text,x-230*SCALING,y-260, xLen-500*SCALING, 500);
      }
    }
    
    public void setCenter(boolean center){
      centerText = center; 
      if(centerText){
        this.x = (xLen)/2 + flappyX;
        this.y = (yLen)/2 + flappyY;
      }else{
        this.x = flappyX+xLen-120;
        this.y = flappyY + 30;
      }
    }
    
    public void update(String t){
      text = t;
    }
    
    
    public float getX(){ return x;}
    public float getY(){ return y;}
    
  }
}
