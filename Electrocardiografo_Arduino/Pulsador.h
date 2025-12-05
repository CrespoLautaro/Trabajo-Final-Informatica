#ifndef PULSADOR_H
#define PULSADOR_H

#include <Arduino.h>

class Pulsador {
private:
	int pin;
	int ultimoEstado;
	
public:
	// Constructor
	Pulsador(int p);
	
	void inicializar();
	bool fuePresionado();
};

#endif
