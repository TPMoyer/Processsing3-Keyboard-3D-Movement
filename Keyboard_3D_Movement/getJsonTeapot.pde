import java.io.FileReader;
import java.util.ArrayList;

void doTranslatedClosedCrossSections(
  JSONObject stuff,
  ArrayList<PVector> axyzs,
  ArrayList<Integer> aTriangleIndices,
  ArrayList<PVector> aTexCoords,
  String type,
  String textureTactic,
  String name
){
  int baseVertNum=axyzs.size();
  log.debug(name+" is TranslatedClosedInvariantCrossSection incomming axyzs.size="+axyzs.size());
  JSONArray crossSections=stuff.getJSONArray("cross sections");
  //log.debug("crossSections has size "+crossSections.size());
  ArrayList<PVector> partInXZThetas     = new ArrayList<PVector>();
  ArrayList<ArrayList<PVector>> partInSetXYZs     = new ArrayList<ArrayList<PVector>>();
  boolean textureReverse=false;
  try{
   textureReverse=stuff.getBoolean("texture reverse X");
  } catch(NullPointerException e) {
    //log.debug("this part did not say if textureReverse. retaining default false ");
  }
  int numAroundCrossSection=-1;
  for(int mm=0;mm<crossSections.size();mm++){ 
    //log.debug("                                                 crossSections "+mm);
    JSONObject crossSection=(JSONObject)crossSections.get(mm);
    String isCoordinateType=stuff.getString("cross section is co-ordinate type");
    JSONArray coords=crossSection.getJSONArray("cross section is co-ordinates");
    ArrayList<PVector> partPureInXYZs = new ArrayList<PVector>();
    ArrayList<PVector> partInXYZs     = new ArrayList<PVector>();
    if("y,z".equals(isCoordinateType)){
      for(int jj=0;jj<coords.size();jj+=2){
        partPureInXYZs.add(new PVector(0.0f,((Double)coords.get(jj)).floatValue(),((Double)coords.get(jj+1)).floatValue()));
        //log.debug(String.format("pure    (%8.3f,%8.3f,%8.3f)",
        //  partPureInXYZs.get(partPureInXYZs.size()-1).x,
        //  partPureInXYZs.get(partPureInXYZs.size()-1).y,
        //  partPureInXYZs.get(partPureInXYZs.size()-1).z
        //)); 
      }
    } else {
      String msg="unprogrammed is specifier 0:"+isCoordinateType+" this is fatal";
      println(msg);
      log.fatal(msg);
      System.exit(3);
    }
    String symmetryOps = stuff.getString("symmetry operations on cross section co-ordinates");
    //log.debug("partInXYZs.size()="+coords.size()/2);
    if("mirrored on y=0 and z=0 planes".equals(symmetryOps)){
      /* This section commits the sin of assuming the co-ordinates are ordered from X=0 to always greater X values.
       * I'm not trying to actually write a fully correct general processor for HighOrderEnumerables, but only to get
       * the concept embodied in the clasic teapot 
       */
      for(int jj=0;jj<partPureInXYZs.size();jj++){
        partInXYZs.add(partPureInXYZs.get(jj));
        //log.debug(String.format("initial (%8.3f,%8.3f,%8.3f)",
        //  partInXYZs.get(partInXYZs.size()-1).x,
        //  partInXYZs.get(partInXYZs.size()-1).y,
        //  partInXYZs.get(partInXYZs.size()-1).z
        //)); 
      }
      /* miror on Y axis*/
      for(int jj=partPureInXYZs.size()-1;jj>-1;jj--){
        if(0.0!=partPureInXYZs.get(jj).z){
          partInXYZs.add(new PVector(partPureInXYZs.get(jj).x,partPureInXYZs.get(jj).y,-partPureInXYZs.get(jj).z));
          //log.debug(String.format("mirrorY (%8.3f,%8.3f,%8.3f)",
          //  partInXYZs.get(partInXYZs.size()-1).x,
          //  partInXYZs.get(partInXYZs.size()-1).y,
          //  partInXYZs.get(partInXYZs.size()-1).z
          //)); 
        }  
      }
      /* miror on Z axis*/
      for(int jj=partInXYZs.size()-1;jj>-1;jj--){
        if(0.0!=partInXYZs.get(jj).y){
          partInXYZs.add(new PVector(partInXYZs.get(jj).x,-partInXYZs.get(jj).y,partInXYZs.get(jj).z));
          //log.debug(String.format("mirrorZ (%8.3f,%8.3f,%8.3f)",
          //  partInXYZs.get(partInXYZs.size()-1).x,
          //  partInXYZs.get(partInXYZs.size()-1).y,
          //  partInXYZs.get(partInXYZs.size()-1).z
          //)); 
        }
      }      
    } else {
      String msg="unprogrammed symmetryOps encountered: "+symmetryOps+" this is fatal";
      println(msg);
      log.fatal(msg);
      System.exit(4);
    }
    numAroundCrossSection=partInXYZs.size();  /* they must all be the same in order for this triangle setting to work, so just grab this metric from the last one */
    //log.debug("");
    String atCoordinateType=stuff.getString("cross section at co-ordinate type");
    JSONArray atCoords=crossSection.getJSONArray("cross section(s) at co-ordinates");
    if("x,z,radians_within_xz_plane".equals(atCoordinateType)){
      for(int jj=0;jj<atCoords.size();jj+=3){
        partInXZThetas.add(new PVector(((Double)atCoords.get(jj)).floatValue(),((Double)atCoords.get(jj+1)).floatValue(),((Double)atCoords.get(jj+2)).floatValue()));
        partInSetXYZs.add(partInXYZs);
        //log.debug(String.format("XZTheta (%8.3f,%8.3f,%8.3f)",
        //  partInXZThetas.get(partInXZThetas.size()-1).x,
        //  partInXZThetas.get(partInXZThetas.size()-1).y,
        //  partInXZThetas.get(partInXZThetas.size()-1).z
        //)); 
      }
    } else {
      String msg="unprogrammed at specifier: "+atCoordinateType+" this is fatal";
      println(msg);
      log.fatal(msg);
      System.exit(4);
    }
    //log.debug("");
  }
  /******************************************************************
   * have ingested all the data from the JSON file for this part.
   * next step is to set the XYZ textureUV perVertex sets.
   * Then will assign the triangleIndices 
   *****************************************************************
   */
  /* Need to double up on the xyz's the textures, so that one can have texture co-ordinate of top, and one of bottom.
   * The bottom of the bottom ring and the top of the top ring do not need this doubling.
   */
  int numRings=partInXZThetas.size();
  int num=0;
  for(int jj=0;jj<numRings;jj++){
    num=partInSetXYZs.get(jj).size();
    for(int kk=0;kk<num+1;kk++){
      PVector xyz=new PVector(
        partInXZThetas.get(jj).x+partInSetXYZs.get(jj).get(kk%num).z*cos(partInXZThetas.get(jj).z),
        partInSetXYZs.get(jj).get(kk%num).y,
        partInXZThetas.get(jj).y+partInSetXYZs.get(jj).get(kk%num).z*sin(partInXZThetas.get(jj).z)
      );
      axyzs.add(xyz);
      if(textureTactic.equals("1X around each cylinder section")){
        /* the kk==num   bit is to enable the texture to complete at 1.0 for the final wrap around */
        //aTexCoords.add(new PVector( (.5+( kk==num?1.0:((kk/(float)num)%1)))%1 ,(0==jj?1.:0.)));
        //aTexCoords.add(new PVector( kk==num?1.0:(kk/(float)num) ,(0==jj?1.:0.)));
        float u=kk==num?1.0:(kk/(float)num);
        aTexCoords.add(new PVector(textureReverse?(1.-u):u,(0==jj?1.:0.)));
      } else {
        String msg="unprogrammed textureTactic: "+textureTactic+" this is fatal";
        println(msg);
        log.fatal(msg);
        System.exit(6);
      }
      //log.debug(String.format("A %2d %2d textureTactic=%30s (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
      //  jj,
      //  kk,
      //  textureTactic,
      //  xyz.x,
      //  xyz.y,
      //  xyz.z,
      //  aTexCoords.get(aTexCoords.size()-1).x,
      //  aTexCoords.get(aTexCoords.size()-1).y
      //));  
    }
    if(0==jj)log.debug("");
    if(  (0!=jj)
       &&((numRings-1)!=jj)
      ){
      //log.debug("");  
      for(int kk=0;kk<num+1;kk++){
        PVector xyz=new PVector(
          partInXZThetas.get(jj).x+partInSetXYZs.get(jj).get(kk%num).z*cos(partInXZThetas.get(jj).z),
          partInSetXYZs.get(jj).get(kk%num).y,
          partInXZThetas.get(jj).y+partInSetXYZs.get(jj).get(kk%num).z*sin(partInXZThetas.get(jj).z)
        );
        axyzs.add(xyz);  
        if(textureTactic.equals("1X around each cylinder section")){
          /* the kk==num   bit is to enable the texture to complete at 1.0 for the final wrap around */
          //aTexCoords.add(new PVector( (.5+(kk==num?1.0:((2.0*kk)/num)%1)%1) , 1.));
          float u=kk==num?1.0:(kk/(float)num);
          aTexCoords.add(new PVector(textureReverse?(1.-u):u, 1.));       
        } else {
          String msg="unprogrammed textureTactic: "+textureTactic+" this is fatal";
          println(msg);
          log.fatal(msg);
          System.exit(6);
        }
        //log.debug(String.format("B %2d %2d textureTactic=%30s (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
        //  jj,
        //  kk,
        //  textureTactic,
        //  xyz.x,
        //  xyz.y,
        //  xyz.z,
        //  aTexCoords.get(aTexCoords.size()-1).x,
        //  aTexCoords.get(aTexCoords.size()-1).y
        //));  
      }
      //log.debug("");
    }  
  }
  /* now assign the triangles */
  int counter=0;
  for(int jj=0;jj<numRings-1;jj++){
    for(int kk=0;kk<numAroundCrossSection;kk++){
      //log.debug(String.format("OffAxis %3d %3d baseVertNum=%4d counter=%4d %4d",ii,jj,baseVertNum,counter,axyzs.size()));
      aTriangleIndices.add(baseVertNum+counter+kk);
      aTriangleIndices.add(baseVertNum+counter+num+1+kk);
      aTriangleIndices.add(baseVertNum+counter+kk+1);
      aTriangleIndices.add(baseVertNum+counter+num+kk+1);
      aTriangleIndices.add(baseVertNum+counter+num+kk+2);
      aTriangleIndices.add(baseVertNum+counter+kk+1);
      //log.debug(String.format("C %3d %3d %3d   %4d %4d %4d   %4d %4d %4d   (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)  (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
      //  ii,
      //  jj,
      //  kk,
      //  aTriangleIndices.get(aTriangleIndices.size()-6),
      //  aTriangleIndices.get(aTriangleIndices.size()-5),
      //  aTriangleIndices.get(aTriangleIndices.size()-4),
      //  aTriangleIndices.get(aTriangleIndices.size()-3),
      //  aTriangleIndices.get(aTriangleIndices.size()-2),
      //  aTriangleIndices.get(aTriangleIndices.size()-1),
      //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-6)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-6)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-6)).z,
      //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-5)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-5)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-5)).z,
      //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-4)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-4)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-4)).z,
      //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-6)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-6)).y,
      //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-5)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-5)).y,
      //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-4)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-4)).y ,
      //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).z,
      //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).z,
      //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).z,
      //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,
      //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,
      //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y 
      //)); 
    }
    counter+=2*(numAroundCrossSection+1);
    //log.debug("off jj="+jj+" aTriangleIndices.size()="+aTriangleIndices.size()+" numTriangles="+(aTriangleIndices.size()/3));
  }
}
void doSurfaceOfRotationAboutZaxis(
  JSONObject stuff,
  ArrayList<PVector> axyzs,
  ArrayList<Integer> aTriangleIndices,
  ArrayList<PVector> aTexCoords,
  String type,
  String textureTactic,
  String name
){
  log.debug(name+" is SurfaceOfRotationAboutZaxis");
  ArrayList<PVector> partInXYZs          = new ArrayList<PVector>();
  int num = stuff.getInt("number of points per revolution");         
  boolean nearEndClosedByTriangleFan=false;
  try{
   nearEndClosedByTriangleFan=stuff.getBoolean("near end closed by triangle fan");
  } catch(NullPointerException e) {
    //log.debug("this part did not say if nearEndClosedByTriangleFan. retaining default false ");
  }
  boolean farEndClosedByTriangleFan=false;
  try{
   farEndClosedByTriangleFan=stuff.getBoolean("far end closed by triangle fan");
  } catch(NullPointerException e) {
    //log.debug("this part did not say if farEndClosedByTriangleFan. retaining default false ");
  }  
  //log.debug("nearEndClosedByTriangleFan="+(nearEndClosedByTriangleFan?"true ":"false"));
  //log.debug(" farEndClosedByTriangleFan="+( farEndClosedByTriangleFan?"true ":"false"));
  String coordinateType=stuff.getString("cross section co-ordinate type");
  JSONArray coords=stuff.getJSONArray("co-ordinates");
  float minZ=Float.MAX_VALUE;
  float maxZ=-Float.MAX_VALUE;      
  if("x,z".equals(coordinateType)){
    for(int jj=0;jj<coords.size();jj+=2){
      partInXYZs.add(new PVector(((Double)coords.get(jj)).floatValue(),0.0f,((Double)coords.get(jj+1)).floatValue()));
      if(minZ > ((Double)coords.get(jj+1)).floatValue())minZ=((Double)coords.get(jj+1)).floatValue();
      if(maxZ < ((Double)coords.get(jj+1)).floatValue())maxZ=((Double)coords.get(jj+1)).floatValue();
    }
  } else {
    String msg="unprogrammed co-ordinate specifier: "+coordinateType+" this is fatal";
    println(msg);
    log.fatal(msg);
    System.exit(5);
  } 
  log.debug("minZ="+minZ+" maxZ="+maxZ+" from partInXYZs="+coords.size()/2);
  int jjLimit=partInXYZs.size();
  int jj=0;
  if(0.0==partInXYZs.get(jj).x){
      String msg="\n\n\ndid not program all enumeratable cases, only those needed for the teapot.\nOmited are:\n1) onAxis first point, \n2) multiple onaxis points, \n3) off-axis point following on-axis point\nHaving encountered such a case is fatal";
      println(msg);
      log.fatal(msg);
      System.exit(1);
  } else { 
    /* need to do this num+1 because of the textures.
     * If it were pure materials, would wrap around with a modulo math.
     * Textures need to have the same XYZ at the end, but with 1.00 as the texture co-ordinate 
     */
    for(int kk=0;kk<num+1;kk++){
      PVector xyz=new PVector(partInXYZs.get(jj).x*cos(kk*2*PI/num),partInXYZs.get(jj).x*sin(kk*2*PI/num),partInXYZs.get(jj).z);
      axyzs.add(xyz);
      if(textureTactic.equals("polar projection over half height")){
        aTexCoords.add(new PVector(kk/(float)num,(2.*(1.0-(partInXYZs.get(jj).z-minZ)/(maxZ-minZ)))%1));
      } else             
      if(textureTactic.equals("1X around rotation")){
        /* the kk==num   bit is to enable the texture to complete at 1.0 for the final wrap around */
        aTexCoords.add(new PVector(kk==num?1.0:(kk/(float)num), 1.0- (partInXYZs.get(jj).z-minZ)/(maxZ-minZ)));
      }
      //log.debug(String.format("A %2d %2d Off Axis textureTactic=%30s (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
      //  jj,
      //  kk,
      //  textureTactic,
      //  xyz.x,
      //  xyz.y,
      //  xyz.z,
      //  aTexCoords.get(aTexCoords.size()-1).x,
      //  aTexCoords.get(aTexCoords.size()-1).y
      //));  
    } 
    if(nearEndClosedByTriangleFan){
      //log.debug("endClosedByTriangleFan");
      int baseVertNum=axyzs.size()-num;
      for(int kk=2;kk<num;kk++){
        aTriangleIndices.add(baseVertNum);
        aTriangleIndices.add(baseVertNum+kk-1);
        aTriangleIndices.add(baseVertNum+kk);             
        //log.debug(String.format("A %3d %3d   %4d %4d %4d  (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f)  (%5.3f,%5.3f) (%5.3f,%5.3f) (%5.3f,%5.3f)",
        //  jj,
        //  kk,
        //  aTriangleIndices.get(aTriangleIndices.size()-3),
        //  aTriangleIndices.get(aTriangleIndices.size()-2),
        //  aTriangleIndices.get(aTriangleIndices.size()-1),
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).z,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).z,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).z,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y            
        //)); 
      }
      //log.debug("fan jj="+jj+" aTriangleIndices.size()="+aTriangleIndices.size()+" numTriangles="+(aTriangleIndices.size()/3));
      //log.debug("end of fan");
    }
  }  
  for(jj=1;jj<jjLimit;jj++){        
    if(  (jj!=0)
       &&(0.0==partInXYZs.get(jj  ).x)
       &&(0.0!=partInXYZs.get(jj-1).x)
      ){
      //log.debug("onAxis");
      int onAxisNum=axyzs.size();
      axyzs.add(partInXYZs.get(jj));
      aTexCoords.add(new PVector(.5,1.0-  (partInXYZs.get(jj).z-minZ)/(maxZ-minZ)));
      //log.debug(String.format("B %2d %2d Off Axis textureTactic=%30s (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
      //  jj,
      //  0,
      //  textureTactic,
      //  partInXYZs.get(jj).x,
      //  partInXYZs.get(jj).y,
      //  partInXYZs.get(jj).z,
      //  aTexCoords.get(aTexCoords.size()-1).x,
      //  aTexCoords.get(aTexCoords.size()-1).y
      //));  
      int baseVertNum=axyzs.size()-num-1;          
      //log.debug(String.format("onAxis  %3d baseVertNum=%4d %4d",jj,baseVertNum,axyzs.size()));
      for(int kk=0;kk<num;kk++){
         aTriangleIndices.add(baseVertNum+kk);
         aTriangleIndices.add(onAxisNum);
         aTriangleIndices.add(baseVertNum+(kk+1)%num);
         //log.debug(String.format("B %3d %3d   %4d %4d %4d  (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f)",
         //  jj,
         //  kk,
         //  aTriangleIndices.get(aTriangleIndices.size()-3),
         //  aTriangleIndices.get(aTriangleIndices.size()-2),
         //  aTriangleIndices.get(aTriangleIndices.size()-1),
         //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).z,
         //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).z,
         //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).z,
         //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,
         //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,
         //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y 
         //)); 
      }
      //log.debug("on  jj="+jj+" aTriangleIndices.size()="+aTriangleIndices.size()+" numTriangles="+(aTriangleIndices.size()/3));
    } else
    if(  (  (0==jj)
          &&(0.0==partInXYZs.get(jj  ).x)
         ) 
       ||(  (0!=jj)
          &&(0.0==partInXYZs.get(jj-1).x)
         ) 
      ){
      String msg="\n\n\ndid not program all enumeratable cases, only those needed for the teapot.\nOmited are:\n1) onAxis first point, \n2) multiple onaxis points, \n3) off-axis point following on-axis point\nHaving encountered such a case is fatal";
      println(msg);
      log.fatal(msg);
      System.exit(2);
    } else {          
      //log.debug("OffAxis, not following an onAxis");
      /* need to do this num+1 because of the textures.
       * If it were pure materials, would wrap around with a modulo math.
       * Textures need to have the same XYZ at the end, but with 1.00 as the texture co-ordinate 
       */
      for(int kk=0;kk<num+1;kk++){
         PVector xyz=new PVector(partInXYZs.get(jj).x*cos(kk*2*PI/num),partInXYZs.get(jj).x*sin(kk*2*PI/num),partInXYZs.get(jj).z);
         axyzs.add(xyz);
         if(textureTactic.equals("polar projection over half height")){
           aTexCoords.add(new PVector(kk/(float)num,(2.*(1.0-(partInXYZs.get(jj).z-minZ)/(maxZ-minZ)))%1));
         } else             
         if(textureTactic.equals("1X around rotation")){
           /* the kk==num   bit is to enable the texture to complete at 1.0 for the final wrap around */
           aTexCoords.add(new PVector(kk==num?1.0:(kk/(float)num), 1.0- (partInXYZs.get(jj).z-minZ)/(maxZ-minZ)));
         }
         //log.debug(String.format("C %2d %2d Off Axis textureTactic=%30s (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
         //  jj,
         //  kk,
         //  textureTactic,
         //  xyz.x,
         //  xyz.y,
         //  xyz.z,
         //  aTexCoords.get(aTexCoords.size()-1).x,
         //  aTexCoords.get(aTexCoords.size()-1).y
         //));  
      }
      int baseVertNum=axyzs.size()-2*(num+1);
      //log.debug(String.format("OffAxis %3d baseVertNum=%4d %4d",jj,baseVertNum,axyzs.size()));
      for(int kk=0;kk<num;kk++){
        aTriangleIndices.add(baseVertNum+kk);
        aTriangleIndices.add(baseVertNum+num+1+kk);
        aTriangleIndices.add(baseVertNum+kk+1);             
        aTriangleIndices.add(baseVertNum+num+kk+1);
        aTriangleIndices.add(baseVertNum+num+kk+2);
        aTriangleIndices.add(baseVertNum+kk+1);
        //log.debug(String.format("C %3d %3d   %4d %4d %4d   %4d %4d %4d   (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)  (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%5.3f,%5.3f)",
        //  jj,
        //  kk,
        //  aTriangleIndices.get(aTriangleIndices.size()-6),
        //  aTriangleIndices.get(aTriangleIndices.size()-5),
        //  aTriangleIndices.get(aTriangleIndices.size()-4),
        //  aTriangleIndices.get(aTriangleIndices.size()-3),
        //  aTriangleIndices.get(aTriangleIndices.size()-2),
        //  aTriangleIndices.get(aTriangleIndices.size()-1),
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-6)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-6)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-6)).z,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-5)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-5)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-5)).z,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-4)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-4)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-4)).z,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-6)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-6)).y,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-5)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-5)).y,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-4)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-4)).y ,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-3)).z,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-2)).z,
        //  axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y,axyzs.get(aTriangleIndices.get(aTriangleIndices.size()-1)).z,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-3)).y,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-2)).y,
        //  aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).x,aTexCoords.get(aTriangleIndices.get(aTriangleIndices.size()-1)).y 
        //)); 
      }
      //log.debug("off jj="+jj+" aTriangleIndices.size()="+aTriangleIndices.size()+" numTriangles="+(aTriangleIndices.size()/3));          
    }
  }
}
void getReducedDataCountJsonTeapot(){
  log.debug("in getMinimalistJsonTeapot");
  String fid=".\\data\\Teapot_Blasphemer_Variant.json";
  log.debug("about to attempt loadJSONObject on "+fid);
  JSONObject json = loadJSONObject(fid);
  log.debug("load did not die");
  JSONArray parts=json.getJSONArray("shape parts");
  log.debug("parts has "+parts.size()+" members");
  ArrayList<PVector> axyzs            = new ArrayList<PVector>();
  ArrayList<Integer> aTriangleIndices = new ArrayList<Integer>();
  ArrayList<PVector> aTexCoords       = new ArrayList<PVector>();
  for(int ii=0;ii<parts.size();ii++){
    //log.debug("in ii="+ii);
    JSONObject stuff=(JSONObject)parts.get(ii);    
    String name=stuff.getString("shape name");
    log.debug(String.format("%2d %-30s %2d",ii,name,stuff.size()));
    String type = stuff.getString("shape type");
    String textureTactic=stuff.getString("texture tactic");
    if(type.equals("surface of rotation about Z axis")){
      doSurfaceOfRotationAboutZaxis(stuff,axyzs,aTriangleIndices,aTexCoords,type,textureTactic,name);
    } else
    if(  type.equals("translated closed invariant cross section")
       ||type.equals("translated closed varying cross sections")
      ){
      doTranslatedClosedCrossSections(stuff,axyzs,aTriangleIndices,aTexCoords,type,textureTactic,name);
    }  
  }
  log.debug("end of parts aTriangleIndices.size()="+aTriangleIndices.size()+" numTriangles="+(aTriangleIndices.size()/3)+" axyzs.size()="+axyzs.size()+" aTexCoords.size()="+aTexCoords.size());
  PVector[] aNormals = getNormals(axyzs,aTriangleIndices);
  
  xyzs      = new float[3*axyzs.size()];
  normals   = new float[3*axyzs.size()];
  texCoords = new float[2*axyzs.size()];
  int counter=0;
  int counter2=0;
  for(int ii=0;ii<axyzs.size();ii++){
    xyzs[counter  ]=axyzs.get(ii).x;
    xyzs[counter+1]=axyzs.get(ii).y;
    xyzs[counter+2]=axyzs.get(ii).z;
    normals[counter  ]=aNormals[ii].x;
    normals[counter+1]=aNormals[ii].y;
    normals[counter+2]=aNormals[ii].z;
    texCoords[counter2  ]=aTexCoords.get(ii).x;
    texCoords[counter2+1]=aTexCoords.get(ii).y;
    counter+=3;
    counter2+=2;
  }  
  trianglesIndexs=new int[aTriangleIndices.size()];
  for(int ii=0;ii<aTriangleIndices.size();ii++){
    trianglesIndexs[ii]=aTriangleIndices.get(ii);
  } 
  //for(int ii=0;ii<xyzs.length;ii+=3){
  //  for(int jj=0;jj<3;jj++){
  //    if(  (-4.6 < xyzs[3*trianglesIndexs[ii+jj]  ])
  //       &&( 4.6 > xyzs[3*trianglesIndexs[ii+jj]  ])
  //      ){ 
  //      log.debug(String.format("min %4d %d (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) (%5.3f,%5.3f)",
  //        ii,
  //        jj,
  //        xyzs[3*trianglesIndexs[ii+jj]  ],
  //        xyzs[3*trianglesIndexs[ii+jj]+1],
  //        xyzs[3*trianglesIndexs[ii+jj]+2],
  //        normals[3*trianglesIndexs[ii+jj]  ],
  //        normals[3*trianglesIndexs[ii+jj]+1],
  //        normals[3*trianglesIndexs[ii+jj]+2],
  //        texCoords[2*trianglesIndexs[ii+jj]  ],
  //        texCoords[2*trianglesIndexs[ii+jj]+1]
  //      ));
  //    }
  //  }
  //}    
}
PVector[] getNormals(
  ArrayList<PVector> axyzs, 
  ArrayList<Integer> aTriangleIndices
 ){
  int num=axyzs.size();
  int numTris=aTriangleIndices.size();
  log.debug("see "+num+" vertices incomming to getNormals.");
  log.debug("numTris="+numTris);
  PVector[] aNormals   = new PVector[num];  
  PVector[] normalSums = new PVector[num];
  int []    normalCounts = new int[num];
  for(int ii=0;ii<num;ii++){
    normalSums[ii]=new PVector(0.,0.,0.);
  }  
  int counter=0;
  for(int ii=0;ii<numTris;ii+=3){
    PVector ab=PVector.sub(axyzs.get(aTriangleIndices.get(ii)),axyzs.get(aTriangleIndices.get(ii+1)));
    PVector ac=PVector.sub(axyzs.get(aTriangleIndices.get(ii)),axyzs.get(aTriangleIndices.get(ii+2)));
    PVector normal=ac.cross(ab);
    float mag=normal.mag();
    normal.mult(1/mag);
    //log.debug(String.format("%4d %4d %4d %4d (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f)  (%6.3f,%6.3f,%6.3f)",
    //  counter,
    //  aTriangleIndices.get(ii  ),
    //  aTriangleIndices.get(ii+1),
    //  aTriangleIndices.get(ii+2),
    //  axyzs.get(aTriangleIndices.get(ii  )).x,
    //  axyzs.get(aTriangleIndices.get(ii  )).y,
    //  axyzs.get(aTriangleIndices.get(ii  )).z,
    //  axyzs.get(aTriangleIndices.get(ii+1)).x,
    //  axyzs.get(aTriangleIndices.get(ii+1)).y,
    //  axyzs.get(aTriangleIndices.get(ii+1)).z,
    //  axyzs.get(aTriangleIndices.get(ii+2)).x,
    //  axyzs.get(aTriangleIndices.get(ii+2)).y,
    //  axyzs.get(aTriangleIndices.get(ii+2)).z,
    //  normal.x,
    //  normal.y,
    //  normal.z
    //));  
    normalSums[aTriangleIndices.get(ii  )].add(normal);
    normalSums[aTriangleIndices.get(ii+1)].add(normal);
    normalSums[aTriangleIndices.get(ii+2)].add(normal);
    normalCounts[aTriangleIndices.get(ii  )]++;
    normalCounts[aTriangleIndices.get(ii+1)]++;
    normalCounts[aTriangleIndices.get(ii+2)]++;
    counter+=1;
  }   
  for(int ii=0;ii<num;ii++){
    aNormals[ii]=normalSums[ii].div(normalCounts[ii]);
    aNormals[ii].div(aNormals[ii].mag());  /* without this many of the normals would be in the range of    1 > normal > 0.7  */
    //log.debug(String.format("%4d (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) %6.3f %2d",
    //  ii,
    //  axyzs.get(ii).x,
    //  axyzs.get(ii).y,
    //  axyzs.get(ii).z,
    //  aNormals[ii].x,
    //  aNormals[ii].y,
    //  aNormals[ii].z,
    //  aNormals[ii].mag(),
    //  normalCounts[ii]
    //));
  }  
  return(aNormals);
}
void getJsonTeapot0(){
  /* With vertex and normal co-ordinates, scenes can be rendered using lighting effects.
   * The glMaterials class has a selection of pre-packaged sets of ambient, diffuse, specular, and shinyness 
   * properties attempting to mimic real world materials ala the OpenGL Red_Book.
   * Textures allow image(s) to overlayed onto materials, and can be rendered with or without lighting effects.
   */
  log.debug("in getJsonTeapot");
  String fid=".\\data\\TeapotZ1.json";
  log.debug("about to attempt loadJSONObject on "+fid);
  JSONObject json = loadJSONObject(fid);
  JSONArray varying=json.getJSONArray("trianglesIndices");
   
  trianglesIndexsAR=varying.getIntArray();
  //log.debug("trianglesIndexsAR.length="+trianglesIndexsAR.length);
  //for(int ii=0;ii<32;ii++){
  ////for(int ii=0;ii<trianglesIndexsAR.length;ii++){  
  //  log.debug(String.format("%4d %4d",ii,trianglesIndexsAR[ii]));
  //}
  //log.debug
  
  varying=json.getJSONArray("vertexXYZs");
  xyzsAR = varying.getFloatArray();
  //log.debug("xyzsAR.length="+xyzsAR.length);
  for(int ii=0;ii<xyzsAR.length;ii+=3){
    xyzsAR[ii+2]+=7.875;
 
    //xyzsAR[ii  ]*= 10.;
    //xyzsAR[ii+1]*=-10.;
    //xyzsAR[ii+2]*= 10.;
    //xyzsAR[ii+2]+=78.75;
    
    //xyzsAR[ii  ]*= 10.;
    //xyzsAR[ii+1]*= 10.;
    //xyzsAR[ii+2]*= 10.;
    //log.debug(String.format("%4d %7.3f %7.3f %7.3f",ii/3,xyzsAR[ii],xyzsAR[ii+1],xyzsAR[ii+2]));  
  } 
  
  varying=json.getJSONArray("vertexNormals");
  normalsAR = varying.getFloatArray();
  //log.debug("normalsAR.length="+normalsAR.length);
  //for(int ii=0;ii<normalsAR.length;ii++){
  //  log.debug(String.format("%4d %8.3f",ii,normalsAR[ii]));
  //} 

  /* Dump the pairs of data for the first 30 verticies to the logger */
  //int limit=30; 
  //log.debug("first "+limit/3+" triangles verticies and normalsAR");
  //for(int ii=0;ii<limit;ii+=3){
  //  log.debug(String.format("%4d (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f)   (%6.3f,%6.3f,%6.3f) (%6.3f,%6.3f,%6.3f) (%6.3f,%6.3f,%6.3f)",
  //    ii/3,
  //    xyzsAR[3*trianglesIndexsAR[ii+0]+0],
  //    xyzsAR[3*trianglesIndexsAR[ii+0]+1],
  //    xyzsAR[3*trianglesIndexsAR[ii+0]+2],
  //    xyzsAR[3*trianglesIndexsAR[ii+1]+0],
  //    xyzsAR[3*trianglesIndexsAR[ii+1]+1],
  //    xyzsAR[3*trianglesIndexsAR[ii+1]+2],
  //    xyzsAR[3*trianglesIndexsAR[ii+2]+0],
  //    xyzsAR[3*trianglesIndexsAR[ii+2]+1],
  //    xyzsAR[3*trianglesIndexsAR[ii+2]+2],
  //    normalsAR[3*trianglesIndexsAR[ii+0]+0],
  //    normalsAR[3*trianglesIndexsAR[ii+0]+1],
  //    normalsAR[3*trianglesIndexsAR[ii+0]+2],
  //    normalsAR[3*trianglesIndexsAR[ii+1]+0],
  //    normalsAR[3*trianglesIndexsAR[ii+1]+1],
  //    normalsAR[3*trianglesIndexsAR[ii+1]+2],
  //    normalsAR[3*trianglesIndexsAR[ii+2]+0],
  //    normalsAR[3*trianglesIndexsAR[ii+2]+1],
  //    normalsAR[3*trianglesIndexsAR[ii+2]+2]
  //  ));
  //}   
        
  varying=json.getJSONArray("vertexTextureCoords");
  texCoordsAR=varying.getFloatArray();
  
    
  float minX= 1000000.;
  float maxX=-1000000.;
  float minY= 1000000.;
  float maxY=-1000000.;
  int numTex=texCoordsAR.length/2;
  for(int ii=0;ii<numTex;ii++){
    if(minX>texCoordsAR[ii*2  ]){
       minX=texCoordsAR[ii*2  ];
    }   
    if(minY>texCoordsAR[ii*2+1]){
       minY=texCoordsAR[ii*2+1];
    }
    if(maxX<texCoordsAR[ii*2  ]){
       maxX=texCoordsAR[ii*2  ];
    }   
    if(maxY<texCoordsAR[ii*2+1]){
       maxY=texCoordsAR[ii*2+1];
    }   
  } 
  log.debug(String.format("texture coordinates  mins=(%8.3f,%8.3f) maxs=(%8.3f,%8.3f)",minX,minY,maxX,maxY));
  for(int ii=0;ii<texCoordsAR.length;ii+=2){
    if(1.<texCoordsAR[ii  ])texCoordsAR[ii  ]-=1.0;
    if(1.<texCoordsAR[ii+1])texCoordsAR[ii+1]-=1.0;
    texCoordsAR[ii+1]=1.-texCoordsAR[ii+1];
  }  
  //int limit=30;  
  //log.debug("first "+limit/3+" triangles verticies and normalsAR texCoordsAR");
  //for(int ii=0;ii<limit;ii+=3){
  //  log.debug(String.format("%4d (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f) (%8.3f,%8.3f,%8.3f)   (%6.3f,%6.3f,%6.3f) (%6.3f,%6.3f,%6.3f) (%6.3f,%6.3f,%6.3f)   (%5.3f,%5.3f) (%5.3f,%5.3f) (%5.3f,%5.3f)",
  //    ii/3,
  //    xyzsAR[3*trianglesIndexsAR[ii+0]+0],
  //    xyzsAR[3*trianglesIndexsAR[ii+0]+1],
  //    xyzsAR[3*trianglesIndexsAR[ii+0]+2],
  //    xyzsAR[3*trianglesIndexsAR[ii+1]+0],
  //    xyzsAR[3*trianglesIndexsAR[ii+1]+1],
  //    xyzsAR[3*trianglesIndexsAR[ii+1]+2],
  //    xyzsAR[3*trianglesIndexsAR[ii+2]+0],
  //    xyzsAR[3*trianglesIndexsAR[ii+2]+1],
  //    xyzsAR[3*trianglesIndexsAR[ii+2]+2],
  //    normalsAR[3*trianglesIndexsAR[ii+0]+0],
  //    normalsAR[3*trianglesIndexsAR[ii+0]+1],
  //    normalsAR[3*trianglesIndexsAR[ii+0]+2],
  //    normalsAR[3*trianglesIndexsAR[ii+1]+0],
  //    normalsAR[3*trianglesIndexsAR[ii+1]+1],
  //    normalsAR[3*trianglesIndexsAR[ii+1]+2],
  //    normalsAR[3*trianglesIndexsAR[ii+2]+0],
  //    normalsAR[3*trianglesIndexsAR[ii+2]+1],
  //    normalsAR[3*trianglesIndexsAR[ii+2]+2],
  //    texCoordsAR[2*trianglesIndexsAR[ii+0]+0],
  //    texCoordsAR[2*trianglesIndexsAR[ii+0]+1],
  //    texCoordsAR[2*trianglesIndexsAR[ii+1]+0],
  //    texCoordsAR[2*trianglesIndexsAR[ii+1]+1],
  //    texCoordsAR[2*trianglesIndexsAR[ii+2]+0],
  //    texCoordsAR[2*trianglesIndexsAR[ii+2]+1]
  //  ));
  //}   

 //for(int ii=0;ii<xyzsAR.length;ii+=3){
 //   for(int jj=0;jj<3;jj++){
 //     if(  (-4.6 < xyzsAR[3*trianglesIndexsAR[ii+jj]  ])
 //        &&( 4.6 > xyzsAR[3*trianglesIndexsAR[ii+jj]  ])
 //       ){ 
 //       log.debug(String.format("old %4d %d (%8.3f,%8.3f,%8.3f) (%6.3f,%6.3f,%6.3f) (%5.3f,%5.3f)",
 //         ii,
 //         jj,
 //         xyzsAR[3*trianglesIndexsAR[ii+jj]  ],
 //         xyzsAR[3*trianglesIndexsAR[ii+jj]+1],
 //         xyzsAR[3*trianglesIndexsAR[ii+jj]+2],
 //         normalsAR[3*trianglesIndexsAR[ii+jj]  ],
 //         normalsAR[3*trianglesIndexsAR[ii+jj]+1],
 //         normalsAR[3*trianglesIndexsAR[ii+jj]+2],
 //         texCoordsAR[2*trianglesIndexsAR[ii+jj]  ],
 //         texCoordsAR[2*trianglesIndexsAR[ii+jj]+1]
 //       ));
 //     }  
 //   }
 // }    
  
  log.debug("lengths trianglesIndexsAR.length="+trianglesIndexsAR.length+" xyzsAR.length="+xyzsAR.length+" normalsAR.length="+normalsAR.length+" texCoordsAR.length="+texCoordsAR.length);
  log.debug("number of triangles="+(trianglesIndexsAR.length/3)+" numVertexs="+(xyzsAR.length/3)+" numnormalsAR="+(normalsAR.length/3)+" numtexCoordsAR="+(texCoordsAR.length/2));
}
