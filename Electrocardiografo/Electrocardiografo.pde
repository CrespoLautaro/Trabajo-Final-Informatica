import processing.serial.*;


Serial myPort;
PImage miImagen;
int btnWidth = 200, btnHeight = 80, btnY = 800;
int btn1X = 300, btn2X = btn1X + btnWidth + 30, btn3X = btn2X + btnWidth + 30;
String label1 = "INICIAR", label2 = "REINICIAR", label3 = "GUARDAR";
ArrayList<Float> ecgData = new ArrayList<Float>();
int maxSamples = 300;
enum Estado { ESPERANDO, MIDIENDO, DESCONECTADO }
Estado estadoActual = Estado.ESPERANDO;
String mensajeTemporal = "";
float tiempoMensaje = 0, duracionMensaje = 2500;

void setup() {
  size(1200, 900);
  surface.setResizable(true);
  miImagen = loadImage("corazon.jpg");
  PFont myFont = createFont(PFont.list()[3], 60);
  textFont(myFont);
  smooth(8); 
  println(Serial.list());
  try {
    myPort = new Serial(this, "COM9", 9600);
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("Error al abrir el puerto COM. Asegúrate de que el Arduino esté conectado.");
    e.printStackTrace();
  }
}

void draw() {
 
  background(255, 242, 242);
  fill(0);
  textSize(58);
  textAlign(LEFT); 
  text("Electrocardiógrafo", 640, 60);
  image(miImagen, 1000, 10);
  textSize(20);
  switch (estadoActual) {
    case DESCONECTADO:
      fill(255, 0, 0);
      text("⚠ Electrodos desconectados ⚠", 50, 140);
      break;
    case MIDIENDO:
      fill(0, 150, 0);
      text("Midiendo señal en tiempo real...", 50, 140);
      break;
    case ESPERANDO:
    default:
      fill(150, 0, 0);
      text("Esperando inicio de medición", 50, 140);
      break;
  }
  drawButton(btn1X, btnY, btnWidth, btnHeight, label1);
  drawButton(btn2X, btnY, btnWidth, btnHeight, label2);
  drawButton(btn3X, btnY, btnWidth, btnHeight, label3);
  drawGraph();
  if (millis() - tiempoMensaje < duracionMensaje) {
    pushStyle(); 
    rectMode(CENTER); 
    fill(0, 0, 0, 150); 
    noStroke();
    float posYMensaje = 300; 
    rect(width / 2, posYMensaje, 450, 100, 15); 
    fill(255); 
    textSize(28);
    textAlign(CENTER, CENTER); 
    text(mensajeTemporal, width / 2, posYMensaje);
    popStyle(); 
  }
}

void drawGraph() {
  
  pushStyle();    
  pushMatrix();   
  translate(50, 200);
  float w = width - 100;
  float h = 500;
  stroke(255, 220, 220); 
  strokeWeight(0.5);
  int pasoMenor = 10;
  for (float x = 0; x <= w; x += pasoMenor) line(x, 0, x, h);
  for (float y = 0; y <= h; y += pasoMenor) line(0, y, w, y);
  stroke(255, 180, 180); 
  strokeWeight(1);
  int pasoMayor = 50;
  for (float x = 0; x <= w; x += pasoMayor) line(x, 0, x, h);
  for (float y = 0; y <= h; y += pasoMayor) line(0, y, w, y);
  stroke(0);
  strokeWeight(1);
  noFill();
  rect(0, 0, w, h); 
  stroke(255, 0, 0); 
  strokeWeight(2);
  noFill();
  beginShape();
  for (int i = 0; i < ecgData.size(); i++) {
    float x_ecg = map(i, 0, maxSamples - 1, 0, w);
    float y_ecg = map(ecgData.get(i), 200, 600, h, 0); 
    vertex(x_ecg, y_ecg);
  }
  endShape();
  popMatrix(); 
  popStyle();  
}

void drawButton(int x, int y, int w, int h, String label) {

  pushStyle(); 
  if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
    fill(200, 200, 255);
  } else {
    fill(220);
  }
  stroke(0);
  rect(x, y, w, h, 5);
  fill(0);
  textSize(16);
  textAlign(CENTER, CENTER);
  text(label, x + w/2, y + h/2);
  popStyle(); 
}

void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString == null) return;
  inString = trim(inString);

  if (inString.equals("IM")) {
    println("[ARDUINO] Comando: Inicio de medición");
    estadoActual = Estado.MIDIENDO;
    ecgData.clear(); 
    mensajeTemporal = "Iniciando medición...";
    tiempoMensaje = millis();
  }  
  else if (inString.equals("ED")) {
    println("[ARDUINO] Comando: Electrodos desconectados");
    estadoActual = Estado.DESCONECTADO;
    mensajeTemporal = "¡Electrodos desconectados!";
    tiempoMensaje = millis();
  }  
  else if (inString.equals("R")) {
    println("[ARDUINO] Comando: Reinicio recibido");
    estadoActual = Estado.ESPERANDO;
    ecgData.clear(); // Limpiamos al reiniciar
    mensajeTemporal = "Reiniciando medición...";
    tiempoMensaje = millis();
  }  
  else if (inString.equals("G")) {
    println("[ARDUINO] Comando: Guardado recibido");
    estadoActual = Estado.ESPERANDO;
    mensajeTemporal = "Medición guardada.";
    tiempoMensaje = millis();
  }  
  
 
  else if (inString.startsWith("<") && inString.endsWith(">")) {
    
    
    inString = inString.substring(1, inString.length() - 1);
    String[] values = split(inString, ',');
    
 
    ArrayList<Float> newData = new ArrayList<Float>();
    
    for (String val : values) {
      try {
        newData.add(float(val)); 
      } catch (Exception e) {}
    }
    

    if (newData.size() == maxSamples) {

      ecgData = newData; 
    }
  
  }  
  
  else {
    if(inString.length() > 0) {
      println("[INFO] " + inString);
    }
  }
}

void keyPressed() {
  if (myPort == null) return;
  if (key == 'M' || key == 'm') myPort.write("IM\n");
  else if (key == 'R' || key == 'r') myPort.write("R\n");
  else if (key == 'G' || key == 'g') myPort.write("G\n");
}

void mousePressed() {
  if (myPort == null) return; 
  if (mouseY > btnY && mouseY < btnY + btnHeight) {
    if (mouseX > btn1X && mouseX < btn1X + btnWidth) myPort.write("IM\n");
    else if (mouseX > btn2X && mouseX < btn2X + btnWidth) myPort.write("R\n");
    else if (mouseX > btn3X && mouseX < btn3X + btnWidth) myPort.write("G\n");
  }
}
