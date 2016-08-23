function pressescape
% It simulates the pressing of keyboard's ESCAPE button using a Java robot.
%
% >> pressescape
%
% Last Modified: 23 March 2016
% Copyright (c) 2016, Xenios Milidonis

% Evoke java.awt.Robot class which can be used to simulate pressing of any
% keyboard button.
robot = java.awt.Robot;

% Simulating pressing of the ESCAPE button.
robot.keyPress    (java.awt.event.KeyEvent.VK_ESCAPE);
robot.keyRelease  (java.awt.event.KeyEvent.VK_ESCAPE);

% Remove the robot.
clear robot

