
import processing.serial.*;

Serial myPort;      // The serial port
char whichKey;  // Variable to hold keystoke values
char inChar, rChar;    // Incoming serial data
String inputString = "";         // a string to hold incoming data
String outputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete
PImage miImagen;

// Variables para definir los botones
int btnWidth = 140;
int btnHeight = 40;
int btnY = 900; // Posición Y común para los tres botones

// Variables para el botón 1
int btn1X = 700;
String label1 = "INICIAR";

// Variables para el botón 2
int btn2X = btn1X + btnWidth + 30; // Separación de 20 píxeles
String label2 = "REINICIAR";

// Variables para el botón 3
int btn3X = btn2X + btnWidth + 30; // Separación de 20 píxeles
String label3 = "GUARDAR";


void setup() {
  size(800, 600); // Un tamaño cualquiera
   surface.setResizable(true);
   surface.setSize(displayWidth, displayHeight);
   miImagen = loadImage("corazon.jpg");
  
  
  PFont myFont = createFont(PFont.list()[2], 60);
  textFont(myFont);
  printArray(Serial.list());
   String portName = Serial.list()[0];
  myPort = new Serial(this, "COM5", 9600);
}

void draw() 
{
  background(255,242,242);
  fill(0,0,0);
  textSize(28);
  text("Electrocardiógrafo ", 960, 60);
  image(miImagen, 1300, 10);
  
  text(inputString, 10, 300);
  
  text("ECG: " + outputString, 10, 100);
  
  
  // Dibuja los 3 botones
  drawButton(btn1X, btnY, btnWidth, btnHeight, label1);
  drawButton(btn2X, btnY, btnWidth, btnHeight, label2);
  drawButton(btn3X, btnY, btnWidth, btnHeight, label3);


  
}

// Función auxiliar para dibujar un botón
void drawButton(int x, int y, int w, int h, String label) {
  // 1. Determina el color (resaltado si el mouse está encima)
  if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) {
    fill(200, 200, 255); // Color claro al pasar el mouse
  } else {
    fill(220); // Color normal
  }
  
  // 2. Dibuja el rectángulo del botón
  rect(x, y, w, h, 5); // Rectángulo con esquinas redondeadas (radio 5)
  
  // 3. Dibuja la etiqueta del texto
  fill(0);
  textSize(16);
  textAlign(CENTER, CENTER);
  text(label, x + w/2, y + h/2);
}
  
  


void serialEvent(Serial myPort) 
{
  
  inChar = (char) myPort.read();

  if (inChar != '\n') 
  {
      if (inChar == 'X')  inputString = "";
      else inputString += inChar; 
  }
    
}

void keyPressed() 
{  
  myPort.write(key);
  if (key <= 10) outputString = "";
  else outputString += key;
        
}
