/*
 * File:          lightFollower.c
 * Date:          
 * Description:   
 * Author:        
 * Modifications: 
 */

/*
 * You may need to add include files like <webots/distance_sensor.h> or
 * <webots/differential_wheels.h>, etc.
 */
#include <webots/robot.h>
#include <webots/differential_wheels.h> 
#include <webots/distance_sensor.h>
#include <webots/light_sensor.h> 
#include <webots/camera.h>
#include <webots/led.h> 
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>

/*
 * You may want to add macros here.
 */
#define TIME_STEP 64

static int MAX_SPEED = 200;
static int TURN_TIME_STEPS = 7;
static int RANDOM_TURN_TIME_STEPS = 21;
static int DISTANCE_THRESHOLD = 750;
static double AXEL_LENGTH = 52;
static double WHEEL_RADIUS = 20.5;
static double ROBOT_RADIUS = 37;
static int LIGHT_SENSOR_VARIANCE_THRESHOLD = 100;
static int LIGHT_DETECTION_THRESHOLD = 3500;
static int stepsInCurrentTurn = 50;
static int timeStepBound = 0;
static WbDeviceTag ps0, ps1, ps2, ps3, ps4, ps5, ps6, ps7;
static WbDeviceTag ls0, ls1, ls2, ls3, ls4, ls5, ls6, ls7;
static WbDeviceTag led4;

static int m_z = 0;
static int m_w = 0;

static enum MovementState {FORWARD, TURNING};
static enum TurnDirection {RIGHT, LEFT};
static enum Behavior {LIGHT_TRACKER, RANDOM_MOVER};

static enum MovementState currentState;
static enum TurnDirection currentDirection;
static enum Behavior currentBehavior;

static void initialize()
{
     wb_robot_init();
     
     currentBehavior = RANDOM_MOVER;
     
     ps0 = wb_robot_get_device("ps0");
     ps1 = wb_robot_get_device("ps1");
     ps2 = wb_robot_get_device("ps2");
     ps3 = wb_robot_get_device("ps3");
     ps4 = wb_robot_get_device("ps4");
     ps5 = wb_robot_get_device("ps5");
     ps6 = wb_robot_get_device("ps6");
     ps7 = wb_robot_get_device("ps7");
     
     ls0 = wb_robot_get_device("ls0");
     ls1 = wb_robot_get_device("ls1");
     ls2 = wb_robot_get_device("ls2");
     ls3 = wb_robot_get_device("ls3");
     ls4 = wb_robot_get_device("ls4");
     ls5 = wb_robot_get_device("ls5");
     ls6 = wb_robot_get_device("ls6");
     ls7 = wb_robot_get_device("ls7");
     
     led4 = wb_robot_get_device("led4");
     
     int sensorTimeout = 100;
      
     wb_distance_sensor_enable(ps0, sensorTimeout);
     wb_distance_sensor_enable(ps1, sensorTimeout);
     wb_distance_sensor_enable(ps2, sensorTimeout);
     wb_distance_sensor_enable(ps3, sensorTimeout);
     wb_distance_sensor_enable(ps4, sensorTimeout);
     wb_distance_sensor_enable(ps5, sensorTimeout);
     wb_distance_sensor_enable(ps6, sensorTimeout);
     wb_distance_sensor_enable(ps7, sensorTimeout);
    
     wb_light_sensor_enable(ls0, sensorTimeout);
     wb_light_sensor_enable(ls1, sensorTimeout);
     wb_light_sensor_enable(ls2, sensorTimeout);
     wb_light_sensor_enable(ls3, sensorTimeout);
     wb_light_sensor_enable(ls4, sensorTimeout);
     wb_light_sensor_enable(ls5, sensorTimeout);
     wb_light_sensor_enable(ls6, sensorTimeout);
     wb_light_sensor_enable(ls7, sensorTimeout);

      m_z = wb_distance_sensor_get_value(ps0) * wb_light_sensor_get_value(ls5);
      m_w = wb_distance_sensor_get_value(ps4) * wb_light_sensor_get_value(ls2);

      wb_led_set(wb_robot_get_device("led0"), 1); 
      wb_led_set(wb_robot_get_device("led1"), 1); 
      wb_led_set(wb_robot_get_device("led2"), 1); 
      wb_led_set(wb_robot_get_device("led3"), 1); 
      wb_led_set(wb_robot_get_device("led4"), 1); 
      wb_led_set(wb_robot_get_device("led5"), 1); 
      wb_led_set(wb_robot_get_device("led6"), 1); 
      wb_led_set(wb_robot_get_device("led7"), 1); 
      wb_led_set(wb_robot_get_device("led8"), 1); 
      wb_led_set(wb_robot_get_device("led9"), 1); 
}

void headStraight()
{
    currentState = FORWARD;
    wb_differential_wheels_set_speed(MAX_SPEED, MAX_SPEED);
}

void turnLeft()
{
    currentState = TURNING;
    wb_differential_wheels_set_speed(MAX_SPEED, -MAX_SPEED);
}

void turnRight()
{
    currentState = TURNING;
    wb_differential_wheels_set_speed(-MAX_SPEED, MAX_SPEED);
}



void setHeading(enum TurnDirection direction)
{
    if(direction == LEFT)
       turnRight();
    else
       turnLeft();

}

