import g4p_controls.*;
import org.apache.log4j.*;
import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.InputEvent;
import java.awt.Point;
import java.awt.MouseInfo;

float angle;
PImage world;

float[] xyzsAR;
float[] normalsAR;
float[] texCoordsAR;
int[] trianglesIndexsAR;

PShape teapot; /* teapot with reduced number of data */
float[] xyzs;
float[] normals;
float[] texCoords;
int[] trianglesIndexs;
/* Can turn any (even dis-connected) set of triangles into a single triangle strip. 
 * Almost certainly with fewer indices.  
 * But will leave that for another day.   Contact TPMoyer006@gmail.com if you are interested 
 */
//int[] triangleStripIndexs;  

/* toggles to cary the effects of GUI clicks back to my code */
boolean showThickAxies=false;
boolean showTeapot=true;
boolean showHello=true;
boolean showCrossHairs=true;

/* Wanted to have focus go to main window after making a selection in the gui window.
 * per https://discourse.processing.org/t/is-it-possible-to-open-a-second-window-in-processing-3-4-using-g4p/5888/7
 * went with the robot class to push a mouse click.  
 * Bit hack'y but sometimes a programmer's gotta do what a programmers gotta do. 
 */
Robot robot; 
Point mainWindowXY=new Point(78,328); /* use variable for the surface X,Y so that the robot class can click on an inside-the-window location */

/* Thank you Jake Seigel for the processing log4j connectivity!    
 * I'm a logggerDebugger and this was key to being able to 
 * dig myself out of several/many  holes/traps/mistakes/typos:   https://jestermax.wordpress.com/2014/06/09/log4j-4-you/    */ 
Logger log = Logger.getLogger("Master"); 

void setup() {
  size(640,480, P3D); 
  /* set to wherever is a convenient viewing location on your system. Numbers are X,Y pixel offsets from UL screen corner */
  surface.setLocation((int)mainWindowXY.getX(),(int)mainWindowXY.getY());

  initLog4j();
  font0 = createFont("Monospaced.bold", 16); /* used by ck.thickLabledAxies()  */
  textFont(font0); 
  colorMode(RGB, 1);
  createGUI();
  initializeGUI();

  //ck.setCameraNear(.01);ck.setCameraFar(40.); /* Allowed precise (close in) movement when using this app to digitize the classic teapot */
  ck.setCameraNear(.1);
  ck.setCameraFar(500.); /* Should prevent most folks from having the teapot become invisible because it is outside the Frustum */
  ck.setDeltaXYZ(8.); 

  perspective(PI/3.0, width/height, ck.getCameraNear(), ck.getCameraFar());
  try{
    robot = new Robot(); /* java Robot class is used to control mouse from within the program. */
  } catch (AWTException e) {
    e.printStackTrace();
  }
  /* This is bigger than is needed for the full teapot view, but the app demo's keyboard movement, so folks will zoom in. */ 
  world=loadImage(".\\data\\world.topo.bathy.200407.3x4096x2048_B35.jpg"); 
 
  getReducedDataCountJsonTeapot();
  createteapot();  
 
  /*          x         y         z            pitch                 roll                 yaw           */  
  ck.set(    0.900,  -28.183,    8.665,    radians(   0.000),   radians(   0.000),   radians(  90.000));
}

