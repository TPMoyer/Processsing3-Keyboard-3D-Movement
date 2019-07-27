/* CameraKey allows keyboard movement of the camera viewpoint
 *
 * the translate keys change the position, but do not change orientation 
 * f and F  = move Forward
 * b and B  = move backward  (also v and V because I kept hitting the wrong keys)
 *
 * The arrow keys are those keys over on the right of a full keyboard 
 * right arrow key = move to the right
 *  left arrow key = move to the left
 *    up arrow key = move up
 *  down arrow key = move down
 *
 * The twist-and-turn keys change orientation, but do not change position
 * An airplane analogy is used to convey directions.
 * r and R = Roll clockwize        (right wing down, left wing up  )
 * c and C = counterClockwize Roll (right wing up  , left wing down)
 * shift    up arrow = push the nose down
 * shift  down arrow = pull the nose up
 * shift right arrow = turn the nose to the right
 * shift  left arrow = turn the nose to the left
 *
 * The speed of motion can be altered with the 
 * F1 key to decrease XYZ motion to 1/2 prior value
 * F2 key to increase XYZ motion 2X
 * F3 key to decrease angular turning speeds to 1/2 prior value
 * F4 key to increase angular turning speeds 2X
 */

/* initial orientation: high above XY(0,0) looking along Z-, with viewpoint up as X+ */ 
/*                           x  y  z           pitch                roll             yaw     */
CameraKey ck = new CameraKey(0.,0.,500.,    radians( -90.000),   radians( 0.000),   radians( 0.000));

/*  so generally useful that everybody should have one of each */
float x,y,z,theta,phi;
PFont font0;

class CameraKey {

  /* x, y, and z are set up to correspond to the orientation taught in USA math an USA physics classes
   * This has 
   *   X positive to the right
   *   Y positive away
   *   Z positive up
   */
 public PVector xyz;
  /* pitch is 0 is nose and tail level.  PI/2 is up -PI/2 is down 
   * pitch of 0 and roll of 0 gives wings level.  Positive roll moves left wing up  
   * yaw is the compass heading with positive X as 0 degrees as East, positive Y is yaw of PI/2 is North  
   * bounds on pitch are -PI/2 to PI/2
   * bounds on roll are 0 to TWO_PI   
   * bounds on yaw are 0 to TWO_PI 
   */
  public PVector pry;  
//  public float deltaXYZ=8;
  public float deltaXYZ=8;   /* depending on the size of your image (in unitless x,y,z values) make this a larger or smaller power of 2 */ 
  public float deltaPRY=radians(30.);
  private boolean verbosePOV=false;
  private boolean showThickAxies=true;
  private float cameraNear;
  private float cameraFar;
  
  private Boolean shiftPressed=false;
  private Boolean ctrlPressed=false; /* currently do not have modifiers for ctrl key being pressed */
  private Boolean altPressed=false;  /* currently do not have modifiers for alt  key being pressed */
  private Integer numModPressed=0;
  private Integer numKeysPressed=0;
  private Boolean postModReleased=false;
  private boolean keyDownSeen=false;
  private boolean mouseDownPOVSeen=false;
  private boolean mouseDownXSeen=false;
  private boolean mouseDownYSeen=false;
  private boolean mouseDownThetaSeen=false;
  private boolean mouseDownPhiSeen=false;
  
  private PVector left    = new PVector();
  private PVector up      = new PVector();
  private PVector forward = new PVector();
  private PVector magnitudes = new PVector();
  
  private PVector left0    = new PVector();
  private PVector up0      = new PVector();
  private PVector forward0 = new PVector();
  private PVector magnitudes0 = new PVector();
  
  
  /* Used by the X,Y,Theta, Phi   Mod series of methods.
   * Allows the user to exit the window without disturbing the current settings 
   * by clicking-and-holding-down a mouse key, as the mouse if moved out of the window
   */
  private float lastPriorX=0.;
  private float lastPriorY=0.;
  private float lastPriorTheta=0;
  private float lastPriorPhi=0.;
  private boolean verboseMod=false; /* toggle for the Mod methods to print to console */

  CameraKey(){};

  CameraKey(float X,float Y,float Z,float pitch, float roll,float yaw){
    this.xyz = new PVector(X,Y,-Z);
    this.pry = new PVector(-pitch,roll,yaw);
    println  (String.format("(%7.3f,%7.3f,%7.3f) (%8.3f,%8.3f,%8.3f)",xyz.x,xyz.y,xyz.z,degrees(pry.x),degrees(pry.y),degrees(pry.z)));
    //log.debug(String.format("(%7.3f,%7.3f,%7.3f) (%8.3f,%8.3f,%8.3f)",xyz.x,xyz.y,xyz.z,degrees(pry.x),degrees(pry.y),degrees(pry.z)));
  }
  // void y3dText2(String s,float x,float y,float z,float pitch,float roll,float yaw){    
  //   pushStyle();
  //     pushMatrix();
  //       fill(0);
  //       //PVector savedPRY=pry;
  //       //PVector savedXYZ=xyz;
  //       //set(0.,0.,0.,pitch,roll,yaw);
       
  //       rotateY(yaw);
  //       rotateX(pitch);
        
  //       text(s,x,-z,y);      
  //       //set(savedXYZ.x,savedXYZ.y,savedXYZ.z,savedPRY.x,savedPRY.y,savedPRY.z);
        
