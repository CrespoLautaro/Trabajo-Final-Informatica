// --- Definiciones y pines ---
#define LOMENOS 11
#define LOMAS 10
#define SIGNAL A0
const int PULSADOR1 = 2; // Iniciar
const int PULSADOR2 = 3; // Reiniciar
const int PULSADOR3 = 4; // Guardar
const int TAM_DE_MEMORIA = 50;

// --- Variables Globales ---
int ECG_Almacenamiento[TAM_DE_MEMORIA];
int Posicion = 0;
String inputString = "";
boolean stringComplete = false;
float Retardo_medicion = 50; // 50ms por muestra (20 Hz)
float TiempoAnterior = 0;

// Máquina de Estados de Arduino
enum Estado {
  INICIO_MEDICION,    // Estado temporal para chequear y enviar "IM"
  REINICIAR_MEDICION, 
  GUARDAR_MEDICION, 
  MIDIENDO_ACTIVA,    // ¡NUEVO ESTADO! Para tomar muestras
  INICIO              // Estado de reposo
};
Estado estadoActual = INICIO;

// Variables Anti-rebote para los botones
int ultimoPULSADOR1 = HIGH; // Inicia en HIGH porque usamos INPUT_PULLUP
int ultimoPULSADOR2 = HIGH;
int ultimoPULSADOR3 = HIGH;

// =======================================================
//  SETUP
// =======================================================
void setup() {
  Serial.begin(9600);
  inputString.reserve(200);

  // --- CONFIGURACIÓN DE PINES ---
  // Usamos INPUT_PULLUP para todos los botones y entradas de detección.
  // Esto significa que el pin está en HIGH (1) por defecto.
  // Cuando se presiona el botón o se conecta el electrodo, el pin es "jalado" a LOW (0).
  
  // Botones
  pinMode(PULSADOR1, INPUT); 
  pinMode(PULSADOR2, INPUT);
  pinMode(PULSADOR3, INPUT);
  
  // Detección de Electrodos (Leads-Off)
  pinMode(LOMENOS, INPUT);   
  pinMode(LOMAS, INPUT);
  
  // Pin de señal (Analógico)
  pinMode(SIGNAL, INPUT); 
}

// =======================================================
//  LOOP PRINCIPAL
// =======================================================
void loop() {
  
  // --- Comandos Seriales (desde Processing) ---
  if (stringComplete) {
    if (inputString == "IM") {
      estadoActual = INICIO_MEDICION;
    } else if (inputString == "R") {
      estadoActual = REINICIAR_MEDICION;
    } else if (inputString == "G") {
      estadoActual = GUARDAR_MEDICION;
    }
    inputString = "";
    stringComplete = false;
  }

  
  // --- Pulsadores Físicos (Lógica Anti-rebote para INPUT_PULLUP) ---

  int actualPULSADOR1 = digitalRead(PULSADOR1);
  int actualPULSADOR2 = digitalRead(PULSADOR2);
  int actualPULSADOR3 = digitalRead(PULSADOR3);

  // Comprobar PULSADOR1 (INICIAR)
  // Busca un flanco descendente (de HIGH a LOW)
  if (actualPULSADOR1 == LOW && ultimoPULSADOR1 == HIGH) {
    estadoActual = INICIO_MEDICION;
    delay(50); // Anti-rebote
  }

  // Comprobar PULSADOR2 (REINICIAR)
  if (actualPULSADOR2 == LOW && ultimoPULSADOR2 == HIGH) {
    estadoActual = REINICIAR_MEDICION;
    delay(50); 
  }

  // Comprobar PULSADOR3 (GUARDAR)
  if (actualPULSADOR3 == LOW && ultimoPULSADOR3 == HIGH) {
    estadoActual = GUARDAR_MEDICION;
    delay(50); 
  }

  // Guardar estado actual para la próxima iteración
  ultimoPULSADOR1 = actualPULSADOR1;
  ultimoPULSADOR2 = actualPULSADOR2;
  ultimoPULSADOR3 = actualPULSADOR3;


  // --- Temporizador y Máquina de Estados (se ejecuta cada 50ms) ---
  float TiempoActual = millis();
  if (TiempoActual - TiempoAnterior >= Retardo_medicion) {
    TiempoAnterior = TiempoActual;

    switch (estadoActual) {

      // ESTADO 1: INICIO MEDICIÓN (Chequeo)
      // Estado temporal que solo chequea los electrodos y pasa al siguiente estado.
      case INICIO_MEDICION:
        // Con INPUT_PULLUP, HIGH significa DESCONECTADO
        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED"); // Error: Electrodos Desconectados
          estadoActual = INICIO;  // Vuelve a esperar
        } else {
          // ¡Todo OK!
          Serial.println("IM"); // Envía "IM" (¡UNA SOLA VEZ!)
          Posicion = 0;           // Reinicia el contador de muestras
          estadoActual = MIDIENDO_ACTIVA; // ¡Pasa al estado de medición!
        }
        break;

      // ESTADO 2: MIDIENDO ACTIVA (Tomando muestras)
      // Este es el estado principal donde se toman y envían datos.
      case MIDIENDO_ACTIVA:
        // Chequea si los electrodos se caen MIENTRAS mide
        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED");
          estadoActual = INICIO; // Detiene la medición y vuelve a esperar
        } else {
          // Todo bien, sigue midiendo
          int Medicion = analogRead(SIGNAL);
          ECG_Almacenamiento[Posicion] = Medicion;
          Posicion++;

          // Si el buffer está lleno, enviarlo
          if (Posicion >= TAM_DE_MEMORIA) {
            Serial.print('<');
            for (int i = 0; i < TAM_DE_MEMORIA; i++) {
              Serial.print(ECG_Almacenamiento[i]);
              if (i < TAM_DE_MEMORIA - 1) Serial.print(',');
            }
            Serial.println(">");
            Posicion = 0;
            // IMPORTANTE: Se queda en estado MIDIENDO_ACTIVA
            // listo para el siguiente paquete de datos.
          }
        }
        break;

      // ESTADO 3: REINICIAR MEDICIÓN
      case REINICIAR_MEDICION:
        Posicion = 0;
        Serial.println("R");
        estadoActual = INICIO; // Vuelve al estado de espera
        break;

      // ESTADO 4: GUARDAR MEDICIÓN
      case GUARDAR_MEDICION:
        Serial.println("G");
        estadoActual = INICIO; // Vuelve al estado de espera
        break;
      
      // ESTADO 0: INICIO (Reposo)
      case INICIO:
      default:
        // No hacer nada, solo esperar un comando
        break;
    }
  }
}

// =======================================================
//  EVENTO SERIAL (para recibir comandos de Processing)
// =======================================================
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