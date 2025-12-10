//Declaracion de la clase pulsador
#ifndef PULSADOR_H //si ya se incluyo no se vuelve a incluir
#define PULSADOR_H

#include <Arduino.h>

class Pulsador {
private:
	int pin;
	int ultimoEstado;  //high o low
	
public:
	// Constructor
	Pulsador(int p);
	
	void inicializar();
	bool fuePresionado();
};


#endif


