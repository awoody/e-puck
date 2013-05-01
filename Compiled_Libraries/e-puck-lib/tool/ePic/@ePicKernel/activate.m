function ePic = activate( ePic, propName, frequency )
%ACTIVATE Activate the reception of some sensor values. It can also
%         activate some mechanisms in the interface.
% 
% ePic = activate(ePic,propName,frequency)
%
% Results :
%   ePic            :   updated ePicKernel object
%
% Parameters :
%   ePic            :   ePicKernel object
%   frequency       :   frequency to refresh (0: none, 1: always, 2: once)
%   propName        :   
%       'accel'           :   accelerometer values
%       'proxi'           :   proximity sensors values
%       'light'           :   light sensors values
%       'micro'           :   microphones values
%       'speed'           :   speed of the motors
%       'pos'             :   wheels encoders values
%       'odom'            :   update odometry
%       'floor'           :   floor sensors
%       'external'        :   external sensors values
%       'image'           :   camera image
%       'custom'          :   custom command

switch propName
case 'accel'
   ePic.update.accel = frequency;
case 'proxi'
   ePic.update.proxi = frequency;
case 'light'
   ePic.update.light = frequency;
case 'micro'
   ePic.update.micro = frequency;
case 'speed'
   ePic.update.speed = frequency;
case 'pos'
   ePic.update.pos = frequency;
case 'odom'     
   ePic.update.odom = frequency;
case 'floor'     
   ePic.update.floor = frequency;
case 'external'
   ePic.update.exter = frequency;
case 'image'
   ePic.update.image = frequency;
case 'custom'
    ePic.update.custom = frequency;
otherwise
   error([propName,' Is not a valid asset property'])
end