  //       ////rotate(pitch,roll,yaw);
  //       ////float theta=thetaMod(-PI,PI);
  //       //rotateX(pitch);
  //       ////rotateY(roll);
  //       ////rotateZ(yaw);
  //       //fill(0);
  //       //pushMatrix();
  //       //  //scale(1,-1,1); /* causes Y to be back to the Processing default */
  //       //  text(s,x,y,z);
  //       //popMatrix();
  //     popMatrix();
  //   popStyle();
  // }  
  

   
  void set(float X,float Y,float Z,float pitch, float roll,float yaw){
    this.xyz = new PVector(X,Y,-Z);
    this.pry = new PVector(-pitch,roll,yaw);
    //log.debug(String.format("(%7.3f,%7.3f,%7.3f) (%8.3f,%8.3f,%8.3f)",xyz.x,xyz.y,xyz.z,degrees(pry.x),degrees(pry.y),degrees(pry.z)));
  }  
  void setDeltaXYZ(float toB){
    deltaXYZ=toB;
  }
  /* start each of these with right hand,  index finger away.   thumb up.    
   * pitch is tilt index finger down,                   phi    symbol is circle with vertical stripe 
   * roll is tilt thumb to left                         psi    symbol is trident  
   * yaw is pivot index finger toward the left          theta  symbol is circle with horizontal stripe
   */
  void setPRY(float pitch,float roll, float yaw){
    pry.set(pitch,roll,yaw);
    this.set(true);
  }
  void checkIfSay(){
    if(!mousePressed) mouseDownPOVSeen=false;
    if(  verbosePOV
       ||(  mousePressed
          &&(mouseButton==37)
          &&(!mouseDownPOVSeen)
         )
      ){
      say();
      mouseDownPOVSeen=true;
    }
  }  
  /* this sets the global X Y Z pitch Roll and Yaw from the current modelview matrix */
  void set(Boolean say){  
    //if(say)log.debug("ck.set incomming "+String.format("(%7.3f,%7.3f,%7.3f) (%8.3f,%8.3f,%8.3f)",xyz.x,xyz.y,xyz.z,degrees(pry.x),degrees(pry.y),degrees(pry.z)));
    //if(say)log.debug(say1());
    pushMatrix();
      PMatrix3D mvm = new PMatrix3D(); 
      camera(0.,0.,0.,  1.,0.,0.,   0.,0.,1.);  /* starting point for 0 pitch, 0 yaw, 0 roll is flat-and-level pointing toward PosX */
      //log.debug("");
      //log.debug(String.format("xyz=(%9.3f,%9.3f,%9.3f) pry=(%8.3f,%8.3f,%8.3f)",xyz.x,xyz.y,xyz.z,degrees(pry.x),degrees(pry.y),degrees(pry.z)));
      rotate(-pry.z,0.,0.,1.); /* rotate yaw along the up vector.  Up is 0.,0.,1. because of the prior camera command */
      mvm=((PGraphicsOpenGL)g).modelview;
      rotate(-pry.x,mvm.m00,mvm.m01,mvm.m02); /* rotate along the (now modified by yaw) right axis */
      mvm=((PGraphicsOpenGL)g).modelview;
      rotate(pry.y,-mvm.m20,-mvm.m21,-mvm.m22); /* rotate along the (now modified by yaw and pitch) forward axis */
      //sayMVM();
      sayMVM(); /* this carries the Processing internal variables to this class's forward, left, and up PVectors */
      //if(say)log.debug("zCameraKey 96 "+sayMVM());
      //if(say)log.debug("zCameraKey 97 "+xyzpryFigure());
    popMatrix();
    camera(xyz.x,xyz.y,xyz.z,   xyz.x+forward.x,xyz.y+forward.y,xyz.z+forward.z,  up.x,up.y,up.z);
    //if(say)log.debug(say1());
    //if(say)println(say1());
 }
 void say(){
    println(String.format("ck.set(%9.3f,%9.3f,%9.3f,    radians(%8.3f),   radians(%8.3f),   radians(%8.3f));",
      xyz.x,
      xyz.y,
      -xyz.z,
      -degrees(pry.x),
      degrees(pry.y),
      degrees(pry.z)   
   )); 
   //println(say1());
  }  
  void sayLog(){
    log.debug(String.format("ck.set(%9.3f,%9.3f,%9.3f,    radians(%8.3f),   radians(%8.3f),   radians(%8.3f));",
      xyz.x,
      xyz.y,
      -xyz.z,
      -degrees(pry.x),
      degrees(pry.y),
      degrees(pry.z)   
   )); 
   //println(say1());
  }  
  String say1(){
    return( String.format("%9.3f (%6.3f,%6.3f,%6.3f)   %9.3f (%6.3f,%6.3f,%6.3f)   %9.3f (%6.3f,%6.3f,%6.3f)",
      magnitudes.x,
      left.x,
      left.y,
      left.z,
      magnitudes.z,
      up.x,
      up.y,
      up.z,
      magnitudes.z,
      forward.x,
      forward.y,
      forward.z      
    ));      
  }  
  String sayDeflected(){
    return( String.format("deflecteds %9.3f (%6.3f,%6.3f,%6.3f)   %9.3f (%6.3f,%6.3f,%6.3f)   %9.3f (%6.3f,%6.3f,%6.3f)",
      magnitudes0.x,
      left0.x,
      left0.y,
      left0.z,
      magnitudes0.z,
      up0.x,
      up0.y,
      up0.z,
      magnitudes0.z,
      forward0.x,
      forward0.y,
      forward0.z      
    ));      
  }  
  void sayPure(){
    println(String.format("(%9.3f,%9.3f,%9.3f) (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) (%6.3f,%6.3f,%6.3f) (%6.3f,%6.3f,%6.3f)",
      xyz.x,
      xyz.y,
      xyz.z,
      degrees(pry.x),
      degrees(pry.y),
      degrees(pry.z),
      cos(pry.x)*sin(pry.z),  // forward[0]
      cos(pry.x)*cos(pry.z),  // forward[1]
      sin(pry.x),             // forward[2]
      -1.0*sin(pry.y)*cos(pry.z)-cos(pry.y)*sin(pry.x)*sin(pry.z), // up[0]
      sin(pry.y)*sin(pry.z)-cos(pry.y)*sin(pry.x)*cos(pry.z),      // up[1]
      cos(pry.y)*cos(pry.x),                                       // up[2] 
      cos(pry.z) * cos(pry.y)  + sin(pry.z) * sin(pry.x) * sin(pry.y), // right[0]
      -sin(pry.z) * cos(pry.y) + cos(pry.z) * sin(pry.x) * sin(pry.y), // right[1]
       cos(pry.x) * sin(pry.y)                                         // right[2]
   ));      
  }  
  /* 3D orientated text.
   * yaw is compass bearing within the XY plane.   
   *    yaw==0      is text perpendicular to east,  to be read from x=0
   *     yaw==PI/2   is text perpendicular to north, to be read from x=0
   *     yaw==PI     is text perpendicular to west,  to be read from x=0
   *     yaw==3*PI/2 is text perpendicular to south, to be read from x=0
   *  pitch is rotation around the line connecting the bases of the text letters
   *     pitch==-PI/2 is viewpoint pointing down. Horizontal text, to be read from Z's more positive than the text
   *     pitch==0     is viewpoint within XY plane. Verticle text,
   *     pitch==PI/2  is veripoint pointing UP.  Horizontal text, to be read from Z's more negative 
   *     pitch==3*PI/2 probably best to not think of pitch outside of   -PI/2 < pitch < PI/2 
   *  roll is rotation around the forward direction from the yaw and pitch
   *     roll==0     is text along observer horizontal, with next letter to the right, ( == normal reading orientation)
   *     roll==PI/2  is text along observer vertical    with next letter further along observer UP.  Text up is observer left. 
   *     roll==PI    is upside down text along observer horizontal, with next letter further along observer left
   *     roll=3*PI/2 is text along observer vertical    with next letter further along observer DOWN.  Text up is observer right.
   */     
  void y3dText(String s,float x,float y,float z,float pitch,float roll,float yaw){
    pushMatrix();
      translate(x,y,z); 
      rotate(-roll,cos(yaw)*cos(pitch),sin(yaw)*cos(pitch),sin(pitch));      
      rotateZ(yaw-PI/2); 
      rotateX(3*PI/2+pitch);
     //println(String.format("xyz for forward=(%6.3f,%6.3f,%6.3f)",cos(yaw)*cos(pitch),sin(yaw)*cos(pitch),sin(pitch)));
      text(s,0.,0.,0.);
    popMatrix();
  }
  /* Asymetric labeled axies
   * The positive ends of each axis has extensions along the positive directions of the other two axies 
   * The labels on the axies can also serve as y3dText orientation examples 
   */
  void thickLabledAxies(){
    //scale(ck.xmod(.01,1)); /* used to find best shrinkage factor */
    //scale(.065);  /* teapot is only +/- 16 and full scale axies are +/- 500, so found .065 most pretty */   
    fill(0);
    y3dText("<= NEG X    X POS =>",-100.,  -4.,  11., -PI/2.,    0.,    PI/2.); /* on top       of X axis */
    y3dText("<= NEG X    X POS =>",-100., -11.,  -4.,     0.,    0.,    PI/2.); /* on yNeg side of X axis */
    y3dText("<= POS X    X NEG =>", 100.,  11.,  -4.,     0.,    0., 3.*PI/2.); /* on yPos side of X axis */
    y3dText("<= NEG X    X POS =>",-100.,   4., -11.,  PI/2.,    0.,    PI/2.); /* on bottom    of X axis */

    y3dText("<= NEG Y    Y POS =>",   4.,-100.,  11., -PI/2.,    0.,    PI   ); /* on top       of Y axis */
    y3dText("<= NEG Y    Y POS =>",  11.,-100.,  -4.,     0.,    0.,    PI   ); /* on xPos side of Y axis */
    y3dText("<= POS Y    Y NEG =>", -11., 100.,  -4.,     0.,    0.,       0.); /* on xNeg side of Y axis */
    y3dText("<= POS Y    Y NEG =>",   4., 100., -11.,  PI/2.,    0.,       0.); /* on bottom    of Y axis */

    y3dText("<= NEG Z    Z POS =>",  -4.,  11.,-100.,     0., PI/2., 3.*PI/2.); /* on yPos side of Z axis */
    y3dText("<= NEG Z    Z POS =>",   4., -11.,-100.,     0., PI/2.,    PI/2.); /* on yNeg side of Z axis */
    y3dText("<= NEG Z    Z POS =>",  11.,   4.,-100.,     0., PI/2.,    PI   ); /* on xPos side of Z axis */
    y3dText("<= NEG Z    Z POS =>", -11.,  -4.,-100,      0., PI/2.,       0.); /* on xNeg side of Z axis */
    
    /* the axis boxes are rendered using the effects of the lights() if they are active */
    pushStyle();  
      stroke(1,0,0);
      strokeWeight(5);
      //strokeWeight(1);
      float thick=20;
      fill(.8);
      //noFill();
           
      box(500., thick, thick);  /* X axis */
      pushMatrix();
        translate(250.,50.,0.);
        box(thick,100.,thick);  /* L on end of X axis toward Y+ */
        translate(0.,-50.,50.);
        box(thick,thick,100.);  /* L on end of Y axis toward Z+ */
      popMatrix();
      
      box( thick,500., thick);
      pushMatrix();
        translate(50.,250.,0.);
        box(100.,thick,thick);  /* L on end of Y axis toward X+ */
        translate(-50.,0.,50.);
        box(thick,thick,100.);  /* L on end of Y axis toward Z+ */
      popMatrix();
      
      box( thick, thick,500.);
      pushMatrix();
        translate(50.,0.,250.);
        box(100.,thick,thick);  /* L on end of Z axis toward X+ */
        translate(-50.,50.,0.);
        box(thick,100.,thick);  /* L on end of Z axis toward Y+ */
      popMatrix();
      
    popStyle();
  }
  /* return a string for a pretty'd up modelview Matrix.  
   * Note that several values output are -1.0X the actual modelview values.
   * Format is presented as left, up, and forward, with magnitudes for each 
   */
  String sayMVM(){
    pushMatrix();
      PMatrix3D mvm=((PGraphicsOpenGL)g).modelview;
      /* uncommenting the following will log the un-modified values of the modelview matrix */
      //log.debug(String.format("raw  \n%6.3f %6.3f %6.3f %9.3f     -leftX    -leftY    -leftZ      leftMagnitude\n%6.3f %6.3f %6.3f %9.3f        upX       upY       upZ       -upMagnitude\n%6.3f %6.3f %6.3f %9.3f  -forwardX -forwardY -forwardZ   forwardMagnitude\n%6.3f %6.3f %6.3f %9.3f",
      //  mvm.m00,mvm.m01,mvm.m02,mvm.m03,
      //  mvm.m10,mvm.m11,mvm.m12,mvm.m13,
      //  mvm.m20,mvm.m21,mvm.m22,mvm.m23,
      //  mvm.m30,mvm.m31,mvm.m32,mvm.m33
      //));
      float m00=mvm.m00*-1.;
      float m01=mvm.m01*-1.;      
      float m02=mvm.m02*-1.;
      float m03=mvm.m03;
      float m10=mvm.m10;
      float m11=mvm.m11;
      float m12=mvm.m12;
      float m13=mvm.m13*-1.;
      float m20=mvm.m20*-1.;
      float m21=mvm.m21*-1.;      
      float m22=mvm.m22*-1.;
      float m23=mvm.m23;
      float m30=mvm.m30;
      float m31=mvm.m31;
      float m32=mvm.m32;
      float m33=mvm.m33;
      if(m00>-0.0005 && m00<0.0005)m00=0.;
      if(m01>-0.0005 && m01<0.0005)m01=0.;
      if(m02>-0.0005 && m02<0.0005)m02=0.;
      if(m03>-0.0005 && m03<0.0005)m03=0.;
      if(m10>-0.0005 && m10<0.0005)m10=0.;
      if(m11>-0.0005 && m11<0.0005)m11=0.;
      if(m12>-0.0005 && m12<0.0005)m12=0.;
      if(m13>-0.0005 && m13<0.0005)m13=0.;
      if(m20>-0.0005 && m20<0.0005)m20=0.;
      if(m21>-0.0005 && m21<0.0005)m21=0.;
      if(m22>-0.0005 && m22<0.0005)m22=0.;
      if(m23>-0.0005 && m23<0.0005)m23=0.;
      String sm00=String.format("%6.3f",m00);
      String sm01=String.format("%6.3f",m01);
      String sm02=String.format("%6.3f",m02);
      String sm03=String.format("%9.3f",m03);
      String sm10=String.format("%6.3f",m10);
      String sm11=String.format("%6.3f",m11);
      String sm12=String.format("%6.3f",m12);
      String sm13=String.format("%9.3f",m13);
      String sm20=String.format("%6.3f",m20);
      String sm21=String.format("%6.3f",m21);
      String sm22=String.format("%6.3f",m22);
      String sm23=String.format("%9.3f",m23);
      String sm30=String.format("%6.3f",m30);
      String sm31=String.format("%6.3f",m31);
      String sm32=String.format("%6.3f",m32);
      String sm33=String.format("%9.3f",m33);
      //log.debug("sm00.substring(sm00.length()-3)="+sm00.substring(sm00.length()-3));
      if("000".equals(sm00.substring(sm00.length()-3)))sm00=sm00.substring(0,sm00.length()-4)+"    ";
      if("000".equals(sm01.substring(sm01.length()-3)))sm01=sm01.substring(0,sm01.length()-4)+"    ";
      if("000".equals(sm02.substring(sm02.length()-3)))sm02=sm02.substring(0,sm02.length()-4)+"    ";
      if("000".equals(sm03.substring(sm03.length()-3)))sm03=sm03.substring(0,sm03.length()-4)+"    ";
      if("000".equals(sm10.substring(sm10.length()-3)))sm10=sm10.substring(0,sm10.length()-4)+"    ";
      if("000".equals(sm11.substring(sm11.length()-3)))sm11=sm11.substring(0,sm11.length()-4)+"    ";
      if("000".equals(sm12.substring(sm12.length()-3)))sm12=sm12.substring(0,sm12.length()-4)+"    ";
      if("000".equals(sm13.substring(sm13.length()-3)))sm13=sm13.substring(0,sm13.length()-4)+"    ";
      if("000".equals(sm20.substring(sm20.length()-3)))sm20=sm20.substring(0,sm20.length()-4)+"    ";
      if("000".equals(sm21.substring(sm21.length()-3)))sm21=sm21.substring(0,sm21.length()-4)+"    ";
      if("000".equals(sm22.substring(sm22.length()-3)))sm22=sm22.substring(0,sm22.length()-4)+"    ";
      if("000".equals(sm23.substring(sm23.length()-3)))sm23=sm23.substring(0,sm23.length()-4)+"    ";
      if("000".equals(sm30.substring(sm30.length()-3)))sm30=sm30.substring(0,sm30.length()-4)+"    ";
      if("000".equals(sm31.substring(sm31.length()-3)))sm31=sm31.substring(0,sm31.length()-4)+"    ";
      if("000".equals(sm32.substring(sm32.length()-3)))sm32=sm32.substring(0,sm32.length()-4)+"    ";
      if("000".equals(sm33.substring(sm33.length()-3)))sm33=sm33.substring(0,sm33.length()-4)+"    ";
      String outString=String.format("sayMVM\n%s %s %s %s      leftX     leftY     leftZ     leftMagnitude - - - +\n%s %s %s %s        upX       upY       upZ       upMagnitude + + + -\n%s %s %s %s   forwardX  forwardY  forwardZ  forwardMagnitude - - - +\n%s %s %s %s",
        sm00,sm01,sm02,sm03,
        sm10,sm11,sm12,sm13,
        sm20,sm21,sm22,sm23,
        sm30,sm31,sm32,sm33
      );
    popMatrix();
    
    left       = new PVector(m00,m01,m02);
    up         = new PVector(m10,m11,m12);
    forward    = new PVector(m20,m21,m22);
    magnitudes = new PVector(m03,m13,m23);
    //log.debug("inside sayMVM outString=\n"+outString);
    //log.debug(String.format("inside sayMVM    left=(%6.3f,%6.3f%6.3f)",left.x   ,left.y   ,left.z   ));
    //log.debug(String.format("inside sayMVM      up=(%6.3f,%6.3f%6.3f)",up.x     ,up.y     ,up.z     ));
    //log.debug(String.format("inside sayMVM forward=(%6.3f,%6.3f%6.3f)",forward.x,forward.y,forward.z));
    //println("outstring=\n"+outString);    
    return(outString);  
  }
  
