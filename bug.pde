int layout = 2;
int bug = 2;

int[] xV = {0,0  , 40, 40,5  ,5  ,35 ,35 ,5  ,5 ,35,35,5 ,5 ,35,35 ,5,5 ,35,35,5 ,5,75,75,20,20,75,75,20,20,75,75,20,20 ,75 ,75 ,20 ,20 ,80 ,80,0};
int[] yV = {0,147,147,140,140,119,119,112,112,91,91,84,84,63,63,56,56,35,35,28,28,7,7 ,42,42,49,49,70,70,77,77,98,98,105,105,126,126,133,133,0 ,0};
int initX;
int initY;
int goalX;
int goalY;

int roomX;
int roomY;
int offsetX;
int offsetY;

int lastTime;
int stepAction;
int stepFrequency;

PGraphics obstacleSpace;
PGraphics bugSpace;

IntList xPath;
IntList yPath;
IntList xBug;
IntList yBug;
int bugNearest;
boolean bugNextStep;

int totalDist;
int pathDist1, pathDist2;

void setup()
{
  if(layout == 2)
  {
    roomX = 200;
    roomY = 200;
    offsetX = 50;
    offsetY = 25;
  }
  else
  {
    roomX = 300;
    roomY = 225;
    offsetX = 50;
    offsetY = 25;
  }
  size(640, 480, P2D);
  
  obstacleSpace = createGraphics(roomX, roomY);
  obstacleSpace.beginDraw();
  obstacleSpace.background(0, 0, 0);
  obstacleSpace.fill(255, 255, 255);
  obstacleSpace.stroke(255, 255, 255);
  if(layout == 2)
  {
    PShape obstacleShape = createShape();
    obstacleShape.beginShape();
    for(int i = 0; i < xV.length; i++)
    {
      obstacleShape.vertex(xV[i], yV[i]);
    }
    obstacleShape.endShape();
      obstacleSpace.shape(obstacleShape, 0, 0);
    initX = 25;
    initY = 157;
    goalX = 25;
    goalY = 17;
  }
  else
  {
    obstacleSpace.ellipse(50, 60, 40, 40);
    obstacleSpace.ellipse(150, 75, 70, 70);
    initX = 10;
    initY = 60;
    goalX = 210;
    goalY = 75;
  }
  obstacleSpace.endDraw();
  
  bugSpace = createGraphics(width, height);
  xPath = new IntList();
  yPath = new IntList();
  xPath.append(initX);
  yPath.append(initY);
  xBug = new IntList();
  yBug = new IntList();
  
  lastTime = millis();
  bugNextStep = false;
  totalDist = 0;
  pathDist1 = 0;
  pathDist2 = 0;
  
  stepAction = 0;
  stepFrequency = 1500;
}

void draw()
{
  step();
  float scaleX = (float) width / roomX;
  float scaleY = (float) height / roomY;
  background(0, 0, 0);
  image(obstacleSpace, offsetX * scaleX - 1, offsetY * scaleY - 1, obstacleSpace.width * scaleX, obstacleSpace.height * scaleY);
  bugSpace.beginDraw();
  bugSpace.background(0, 0, 0, 0);
  bugSpace.noStroke();
  bugSpace.fill(255, 0, 0);
  bugSpace.ellipse((initX + offsetX) * scaleX, (initY + offsetY) * scaleY, scaleX * 3, scaleX * 3);
  bugSpace.fill(0, 255, 0);
  bugSpace.ellipse((goalX + offsetX) * scaleX, (goalY + offsetY) * scaleY, scaleX * 3, scaleX * 3);
  bugSpace.noFill();
  bugSpace.strokeWeight(scaleX);
  bugSpace.stroke(0, 255, 255);
  for(int i = 0; i + 1 < xBug.size(); i++)
  {
    bugSpace.line((xBug.get(i) + offsetX) * scaleX, (yBug.get(i) + offsetY) * scaleY,
      (xBug.get(i + 1) + offsetX) * scaleX, (yBug.get(i + 1) + offsetY) * scaleY);
  }
  if(stepAction == 2)
  {
    bugSpace.noStroke();
    bugSpace.fill(0, 255, 255);
    bugSpace.ellipse((xBug.get(xBug.size() - 1) + offsetX) * scaleX,
      (yBug.get(yBug.size() - 1) + offsetY) * scaleY, scaleX * 3, scaleX * 3);
    bugSpace.noFill();
  }
  if(bugNearest < xBug.size())
  {
    bugSpace.noStroke();
    bugSpace.fill(255, 0, 255);
    bugSpace.ellipse((xBug.get(bugNearest) + offsetX) * scaleX,
      (yBug.get(bugNearest) + offsetY) * scaleY, scaleX * 3, scaleX * 3);
    bugSpace.noFill();
  }
  bugSpace.stroke(255, 255, 0);
  for(int i = 0; i + 1 < xPath.size(); i++)
  {
    bugSpace.line((xPath.get(i) + offsetX) * scaleX, (yPath.get(i) + offsetY) * scaleY,
      (xPath.get(i + 1) + offsetX) * scaleX, (yPath.get(i + 1) + offsetY) * scaleY);
  }
  bugSpace.endDraw();
  //image(bugSpace, offsetX * scaleX, offsetY * scaleY, bugSpace.width  * scaleX, bugSpace.height * scaleY);
  image(bugSpace, 0, 0);
}

