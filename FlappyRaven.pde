import java.util.Random;

public class FlappyRaven extends PApplet{
  int bgGroundLevel = 60;
  PImage bg;
  Game game;
  
  public FlappyRaven() {
    super();
  }
  
  public void settings(){
    size(1000, 500);
    //removeExitEvent(getSurface());
    game = new Game();
    bg = loadImage("Background.png");
  }
  
  void draw() 
  {
    background(bg);
    
    game.update();
    game.draw();
  }
  
  void mouseClicked(){
    game.jump();
  }
  
  @ Override void exit() {
  }

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
    
    public void update(){
      if(showOpeningInfo){
        td.update("Welcome to Flappy Raven! Click anywhere to begin.");
        td.setCenter(true);
      }else if(!gameOver){
      
        if(millis() - time >= difficulty){
          bars.add(makeBar(width));
          //System.out.println("here");
          time = millis();
        }
        
        
        for(int i = 0; i < bars.size(); i++){
            bars.get(i).update();
            if(!bars.get(i).checkBounds()){
              bars.remove(i);
              difficulty = difficulty < 3000? difficulty: difficulty-400;
              score++;
            }
            
        }
        
        if(bars.get(0).collision(bird))
              gameOver();
        
        bird.update();
        if(bird.getY() > height-bgGroundLevel)
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
     difficulty = 5000;
     bars.clear();
     bars.add(makeBar(width - 300));
     bars.add(makeBar(width));
     bird = new Bird();
     score =0;
     time = millis();
     gameOver = false;
     showOpeningInfo = false;
     td = new TextDisplay("Score: 0");
     td.setCenter(false);
    }
    
    private Bar makeBar(int x){
      int size = difficulty/20;
      int pos = (int)r.nextInt((height-size-bgGroundLevel-5));
      if(pos<25) pos = 25;
      if(pos > height-size-65) pos = height-size-bgGroundLevel-5;
      //System.out.print(difficulty/25);
      return new Bar(x,size,pos);
    }
    
    public void draw(){
      for(int i = 0; i < bars.size(); i++){
          bars.get(i).draw();
      }
      bird.draw();
      td.draw();
    }
    
    public void jump(){
      if(!gameOver){
        bird.jump();
      }else if(millis() - time > 1000){
        startGame();
      }
    }
  }
  
  class Bird{
    int x;
    int y;
    float accel;
    
    public Bird(){
     x = 50;
     y = height/2;
    }
    
    public void update(){
      y += accel;
      if(y < 20)
        y = 20;
      accel = accel > 3? accel: accel + 0.05;
    }
    
    public void jump(){
       accel = -1.5;
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
      rotate(accel/2-0.3);
      
      fill(0);
      ellipse(0,0,35,30); //body
      fill(108);
      ellipse(15,0,20,8); //beak
      
      
      ellipse(12,-10,5,5); //pupil
      fill(40);
      ellipse(-12,0,25,accel*8 -4); //wing. using the current accel makes it look like it is flapping
      popMatrix();
      
      
      pushMatrix();
      translate(x,y);
      rotate(accel/2-0.8);
      fill(0xff);
      ellipse(16,-2,9,12); //eye
      
      fill(0);
      ellipse(17,0,3,3); //pupil
      popMatrix();
      
      
    }
  }
  
  class Bar{
    int barWidth;
    int x;
    int breakSize;
    int breakPosition;
    
    public Bar(int x, int size, int pos){
      this.x = x;
      this.breakSize = size;
      this.breakPosition = pos;
      barWidth = 40;
    }
    
    
    public void draw(){
      
      fill(99,209,62);
      rect(x,0,barWidth,breakPosition);
      rect(x,breakPosition+breakSize,barWidth,height - (breakPosition+breakSize) - 40);
      rect(x-6,breakPosition-20,barWidth + 12,20);
      rect(x-6,breakPosition+breakSize,barWidth + 12,20);
    }
    
    public void update(){
      x--;
    }
    
    public boolean checkBounds(){
     if(x < -barWidth)
       return false;
     return true;
    }
    
    //checks if the bar collides with the bird
    public boolean collision(Bird b){
      if(b.getX() + 17 >= x && b.getX() - 17 < x + barWidth){
          
        if(!(b.getY() - 15 > breakPosition && b.getY() + 15 < breakPosition+breakSize))
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
      textAlign(CENTER);
      
      if(!centerText){
        fill(0xff,160);
        ellipse(x,y,(size-5)*text.length()+4,40);
        fill(0);
        text(text,x,y+7);
      }else{
        fill(0xff,160);
        ellipse(x,y,800,400);
        fill(0);
        
        text(text,x,y);
      }
    }
    
    public void setCenter(boolean center){
      centerText = center; 
      if(centerText){
        this.x = width/2;
        this.y = height/2;
      }else{
        this.x = width-120;
        this.y = 30;
      }
    }
    
    public void update(String t){
      text = t;
    }
    
    
    public float getX(){ return x;}
    public float getY(){ return y;}
    
  }
}