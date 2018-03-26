import frames.timing.*;
import frames.primitives.*;
import frames.processing.*;

// 1. Frames' objects
Scene scene;
Frame frame;
Vector v1, v2, v3;
// timing
TimingTask spinningTask;
boolean yDirection;
// scaling is a power of 2
int n = 4;

// 2. Hints
boolean triangleHint = true;
boolean gridHint = true;
boolean debug = true;

// 3. Use FX2D, JAVA2D, P2D or P3D
String renderer = P3D;

void setup() {
  //use 2^n to change the dimensions
  size(1024, 1024, renderer);
  scene = new Scene(this);
  if (scene.is3D())
    scene.setType(Scene.Type.ORTHOGRAPHIC);
  scene.setRadius(width/2);
  scene.fitBallInterpolation();

  // not really needed here but create a spinning task
  // just to illustrate some frames.timing features. For
  // example, to see how 3D spinning from the horizon
  // (no bias from above nor from below) induces movement
  // on the frame instance (the one used to represent
  // onscreen pixels): upwards or backwards (or to the left
  // vs to the right)?
  // Press ' ' to play it :)
  // Press 'y' to change the spinning axes defined in the
  // world system.
  spinningTask = new TimingTask() {
    public void execute() {
      spin();
    }
  };
  scene.registerTask(spinningTask);

  frame = new Frame();
  frame.setScaling(width/pow(2, n));

  // init the triangle that's gonna be rasterized
  randomizeTriangle();
}

void draw() {
  background(0);
  stroke(0, 255, 0);
  if (gridHint)
    scene.drawGrid(scene.radius(), (int)pow( 2, n));
  if (triangleHint)
    drawTriangleHint();
  pushMatrix();
  pushStyle();
  scene.applyTransformation(frame);
  triangleRaster();
  popStyle();
  popMatrix();
}

float oriented(float x1, float x2, float x3, float y1, float y2, float y3) {
  return (x1 - x3)*(y2 - y3) - (y1 - y3)*(x2 - x3);
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the frame system which has a dimension of 2^n
void triangleRaster() {
  // frame.coordinatesOf converts from world to frame
  // here we convert v1 to illustrate the idea
  
  float x1 = frame.coordinatesOf(v1).x();
  float x2 = frame.coordinatesOf(v2).x();
  float x3 = frame.coordinatesOf(v3).x();
  
  float y1 = frame.coordinatesOf(v1).y();
  float y2 = frame.coordinatesOf(v2).y();
  float y3 = frame.coordinatesOf(v3).y();
  
  int minx = round(min(x1, x2, x3));
  int miny = round(min(y1, y2, y3));
  int maxx = round(max(x1, x2, x3));
  int maxy = round(max(y1, y2, y3));
  
  if (debug) {  
    pushStyle();
    stroke(255, 255, 0);
    
    point(round(x1), round(y1));
    point(round(x2), round(y2));
    point(round(x3), round(y3));
    point(round( (x3+x2+x1)/3), round((y3+y2+y1)/3));
    
    //System.out.println(x1 + " | " + y1);
    
    /*
    if( ((x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1)) < 0){
    Vector tmp = v1;
      v1 = v2;
      v2 = tmp;
    }*/
    
    String next = "mayor";
    
    if(oriented(x1, x2, x3, y1, y2, y3) < 0){
      next = "menor";
    }
    
    strokeWeight(0);
    for(int x = minx; x < maxx; x++){
      for(int y = miny; y < maxy; y++){
        float a, b, c;
        a = oriented(x1, x2, x, y1, y2, y);
        b = oriented(x2, x3, x, y2, y3, y);
        c = oriented(x3, x1, x, y3, y1, y);
        
        if(next == "mayor"){
          if(a >= 0 && b >= 0 && c >= 0)
            rect(x-0.5, y-0.5, 1, 1);
            
        } else {
          if(a < 0 && b < 0 && c < 0)
            rect(x-0.5, y-0.5, 1, 1);
        }
      }
    }
  popStyle();
    
  }
}

void randomizeTriangle() {
  int low = -width/2;
  int high = width/2;
  v1 = new Vector(random(low, high), random(low, high));
  v2 = new Vector(random(low, high), random(low, high));
  v3 = new Vector(random(low, high), random(low, high));
}

void drawTriangleHint() {
  pushStyle();
  noFill();
  strokeWeight(2);
  stroke(255, 0, 0);
  triangle(v1.x(), v1.y(), v2.x(), v2.y(), v3.x(), v3.y());
  strokeWeight(5);
  stroke(0, 255, 255);
  point(v1.x(), v1.y());
  point(v2.x(), v2.y());
  point(v3.x(), v3.y());
  popStyle();
}

void spin() {
  if (scene.is2D())
    scene.eye().rotate(new Quaternion(new Vector(0, 0, 1), PI / 100), scene.anchor());
  else
    scene.eye().rotate(new Quaternion(yDirection ? new Vector(0, 1, 0) : new Vector(1, 0, 0), PI / 100), scene.anchor());
}

void keyPressed() {
  if (key == 'g')
    gridHint = !gridHint;
  if (key == 't')
    triangleHint = !triangleHint;
  if (key == 'd')
    debug = !debug;
  if (key == '+') {
    n = n < 7 ? n+1 : 2;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == '-') {
    n = n >2 ? n-1 : 7;
    frame.setScaling(width/pow( 2, n));
  }
  if (key == 'r')
    randomizeTriangle();
  if (key == ' ')
    if (spinningTask.isActive())
      spinningTask.stop();
    else
      spinningTask.run(20);
  if (key == 'y')
    yDirection = !yDirection;
}