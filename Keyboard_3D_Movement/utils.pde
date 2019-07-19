void initLog4j(){
  /* patterned after the input from Jake Seigel:   https://jestermax.wordpress.com/2014/06/09/log4j-4-you/   */
  //String masterPattern = "[%c{1}], %d{HH:mm:ss}, %-5p, {%C}, %m%n";
  //String masterPattern = "%-5p %8r %3L %c{1} - %m%n";
  String masterPattern = "%-5p %8r - %m%n"; /* source miliseconds - message *? 
  //String masterPattern = "%-5p - %m%n"; /* source - message */
  FileAppender fa = new FileAppender();
  fa.setName("Master");
  //fa.setFile(sketchPath("./Logs/" + "Master.log"));
  fa.setFile("c:\\logs\\logger.log");
  fa.setLayout(new PatternLayout(masterPattern));
  fa.setThreshold(Level.DEBUG);
  fa.setAppend(false);
  fa.activateOptions();
  Logger.getRootLogger().addAppender(fa);
}
/* want the user to have the scene respond to keystrokes
 * This in turn requires that the main window have focus
 */
void focusOnMainWindow(){
  /* 
   * Zoom the mouse over to the middle of main window, 
   * click there to put focus on the main window, 
   * and move back to current position
   */
  try {
    Point p = MouseInfo.getPointerInfo().getLocation();
    //log.debug("see mouse at "+p.getX()+" "+p.getY());
    robot.mouseMove((int)mainWindowXY.getX()+width/2,(int)mainWindowXY.getY()+10);
    Thread.sleep(10);
    robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
    Thread.sleep(10);
    robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
    Thread.sleep(10);
    robot.mouseMove((int)p.getX(),(int)p.getY());
  } catch (InterruptedException e) {
    System.err.format("IOException: %s%n", e);
  }
}  
