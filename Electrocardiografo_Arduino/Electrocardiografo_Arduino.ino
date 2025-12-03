//Definiciones y pines
#define LOMENOS 11
#define LOMAS 10
#define SIGNAL A0
const int PULSADOR1 = 2; //Iniciar
const int PULSADOR2 = 3; //Pausar
const int PULSADOR3 = 4; //Guardar
const int TAM_DE_MEMORIA = 300; //Buffer

//Variables globales
int ECG_Almacenamiento[TAM_DE_MEMORIA]; 
int Posicion = 0;
String inputString = ""; //
boolean stringComplete = false;
float Retardo_medicion = 50; //50ms de muestra(20 Hz)
float TiempoAnterior = 0;

//Maquina de estados de arduino
enum Estado {
  INICIO_MEDICION,    //Estado temporal para chequear y enviar "IM
  PAUSAR_MEDICION, 
  GUARDAR_MEDICION, 
  MIDIENDO_ACTIVA,    //Estado para tomar muestras
  INICIO              //Estado de reposo
};
Estado estadoActual = INICIO;

//Variables anti-rebote para los pulsadore
//Arrancan en HIGH porque usamos INPUT_PULLUP
int ultimoPULSADOR1 = HIGH; 
int ultimoPULSADOR2 = HIGH;
int ultimoPULSADOR3 = HIGH;

//setup
void setup() {
  Serial.begin(9600);
  inputString.reserve(200);
  
  //Pulsadores
  pinMode(PULSADOR1, INPUT); 
  pinMode(PULSADOR2, INPUT);
  pinMode(PULSADOR3, INPUT);
  
  //Deteccion de electrodos
  pinMode(LOMENOS, INPUT);   
  pinMode(LOMAS, INPUT);
  
  //Pin de señal (Analogico)
  pinMode(SIGNAL, INPUT); 
}

//Loop
void loop() {
  
  //Comandos seriales (desde processing)
  if (stringComplete) {
    if (inputString == "IM") {
      estadoActual = INICIO_MEDICION;
    } else if (inputString == "P") {
      estadoActual = PAUSAR_MEDICION;
    } else if (inputString == "G") {
      estadoActual = GUARDAR_MEDICION;
    }
    inputString = "";
    stringComplete = false;
  }

  //Pulsadores fisicos
  int actualPULSADOR1 = digitalRead(PULSADOR1);
  int actualPULSADOR2 = digitalRead(PULSADOR2);
  int actualPULSADOR3 = digitalRead(PULSADOR3);

  //Comprobar el Pulsador 1 (Iniciar)
  if (actualPULSADOR1 == LOW && ultimoPULSADOR1 == HIGH) {
    estadoActual = INICIO_MEDICION;
    delay(50); 
  }

  //Comprobar el Pulsador 2 (Reiniciar)
  if (actualPULSADOR2 == LOW && ultimoPULSADOR2 == HIGH) {
    estadoActual = PAUSAR_MEDICION;
    delay(50); 
  }

  //Comprobar el Pulsador 3 (Guardar)
  if (actualPULSADOR3 == LOW && ultimoPULSADOR3 == HIGH) {
    estadoActual = GUARDAR_MEDICION;
    delay(50); 
  }

  //Guarda el estado actual para la próxima interación
  ultimoPULSADOR1 = actualPULSADOR1;
  ultimoPULSADOR2 = actualPULSADOR2;
  ultimoPULSADOR3 = actualPULSADOR3;


  //Temporizador y maquina de Estados
  float TiempoActual = millis();
  if (TiempoActual - TiempoAnterior >= Retardo_medicion) {
    TiempoAnterior = TiempoActual;

    switch (estadoActual) {
      
      //ESTADO 1: Inicio de medicion (Chequeo)
      //Estado temporal que solo chequea los electrodos y pasa al siguiente estado
      case INICIO_MEDICION:
        //Con INPUT_PULLUP, HIGH significa desconectado
        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED"); //Error: electrodos desconectados
          estadoActual = INICIO; 
        } else {
          Serial.println("IM"); //Envia IM
          Posicion = 0; //Reinicia el contador de muestras
          estadoActual = MIDIENDO_ACTIVA; //pasa al estado de medicion
        }
        break;

      //ESTADO 2: Tomando muestras
      //estado principal donde se toman y envian losdatos
      case MIDIENDO_ACTIVA:
        //Chequea si los electrodos se desconectan en la medicion
        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED");
          estadoActual = INICIO; //Detiene la medición ycomienza de vuelta
        } else {
          int Medicion = analogRead(SIGNAL);
          ECG_Almacenamiento[Posicion] = Medicion;
          Posicion++;

          //Si el buffer esta lleno, se envia
          if (Posicion >= TAM_DE_MEMORIA) {
            Serial.print('<');
            for (int i = 0; i < TAM_DE_MEMORIA; i++) {
              Serial.print(ECG_Almacenamiento[i]);
              if (i < TAM_DE_MEMORIA - 1) Serial.print(',');
            }
            Serial.println(">");
            Posicion = 0;
          }
        }
        break;

      // ESTADO 3: Reiniciar medicion
      case PAUSAR_MEDICION:
        Posicion = 0;
        Serial.println("P");
        estadoActual = INICIO; //Vuelve al estado de espera
        break;

      // ESTADO 4: Guardar medicion
      case GUARDAR_MEDICION:
        Serial.println("G");
        estadoActual = INICIO; //Vuelve al estado de espera
        break;
      
      // ESTADO 0: Inicio
      case INICIO:
      default:
        // No hacer nada, solo esperar un comando
        break;
    }
  }
}
// serialEvent(para recibir comandos de Processing)
void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    if (inChar != '\n') {
      inputString += inChar;
    } else {
      stringComplete = true;
    }
  }
}

