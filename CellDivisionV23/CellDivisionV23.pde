/**
* collision with many particles in 3D
*
* @author aa_debdeb
* @date 2017/01/05
*/

float MIN_RADIUS = 5;
float MAX_RADIUS = 30;

float e = 0.10;
float k = 0.1;

float rotX = 0;
float rotY = 0;

int startOffset = 200;
int slowdownStart = 270;
int slowDownEnd = 330;

ArrayList<Particle> particles;

void setup(){
  size(500, 500, P3D);
  noStroke();
  frameRate(30);
  particles = new ArrayList<Particle>();
  /*for(int i = 0; i < 550; i++){
    System.out.println("Frame: " + i + "  Number of Points: " + targetPointNumber(i) );
  }
  exit();*/
}

int targetPointNumber(int frame){
  
  ArrayList<PVector> pointsInTime = new ArrayList<PVector>(); //Frame, number of points
  //pointsInTime.add(new PVector(0,1));
  pointsInTime.add(new PVector(50,1));
  pointsInTime.add(new PVector(51,2));
  pointsInTime.add(new PVector(100,2));
  pointsInTime.add(new PVector(105,10));
  pointsInTime.add(new PVector(200,10));
  pointsInTime.add(new PVector(205,60));
  pointsInTime.add(new PVector(300,60));
  pointsInTime.add(new PVector(330,1000));
  
  PVector previous = new PVector(-100000,1);
  PVector next = new PVector(100000,1);
  
  for(PVector p1: pointsInTime){
    //suche für dichteren previous
    if((p1.x + startOffset <= frame) && (p1.x + startOffset > previous.x)){
      previous = p1;
    }
    
    //suche für dichteren previous
    if((p1.x + startOffset >= frame) && (p1.x + startOffset < next.x)){
      next = p1;
    }    
  }
  
  if(previous.x == next.x){
    return floor(next.y);
  }
  
  if (previous.x == -100000){
    return floor(next.y);
  }
  
  if (next.x == -100000){
    return floor(previous.y);
  }
  
  //return floor(mapCorrect(frame,previous.x,next.x,previous.y,next.y));
  return floor(mapExp(frame,previous.x+ startOffset,next.x+ startOffset,previous.y,next.y));
}

float mapCorrect(float in, float inLower, float inUpper, float outLower, float outUpper){
  return map(limitRange(in,inLower,inUpper),inLower,inUpper,outLower,outUpper);
}

float mapExp(float in, float inLower, float inUpper, float outLower, float outUpper){
  in = limitRange(in,inLower,inUpper);
  if(in == inLower)
    return outLower;
  if(in == inUpper)
    return outUpper;
  
  float inDiff = abs(inUpper - inLower);
  float outFactor =abs(outUpper/outLower);
  float base = pow(outFactor,1/inDiff);
  float exponent = abs(inLower-in);
  float inOutFactor = pow(base,exponent);
  float diffOutLower = (abs(outLower)*inOutFactor)-abs(outLower);
  if (outUpper>= outLower){
    return outLower + diffOutLower;
  } else {
    return outLower - diffOutLower;
  }
}

float limitRange(float in, float inLower, float inUpper){
  if(inLower < inUpper){
    return (min(max(in,inLower),inUpper));
  } else {
    return (min(max(in,inUpper),inLower));
  }
}