  String xyzpryFigure(){
    /* author's note:  pretty easy to see which side of the "use logging" vs "set breakpoints" debugging technique I favor. 
     * I'd feel bad about it if somebody else had come up with a way to know:    Which way is up?
     */
    float x,y,z,pitch,roll,yaw;
    pushMatrix();
      PMatrix3D mvm=((PGraphicsOpenGL)g).modelview;
      /* uncommenting the following expression shows the un-modified modelview matrix in it's native state */  
      //log.debug(String.format("raw  \n%6.3f %6.3f %6.3f %9.3f     -leftX    -leftY    -leftZ      leftMagnitude\n%6.3f %6.3f %6.3f %9.3f        upX       upY       upZ       -upMagnitude\n%6.3f %6.3f %6.3f %9.3f  -forwardX -forwardY -forwardZ   forwardMagnitude\n%6.3f %6.3f %6.3f %9.3f",
      //  mvm.m00,mvm.m01,mvm.m02,mvm.m03,
      //  mvm.m10,mvm.m11,mvm.m12,mvm.m13,
      //  mvm.m20,mvm.m21,mvm.m22,mvm.m23,
      //  mvm.m30,mvm.m31,mvm.m32,mvm.m33
      //));
      /* Changing the mvm.m00 changes the real, continues to be used, modelviewMatrix.  Sheesh!
       * Copied the parameters over to local floats to avoid odd behavior in calling and called code.  
       * Aligned parameters with preconcieved desires (left,up,forward) and
       * implemented desire to have all presented numbers be non-negated.  
       */
      float m00=mvm.m00*-1.;
      float m01=mvm.m01*-1.;
      float m02=mvm.m02*-1.;
      float m03=mvm.m03;
      float m10=mvm.m10;
      float m11=mvm.m11;
      float m12=mvm.m12;
      float m13=mvm.m13*-1.;
      float m20=mvm.m20*-1.;
      float m21=mvm.m21*-1.;
      float m22=mvm.m22*-1.;
      float m23=mvm.m23;
      x= m00*m03+m10*m13+m20*m23;
      y= m01*m03+m11*m13+m21*m23;
      z= m02*m03+m12*m13+m22*m23;
      /* if forward is not straight down or straight up */
      if(  (Math.abs(m20)>0.000001)
         ||(Math.abs(m21)>0.000001)
        ) {
        //log.debug("normal yaw");  
        yaw=(float)Math.atan2(m21,m20);
      } else  {    
        if(0. > m22){
          //log.debug("vertical down yaw");
          yaw=(float)Math.atan2(m11,m10);
        } else {
          //log.debug("vertical up yaw");
          yaw=(float)Math.atan2(-m11,-m10);
        }  
      }
      if( (yaw   > -0.000001) && (yaw   < 0.000001)) yaw   = 0.;
      if(TWO_PI<=yaw)yaw-=TWO_PI;
      if(0.>yaw)yaw+=TWO_PI;
    
      pitch=(float)Math.atan2(m22,sqrt(m20*m20+m21*m21));
      if( (pitch > -0.000001) && (pitch < 0.000001)) pitch = 0.;
      roll=0.;
      pushMatrix();
        /* roll is the toughest. */
        //log.debug("translate back to zero so we are only spinning in place");
        translate(-x,-y,-z);
        //sayMVM();
        //log.debug("rotate yaw along Z so it is now in XZ plane");
        rotate(yaw,0.,0.,1.);
        //sayMVM();
        //log.debug("rotate pitch along Y ");
        rotate(-pitch,0.,1.,0.);
        //sayMVM();
        PMatrix3D mvm0=((PGraphicsOpenGL)g).modelview;     
        roll=(float)Math.atan2(mvm0.m11,mvm0.m12);
      popMatrix();
  
      if(TWO_PI<=roll)roll-=TWO_PI;
      if(0.>roll)roll+=TWO_PI;
      if( (roll  > -0.000001) && (roll  < 0.000001)) roll  = 0.;
      if( (roll  > TWO_PI-0.000001)) roll  = 0.;
    
      String outString=String.format("xyz=(%9.3f,%9.3f,%9.3f) pry=(%8.3f,%8.3f,%8.3f)",x,y,z,degrees(pitch),degrees(roll),degrees(yaw));
      xyz = new PVector(x,y,z);
      pry = new PVector(pitch,roll,yaw);
    popMatrix(); 
    return(outString);
  }
  void drawCrossHairs(){
    pushStyle();
    pushMatrix();
      scale(1,1,-1);
      /* as each of the movements calls xyzpryFigure, the left, up, and forward vectors are maintained up-to-date */
      //log.debug(String.format("incomming to drawCrossHairs\nleft=(%6.3f,%6.3f,%6.3f)   up=(=(%6.3f,%6.3f,%6.3f) forward=(%6.3f,%6.3f,%6.3f)",
      //  left.x,left.y,left.z,
      //  up.x,up.y,up.z,
      //  forward.x,forward.y,forward.z
      //  ));
      //xyzpryFigure();
      //log.debug(String.format("post xyzpryFigure          \nleft=(%6.3f,%6.3f,%6.3f)   up=(=(%6.3f,%6.3f,%6.3f) forward=(%6.3f,%6.3f,%6.3f)",
      //  left.x,left.y,left.z,
      //  up.x,up.y,up.z,
      //  forward.x,forward.y,forward.z
      //  ));
    
      float noseExtension= 1.01*cameraNear;  /* crosshair X factor */
      //    log.debug("noseExtension="+noseExtension);
      //   sayLog();
      translate(
        xyz.x+noseExtension*forward.x,
        xyz.y+noseExtension*forward.y,
        xyz.z+noseExtension*forward.z
      );
      //   sayLog();
      stroke(1.,0.,0.);
      x=.018;y=.032;z=.125;
      //x=xMod(0.,.25);
      //y=xMod(.036,.1);
      //z=yMod(.5,.2);
     for(int ii=0;ii<4;ii++){
       pushMatrix();
         rotate(ii*PI/2.,forward.x,forward.y,forward.z);
         line(0.,0.,0.,
           x*cameraNear* left.x*(0==ii%2?1.:width/(float)height),
           x*cameraNear* left.y*(0==ii%2?1.:width/(float)height),
           x*cameraNear* left.z*(0==ii%2?1.:width/(float)height)
         );
         line(
           y*cameraNear* left.x*(0==ii%2?1.:width/(float)height),
           y*cameraNear* left.y*(0==ii%2?1.:width/(float)height),
           y*cameraNear* left.z*(0==ii%2?1.:width/(float)height),
           z*cameraNear* left.x*(0==ii%2?1.:width/(float)height),
           z*cameraNear* left.y*(0==ii%2?1.:width/(float)height),
           z*cameraNear* left.z*(0==ii%2?1.:width/(float)height)
         );
       popMatrix();  
     }
    popMatrix();
    popStyle();
  }
  void moveForward(){
    //println("forward");
    sayMVM();
    xyz.add(PVector.mult(forward,(deltaXYZ/frameRate)));
    if(verbosePOV)say();
  }
  void moveBackward(){
    //println("backward");
    sayMVM();
    xyz.add(PVector.mult(forward,(-1.*deltaXYZ/frameRate)));
    if(verbosePOV)say();
  }
  void moveUp(){
    //println("up");
    sayMVM();
    xyz.add(PVector.mult(up,(-1.*deltaXYZ/frameRate)));
    if(verbosePOV)say();
  }
  void moveDown(){
    //println("down");
    sayMVM();
    xyz.add(PVector.mult(up,(deltaXYZ/frameRate)));
    if(verbosePOV)say();
  }  
  
