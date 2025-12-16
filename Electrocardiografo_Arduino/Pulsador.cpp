#include "Pulsador.h"
unsigned long ultimoTiempo;
  const unsigned long debounce = 30;
// Constructor
Pulsador::Pulsador(int p) {     //de la forma, Clase::constructor
	pin = p;
	ultimoEstado = HIGH; 
}

// Configuracion del pin
void Pulsador::inicializar() {   
    pinMode(pin, INPUT_PULLUP); 
    ultimoEstado = digitalRead(pin);        
}
// Logica del boton
bool Pulsador::fuePresionado() {
	int estadoActual = digitalRead(pin);
	bool resultado = false;
	unsigned long tiempoAhora = millis();

	if (estadoActual == LOW && ultimoEstado == HIGH) {
		// Solo aceptamos la pulsación si pasaron más de 50ms desde la última
     if (tiempoAhora - ultimoTiempo > retardoantirrebote) {
         resultado = true;
         ultimoTiempo = tiempoAhora; // Actualizamos el cronómetro
        }
		}
	
	ultimoEstado = estadoActual;
	return resultado;

}
