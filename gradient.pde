int layout = 1;

int method = 2;

int initX = 10;
int initY = 60;
int goalX = 210;
int goalY = 75;

int roomX = 320;
int roomY = 240;
int offsetX = 0;
int offsetY = 0;

int lastTime;
int stepAction;
int stepFrequency;

PGraphics obstacleSpace;
PGraphics navSpace;

FloatList xPath;
FloatList yPath;

float totalDist;
boolean done;

void setup()
{
  size(640, 480, P2D);
  
  obstacleSpace = createGraphics(roomX, roomY);
  obstacleSpace.beginDraw();
  obstacleSpace.background(0, 0, 0, 255);
  obstacleSpace.noStroke();
  for(int i = 0; i < obstacleSpace.width; i++)
    for(int j = 0; j < obstacleSpace.height; j++)
    {
      float c = alt(i, j);
      c = constrain(c, 0, 1);
      //if(c != 0)
      //println(obs1 + " " + obs2 + " " + c);
      c *= 255;
      obstacleSpace.set(i, j, color(c));
      //obstacleSpace.set(i, j, color(255, 255, 255, dist(i, j, goalX, goalY) / 1.3));
    }
  
  obstacleSpace.endDraw();
  
  lastTime = millis();
  
  navSpace = createGraphics(width, height);
  xPath = new FloatList();
  yPath = new FloatList();
  xPath.append(initX);
  yPath.append(initY);
  
  totalDist = 0;
  done = false;
}

void draw()
{
  step();
  float scaleX = (float) width / roomX;
  float scaleY = (float) height / roomY;
  background(0, 0, 0);
  image(obstacleSpace, offsetX * scaleX - 1, offsetY * scaleY - 1, obstacleSpace.width * scaleX, obstacleSpace.height * scaleY);
  navSpace.beginDraw();
  navSpace.background(0, 0, 0, 0);
  navSpace.noStroke();
  navSpace.fill(255, 0, 0);
  navSpace.ellipse((initX + offsetX) * scaleX, (initY + offsetY) * scaleY, scaleX * 3, scaleX * 3);
  navSpace.fill(0, 255, 0);
  navSpace.ellipse((goalX + offsetX) * scaleX, (goalY + offsetY) * scaleY, scaleX * 3, scaleX * 3);
  navSpace.fill(0, 0, 255);
  if(layout == 1)
  {
    navSpace.ellipse((50 + offsetX) * scaleX, (60 + offsetY) * scaleY, 40 * scaleX, 40 * scaleY);
    navSpace.ellipse((150 + offsetX) * scaleX, (75 + offsetY) * scaleY, 70 * scaleX, 70 * scaleY);
  }
  else
  {
    navSpace.ellipse((170 + offsetX) * scaleX, (60 + offsetY) * scaleY, 40 * scaleX, 40 * scaleY);
    navSpace.ellipse((170 + offsetX) * scaleX, (90 + offsetY) * scaleY, 40 * scaleX, 40 * scaleY);
  }
  navSpace.noFill();
  navSpace.stroke(255, 255, 0);
  navSpace.strokeWeight(2);
  for(int i = 0; i + 1 < xPath.size(); i++)
  {
    navSpace.line(((int)xPath.get(i) + offsetX) * scaleX, ((int)yPath.get(i) + offsetY) * scaleY,
      ((int)xPath.get(i + 1) + offsetX) * scaleX, ((int)yPath.get(i + 1) + offsetY) * scaleY);
  }
  navSpace.endDraw();
  image(navSpace, 0, 0);
}