double getStandardDeviation(int size, double average, WbDeviceTag* tags)
{
    double deviation = 0;

    int i;
    for(i=0; i < size; i++)
    {
        WbDeviceTag current = tags[i];
        double currentValue = wb_light_sensor_get_value(current);
        double rawValue = currentValue - average;
        deviation += (rawValue * rawValue);
    }
    
    return sqrt(deviation); 
}

double getAverage(int size, WbDeviceTag* tags)
{
    double average = 0;

    int i;
    for(i=0; i < size; i++)
    {
        WbDeviceTag current = tags[i];
        double currentValue = wb_light_sensor_get_value(current);
        average += currentValue; 
    }
    
    return average / size; 
}


double getMinimum(int size, WbDeviceTag* tags)
{
    double min = 1000000;

    int i;
    for(i=0; i < size; i++)
    {
        WbDeviceTag current = tags[i];
        double currentValue = wb_light_sensor_get_value(current);
        if(currentValue < min)
            min = currentValue;   
    }
    
    return min; 
}

double getMinimumIndex(int size, WbDeviceTag* tags)
{
    double min = 1000000;
    double minIndex = -1;

    int i;
    for(i=0; i < size; i++)
    {
        WbDeviceTag current = tags[i];
        double currentValue = wb_light_sensor_get_value(current);
        if(currentValue < min)
        {
           min = currentValue;   
           minIndex = i;
        }    
    }
    
    return minIndex; 
}

int frontLightSensorsBelowThreshold()
{
    WbDeviceTag allTags[] = {ls0, ls1, ls2, ls3, ls4, ls5, ls6, ls7};
    int minIndex = getMinimumIndex(8, allTags);

    if(minIndex == 0 || minIndex == 7)
         return 1;
    else
         return 0;
}

enum TurnDirection getTurnDirectionOfSmallestVarianceSensor()
{
    WbDeviceTag leftSideTags[] = {ls0, ls1, ls2, ls3};
    WbDeviceTag rightSideTags[] = {ls4, ls5, ls6, ls7};
    double leftSideMin = getMinimum(4, leftSideTags);
    double rightSideMin = getMinimum(4, rightSideTags);
    
    enum TurnDirection direction = RIGHT;
    if(leftSideMin > rightSideMin)
        direction = LEFT;
        
    return direction;      
}

int randomMoverNeedsBehaviorSwitch()
{
    WbDeviceTag allTags[] = {ls0, ls1, ls2, ls3, ls4, ls5, ls6, ls7};
    double min = getMinimum(8, allTags);
    return min < LIGHT_DETECTION_THRESHOLD;
}

int lightTrackerNeedsBehaviorSwitch()
{
    WbDeviceTag allTags[] = {ls0, ls1, ls2, ls3, ls4, ls5, ls6, ls7};
    double min = getMinimum(8, allTags);
    return min > LIGHT_DETECTION_THRESHOLD;
}

int turnHasEnded()
{
     int value = stepsInCurrentTurn >= timeStepBound ? 1 : 0;
     return value;
} 

int collisionPending()
{
   // WbDeviceTag allDistanceSensors[] = {ps0, ps1, ps2, ps3, ps4, ps5, ps6, ps7};
   WbDeviceTag allDistanceSensors[] = {ps0, ps7, ps6, ps1, ps5, ps2};
    int tooHot = 0;
    int i;
    for(i=0; i < 6; i++)
    {
       double currentSensorValue = wb_distance_sensor_get_value(allDistanceSensors[i]);
    
       if(currentSensorValue > DISTANCE_THRESHOLD)
           tooHot = 1;
    }
    
    return tooHot;
}



int randomTurnBound = 1800;
int randomTurnFrequency = 1783;

int shouldDoRandomTurn()
{
    //multiply-with-carry RNG from wikipedia
    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
    int rand = (m_z << 16) + m_w;  
    
    int modulo = (rand >= randomTurnBound) ? (rand % randomTurnBound) : rand;
    
    if(modulo >= randomTurnFrequency)
        return 1;
    else
        return 0;
      
}

void randomMoverStep()
{
    if(currentState == FORWARD)
    {
        if(collisionPending() == 1)
            turnLeft();
        else if(shouldDoRandomTurn())
        {
            timeStepBound = RANDOM_TURN_TIME_STEPS;
            turnRight();
        } 
    }
    else
    {
        if(turnHasEnded() == 1)
        {
           headStraight();
           timeStepBound = TURN_TIME_STEPS;
           stepsInCurrentTurn = 0;
        }
        
        stepsInCurrentTurn++;
    }

}

/*
 * This is the main program.
 * The arguments of the main function can be specified by the
 * "controllerArgs" field of the Robot node
 */
int main()
{
  /* necessary to initialize webots stuff */
   initialize();

   headStraight();
  
  /* main loop
   * Perform simulation steps of TIME_STEP milliseconds
   * and leave the loop when the simulation is over
   */
  while (wb_robot_step(TIME_STEP) != -1) 
  {
       randomMoverStep();
  };
  
  /* Enter your cleanup code here */
  
  /* This is necessary to cleanup webots resources */
  wb_robot_cleanup();
  
  return 0;
}


