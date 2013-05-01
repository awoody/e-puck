function ePic = deactivate( ePic, propName )
%DEACTIVATE Deactivate the reception of some sensor values. It can also
%           deactivate some mechanisms in the interface.
% 
% ePic = deactivate(ePic,propName)
%
% Results :
%   ePic            :   updated ePicKernel object
%
% Parameters :
%   ePic            :   ePicKernel object
%   propName        :   
%       'accel'           :   accelerometer values
%       'proxi'           :   proximity sensors values
%       'light'           :   light sensors values
%       'micro'           :   microphones values
%       'speed'           :   speed of the motors
%       'pos'             :   wheels encoders values
%       'odom'            :   do not update odometry
%       'floor'           :   floor sensors
%       'external'        :   external sensors values
%       'image'           :   camera image
%       'custom'          :   custom command

switch propName
case 'accel'
   ePic.update.accel = 0;
case 'proxi'
   ePic.update.proxi = 0;
case 'light'
   ePic.update.light = 0;
case 'micro'
   ePic.update.micro = 0;
case 'speed'
   ePic.update.speed = 0;
case 'pos'
   ePic.update.pos = 0;
case 'odom'     
   ePic.update.odom = 0;
case 'floor'     
   ePic.update.floor = 0;
case 'external'
   ePic.update.exter = 0;
case 'image'
   ePic.update.image = 0;
case 'custom'
    ePic.update.custom = 0;
otherwise
   error([propName,' Is not a valid asset property'])
end