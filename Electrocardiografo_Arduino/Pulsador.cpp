#include "Pulsador.h"

// Constructor
Pulsador::Pulsador(int p) {
	pin = p;
	ultimoEstado = HIGH; 
}

// Configuraci�n del pin
void Pulsador::inicializar() {
    pinMode(pin, INPUT_PULLUP); // <--- CAMBIO CLAVE
    ultimoEstado = HIGH;        // Asumimos que arranca sin pulsar (HIGH por el pullup)
}
// L�gica del bot�n
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
