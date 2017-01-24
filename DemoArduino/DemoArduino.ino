

#include <Keyboard.h>
#define ECG_PRINT_SPEED 10
#define EMG_PRINT_SPEED 5
#define ECG_SIG_PIN 0
#define ECG_NOSIG_PIN1 10
#define ECG_NOSIG_PIN2 11
#define EMG_RAW_PIN 1
#define EMG_ENV_PIN 2


typedef enum {
  NONE,
  ECG,
  EMG
} mode_t;

float threshold;
int oldEnv;
int env;
mode_t currMode;

/*
   This class is to filter the incoming data from the heart rate monitor and remove unneccesary noise
*/
class DynamicFilter
{
  private:
    int oldx[7];
    int oldy[7];
    float a[7];
    float b[7];
    int arrLen;


  public:
    /*
       Constructor for the Filter
       Assigns the a and b values, a and b must have 3 values each. a[0] must be 1.
    */
    DynamicFilter(float aValues[], float bValues[], int baSize)
    {
      arrLen = baSize - 1;
      if (arrLen > 7)
        arrLen = 7;

      for (int i = 0; i < arrLen; i++)
      {
        a[i] = aValues[i];
        b[i] = bValues[i];
        oldx[i] = 0;
        oldy[i] = 0;
      }


      a[arrLen] = aValues[arrLen];
      b[arrLen] = bValues[arrLen];
    }


    /*
       When a new value is added, it performs the IIR filter
    */
    void addValue(int in)
    {

      float newY = in * b[0]; // + oldx[0]*b[1] + oldx[1]*b[2] - oldy[0]*a[1] - oldy[1]*a[2];

      for (int i = arrLen; i >= 1; i--)
      {
        newY += oldx[i - 1] * b[i] - oldy[i - 1] * a[i];
      }



      for (int i = arrLen - 1; i >= 1; i--)
      {
        oldy[i] = oldy[i - 1];
        oldx[i] = oldx[i - 1];
      }

      oldy[0] = newY;
      oldx[0] = in;

    }

    /*
       @return y_1 and y_2 as a string
    */
    String getLastTwoValues()
    {
      return String(oldy[0]) + " " + String(oldy[1]);
    }

    String getLastValue()
    {
      return String(oldy[0]);
    }

};


//float a[] = {1.0f, -2.0484, 1.8418, -0.7824, 0.1317}; //butter second order 30Hz low-pass filter with 250 Hz sampling
//float b[] = {0.0089, 0.0357, 0.0535, 0.0357, 0.0089};

//float a[] = {1.0f, -0.2308, 1.6609, -0.1930, 0.7009}; //butter second order 55-65Hz Notch filter with 250 Hz sampling
//float b[] = {0.8371, -0.2119, 1.6876, -0.2119, 0.8371};

//float a[] = {1.0f, -0.3244, 2.0393, -0.4487, 1.4722,-0.1642, 0.3618}; //butter third order 50-70Hz Notch filter with 250 Hz sampling
//float b[] = {0.6016, -0.2340, 1.8351, -0.4693, 1.8351, -0.2340, 0.6016};

//float a[] = {1.0f, -0.2898, 1.0734, -0.2402, 0.6388,-0.0702, 0.1180}; //butter third order 40-80Hz Notch filter with 250 Hz sampling
//float b[] = {0.3484, -0.1498, 1.0667, -0.3006, 1.0667, -0.1498, 0.3484}; //Found most of Vicky's heart beats.

float a[] = {1.0f, -0.2776, 0.6048, -0.1560, 0.4314, -0.0458, 0.0563}; //butter third order 35-85Hz Notch filter with 250 Hz sampling
float b[] = {0.2569, -0.1196, 0.7893, -0.24002, 0.7893, -0.1196, 0.2569};

float a2[] = {1.0f, 0.3459, 0.3650, 0.0323, 0, 0, 0}; //butter third order 100Hz high-pass filter with 250 Hz sampling
float b2[] = {0.1234, -0.3701, 0.3701, -0.1234, 0, 0, 0};