  void moveRight(){
    //println("right");
    sayMVM();
    xyz.add(PVector.mult(left,(-1.*deltaXYZ/frameRate)));
    if(verbosePOV)say();
  }
  void moveLeft(){
    //println("left");
    sayMVM();
    xyz.add(PVector.mult(left,(deltaXYZ/frameRate)));
    if(verbosePOV)say();
  }  

  void roll(){
    //println("roll");
    //log.debug("roll");
    sayMVM();
    translate( xyz.x, xyz.y, xyz.z);
    rotate(deltaPRY/frameRate,forward.x,forward.y,forward.z);
    translate(-xyz.x,-xyz.y,-xyz.z);
    xyzpryFigure();
    if(verbosePOV)say();    
  }
  void counterRoll(){
    //print("counterRoll");
    sayMVM();
    translate( xyz.x, xyz.y, xyz.z);
    rotate(-1.*deltaPRY/frameRate,forward.x,forward.y,forward.z);
    translate(-xyz.x,-xyz.y,-xyz.z);
    xyzpryFigure();
    if(verbosePOV)say();
  }  
  /* pitch internally is 0 at level, -PI/2 at down, pi/2 is up */
  void pitchNoseDown(){
    //println("nose down");
    //log.debug("nose down");
    sayMVM();
    translate( xyz.x, xyz.y, xyz.z);
    rotate(deltaPRY/frameRate,left.x,left.y,left.z);
    translate(-xyz.x,-xyz.y,-xyz.z);
    xyzpryFigure();
    if(verbosePOV)say();
  }
  void pitchNoseUp(){
    //println("nose up");
    sayMVM();
    translate( xyz.x, xyz.y, xyz.z);
    rotate(-1.*deltaPRY/frameRate,left.x,left.y,left.z);
    translate(-xyz.x,-xyz.y,-xyz.z);
    xyzpryFigure();
    if(verbosePOV)say();
  }
  /* limit yaw from 0 to TWO_PI */
  void yawRight(){
    //println("yaw right");
    sayMVM();
    translate( xyz.x, xyz.y, xyz.z);
    rotate(-1.*deltaPRY/frameRate,up.x,up.y,up.z);
    translate(-xyz.x,-xyz.y,-xyz.z);
    xyzpryFigure();
    if(verbosePOV)say();
  }
  /* limit yaw from 0 to TWO_PI */
  void yawLeft(){
    //println("yaw left");
    sayMVM();
    translate( xyz.x, xyz.y, xyz.z);
    rotate(deltaPRY/frameRate,up.x,up.y,up.z);
    translate(-xyz.x,-xyz.y,-xyz.z);
    xyzpryFigure();
    if(verbosePOV)say();
  }
  void drawMethods(){
    feedKeys();/* if any key is currently pressed, feed that directive to the methods which update POV variables */
    set(false);/* set the camera viewpoint.  false== do not print the current location & orientation */
    checkIfSay(); /* Mouse-Left-Click prints to console the CameraKey command which can be used to   set the current position & orientation */  
  }
  void feedKeys(){
   if(  (true==keyPressed)
       &&(  (0==numModPressed)
          ||(false==postModReleased)
         ) 
      ){
      if ('f' == key || 'F' == key) {
        ck.moveForward();
      } else 
      if (('b' == key)||('v' == key)||('B' == key)||('V' == key)){
        ck.moveBackward();
      } else
      if ('r' == key||'R' == key) {
        ck.roll();
      } else 
      if ('c' == key||'C' == key) {
        ck.counterRoll();
      } else 
      if (key == CODED) {
        //println(sayMVM());
        //log.debug("keyCode="+keyCode+"\n"+sayMVM());
        if(shiftPressed){
          if (UP    == keyCode) {
            ck.pitchNoseDown();
          } else 
          if (DOWN  == keyCode) {
            ck.pitchNoseUp();
          } else 
          if (LEFT  == keyCode) {
            ck.yawRight();
          } else 
          if (RIGHT == keyCode) {
            ck.yawLeft();
          }  
        } else {
          if (UP    == keyCode) {
            ck.moveUp();
          } else 
          if (DOWN  == keyCode) {
            ck.moveDown();
          } else 
          if (LEFT  == keyCode) {
            ck.moveLeft();
          } else 
          if (RIGHT == keyCode) {
            ck.moveRight();
          }  
        }
        //log.debug("post move");
        set(true);
      }
    }
    //if(  (true==keyPressed)
    //   &&(true==postModReleased)
    //  ){
    //  println("pre-empted ongoing shifting of pry");
    //}
  }
  /* used by the production version to parse keys to the app to control stuff */
  void feedKeysP(){
   //println("cme@feedKeysP() keyPressed="+keyPressed);
   if(true==keyPressed){
      println("key==CODED is "+(key==CODED)+" keyCode="+keyCode+" key="+key);
      if(false==ck.keyDownSeen){
        if (key == CODED) { 
          if (LEFT  == keyCode) {
            ck.keyDownSeen=true;
          } else 
          if (RIGHT == keyCode) {
            ck.keyDownSeen=true;
          }
        } else {
           println("keyDownSeen=true"); 
        }
      }
    }
    if(false==keyPressed)ck.keyDownSeen=false;
  }
  void setVerboseMod(boolean tf){
    verboseMod=tf;
  }
  boolean getVerboseMod(boolean tf){
    return(verboseMod);
  }
  void setVerbosePOV(boolean tf){
    verbosePOV=tf;
  }
  boolean getVerbosePOV(boolean tf){
    return(verbosePOV);
  }
  void setShowThickAxies(boolean tf){
    showThickAxies=tf;
  }
  boolean getShowThickAxies(){
    return(showThickAxies);
  }  
  void setLastPriorTheta(float thetaIn){
    println("cme@ setLastPriorTheta("+thetaIn+");");
    lastPriorTheta=thetaIn;
  }
  float getLastPriorTheta(){
    return(lastPriorTheta);
  }
  void setLastPriorPhi(float phiIn){
    lastPriorPhi=phiIn;
  }
  float getLastPriorPhi(){
    return(lastPriorPhi);
  }
  void setCameraNear(float cn){
    cameraNear=cn;
  }
  float getCameraNear(){
    return(cameraNear);
  }  
  void setCameraFar(float cf){
    cameraFar=cf;
  }
  float getCameraFar(){
    return(cameraFar);
  } 
  /* for these several mouse interactive methods 
   *    thetaMod()  thetaMod(minAngle,maxAngle)
   *    phiMod()    phiMod(minAngle,maxAngle)
   *    xMod()      xMod(minX,maxX)
   *    yMod()      yMod(minY,maxY)
   * a right-mouse-button click will print the current value to the console 
   */   
  float xMod(){
    if(!mousePressed) mouseDownXSeen=false;
    float min=0;
    float max=width;
    if(  (!mousePressed)
       &&(0<=mouseX)
       &&(width>=mouseX)
       &&(0<=mouseY)
       &&(height>=mouseY)
    ){
      lastPriorX=min+(max-min)*mouseX/width;
    }
   if(  verboseMod
       ||(  mousePressed
          &&(mouseButton==39)
          &&(!mouseDownXSeen)
         )
      ){
      println(String.format("x=%5.0f      min=%4.0f max=%4.0f mouseX=%4d width=%d x=%9.3f",lastPriorX,min,max,mouseX,width,lastPriorX));
      mouseDownXSeen=true;
    }
    return(lastPriorX);
  }
  float yMod(){
    if(!mousePressed) mouseDownYSeen=false;
    float min=0;
    float max=height;
    if(  (!mousePressed)
       &&(0<=mouseX)
       &&(width>=mouseX)
       &&(0<=mouseY)
       &&(height>=mouseY)
    ){
      lastPriorY=min+(max-min)*(height-mouseY)/height;
    }
    if(  verboseMod
       ||(  mousePressed
          &&(mouseButton==39)
          &&(!mouseDownYSeen)
         )
      ){
      println(String.format("y=%5.0f      min=%4.0f max=%4.0f mouseX=%4d width=%d y=%9.3f",lastPriorY,min,max,mouseX,width,lastPriorY));
      mouseDownYSeen=true;
    }
    return(lastPriorY);
  }
  float xMod(float min, float max){
    if(!mousePressed) mouseDownXSeen=false;
    if(  (!mousePressed)
       &&(0<=mouseX)
       &&(width>=mouseX)
       &&(0<=mouseY)
       &&(height>=mouseY)
    ){  
      lastPriorX=min+(max-min)*mouseX/width;
    }
    if(  verboseMod
       ||(  mousePressed
          &&(mouseButton==39)
          &&(!mouseDownXSeen)
         )
      ){
      println(String.format("x=%5.0f      min=%4.0f max=%4.0f mouseX=%4d width=%d x=%9.3f",lastPriorX,min,max,mouseX,width,lastPriorX));
      mouseDownXSeen=true;
    }
    return(lastPriorX);
  }
  float yMod(float min,float max){
    if(!mousePressed) mouseDownYSeen=false;
    if(  (!mousePressed)
       &&(0<=mouseX)
       &&(width>=mouseX)
       &&(0<=mouseY)
       &&(height>=mouseY)
    ){
      lastPriorY=min+(max-min)*(height-mouseY)/height;
    }
    if(  verboseMod
       ||(  mousePressed
          &&(mouseButton==39)
          &&(!mouseDownYSeen)
         )
      ){
      println(String.format("y=%5.0f      min=%4.0f max=%4.0f mouseX=%4d width=%d y=%9.3f",lastPriorY,min,max,mouseX,width,lastPriorY));
      mouseDownYSeen=true;
    }
    return(lastPriorY);
  }
  float thetaMod(){
    return(thetaMod(-PI,PI));
  }
  float thetaMod(float min,float max){
    //println(String.format("at top of thetaMod(min,max) lastPriorTheta=%6.3f = %8.3f degrees  mouseY=%3d",lastPriorTheta,degrees(lastPriorTheta),mouseY));
    if(!mousePressed) mouseDownThetaSeen=false;
    if(  (!mousePressed)
       &&(0<=mouseX)
       &&(width>=mouseX)
       &&(0<=mouseY)
       &&(height>=mouseY)
    ){
      lastPriorTheta=min+(max-min)*(height-mouseY)/height;
    }
    //else {
    //  println(String.format("unchanged lastPriorTheta=%6.3f = %8.3f degrees",lastPriorTheta,degrees(lastPriorTheta)));
    //}  
    if(  verboseMod
       ||(  mousePressed
          &&(mouseButton==39)
          &&(!mouseDownThetaSeen)
         )
      ){
      float degrees = degrees(lastPriorTheta);
      println(String.format("theta=%6.3f degrees(theta)=%8.3f min=%4.0f max=%4.0f mouseY=%d height=%d",lastPriorTheta,(degrees+(degrees<0.?360.:0.)),min,max,mouseY,height));
      mouseDownThetaSeen=true;
    }
    //println(String.format("at bot of thetaMod(min,max) lastPriorTheta=%6.3f = %8.3f degrees",lastPriorTheta,degrees(lastPriorTheta)));
    return(lastPriorTheta);
  }
  float phiMod(){
    return(phiMod(-PI,PI));
  }  
  float phiMod(float min,float max){
    if(!mousePressed) mouseDownPhiSeen=false;
    if(  (!mousePressed)
       &&(0<=mouseX)
       &&(width>=mouseX)
       &&(0<mouseY)
       &&(height>=mouseY)
    ){
      lastPriorPhi=min+(max-min)*mouseX/width;
    }  
    if(  verboseMod
       ||(  mousePressed
          &&(mouseButton==39)
          &&(!mouseDownPhiSeen)
         )
      ){
      float degrees = degrees(lastPriorPhi  );  
      println(String.format("phi  =%6.3f degrees(phi  )=%8.3f min=%4.0f max=%4.0f mouseX=%d width =%d",lastPriorPhi  ,(degrees+(degrees<0.?360.:0.)),min,max,mouseX,width));
      mouseDownPhiSeen=true;
    }
    return(lastPriorPhi);
  }
  