void step()
{
  if(millis() < 3500)
    return;
  if(millis() - lastTime < 30)
    return;
  if(done)
    return;
  lastTime = millis();
  float currX = xPath.get(xPath.size() - 1);
  float currY = yPath.get(yPath.size() - 1);
  if(method == 1)
  {
    int bestX = (int)currX;
    int bestY = (int)currY;
    float best = alt((int)currX, (int)currY);
    for(int r = 1; r < 8; r++)
    {
      PVector delta = new PVector(1, 1);
      delta.normalize();
      delta.mult(1 + r);
      //println("curr: " + bestX + ", " + bestY + ", " + alpha(obstacleSpace.get(currX, currY)));
      for(int i = 0; i < pow(2, (1 + r)); i++)
      {
        delta.rotate(PI / pow(2, (r)));
        int newX = (int)(currX + delta.x);
        int newY = (int)(currY + delta.y);
        float newAlt = alt(newX, newY);
        //println("test: " + newX + ", " + newY + ", " + newColor);
        int N; //Temporary thing to conditionally use within an if statement
        if(newAlt < best || (newAlt == best && ((N = xPath.index(newX)) != -1) && (yPath.get(N) != newY)))
        {
          bestX = newX;
          bestY = newY;
          best = newAlt;
        }
        //println(newX + ", " + newY + ": " + newAlt);
      }
      if((bestX != currX || bestY != currY) && r > 2)
        break;
    }
    xPath.append(bestX);
    yPath.append(bestY);
  }
  else
  {
    PVector delta = dir(currX, currY);
    delta.mult(5);
    //println(delta.toString() + " - " + currX + ", " + currY);
    float newX = currX + delta.x;
    float newY = currY + delta.y;
    xPath.append(newX);
    yPath.append(newY);
    totalDist += dist(currX, currY, newX, newY);
    if(dist(newX, newY, goalX, goalY) < 2)
    {
      done = true;
      float eucDist = dist(initX, initY, goalX, goalY);
      println("Euclidean distance: " + eucDist);
      println("Actual distance traveled: " + totalDist);
      println("Ratio: " + (float) totalDist / eucDist);
    }
  }
  //println(bestX + ", " + bestY + ": " + best);
}

float obstacle(int obsX, int obsY, int R, float X, float Y)
{
  float d = dist(X, Y, obsX, obsY);
  float p = 1 - norm(d, R, R * 1.5);//((d - R) / (R * 0.5));
  //if(d < 50)
  //println(d + ", " + p);
  p = constrain(p, 0, 1);
  return p;
}

float obstacleForce(int obsX, int obsY, int R, float X, float Y)
{
  float d = dist(X, Y, obsX, obsY);
  float p = 1.0 / norm(d, R, R * 1.5) - 1;
  p = max(p, 0);
  //println(obsY + ": " + p);
  return p;
}

float slope(int targetX, int targetY, float X, float Y)
{
  float d = dist(X, Y, targetX, targetY);
  float p = (d / (roomX * 0.7));
  //p += (0.0001 * pow(d, 1.05));
  return p;
}

float alt(int X, int Y)
{
  float c;
  if(layout == 1)
  {
    float obs1 = obstacle(50, 60, 20, X, Y);
    float obs2 = obstacle(150, 75, 35, X, Y);
    float hill = slope(goalX, goalY, X, Y);
    c = obs1 + obs2 + hill;
  }
  else
  {
    float obs1 = obstacle(170, 60, 20, X, Y);
    float obs2 = obstacle(170, 90, 20, X, Y);
    float hill = slope(goalX, goalY, X, Y);
    c = obs1 + obs2 + hill;
  }
  return c;
}

PVector dir(float X, float Y)
{
  PVector c = new PVector(0, 0);
  if(layout == 1)
  {
    PVector obs1 = new PVector(X - 50, Y - 60);
    obs1.normalize();
    obs1.mult(obstacleForce(50, 60, 20, X, Y));
    PVector obs2 = new PVector(X - 150, Y - 75);
    obs2.normalize();
    obs2.mult(obstacleForce(150, 75, 35, X, Y));
    PVector hill = new PVector(goalX - X, goalY - Y);
    hill.normalize();
    hill.mult(constrain(slope(goalX, goalY, X, Y), 0, 1) * 1.1);
    c = PVector.add(obs1, obs2);
    c.add(hill);
  }
  else
  {
    PVector obs1 = new PVector(X - 170, Y - 60);
    obs1.normalize();
    obs1.mult(obstacleForce(170, 60, 20, X, Y));
    PVector obs2 = new PVector(X - 170, Y - 90);
    obs2.normalize();
    obs2.mult(obstacleForce(170, 90, 20, X, Y));
    PVector hill = new PVector(goalX - X, goalY - Y);
    hill.normalize();
    hill.mult(constrain(slope(goalX, goalY, X, Y), 0, 1));
    c = PVector.add(obs1, obs2);
    c.add(hill);
  }
  return c;
}
