
class GestorArchivos {        //Definimos la clase
  
  private String nombreBase;
  
  public GestorArchivos(String nombre) {    //constructor
    this.nombreBase = nombre;
  }
  

  public void guardar(ArrayList<Float> datos, String infoPaciente, String nombrePacienteParaArchivo) {         //Metodo
    
    if (datos.size() == 0) {
      println("No hay datos para guardar.");
      return;
    }

    String[] lineas = new String[datos.size() + 1];
    
   
    String fechaHora = year() + "-" + month() + "-" + day() + " " + hour() + ":" + minute() + ":" + second();
    lineas[0] = "FECHA: " + fechaHora + "\n" + infoPaciente + "\n--- DATOS ECG ---";

    // 2. Datos numéricos
    for (int i = 0; i < datos.size(); i++) {
      String valor = str(datos.get(i)).replace(".", ",");
      lineas[i + 1] = valor; 
    }
    
    
    // Quitamos espacios y caracteres raros para que Windows no de error al crear el archivo
    String nombreLimpio = nombrePacienteParaArchivo.trim(); 
    nombreLimpio = nombreLimpio.replaceAll("[^a-zA-Z0-9]", "_"); // Reemplaza símbolos raros por guión bajo
    
 
    String nombreArchivo = nombreLimpio + "_" + year() + "-" + month() + "-" + day() + "_" + hour() + "-" + minute() + "-" + second() + ".csv";

    saveStrings(nombreArchivo, lineas); //función de Processing para guardar archivos
    println("--> Archivo guardado: " + nombreArchivo);
  }
}