void step()
{
  if((millis() - lastTime) > stepFrequency)
  {
    lastTime = millis();
    //println(stepAction + " " + stepFrequency);
    switch(stepAction)
    {
      case 0: //wait
        stepAction = 1;
        stepFrequency = 30;
        break;
      case 1: //main
        bug();
        break;
      case 2: //Circumnavigation
        moveCreepStep();
        break;
      case 3: //Done circumnavigating
        moveCreep1Finish();
        break;
      case 4: //Kinda done circumnavigating
        moveCreep2Finish();
        break;
      default: //Done
        return;
    }
  }
}

//Traces a path through obstacleSpace to test for edges. Returns point before first contact.
int[] raycast(int x1, int y1, int x2, int y2)
{
  int dist = max(abs(x1 - x2), abs(y1 - y2));
  int lastX = x1;
  int lastY = y1;
  for(int i = 0; i <= dist; i++)
  {
    float prog = (float) i / dist;
    int testX = x1 + round((x2 - x1) * prog);
    int testY = y1 + round((y2 - y1) * prog);
    //println(i + "/" + dist + ": " + testX + ", " + testY + ": " + hex(obstacleSpace.get(testX, testY)));
    if(testX < 0 || testX > obstacleSpace.width 
      || testY < 0 || testY > obstacleSpace.height)
      continue;
    if(obstacleSpace.get(testX, testY) == color(255, 255, 255))
      return new int[] {lastX, lastY};
    lastX = testX;
    lastY = testY;
  }
  return new int[] {x2, y2};
}

//Helper method for intersection test
boolean CCW(int x1, int y1, int x2, int y2, int x3, int y3)
{
  return (y3 - y1) * (x2 - x1) > (y2 - y1) * (x3 - x1);
}

//Tests for an intersection between lines 1-2 and 3-4
boolean intersect(int x1, int y1, int x2, int y2, int x3, int y3, int x4, int y4)
{
  //println(CCW(x1, y1, x3, y3, x4, y4) != CCW(x2, y2, x3, y3, x4, y4));
  return (CCW(x1, y1, x3, y3, x4, y4) !=
          CCW(x2, y2, x3, y3, x4, y4)) &&
         (CCW(x1, y1, x2, y2, x3, y3) !=
          CCW(x1, y1, x2, y2, x4, y4));
}

//Moves from the current position towards the goal until
//hitting an obstacle.
void moveDirect()
{
  int[] next = raycast(xPath.get(xPath.size() - 1), yPath.get(yPath.size() - 1), goalX, goalY);
  if(xPath.get(xPath.size() - 1) == next[0] &&
    yPath.get(yPath.size() - 1) == next[1])
    return;
  totalDist += dist(xPath.get(xPath.size() - 1), yPath.get(yPath.size() - 1), next[0], next[1]);
  xPath.append(next[0]);
  yPath.append(next[1]);
  
}

//Circumnavigates a surface from a position on the border, notes
//the point along the border closest to the goal, and sets that
//as the next point.
//boolean test;
void moveCreepSetup()
{
  //test = true;
  xBug.clear();
  yBug.clear();
  xBug.append(xPath.get(xPath.size() - 2));
  yBug.append(yPath.get(yPath.size() - 2));
  xBug.append(xPath.get(xPath.size() - 1));
  yBug.append(yPath.get(yPath.size() - 1));
  bugNearest = 1;
  pathDist1 = 0;
  pathDist2 = 0;
  if(bug != 2)
    for(int i = 0; i < 5; i++)
      moveCreepStep();
  else
  {
    moveCreepStep();
  }
  //while(abs(xBug.get(xBug.size() - 1) - xBug.get(1)) > 5 ||
  //  abs(yBug.get(yBug.size() - 1) - yBug.get(1)) > 5) //The "close enough" distance formula.
  //  {
      //println(abs(xBug.get(xBug.size() - 1) - xBug.get(1)) + ", "
      //+ abs(yBug.get(yBug.size() - 1) - yBug.get(1)) + " - " + xBug.size());
  //  moveCreepStep();
  //}
  stepAction = 2;
  stepFrequency = 20;
  if(bug == 2 && layout == 2)
    stepFrequency = 1;
}

