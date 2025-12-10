import processing.serial.*;
import javax.swing.*; //libreria de java para ventanas emergentes

// Usamos libreria propia
GestorArchivos miArchivo; 

Serial myPort;
PImage miImagen; 

// Se calculan dinámicamente según el tamaño de la ventana
float btnX1, btnX2, btnX3;
float btnY, btnW, btnH;
float graphX, graphY, graphW, graphH;
float tamTextoTitulo, tamTextoNormal;

// Botones
String label1 = "INICIAR";
String label2 = "PAUSAR"; 
String label3 = "GUARDAR";

// Datos y Estados
ArrayList<Float> ecgData = new ArrayList<Float>();
int maxSamples = 300;
float rangoMin = 0;   
float rangoMax = 1023;
enum Estado { ESPERANDO, MIDIENDO, PAUSADO, DESCONECTADO }
Estado estadoActual = Estado.ESPERANDO;

// Mensajes Emergentes
String mensajeTemporal = "";
float tiempoMensaje = 0;
float duracionMensaje = 2500;

void setup() {
  //Ventana redimensionable
  size(1000, 700); 
  surface.setResizable(true);
  
  miImagen = loadImage("corazon.jpg"); 
  
  // Inicializamos librería
  miArchivo = new GestorArchivos("Datos_ECG");

  println(Serial.list());
  try {
 
    myPort = new Serial(this, "COM3", 9600); 
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("Error: Arduino no conectado.");
  }
}

// Funcion de calculo de las posiciones
void recalcularInterfaz() {
  
  btnW = width * 0.15;
  btnH = height * 0.08;
  btnY = height * 0.85; 
  
  //Centrado de botones
  float espacio = width * 0.02; 
  float anchoTotalBotones = (btnW * 3) + (espacio * 2);
  float inicioX = (width - anchoTotalBotones) / 2;
  
  btnX1 = inicioX;
  btnX2 = btnX1 + btnW + espacio;
  btnX3 = btnX2 + btnW + espacio;
  
  graphX = width * 0.05;
  graphY = height * 0.20;
  graphW = width * 0.90;
  graphH = height * 0.55;
  
  tamTextoTitulo = height * 0.06; 
  tamTextoNormal = height * 0.025; 
}

void draw() {

  recalcularInterfaz();
  
  background(255, 242, 242);
  
  fill(0); 
  textSize(tamTextoTitulo); 
  textAlign(CENTER); 
  text("Electrocardiógrafo", width / 2, height * 0.10);
 
  if (miImagen != null) {
    float imgSize = height * 0.1; 
    image(miImagen, width - imgSize*4 , 20, 150, imgSize);
  }
  
  textSize(tamTextoNormal);
  textAlign(LEFT);
  float estadoY = graphY - 15; 
  
  switch (estadoActual) {
    case DESCONECTADO: fill(255, 0, 0); text("Electrodos desconectados", graphX, estadoY); break;
    case MIDIENDO:     fill(0, 150, 0); text("Midiendo señal...", graphX, estadoY); break;
    case PAUSADO:      fill(0, 0, 150); text("Visualización Pausada", graphX, estadoY); break;
    default:           fill(150, 0, 0); text("Esperando inicio...", graphX, estadoY); break;
  }

  // --- DIBUJAR BOTONES ---
  drawButton(btnX1, btnY, btnW, btnH, label1);
  drawButton(btnX2, btnY, btnW, btnH, label2);
  drawButton(btnX3, btnY, btnW, btnH, label3);
  
  drawGraph();
  
  // --- MENSAJE FLOTANTE ---
  if (millis() - tiempoMensaje < duracionMensaje) {
    pushStyle(); 
    rectMode(CENTER); fill(0, 0, 0, 150); noStroke();
    rect(width / 2, height / 2, width * 0.5, height * 0.1, 15); 
    fill(255); textSize(tamTextoNormal * 1.5); textAlign(CENTER, CENTER); 
    text(mensajeTemporal, width / 2, height / 2);
    popStyle(); 
  }
}

