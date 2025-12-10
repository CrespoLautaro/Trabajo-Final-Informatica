#include "Pulsador.h"

// Constructor
Pulsador::Pulsador(int p) {     //de la forma, Clase::constructor
	pin = p;
	ultimoEstado = HIGH; 
}

// Configuracion del pin
void Pulsador::inicializar() {   
    pinMode(pin, INPUT_PULLUP); 
    ultimoEstado = HIGH;        
}
// Logica del boton
bool Pulsador::fuePresionado() {
	int estadoActual = digitalRead(pin);
	bool resultado = false;
	
	if (estadoActual == LOW && ultimoEstado == HIGH) {
		resultado = true;
		delay(50); // Anti-rebote
	}
	
	ultimoEstado = estadoActual;
	return resultado;

}