void moveCreep1Finish()
{
  int[] newX;
  int[] newY;
  if(bugNearest < xBug.size() / 2)
  {
    newX = new int[bugNearest];
    newY = new int[bugNearest];
    arrayCopy(xBug.array(), 0, newX, 0, bugNearest);
    arrayCopy(yBug.array(), 0, newY, 0, bugNearest);
    totalDist += pathDist1;
  }
  else
  {
    newX = new int[xBug.size() - bugNearest];
    newY = new int[yBug.size() - bugNearest];
    arrayCopy(xBug.array(), bugNearest, newX, 0, xBug.size() - bugNearest);
    arrayCopy(yBug.array(), bugNearest, newY, 0, yBug.size() - bugNearest);
    newX = reverse(newX);
    newY = reverse(newY);
    totalDist += pathDist2;
  }
  xPath.append(newX);
  yPath.append(newY);
  stepAction = 0;
  stepFrequency = 1000;
  //println(xPath + "---" + yPath);
}

void moveCreep2Finish()
{
  //if(!test)
  //  throw new RuntimeException("AAAAAA");
  //test = false;
  //println(xBug.toString() + "; " + yBug.toString() + "; " + xPath + "; " + yPath);
  int[] newX = new int[xBug.size() - 2];
  int[] newY = new int[yBug.size() - 2];
  arrayCopy(xBug.array(), 2, newX, 0, xBug.size() - 2);
  arrayCopy(yBug.array(), 2, newY, 0, yBug.size() - 2);
  //newX = reverse(newX);
  //newY = reverse(newY);
  xPath.append(newX);
  yPath.append(newY);
  totalDist += pathDist2;
  stepAction = 0;
  stepFrequency = 1000;
}

//Single step of tracing a path around an obstacle.
void moveCreepStep()
{
  //println(xBug.toString() + "; " + yBug.toString() + "; " + xPath + "; " + yPath);
  int testX = xBug.get(xBug.size() - 1);
  int testY = yBug.get(yBug.size() - 1);
  PVector delta = new PVector(xBug.get(xBug.size() - 2) - testX, yBug.get(yBug.size() - 2) - testY);
  delta.normalize();
  if(delta.mag() == 0)
    return;
  delta.mult(2);
  int bestX = 0, bestY = 0;
  for(int i = 0; i < 8; i++)
  {
    delta.rotate(PI / 4);
    int newX = testX + (int) delta.x;
    int newY = testY + (int) delta.y; 
    int[] ray = raycast(testX, testY, newX, newY);
    //println(testX + ", " + testY + "; " + delta.x + ", " + delta.y + "; " + newX + ", " + newY + "; " + ray[0] + ", " + ray[1]);
    if(ray[0] != newX || ray[1] != newY)
    {
      //println("Hit!");
      xBug.append(bestX);
      yBug.append(bestY);
      int lastX = (xBug.get(xBug.size() - 2));
      int lastY = (yBug.get(yBug.size() - 2));
      pathDist2 += dist(testX, testY, bestX, bestY);
      totalDist += dist(testX, testY, bestX, bestY);
      if(bug == 2)
      {
        if(intersect(lastX, lastY, bestX, bestY, initX, initY, goalX, goalY)
          && dist(xBug.get(1), yBug.get(1), goalX, goalY) > dist(bestX, bestY, goalX, goalY))
        {
          //moveCreep2Finish();
          //println("Intersection! " + lastX + ", " + lastY + "; " + bestX + ", " + bestY + "; " + initX + ", " + initY + "; " + goalX + ", " + goalY);
          bugNearest = xBug.size() - 1; 
          stepAction = 4;
          stepFrequency = 1000;
        }
      }
      else
      {
        if(dist(bestX, bestY, goalX, goalY) < dist(xBug.get(bugNearest), yBug.get(bugNearest), goalX, goalY))
        {
          bugNearest = xBug.size() - 1;
          pathDist1 += pathDist2;
          pathDist2 = 0;
        }
        if(abs(bestX - xBug.get(1)) < 2 &&
          abs(bestY - yBug.get(1)) < 2)
        {
          stepAction = 3;
          stepFrequency = 1000;
        }
      }
      return;
    }
    bestX = ray[0];
    bestY = ray[1];
  }
}

//Repeatedly attempts the two steps of the bug1 algorithm.
void bug()
{
  if(xPath.get(xPath.size() - 1) == goalX && 
    yPath.get(yPath.size() - 1) == goalY)
  {
    stepAction = 5;
    stepFrequency = 1000;
    float eucDist = dist(initX, initY, goalX, goalY);
    println("Euclidean distance: " + eucDist);
    println("Actual distance traveled: " + totalDist);
    println("Ratio: " + (float) totalDist / eucDist);
    return;
  }
  if(!bugNextStep)
  {
    moveDirect();
    stepAction = 1;
    stepFrequency = 1000;
  }
  else
  {
    moveCreepSetup();
  }
  bugNextStep = !bugNextStep;
}