//
void mousePressed() {
  
  if (mouseY > btnY && mouseY < btnY + btnH) {  
    
    // --- BOTÓN 1: INICIAR ---
    if (mouseX > btnX1 && mouseX < btnX1 + btnW) {
      if (estadoActual == Estado.PAUSADO) {
        estadoActual = Estado.MIDIENDO;
        mensajeTemporal = "Reanudando...";
      } else {
        if(myPort != null) myPort.write("IM\n"); // Enviar a Arduino
        estadoActual = Estado.MIDIENDO;
        mensajeTemporal = "Iniciando...";
      }
      tiempoMensaje = millis();
    }
    
    // --- BOTÓN 2: PAUSAR / REANUDAR ---
    else if (mouseX > btnX2 && mouseX < btnX2 + btnW) { 
      if (estadoActual == Estado.MIDIENDO) {        
        estadoActual = Estado.PAUSADO;
        mensajeTemporal = "Gráfico Pausado";
      } else if (estadoActual == Estado.PAUSADO) {
        estadoActual = Estado.MIDIENDO;
        mensajeTemporal = "Reanudando...";
      }
      tiempoMensaje = millis();
    }
    
    // --- BOTÓN 3: GUARDAR ---
    else if (mouseX > btnX3 && mouseX < btnX3 + btnW) {
      realizarGuardadoConDatos();
    }
  }
}

// --- LÓGICA DE GUARDADO ---
void realizarGuardadoConDatos() {
  // 1. VALIDACIÓN
  if (ecgData == null || ecgData.size() == 0) {
    mensajeTemporal = "¡No hay datos para guardar!";
    tiempoMensaje = millis();
    return; 
  }

  // 2. PAUSA
  Estado estadoPrevio = estadoActual;
  estadoActual = Estado.PAUSADO; 
  
  // 3. VENTANA
  String[] resultado = pedirDatosPaciente();
  
  if (resultado != null) {
     String infoCompleta = resultado[0];
     String nombreSolo = resultado[1];
     miArchivo.guardar(ecgData, infoCompleta, nombreSolo);
     mensajeTemporal = "Guardado: " + nombreSolo;
  } else {
     mensajeTemporal = "Guardado cancelado";
  }
  
  tiempoMensaje = millis();
  
  // 4. REACTIVACIÓN AUTOMÁTICA (Si estaba midiendo antes)
  if (estadoPrevio == Estado.MIDIENDO) estadoActual = Estado.MIDIENDO;
}

// --- VENTANA EMERGENTE ---
String[] pedirDatosPaciente() {
  JPanel panel = new JPanel();
  panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
  
  JTextField nombreField = new JTextField(15);
  JTextField edadField = new JTextField(5);
  JTextField dniField = new JTextField(10);
  JTextField antecedenteField = new JTextField(20);

  panel.add(new JLabel("Nombre y Apellido (Nombre de Archivo):"));
  panel.add(nombreField);
  panel.add(new JLabel("Edad:"));
  panel.add(edadField);
  panel.add(new JLabel("DNI:"));
  panel.add(dniField);
  panel.add(new JLabel("Antecedentes Médicos:"));
  panel.add(antecedenteField);

  int result = JOptionPane.showConfirmDialog(null, panel, 
               "Guardar ECG - Datos del Paciente", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

  if (result == JOptionPane.OK_OPTION) {
    String nombre = nombreField.getText();
    if (nombre.trim().length() == 0) nombre = "Paciente_Sin_Nombre";
    
    String info = "PACIENTE: " + nombre + "\n" +
                  "EDAD: " + edadField.getText() + "\n" +
                  "DNI: " + dniField.getText() + "\n" +
                  "ANTECEDENTES: " + antecedenteField.getText();
    
    return new String[] { info, nombre };
  } else {
    return null;
  }
}

// --- FUNCIONES DE DIBUJO ---
void drawButton(float x, float y, float w, float h, String label) {
  pushStyle(); 
  if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) fill(200, 200, 255);
  else fill(220);
  stroke(0); 
  rect(x, y, w, h, 10);
  fill(0); 
  textSize(tamTextoNormal); 
  textAlign(CENTER, CENTER);
  text(label, x + w/2, y + h/2);
  popStyle(); 
}

