import processing.serial.*;
import javax.swing.*; //libreria de java para ventanas emergentes

// Usamos libreria propia
GestorArchivos miArchivo; 

Serial myPort;
PImage miImagen; //imagen del corazon

// Se calculan dinámicamente según el tamaño de la ventana
float btnX1, btnX2, btnX3;
float btnY, btnW, btnH;
float graphX, graphY, graphW, graphH;
float tamTextoTitulo, tamTextoNormal;

// Texto que aparece dentro de los Botones
String label1 = "INICIAR";
String label2 = "PAUSAR"; 
String label3 = "GUARDAR";

// Datos y Estados
ArrayList<Float> ecgData = new ArrayList<Float>();  //vector donde se almacenan las 300 muestras que manda Arduino
int maxSamples = 300;
float rangoMin = 0;   
float rangoMax = 1023;
enum Estado { ESPERANDO, MIDIENDO, PAUSADO, DESCONECTADO }
Estado estadoActual = Estado.ESPERANDO; //estado inicial

// variable para los Mensajes Emergentes
String mensajeTemporal = "";
float tiempoMensaje = 0;
float duracionMensaje = 2500;

void setup() {
  
  size(1000, 700); 
  surface.setResizable(true); //funcion para hacer la ventana redimensionable
  
  miImagen = loadImage("corazon.jpg");  //cargamos la imagen del corazon
  
  // Creamos el objeto
  miArchivo = new GestorArchivos("Datos_ECG");

  println(Serial.list());  //Imprime todos los puertos COM detectados.
  try {
 
    myPort = new Serial(this, "COM3", 9600); 
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("Error: Arduino no conectado.");
  }
}