void draw(){
  if(frameCount>slowDownEnd+startOffset){
    exit();
  }
  
  background(230);
  translate(width / 2, height / 2);
  lights();
  int targetPointNumber = targetPointNumber(frameCount);
   if((particles.size() < 1) && (targetPointNumber>0)){
    float radius = MAX_RADIUS;
    PVector loc = new PVector(0,0,0);
    PVector vel = new PVector(0,0,0);
    particles.add(new Particle(loc, vel, radius));
 
  }else if( (particles.size() > 0) && (targetPointNumber > 0)){
    for(int i = particles.size(); i < targetPointNumber; i++){
      Particle first = particles.get( floor( random( 0, floor(particles.size() ) ) ) );
      if(particles.size() == 1){
        particles.add(new Particle(new PVector(random(-1,1),0,0).add(first.loc), new PVector(0,0,0).add(first.vel), MAX_RADIUS));
      }else{
        particles.add(new Particle(new PVector(random(-1,1),random(-1,1),random(-1,1)).add(first.loc), new PVector(0,0,0).add(first.vel), random(MIN_RADIUS, MAX_RADIUS)));
      }
      System.out.println("Partice number: " + particles.size() + " Frame: " + frameCount);
    }
  }
 
  
  if(frameCount %25 ==0){
    System.out.println("FRAME: " + frameCount);
  }
  
  for(Particle p: particles){
    p.render();
    //int average = floor(map(particles.size(), 15, 30, 1 , 6));
    //p.moveAverage(average);
    p.moveAverage(6);
  }
  
  for(Particle p1: particles){
    for(Particle p2: particles){
      if(p1 == p2){continue;}
      float d = PVector.dist(p1.loc, p2.loc);
      if(d <= p1.radius + p2.radius){
        PVector p12 = PVector.sub(p2.loc, p1.loc);
        PVector n = PVector.div(p12, p12.mag());
        PVector v12 = PVector.sub(p2.vel, p1.vel);
        PVector vn1 = PVector.mult(n, PVector.dot(p1.vel, n));
        PVector vt1 = PVector.sub(p1.vel, vn1);
        PVector t = PVector.div(vt1, vt1.mag());
        float spring = -k * (p1.radius + p2.radius - d);
        float j = (1 + e) * (p1.mass * p2.mass / (p1.mass + p2.mass)) * PVector.dot(v12, n);
        PVector impulse = PVector.mult(n, j + spring*8).mult(0.6); 
        p1.nvel.add(impulse);
      }
    }
  }
  
  
  for(Particle p: particles){
    p.updateVel();
  }
  
  
  //write obj
  if(true){
    PrintWriter output = createWriter("output"+frameCount+".obj");
    for(Particle p: particles){
      output.println("v " + p.loc.x + " " + p.loc.y + " " + p.loc.z);
    }
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
  }
}

class Particle{
  
  public PVector loc, vel, nvel;
  public float radius, mass;
  color c;
  ArrayList<PVector> locations = new ArrayList<PVector>();
  
  Particle(PVector loc, PVector vel, float radius){
    this.loc = loc;
    this.vel = vel;
    this.nvel = new PVector(vel.x, vel.y, vel.z);
    this.radius = radius;
    this.mass = 1;
    c = color(lerpColor(color(255, 140, 0), color(255, 0, 170), pow((radius - MIN_RADIUS) / (MAX_RADIUS - MIN_RADIUS), 3)), 200);
  }
  
  void move(){
    moveAverage(1);
  }
  
  void moveAverage(int average){
    PVector center = new PVector(0, 0, 0);
    PVector acc = PVector.sub(center, loc).mult(0.5);
    acc.limit(1.0);
    vel.mult(0.8);
    vel.add(acc);
    //vel.add(random(-0.3,0.3),random(-0.3,0.3),random(-0.3,0.3));
    float velLimit = mapCorrect(frameCount,slowdownStart+startOffset,slowdownStart+startOffset,3.0,0);
    //vel.limit(7.0);
    vel.limit(velLimit);
    nvel = new PVector(vel.x, vel.y, vel.z);
    loc.add(vel);
    locations.add(loc);
    if(locations.size()>10){
      locations.remove(0);
    }
    if(average > 1){
      average = max(1,  average);
      average = min(average, locations.size());
      PVector averageLoc = new PVector(0,0,0);
      for(int i = locations.size()-average; i < locations.size(); i++){
        averageLoc.add(locations.get(i));
      }
      averageLoc.div(average);
      loc = averageLoc.copy();
    }
  }
  
  void render(){
    fill(c);
    pushMatrix();
    translate(loc.x, loc.y, loc.z);
    sphere(radius);
    popMatrix();
  }
  
  void updateVel(){
    //float nvelLimit = mapCorrect(frameCount, 355, 450, 30, 0);
    vel = nvel;//.limit(nvelLimit);
    nvel = new PVector(vel.x, vel.y, vel.z);
  }
}