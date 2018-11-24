/*** Módulo para trabajar con el sistema de archivos en la computadora. ***/
const fs = require('fs');

/*** Modulo para las funciones de utilidad ***/
const util = require('util');

/*** Carpeta que contiene los archivos ***/
//const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100';
const carpeta = 'Archivos'

/*** Convierte la función callback-based a una Promise-based. ***/
const leerCarpeta = util.promisify(fs.readdir);

/***
 * Funcion asincrona que lee los archivos linea por linea.
 * @archivo. - archivo extraido de la ruta de la carpeta.
***/ 
async function leerArchivosXLinea (archivo) {
  return new Promise(resolve => {
    let texto = '';
    const etiqueta = `Se leyo el archivo- ${archivo} y tardo`;
    console.time(etiqueta);
      const stream = fs.createReadStream(carpeta + '/' + archivo, {encoding: 'utf-8'});
      stream.on('data', data => {
        texto += data;
        stream.destroy();
      });
      stream.on('close', () => {
        transformar (texto, archivo)
        console.timeEnd(etiqueta);
        resolve();
      });
    //});
  });
}

/***
 * Se ingresa la carpeta de archivos para extraerlos filtrando la terminacion .sql
 * @carpeta. - Ruta de la carpeta
***/
function remplazar (texto, archivo) {
  let writeStream = fs.createWriteStream(carpeta + '/' + archivo);

  /*** Escribe el archivo***/
  writeStream.write(texto);

  /*** El evento final se emite cuando todos los datos se han vaciado del flujo ***/
  writeStream.on('finish', () => {  
    console.log('Se escribio todo el documento');
  });

  /*** Fin del Stream ***/ 
  writeStream.end();  
}

/***
 * Aplica expresiones regulares que remplazan ciertos patrones de texto.
 * @archivo. - archivo extraido de la ruta de la carpeta.
 * @texto. - cadena con el contenido del archivo
***/ 
function transformar (texto, archivo) {

  /*** Quitar comentarios ***/
  texto = texto.replace(/(\/\*((\s+)(\n).*?|(\n).*?|.*?)(|(\s+)(\n).*?|(\n).*?)+(\*\/|\/\*.*?\*\/(.*(\n))+\*\/)|--.*)/gm,'')

  /*** Quitar With (NoLock) y With (RowLock) ***/
  texto = texto.replace(/with\(nolock\)|with \(nolock\)/mig,'')
  texto = texto.replace(/with\(rowlock\)|with \(rowlock\)/mig,'')

  /*** Quita los saltos de linea y espacios del comienzo ***/
  texto = texto.replace(/((?=[\ \t])|^\s+|$)+/mg,'')

  /*** Quita la tabulacion ***/
  texto = texto.replace(/\t/mg,' ')

  /***
   *Quita los espacios de mas entre las palabras reduciéndolos a 1 (incluye algunos caracteres especiales)
   *Quita los espacios del fin de la linea
  ***/ 
  texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
  
  remplazar(texto, archivo)
}

/***
 * Funcion asincrona que procesa los archivos.
 * @archivos. - archivos extraidos de la ruta de la carpeta.
***/ 
async function procesarArchivos(archivos) {
  for (let archivo of archivos) {
    console.log('Archivo leido en procesar:  ' + archivo);
    /*** Await permite entrar en fase de espera continuando con la funcionalidad ***/
    await leerArchivosXLinea(archivo);
  }
}

/***
 * Se ingresa la carpeta de archivos para extraerlos filtrando la terminacion .sql
 * @carpeta. - ruta de la carpeta.
 * @archivos. - toma el valor de los archivos
 * Se aplica filtro para extensiones predeterminadas
***/
leerCarpeta(carpeta).then(archivos => {
  procesarArchivos(archivos.filter(archivo => /.\.sql|\.vis|\.frm|\.esp|\.tbl|\.rep|\.dlg$/i.test(archivo)))
  //procesarArchivos(archivos);
});
