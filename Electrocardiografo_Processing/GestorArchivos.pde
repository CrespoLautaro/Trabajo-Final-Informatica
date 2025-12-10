
class GestorArchivos {        //Definimos la clase
  
  private String nombreBase;
  
  public GestorArchivos(String nombre) {    //constructor
    this.nombreBase = nombre;
  }
  

  public void guardar(ArrayList<Float> datos, String infoPaciente, String nombrePacienteParaArchivo) {         //Metodo
    
    if (datos.size() == 0) {                                    //Verificamos si hay datos
      println("No hay datos para guardar.");
      return;
    }

    String[] lineas = new String[datos.size() + 1];          //Creamos un array de Strings para escribir el archivo
    
   
    String fechaHora = year() + "-" + month() + "-" + day() + " " + hour() + ":" + minute() + ":" + second();      //Usamos funciones de Processing para obtener fecha/hora del sistema.
    lineas[0] = "FECHA: " + fechaHora + "\n" + infoPaciente + "\n--- DATOS ECG ---";

    // Agrega todos los datos ECG línea por línea
    for (int i = 0; i < datos.size(); i++) {
      String valor = str(datos.get(i)).replace(".", ",");     //Reemplazamos puntos por comas para que lo pueda leer Excell
      lineas[i + 1] = valor; 
    }
    
    
    // Quitamos espacios y caracteres raros para que Windows no de error al crear el archivo
    String nombreLimpio = nombrePacienteParaArchivo.trim(); 
    nombreLimpio = nombreLimpio.replaceAll("[^a-zA-Z0-9]", "_"); // Funcion que cualquier cosa que NO sea:A–Z, a–z, 0–9 lo reemplaza por _
    
    String nombreArchivo = nombreLimpio + "_" + year() + "-" + month() + "-" + day() + "_" + hour() + "-" + minute() + "-" + second() + ".csv";    //Armamos el nombre del Archivo

    saveStrings(nombreArchivo, lineas); //función de Processing para guardar archivos
    println("--> Archivo guardado: " + nombreArchivo); //mensaje final de que se guardo bien y donde
  }
}




