// Incluimos nuestra libreria
#include "Pulsador.h"

#define LOMENOS 11
#define LOMAS 10
#define SIGNAL A0

const int TAM_DE_MEMORIA = 300;

//creo los objetos
Pulsador btnInicio(2);
Pulsador btnPausa(3);
Pulsador btnGuardar(4);


int ECG_Almacenamiento[TAM_DE_MEMORIA];
int Posicion = 0;
String inputString = "";
boolean stringComplete = false;
unsigned long Retardo_medicion = 15; 
unsigned long TiempoAnterior = 0;

enum Estado {
   INICIO, MEDICION, PAUSAR_MEDICION, GUARDAR_MEDICION
};
Estado estadoActual = INICIO;

void setup() {
  Serial.begin(9600);
  inputString.reserve(200); //Reservamos memoria

  //inicializo los objetos
  btnInicio.inicializar();
  btnPausa.inicializar();
  btnGuardar.inicializar();
  
  pinMode(LOMENOS, INPUT);   
  pinMode(LOMAS, INPUT);
  pinMode(SIGNAL, INPUT); 
}

//Lectura de comandos seriales
void loop() {
  if (stringComplete) {
    if (inputString == "IM") estadoActual = MEDICION;
    else if (inputString == "P") estadoActual = PAUSAR_MEDICION;
    else if (inputString == "G") estadoActual = GUARDAR_MEDICION;
    inputString = "";
    stringComplete = false;
  }

  // Cambio de estados
  if (btnInicio.fuePresionado()) {
    Serial.println("IM");
    Posicion= 0;
    estadoActual = MEDICION;
    }
  if (btnPausa.fuePresionado()) estadoActual = PAUSAR_MEDICION;
  if (btnGuardar.fuePresionado()) estadoActual = GUARDAR_MEDICION;

unsigned long TiempoActual = millis();

    switch (estadoActual) {
      case MEDICION:
        if (TiempoActual - TiempoAnterior >= Retardo_medicion) {
        TiempoAnterior = TiempoActual;

        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED");
          estadoActual = INICIO;
        } else {
          ECG_Almacenamiento[Posicion] = analogRead(SIGNAL);
          Posicion++;

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
      }
      break;

      case PAUSAR_MEDICION:
        Posicion = 0;
        Serial.println("P");
        estadoActual = INICIO; 
        break;

      case GUARDAR_MEDICION:
        Serial.println("G");
        estadoActual = INICIO; 
        break;
      
      default: break;
    
  }
}

//no se llama, junta caracteres que llegan por Serial y los va agregando a inputString
void serialEvent() {
  while (Serial.available()) {         // Mientras haya caracteres disponibles...
    char inChar = (char)Serial.read(); // Leer un carácter
    if (inChar != '\n')                // Si no es un salto de línea
      inputString += inChar;           // Lo agregamos a la cadena
    else
      stringComplete = true;           // Cadena completa lista para procesar
  }
}
