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

//orientación  para decidir si un punto está o no el interior de un triaángulo, aplicando la orientación respectiva de un triangulo A1A2A3 
float oriented(float x1, float x2, float x3, float y1, float y2, float y3) {
  //formula matématica para saber la orientación respectiva del triángulo.
  return (x1 - x3)*(y2 - y3) - (y1 - y3)*(x2 - x3);
}

// Implement this function to rasterize the triangle.
// Coordinates are given in the frame system which has a dimension of 2^n
void triangleRaster() {
  // frame.coordinatesOf converts from world to frame
  // here we convert v1 to illustrate the idea
  // coordenadas en la posicion x de cada uno de los tres vectores
  float x1 = frame.coordinatesOf(v1).x();
  float x2 = frame.coordinatesOf(v2).x();
  float x3 = frame.coordinatesOf(v3).x();
  //coordenadas en la posicion y de cada uno de los tres vectores
  float y1 = frame.coordinatesOf(v1).y();
  float y2 = frame.coordinatesOf(v2).y();
  float y3 = frame.coordinatesOf(v3).y();
  // el valor minimo de los vertices que se encuentran en la coordenada x
  int minx = round(min(x1, x2, x3));
  //Valor minimo de los vertices que se encuedntran en la coordenada y
  int miny = round(min(y1, y2, y3));
  //Valor maximo de los vertices que se encuentran en la coordenada x
  int maxx = round(max(x1, x2, x3));
  //Valor maximo de los vertices que se encuedntran en la coordenada y
  int maxy = round(max(y1, y2, y3));
  
  if (debug) {  
    pushStyle();
    //primer punto con color verde  
    stroke(0,255, 0);  
    point(round(x1), round(y1));
    // segundo punto con color azul
    stroke(0, 0, 255);
    point(round(x2), round(y2));
    // tercer punto con color rojo
    stroke(255, 0, 0);
    point(round(x3), round(y3));
    // punto que se encuentra en el medio (baricentro)
    //stroke(255);
    //point(round( (x3+x2+x1)/3), round((y3+y2+y1)/3));
    
    String next = "mayor";
    // si el resultado de la oreintacion del triangulo es negativa , la orientacion del triangulo sera negativa
    if(oriented(x1, x2, x3, y1, y2, y3) < 0){
      next = "menor";
    }
    //Es necesario el strokeWeigh para que el tamaño de cada uno de los rectangulos que dibuja dentro del triángulo corresponda a un cuadrado 
    strokeWeight(0);
    fill(255,0,255);
    //subdivision del antialiasing 
    int antialiasing = 4;
    // se eligen los parametros minimos y maximos para recorrer solamente el área necesaria
    for(int x = minx; x < maxx; x++){
      for(int y = miny; y < maxy; y++){
        //se definen los colores del respectivo triangulo
        float color1 = 0;
        float color2 = 0;
        float color3 = 0;
        // se recorre el respectivo triangulo
        for (float i = 0; i<1; i+=(float)1/antialiasing){
          for (float j = 0; j<1; j+=(float)1/antialiasing) {
            //orientacion de cada uno de los puntos con su respectivo antialiasing (subdivisiones correspondientes)
            float a, b, c;
            //Vector p = new Vector(x+i+1/antialiasing/2, y+i+1/antialiasing/2);
            a = oriented(x1, x2, x+i+1/antialiasing/2, y1, y2, y+i+1/antialiasing/2);
            b = oriented(x2, x3, x+i+1/antialiasing/2, y2, y3, y+i+1/antialiasing/2);
            c = oriented(x3, x1, x+i+1/antialiasing/2, y3, y1, y+i+1/antialiasing/2);
            //En caso de que la orientacion sea mayor , es decir todos los puntos esten orientados en el plano positivo se dibujará el triángulo con los colores  RGB
            if(next == "mayor"){
              if(a >= 0 && b >= 0 && c >= 0){
                //cada punto del triangulo  se subdivide en 16
                color1+=a*255/(a+b+c)/(Math.pow(antialiasing,2));
                color2+=b*255/(a+b+c)/(Math.pow(antialiasing,2));
                color3+=c*255/(a+b+c)/(Math.pow(antialiasing,2));
                //rellenar cada una de las subdivisiones del triangulo con los colores correspondientes
                fill(color(round(color1), round(color2), round(color3)));
                rect(x, y, 1, 1);
              }  
            } else {
              //En caso contrario se encontrarán en el caso donde todos los puntos estan en la coordenada negativa , igualmente se dibujará el triángulo con los colores RGB
              if(a < 0 && b < 0 && c < 0){
                //cada punto del tringulo se subdivide en 16
                color1+=a*255/(a+b+c)/(Math.pow(antialiasing,2));
                color2+=b*255/(a+b+c)/(Math.pow(antialiasing,2));
                color3+=c*255/(a+b+c)/(Math.pow(antialiasing,2));
                //rellena cada una de las subdivisiones del triángulo con los colores correspondientes    
                fill(color(round(color1), round(color2), round(color3)));
                rect(x, y, 1, 1);
              }
            }
          }
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