  /* used in 2D apps to allow Y ordinate to increase up */
  void yText(String s,float x,float y){
    fill(0);
    noStroke();
    pushMatrix();
      scale(1,-1);
      text(s,x,-y);
    popMatrix();
  }
  /* used in 2D apps to allow Y ordinate to increase up */
  void yTextNoColor(String s,float x,float y){
    pushMatrix();
      scale(1,-1);
      text(s,x,-y);
    popMatrix();
  }  
  /* used in 2D apps to allow Y ordinate to increase up */
  void yText(String s,float x,float y,float x2, float y2){
    pushMatrix();
      scale(1,-1);
      text(s,x,height-y,x2,height-y2);
    popMatrix();
  } 
  /* works in default 2D and Y ordinate increases up apps */
  void fullGrid(){
    strokeWeight(1);
    stroke(.9);
    /* vertical lines on 10 pixel spacing */
    for(int ii=1;ii<width/10+1;ii++){
       if(0!=ii%10)line(ii*10,0,ii*10,height);  
    }
    /* horizontal lines on 100 pixel spacing */
    for(int ii=1;ii<height/10+1;ii++){
       if(0!=ii%10)line(0,ii*10,width,ii*10);
    }
    stroke(.75);
    //dash.pattern(10, 3, 84, 3);
    /* horizontal lines on 100 pixel spacing */
    for(int ii=1;ii<width/100+1;ii++){
     //dash.line(ii*100,-5,ii*100,height+10);
     line(ii*100,-5,ii*100,height+10);
    }
    /* vertical lines on 100 pixel spacing */
    for(int ii=1;ii<height/100+1;ii++){
      //dash.line(-5,ii*100,width+10,ii*100);
      line(-5,ii*100,width+10,ii*100);
    }
  } 
  /* works in default 2D and Y ordinate increases up apps */
  void fullGridBlack(){
    strokeWeight(1);
    float sv=.25;
    //sv=xMod(0,1);
    stroke(sv);
    /* vertical lines on 10 pixel spacing */
    for(int ii=1;ii<width/10+1;ii++){
       if(0!=ii%10)line(ii*10,0,ii*10,height);  
    }
    /* horizontal lines on 100 pixel spacing */
    for(int ii=1;ii<height/10+1;ii++){
       if(0!=ii%10)line(0,ii*10,width,ii*10);
    }
    sv=.34;
    //sv=xMod(0,1);
    stroke(sv);
    //dash.pattern(10, 3, 84, 3);
    /* horizontal lines on 100 pixel spacing */
    for(int ii=1;ii<width/100+1;ii++){
     //dash.line(ii*100,-5,ii*100,height+10);
     line(ii*100,-5,ii*100,height+10);
    }
    /* vertical lines on 100 pixel spacing */
    for(int ii=1;ii<height/100+1;ii++){
      //dash.line(-5,ii*100,width+10,ii*100);
      line(-5,ii*100,width+10,ii*100);
    }
  } 
  

  
  
 
  
  
  void longSentance(){
    //textFont(font0);
    pushMatrix();
      fill(0);
      rotateZ(PI/2);
      rotateX(PI/2); /* rotate arround what is now the Y axis */
      pushMatrix();
        scale(1,-1,1); /* causes Y to be back to the Processing default */
        text("Just the place for a snark the bellman cried as he landed his crew with care, supporting each man on the top of the tide by a finger entwined in his hair.",0.,-60.,0.);
      popMatrix();
    popMatrix();
  }    
  void pointLightAndEmissiveMarker(){
    pointLight(1.,1.,1.,-140+mouseX,-100*((mouseY/(height/2.))-1),40); 
    pushMatrix();
      translate(-140+mouseX,-100*((mouseY/(height/2.))-1),40);
      emissive(.8,.8,0.);
      stroke(0.0,0.0,1.0);
      box(5);
      emissive(0.0);
    popMatrix();  
  }

} /* end of CameraKey class */