void drawGraph() {
  pushStyle(); 
  pushMatrix(); 
  translate(graphX, graphY);
  
  // 1. Fondo Blanco
  stroke(0); strokeWeight(2); fill(255); 
  rect(0, 0, graphW, graphH); 
  
  // 2. Grilla y Escalas
  stroke(220); strokeWeight(1); fill(80); textSize(10); // Texto gris oscuro y pequeño
  
  // --- EJE X (Horizontal - Muestras) ---
  int numDivisoresX = 20;
  textAlign(CENTER, TOP); // Alineado al centro y pegado arriba (para que quede bajo la línea)
  
  for(int i=0; i<=numDivisoresX; i++) {
    float x = map(i, 0, numDivisoresX, 0, graphW);
    line(x, 0, x, graphH); // Línea vertical
    
    // Dibujamos el número solo cada 2 líneas para no amontonar
    if (i % 2 == 0) {
      int valorMuestra = int(map(i, 0, numDivisoresX, 0, maxSamples));
      text(valorMuestra, x, graphH + 5); // Dibujamos 5 pixeles debajo del gráfico
    }
  }

  // Escalas grafico
  int numDivisoresY = 10;
  textAlign(RIGHT, CENTER); 
  
  for(int i=0; i<=numDivisoresY; i++) {
    float y = map(i, 0, numDivisoresY, graphH, 0); 
    line(0, y, graphW, y); // Línea horizontal
    int valorAmplitud = int(map(i, 0, numDivisoresY, 200, 650));
    text(valorAmplitud, -5, y); 
  }
  
  
  fill(0);
  textAlign(CENTER);
  text("Muestras (Tiempo)", graphW / 2, graphH + 25);
  
  pushMatrix();
  rotate(-HALF_PI); 
  text("Amplitud (ADC)", -graphH / 2, -30);
  popMatrix();

  // Dibujamo la Señal 
  stroke(255, 0, 0); strokeWeight(2); noFill();
  beginShape();
  for (int i = 0; i < ecgData.size(); i++) {
    float x_ecg = map(i, 0, maxSamples - 1, 0, graphW);
    float y_ecg = map(ecgData.get(i), 200, 700, graphH, 0); 
    vertex(x_ecg, y_ecg);
  }
  endShape();
  
  popMatrix(); 
  popStyle();  
}

//COMUNICACIÓN SERIAL ---
void serialEvent(Serial myPort) {
  String inString = myPort.readStringUntil('\n');
  if (inString == null) return;
  inString = trim(inString);

  // COMANDOS DE ESTADOS
  if (inString.equals("IM")) {
    estadoActual = Estado.MIDIENDO; 
    ecgData.clear(); // Limpiamos al iniciar
    mensajeTemporal = "Iniciando..."; 
    tiempoMensaje = millis();
    
  } else if (inString.equals("ED")) {
    estadoActual = Estado.DESCONECTADO; 
    mensajeTemporal = "¡Electrodos Desconectados!"; 
    tiempoMensaje = millis();
    
  } else if (inString.equals("P")) {
    estadoActual = Estado.PAUSADO; 
    mensajeTemporal = "Pausado - Listo para Guardar"; 
    tiempoMensaje = millis();
    
  } else if (inString.equals("G")) {
    realizarGuardadoConDatos();
    
 
  } else if (inString.startsWith("<") && inString.endsWith(">")) {
    
    inString = inString.substring(1, inString.length() - 1);
    String[] values = split(inString, ',');
    ArrayList<Float> newData = new ArrayList<Float>();
    
    for (String val : values) { 
       try { 
         float valorLeido = float(val);
         
         // FILTRO: Invalidamos menores a 200
         if (valorLeido < 200) {
           valorLeido = 200; 
         }
         
         
         newData.add(valorLeido); 
         
       } catch (Exception e) {} 
    }
    
    // Solo actualizamos si llegaron los 300 datos completos y no estamos en pausa
    if (newData.size() == maxSamples && estadoActual != Estado.PAUSADO) {
      ecgData = newData;
    }
  }
}

void keyPressed() {
  if (myPort == null) return;
  if (key == 'M' || key == 'm') myPort.write("IM\n");
  else if (key == 'P' || key == 'p') myPort.write("P\n");
  else if (key == 'G' || key == 'g') myPort.write("G\n");
}

