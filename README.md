Trabajo Final: Electrocardiograma con Arduino
Integrantes: Crespo Lautaro, Polvoreda Juan Pablo
![sddefault](https://github.com/user-attachments/assets/9c469f0e-1dd4-4b16-af0d-0d46659e5386)

🧠Proyecto: Monitor de Electrocardiograma (ECG) con Arduino y Processing.
Este proyecto desarrolla un sistema de bajo costo para adquisición y visualización de la señal eléctrica del corazón (ECG) utilizando hardware de código abierto y un entorno de programación visual.

🌟 Objetivo Principal.
Implementar una cadena de adquisición de datos biométricos que permita capturar la señal cardíaca, acondicionarla y representarla gráficamente en tiempo real en una computadora, simulando un monitor de ECG médico.

⚙️ Elementos de Hardware UtilizadosComponenteCantidadArduino Uno1Módulo Sensor AD8232 Ritmo Cardiaco C/3 Electrodos1Cables Dupont5Cable USB-B a USB-A1Pulsadores3Resistencias de $10\text{K}\ \Omega$3

💻 Software y Flujo de Trabajo
El proyecto se divide en dos entornos de programación que trabajan de forma conjunta:

1. Código en Arduino (Firmware)
Función: Lee continuamente la señal analógica acondicionada proveniente del pin de salida del módulo AD8232.

Proceso: Convierte el valor analógico a un número digital y lo envía de manera constante al puerto serial de la computadora a una velocidad de baudios específica.

2. Código en Processing (Visualización)
Función: Actúa como la interfaz gráfica de usuario (GUI).

Proceso:

Establece la comunicación serial con el Arduino.

Recibe los datos digitales enviados por el Arduino.

Utiliza estos datos para dibujar la gráfica del ECG en tiempo real en la pantalla, moviendo la forma de onda de izquierda a derecha.
