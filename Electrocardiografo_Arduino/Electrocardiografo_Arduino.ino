// Incluimos nuestra libreria
#include "Pulsador.h"

#define LOMENOS 11
#define LOMAS 10
#define SIGNAL A0

const int TAM_DE_MEMORIA = 300;


Pulsador btnInicio(2);
Pulsador btnPausa(3);
Pulsador btnGuardar(4);


int ECG_Almacenamiento[TAM_DE_MEMORIA];
int Posicion = 0;
String inputString = "";
boolean stringComplete = false;
float Retardo_medicion = 4; 
float TiempoAnterior = 0;

enum Estado {
  INICIO_MEDICION, PAUSAR_MEDICION, GUARDAR_MEDICION, MIDIENDO_ACTIVA, INICIO
};
Estado estadoActual = INICIO;

void setup() {
  Serial.begin(9600);
  inputString.reserve(200); //Reservamos memoria
  
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
    if (inputString == "IM") estadoActual = INICIO_MEDICION;
    else if (inputString == "P") estadoActual = PAUSAR_MEDICION;
    else if (inputString == "G") estadoActual = GUARDAR_MEDICION;
    inputString = "";
    stringComplete = false;
  }

  // CÓDIGO LIMPIO GRACIAS A LA LIBRERÍA
  if (btnInicio.fuePresionado()) estadoActual = INICIO_MEDICION;
  if (btnPausa.fuePresionado()) estadoActual = PAUSAR_MEDICION;
  if (btnGuardar.fuePresionado()) estadoActual = GUARDAR_MEDICION;

  // Lógica de Tiempos y Estados
  float TiempoActual = millis();
  if (TiempoActual - TiempoAnterior >= Retardo_medicion) {
    TiempoAnterior = TiempoActual;

    switch (estadoActual) {
      case INICIO_MEDICION:
        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED");
          estadoActual = INICIO; 
        } else {
          Serial.println("IM");
          Posicion = 0; 
          estadoActual = MIDIENDO_ACTIVA; 
        }
        break;

      case MIDIENDO_ACTIVA:
        if (digitalRead(LOMENOS) == HIGH || digitalRead(LOMAS) == HIGH) {
          Serial.println("ED");
          estadoActual = INICIO; 
        } else {
          int Medicion = analogRead(SIGNAL);
          ECG_Almacenamiento[Posicion] = Medicion; // Guardamos la medición en el buffer
          Posicion++;
          
          if (Posicion >= TAM_DE_MEMORIA) {
            Serial.print('<');  // Enviamos todo en formato <v1,v2,v3,...>
            for (int i = 0; i < TAM_DE_MEMORIA; i++) {
              Serial.print(ECG_Almacenamiento[i]);
              if (i < TAM_DE_MEMORIA - 1) Serial.print(',');
            }
            Serial.println(">");
            Posicion = 0;
          }
        }
        break;

      case PAUSAR_MEDICION:
        Posicion = 0; Serial.println("P"); estadoActual = INICIO; 
        break;

      case GUARDAR_MEDICION:
        Serial.println("G"); estadoActual = INICIO; 
        break;
      
      default: break;
    }
  }
}

void serialEvent() {
  while (Serial.available()) {         // Mientras haya caracteres disponibles...
    char inChar = (char)Serial.read(); // Leer un carácter
    if (inChar != '\n')                // Si no es un salto de línea
      inputString += inChar;           // Lo agregamos a la cadena
    else
      stringComplete = true;           // Cadena completa lista para procesar
  }
}
