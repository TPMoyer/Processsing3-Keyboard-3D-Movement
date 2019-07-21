# Processsing3 Keyboard 3D Movement


+ 6DOF (Six Degree Of Freedom) keyboard control of the camera (viewpoint) position & orientation.  
+ Teapot with dramatically reduced data content... highlights the utility of Enumerable Higher Order Concepts.

Sketch is intended for inclusion in the \topics\interaction\  section of the processing3 examples.

A single .pde encapsulates the cameraKey class which enables motion with 6 degrees of fredom.   Copying this into your sketch gets you the full function.   The Keyboard_3D_Movement.pde has the few initialization options needed.

Did set things up to be consistent with the axis orientation taught in USA math and USA physics classes:
+    X positive to the east
+    Y positive to the north
+    Z positive up
     
     
Motion control is:
+   f          key moves you forward
+   b          key moves you backward
+   left-arrow key moves you left
+   righ-arrow key moves you right
+   up-arrow   key moves you up 
+   down-arrow key moves you down

+   r key rolls you clockwize (left wing up)
+   c key CounterClockwise rolls you (right wing up)
+   shift-left-arrow  turns  your nose left  
+   shift-right-arrow turns  your nose right
+   shift-up-arrow    pushes your nose down 
+   shift-down-arrow  pulls  your nose up  
   
+   The speed at which you movement occurs can be halved  by hitting F1
+   The speed at which you movement occurs can be doubled by hitting F2
   
+   The speed at which you turning occurs can be halved  by hitting F3
+   The speed at which you turning occurs can be doubled by hitting F4
   
The teapot version included employs the concept of EHOC's (Enumerated Higher Order Concepts) as an example of a technique which allows dramatic reductions in data size.   By my count, the number of data needed to programmatically create the 785 vertices (vec3), normals(vec3),and texture coordinates (vec2), and triangle indices (Int3) is less than 200 data vs the classic solution of 785*(3+3+2) + 990*3 data. 

  In using this app to digitize the classic teapot json file, discovered that the almost ellipses in the handle are invariant is size.  Only their rotation changes.   This is not consistant with the teapot lore which has come down to us about a real teapot having been digitized, and the height then reduced in post processing. 

  Did include this classic teapot json in the sketch file set after having performed two non-deforming alterations: 
1) turned upright so +Z is up
2) shifted the axis of symetry for the lid and body back to x,y=(0,0).