void keyPressed() {
  //println("key pressed ="+key+" "+((CODED==key)?"CODED  ":"regular")+" keyCode="+keyCode+" incomming numModPressed="+numModPressed);
  if (16==keyCode) {
    ck.shiftPressed=true;
    ck.postModReleased=false;
    ck.numModPressed+=1;
  } else
  if (17==keyCode) {
    ck.ctrlPressed=true;
    ck.postModReleased=false;
    ck.numModPressed+=1;
  } else
  if (18==keyCode) {
    ck.altPressed=true;
    ck.postModReleased=false;
    ck.numModPressed+=1;
  } 
  if(0<ck.numModPressed){
    if(  (37 == keyCode)
       ||(38 == keyCode)
       ||(39 == keyCode)
       ||(40 == keyCode)
      )ck.postModReleased=false;       
  }
  if(0==ck.numKeysPressed){
    if(97==keyCode){
      ck.deltaXYZ/=2.;
    } else
    if(98==keyCode){
      ck.deltaXYZ*=2.;
    } else
    if(99==keyCode){
      ck.deltaPRY/=2.;
    } else
    if(100==keyCode){
      ck.deltaPRY*=2.;
    }    
  }  
  ck.numKeysPressed+=1;
  //println("keyPressed  outGoing numModPressed="+numModPressed +" postModReleased="+(postModReleased?"true ":"false"));
}
void keyReleased() {
  //println("key released="+key+" "+((CODED==key)?"CODED  ":"regular")+" keyCode="+keyCode+" incomming numModPressed="+numModPressed);
  if (16==keyCode) {
    ck.shiftPressed=false;
    ck.numModPressed-=1;
  } else
  if (17==keyCode) {
    ck.ctrlPressed=false;
    ck.numModPressed-=1;
  } else
  if (18==keyCode) {
    ck.altPressed=false;
    ck.numModPressed-=1;
  }
  if(0<ck.numModPressed){
    if(  (37 == keyCode)
       ||(38 == keyCode)
       ||(39 == keyCode)
       ||(40 == keyCode)
      )ck.postModReleased=true;       
  }
  ck.numKeysPressed-=1;
  //println("keyReleased outGoing numModPressed="+numModPressed +" postModReleased="+(postModReleased?" true ":" false"));    
}  