// Funcion de calculo de las posiciones redimensionables
void recalcularInterfaz() {
  //utilizamos el ancho y el alto de la ventana y le asignamos un porcentaje
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

//Funcion de dibujado principal
void draw() {

  recalcularInterfaz();
  
  background(255, 242, 242); //color de fondo

 //Titulo principal
  fill(0);  //color
  textSize(tamTextoTitulo); //tamaño segun la ventana
  textAlign(CENTER); //centramos el texto
  text("Electrocardiógrafo", width / 2, height * 0.10);   
 
  if (miImagen != null) {
    float imgSize = height * 0.1;            //tamaño y posicion de la imagen
    image(miImagen, width - imgSize*4 , 20, 150, imgSize);
  }

//texto que indica el estado
  textSize(tamTextoNormal);
  textAlign(LEFT);
  float estadoY = graphY - 15; 
  
  switch (estadoActual) {  //Segun el estado, el texto que "imprime"

    case DESCONECTADO: fill(255, 0, 0); text("Electrodos desconectados", graphX, estadoY); break;
    case MIDIENDO:     fill(0, 150, 0); text("Midiendo señal...", graphX, estadoY); break;
    case PAUSADO:      fill(0, 0, 150); text("Visualización Pausada", graphX, estadoY); break;
    default:           fill(150, 0, 0); text("Esperando inicio...", graphX, estadoY); break;
  }

  // Dibujamos los botones
  drawButton(btnX1, btnY, btnW, btnH, label1);
  drawButton(btnX2, btnY, btnW, btnH, label2);
  drawButton(btnX3, btnY, btnW, btnH, label3);
  
  drawGraph();  //Dibuja el grafico del ECG
  
  // Mensajes emergentes o flotantes
  if (millis() - tiempoMensaje < duracionMensaje) {   //Mientras el tiempo sea menor a 2,5s muestra el mensaje

    pushStyle();             //Guarda el estilo gráfico actual
    rectMode(CENTER);  //dibuja el rectangulo desde el centro
    fill(0, 0, 0, 150);  //color de fondo
    noStroke();  //sin bordes
    rect(width / 2, height / 2, width * 0.5, height * 0.1, 15); //dibuja el rectangulo

    //Escribe el texto dentro del rectangulo
    fill(255);        
    textSize(tamTextoNormal * 1.5);
    textAlign(CENTER, CENTER);           
    text(mensajeTemporal, width / 2, height / 2);
    popStyle(); //Restaura el estilo gráfico
  }
}

void ejecutarAccion(Estado nuevoEstado) {
    
    // Evita ejecutar lógica compleja si el estado no cambia
    if (estadoActual == nuevoEstado && nuevoEstado != Estado.DESCONECTADO) {
        return;
    }
           
    switch (nuevoEstado) {
        
        case MIDIENDO:
            // Envia comando de INICIO a Arduino
            if (myPort != null) myPort.write("IM\n");
            
            // Limpiar datos solo si se inicia desde cero (no si se reanuda desde PAUSADO)
            if (estadoActual == Estado.ESPERANDO || estadoActual == Estado.DESCONECTADO) { 
                ecgData.clear();
            }        
            mensajeTemporal = (estadoActual == Estado.PAUSADO) ? "Reanudando Medición" : "Iniciando Medición...";
            break;
            
        case PAUSADO:
            //Envia comando de PAUSA a Arduino
            if (myPort != null) myPort.write("P\n");           
            mensajeTemporal = "Visualización Pausada";
            break;
            
        case DESCONECTADO:
            //El comando viene de arduino
            mensajeTemporal = "¡Electrodos Desconectados!";
            break;
            
        case ESPERANDO:
            // Estado por defecto.
            mensajeTemporal = "Esperando la señal de inicio...";
            break;
    }
    
    //  Aplicar el nuevo estado 
    estadoActual = nuevoEstado;
    tiempoMensaje = millis(); // Reiniciar el temporizador del mensaje flotante
}

//Botones  con el mouse
void mousePressed() {   
    if (mouseY > btnY && mouseY < btnY + btnH) {    // Comprueba que el clic esté en la franja vertical donde están los botones
             if (mouseX > btnX1 && mouseX < btnX1 + btnW) {     // BOTÓN 1: INICIAR 
             ejecutarAccion(Estado.MIDIENDO);
        }

        else if (mouseX > btnX2 && mouseX < btnX2 + btnW) {    //BOTÓN 2: PAUSAR
            if (estadoActual == Estado.MIDIENDO) {
                ejecutarAccion(Estado.PAUSADO);
            } else if (estadoActual == Estado.PAUSADO) {
                ejecutarAccion(Estado.MIDIENDO); // Reanudar
            } }
        else if (mouseX > btnX3 && mouseX < btnX3 + btnW) {     // BOTÓN 3: GUARDAR 
           ejecutarAccion(Estado.PAUSADO);  // Se pausa primero para asegurar que los datos no cambien mientras se guardan
            realizarGuardadoConDatos();
        }
    }
}



// Funcion de Guardado
void realizarGuardadoConDatos() {
  if (ecgData == null || ecgData.size() == 0) {     // Validamos si hay datos
    mensajeTemporal = "¡No hay datos para guardar!";
    tiempoMensaje = millis();
    return; 
  }
//Si hay datos:
  Estado estadoPrevio = estadoActual;      //Guardamos el estado en que estaba
  estadoActual = Estado.PAUSADO;      // Pausamos la medicion
  String[] resultado = pedirDatosPaciente();      //Pedimos los datos del paciente, abriendo una ventana
  
  if (resultado != null) {               //si no es null(si el usuario no cancelo)
     String infoCompleta = resultado[0];      //datos del paciente
     String nombreSolo = resultado[1];        //nombre del archivo
     miArchivo.guardar(ecgData, infoCompleta, nombreSolo);  //Llamamos al metodo del objeto
     mensajeTemporal = "Guardado: " + nombreSolo;
  } else {
     mensajeTemporal = "Guardado cancelado";
  }
    tiempoMensaje = millis(); 
  if (estadoPrevio == Estado.MIDIENDO) estadoActual = Estado.MIDIENDO;  //Si antes estaba midiendo, sigue midiendo
}

// Funcion de Ventana emergente, para pedir datos
String[] pedirDatosPaciente() {
  JPanel panel = new JPanel();
  panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS)); //Crear el panel vertical