void draw() {  
  ck.drawMethods();
  scale(1.,1.,-1.); /* set Y axis conformal to USA Math, USA Physics, and OpenGL:  X Positive to the right, Y Positive Away, Z Positive is up */
  background(0.9); /* different from full white, so that if anything is ever inadvertantly drawn white, it will still be visible */
  lights();
  if(showCrossHairs)ck.drawCrossHairs();
   
  label1.setText(String.format(
    "XYZ (%9.3f,%9.3f,%9.3f)   Pitch,Roll,Yaw (%8.3f,%8.3f,%8.3f)  %5.1f distance/sec  %6.2f°/sec",
    ck.xyz.x,
    ck.xyz.y,
    -ck.xyz.z,
    degrees(-ck.pry.x),
    degrees(ck.pry.y),
    degrees(ck.pry.z),
    ck.deltaXYZ,
    degrees(ck.deltaPRY) 
   ));
    
  if(showThickAxies){  
    pushMatrix();
      scale(.065);
      //scale(ck.xMod(.01,.1));
      ck.thickLabledAxies();
    popMatrix();
  }
  if(showTeapot){
    pushMatrix();
      shape(teapot);
    popMatrix();
  }  
  if(showHello)sayHello();
  
  angle += 0.01; 
  //angle=0.353;
  //angle=ck.thetaMod(); /* used to find angle for a pretty screenshot */
}
void createteapot() {
  textureMode(NORMAL);
  teapot = createShape();
  teapot.beginShape(TRIANGLES);
 // teapot.noStroke();
  teapot.texture(world);
  int numTriangles=trianglesIndexs.length/3;
  /**/log.debug("see numTriangles as "+numTriangles);
  for (int ii=0;ii<numTriangles;ii++) {
    for(int jj=0;jj<3;jj++){
      //log.debug(String.format("%5d %5d %5d",ii,jj,trianglesIndexs[3*ii+jj]));
      teapot.normal(normals[3*trianglesIndexs[3*ii+jj]  ],
                normals[3*trianglesIndexs[3*ii+jj]+1],
                normals[3*trianglesIndexs[3*ii+jj]+2]
               );
      teapot.vertex(xyzs     [3*trianglesIndexs[3*ii+jj]  ],
                xyzs     [3*trianglesIndexs[3*ii+jj]+1],
                xyzs     [3*trianglesIndexs[3*ii+jj]+2],
                texCoords[2*trianglesIndexs[3*ii+jj]  ],
                texCoords[2*trianglesIndexs[3*ii+jj]+1]
               );      

      //if(ii<30){
        //log.debug(String.format("min %4d (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) (%5.3f,%5.3f)",
        //  ii,
        //  xyzs[3*trianglesIndexs[3*ii+jj]  ],
        //  xyzs[3*trianglesIndexs[3*ii+jj]+1],
        //  xyzs[3*trianglesIndexs[3*ii+jj]+2],
        //  normals[3*trianglesIndexs[3*ii+jj]  ],
        //  normals[3*trianglesIndexs[3*ii+jj]+1],
        //  normals[3*trianglesIndexs[3*ii+jj]+2],
        //  texCoords[2*trianglesIndexs[3*ii+jj]  ],
        //  texCoords[2*trianglesIndexs[3*ii+jj]+1]
        //));
      //}
    }
  }
  teapot.endShape();
}
void sayHello(){
  String hw="Hello World";
  float orbitRadius0=94.;
  //orbitRadius0=ck.xMod(65.,100); /* the xMod(), yMod(), thetaMod(), and phiMod() methods are used to allow mouse position on the main window to affect visual parameters */
  float orbitHeight0=120.;
  //orbitHeight0=ck.yMod(0,145);
  float orbitRadius1=106.;
  //orbitRadius1=ck.xMod(95.,140);
  float orbitHeight1=36.;
  //orbitHeight1=ck.yMod(-45,100);
  float deltaTheta=.1;
  //deltaTheta=ck.xMod(0,.1);

  orbitRadius0+=5;
  pushMatrix();
    scale(.1);
    fill(0.,1.,0.);
    for(int jj=0;jj<4;jj++){
      float yaw=angle+jj*PI/2.;
      for(int ii=0;ii<hw.length();ii++){
        ck.y3dText(
          hw.substring(ii,ii+1),
          orbitRadius0*cos(yaw),
          orbitRadius0*sin(yaw),
          orbitHeight0,
          radians(48),
          0.,
          yaw
        );
        yaw-=deltaTheta;
      }
    }  

    for(int jj=0;jj<4;jj++){
      //float northSouthShift=ck.xMod(0.,PI/4);
      float northSouthShift=0.703;
      float yaw=-angle+jj*PI/2.+northSouthShift;
      for(int ii=0;ii<hw.length();ii++){
        ck.y3dText(
          hw.substring(ii,ii+1),
          orbitRadius1*cos(yaw),
          orbitRadius1*sin(yaw),
          orbitHeight1,
          //ck.thetaMod(),    /* radians(ck.xMod(0,360)   or  thetaMod() to find the angle wanted.  right-mouse-click pushes mouse data to console */
          -.393,
          //ck.phiMod(),
          PI,
          yaw
        );
        yaw+=deltaTheta;
      }
    }
  popMatrix();
}
