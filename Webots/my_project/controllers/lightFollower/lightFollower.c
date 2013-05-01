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

static int MAX_SPEED = 380;

static double STOP_THRESHOLD = 2400;
static double SLOW_THRESHOLD = 500;

static WbDeviceTag ps0, ps1, ps2, ps3, ps4, ps5, ps6, ps7;
static WbDeviceTag ls0, ls1, ls2, ls3, ls4, ls5, ls6, ls7;
static WbDeviceTag led4;

static enum MovementState {FORWARD, TURNING};
static enum TurnDirection {RIGHT, LEFT};
static enum Behavior {LIGHT_TRACKER, RANDOM_MOVER};

static enum MovementState currentState;
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

     wb_led_set(led4, 1); 
}

//Determines whether or not the puck is extremely close,
//moderately close, or far from something in front of it.
int collisionPending()
{
    WbDeviceTag frontDistanceSensors[] = {ps0, ps7};
    int tooHot = 0;
    int i;
    for(i=0; i < 2; i++)
    {
       double currentSensorValue =  wb_distance_sensor_get_value(frontDistanceSensors[i]);
    
       if(currentSensorValue >= STOP_THRESHOLD)
           tooHot = 1;
       else if(currentSensorValue > SLOW_THRESHOLD)
           tooHot = 2;
    }
    
    return tooHot;
}

//Heads straight, adjusting speed based on 
//whether or not a collision is imminent.
void headStraight()
{
    currentState = FORWARD;
    
    int speed = collisionPending();
    
    if(speed == 2)
    {
        wb_differential_wheels_set_speed(200, 200);
        wb_led_set(led4, 1); 
    }    
    else if(speed == 1)
    {
        wb_differential_wheels_set_speed(0, 0);
        wb_led_set(led4, 1); 
    }
    else
    {
        wb_differential_wheels_set_speed(MAX_SPEED, MAX_SPEED);
        wb_led_set(led4, 0); 
    }
}

//Turns left by setting speed
void turnLeft()
{
    wb_led_set(led4, 0); 
    currentState = TURNING;
    wb_differential_wheels_set_speed(MAX_SPEED, -MAX_SPEED);
}

//Turns right by setting speed
void turnRight()
{
    wb_led_set(led4, 0); 
    currentState = TURNING;
    wb_differential_wheels_set_speed(-MAX_SPEED, MAX_SPEED);
}

//Sets the heading in the indicated direction.
void setHeading(enum TurnDirection direction)
{
    if(direction == LEFT)
       turnRight();
    else
       turnLeft();

}

//Returns the minimum value from all sampled sensors.
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

//Returns the index in the array of the minimum valued
//sensor.
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

//Returns 1 if the front sensors are the minimum value sensors.
int frontLightSensorsBelowThreshold()
{
    WbDeviceTag allTags[] = {ls0, ls1, ls2, ls3, ls4, ls5, ls6, ls7};
    int minIndex = getMinimumIndex(8, allTags);

    if(minIndex == 0 || minIndex == 7)
         return 1;
    else
         return 0;
}

//Obtains the turn direction of the minimum value sensor.
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

//Dictates a light tracker step.
void lightTrackerStep()
{
     //As long as one of the front sensors is the minimum of all sampled
     //light sensors, go straight
    if(frontLightSensorsBelowThreshold() == 1)
    {
        headStraight();
    }
    else //Otherwise set the heading to the direction of the minimum value sensor.
    {
        setHeading(getTurnDirectionOfSmallestVarianceSensor() == 1);
    }
}

//Used if state-machine behavior is desired, but not currently enabled.
enum Behavior lightTrackerNextState()
{
    return RANDOM_MOVER;
}

//Used if state-machine behavior is descired, but not currently enabled.
enum Behavior randomMoverNextState()
{
    return LIGHT_TRACKER;
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

   //Initially, the puck just heads straight.
   headStraight();
  
  /* main loop
   * Perform simulation steps of TIME_STEP milliseconds
   * and leave the loop when the simulation is over
   */
  while (wb_robot_step(TIME_STEP) != -1) 
  {
      //As long as there is time, keep taking lightTrackerSteps;
      lightTrackerStep();
  };
  
  /* Enter your cleanup code here */
  
  /* This is necessary to cleanup webots resources */
  wb_robot_cleanup();
  
  return 0;
}