//Creamos los campos de texto:
  JTextField nombreField = new JTextField(15);
  JTextField edadField = new JTextField(5);
  JTextField dniField = new JTextField(10);
  JTextField antecedenteField = new JTextField(20);

 //Agregamos etiquetas + campos a llenar
  panel.add(new JLabel("Nombre y Apellido (Nombre de Archivo):"));
  panel.add(nombreField);
  panel.add(new JLabel("Edad:"));
  panel.add(edadField);
  panel.add(new JLabel("DNI:"));
  panel.add(dniField);
  panel.add(new JLabel("Antecedentes Médicos:"));
  panel.add(antecedenteField);

//Abrimos la ventana emergente
  int result = JOptionPane.showConfirmDialog(null, panel, 
               "Guardar ECG - Datos del Paciente", JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);   //botones de ok y cancelar

  if (result == JOptionPane.OK_OPTION) {   //Si el usuario presiona ok
    String nombre = nombreField.getText();
    if (nombre.trim().length() == 0) nombre = "Paciente_Sin_Nombre"; //Validamos, si el paciente no coloco nombre se pone uno

//Contruccion del texto
    String info = "PACIENTE: " + nombre + "\n" +
                  "EDAD: " + edadField.getText() + "\n" +
                  "DNI: " + dniField.getText() + "\n" +
                  "ANTECEDENTES: " + antecedenteField.getText();
    
    return new String[] { info, nombre };
  } else {        //si cancelo:
    return null;
  }
}

//  FUNCIONES DE DIBUJO
void drawButton(float x, float y, float w, float h, String label) {  //Dibujo un boton
  pushStyle(); 
  if (mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h) fill(200, 200, 255);  //si el mouse esta encima cambia el color
  else fill(220);
  stroke(0); 
  rect(x, y, w, h, 10);     //dibuja el rectangulo del boton sin bordes
  fill(0); 
  textSize(tamTextoNormal);  //texto del boton
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


//Comunicacion serial con Arduino

void serialEvent(Serial myPort) {
    String inString = myPort.readStringUntil('\n');  //cada vez que Arduino envía algo terminado en \n
    if (inString == null) return;   //Leemos la linea
    inString = trim(inString);
    
    if (inString.equals("IM")) {
         ejecutarAccion(Estado.MIDIENDO);    //cambia de estado a Midiendo
        
    } else if (inString.equals("ED")) {
        ejecutarAccion(Estado.DESCONECTADO);    //cambia de estado a Desconectado
        
    } else if (inString.equals("P")) {
        ejecutarAccion(Estado.PAUSADO);    //cambia de estado a Pausado
        
    } else if (inString.equals("G")) {
        // Arduino envió comando para Guardar (inicia el proceso de guardado)
        realizarGuardadoConDatos();

   //RECEPCIÓN DE DATOS ECG
     } else if (inString.startsWith("<") && inString.endsWith(">")) {     //Los datos vienen con la forma: <512,520,530, ... , 490>
    inString = inString.substring(1, inString.length() - 1);             //Le quitamos < >
    String[] values = split(inString, ',');                              //Y los separamos con una coma
    ArrayList<Float> newData = new ArrayList<Float>();
   
    for (String val : values) { 
       try { 
         float valorLeido = float(val);
           if (valorLeido < 200) {              // FILTRO: Invalidamos menores a 200 (valores anormales)
           valorLeido = 200; 
         }
         newData.add(valorLeido); 
    } catch (Exception e) {} 
    }
    
    if (newData.size() == maxSamples && estadoActual != Estado.PAUSADO) {    // Solo actualizamos si llegaron los 300 datos completos y no estamos en pausa
      ecgData = newData;
    }
  }
}