//float a[3] = {0.0f,0.f,0.f}; //No Filter
//float b[3] = {1.f,0.f,0.f};

//keeps track of if the data should be sent or not
bool sendData;
//stores the reset value for the timer
int timer1_counter;


//Filter notchF(a,b);
DynamicFilter ecgFilter(a, b, 7);
DynamicFilter emgFilter(a2, b2, 7);



void enableRead(bool en) {
  if (en) {
    noInterrupts();           // disable all interrupts
    TCCR1A = 0;
    TCCR1B = 0;

    // Set timer1_counter to the correct value for our interrupt interval
    //  timer1_counter = 65223;   // preload timer 65536-16MHz/256/200Hz
    timer1_counter = 65286;   // preload timer 65536-16MHz/256/250Hz
    //  timer1_counter = 65380;   // preload timer 65536-16MHz/256/400Hz

    TCNT1 = timer1_counter;   // preload timer
    TCCR1B |= (1 << 2);    // 256 prescaler
    TIMSK1 |= (1 << TOIE1);   // enable timer overflow interrupt
    interrupts();             // enable all interrupts
  } else {
    noInterrupts();           // disable all interrupts
    TCCR1A = 0;
    TCCR1B = 0;
    interrupts();             // enable all interrupts
  }
}



ISR(TIMER1_OVF_vect)        // interrupt service routine
{
  TCNT1 = timer1_counter;   // preload timer
  if (currMode == ECG) {
    ecgFilter.addValue(analogRead(ECG_SIG_PIN));
  } else if (currMode == EMG) {
    emgFilter.addValue(analogRead(EMG_RAW_PIN));
  }
}







void setup() {

  pinMode(ECG_NOSIG_PIN1, INPUT); // Setup for leads off detection LO +
  pinMode(ECG_NOSIG_PIN2, INPUT); // Setup for leads off detection LO -
  enableRead(false);

  oldEnv = 0;
  env = 0;

  pinMode(EMG_RAW_PIN, INPUT);
  pinMode(EMG_ENV_PIN, INPUT);

  currMode = NONE;

  // initialize the serial communication
  Keyboard.begin();
  Serial.begin(9600);
}


void loop()
{
  //Start sending data if a '1' is sent. Stop sending data if a '0' is sent
  if (Serial.available())
  {
    String s = Serial.readString();
    switch (currMode) {
      case NONE:
        if (s.equals("EMG")) {
          currMode = EMG;
          threshold = 200.0;
          enableRead(true);
        } else if (s.equals("ECG")) {
          currMode = ECG;
          enableRead(true);
        }
        break;
      case ECG:
        if (s.equals("NONE")) {
          currMode = NONE;
          enableRead(false);
        }
      case EMG:
        if (s.equals("NONE")) {
          currMode = NONE;
          enableRead(false);
        } else if (s.substring(0, 6).equals("THRSH:")) {
          threshold = s.substring(6).toFloat();
        }
    }
    Serial.println(currMode);
  }



  switch (currMode) {
    case ECG:

      if ((digitalRead(ECG_NOSIG_PIN1) == 0) && (digitalRead(ECG_NOSIG_PIN2) == 0))
        Serial.println(ecgFilter.getLastValue());
      else
        Serial.println("!");

      //Wait for a bit to keep serial data from saturating
      delay(ECG_PRINT_SPEED);
      break;

    case EMG:

      oldEnv = env;
      env = analogRead(EMG_ENV_PIN);

      Serial.print(emgFilter.getLastValue());
      Serial.print(" ");
      Serial.println(env);

      if (oldEnv < threshold && env > threshold)
        Keyboard.write(0x20);

      //Wait for a bit to keep serial data from saturating
      delay(EMG_PRINT_SPEED);
      break;

    default:
      //Wait for a bit to keep serial data from saturating
      delay(ECG_PRINT_SPEED);
      break;
  }
}



