/*** Módulo para trabajar con el sistema de archivos en la computadora. ***/
const fs = require('fs')

/*** Modulo para las funciones de utilidad ***/
const util = require('util')


/*** Carpeta que contiene los archivos ***/
//const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100';
const carpeta = 'Archivos'

/*** Convierte la función callback-based a una Promise-based. ***/
const leerCarpeta = util.promisify(fs.readdir)

/***
 * Funcion asincrona que lee los archivos linea por linea.
 * @archivo. - archivo extraido de la ruta de la carpeta.
***/ 
async function leerArchivosXLinea (archivo) {
  return new Promise(resolve => {
    let texto = ''
    const etiqueta = `Se leyo el archivo - ${archivo} y tardo`
    console.time(etiqueta)
    const stream = fs.createReadStream(carpeta + '/' + archivo, {encoding: 'utf8'})
    stream.on('data', data => {
      texto += data
      console.log(data)
      stream.destroy()
    });
    stream.on('close', () => {
      remplazar(texto, archivo)
      console.timeEnd(etiqueta)
      resolve()
    })
  })
}

/***
 * Se ingresa la carpeta de archivos para extraerlos filtrando la terminacion .sql
 * @carpeta. - Ruta de la carpeta
***/
function remplazar (texto, archivo) {
  fs.writeFile(carpeta + '/' + archivo + '.txt', texto, function (err) {
    if (err) return console.log(err)
  })
}

/***
 * Funcion asincrona que procesa los archivos.
 * @archivos. - archivos extraidos de la ruta de la carpeta.
***/ 
async function procesarArchivos (archivos) {
  for (let archivo of archivos) {
    console.log(archivo)
    await leerArchivosXLinea(archivo)
  }
}

/***
 * Se ingresa la carpeta de archivos para extraerlos filtrando la terminacion .sql
 * @carpeta. - uta de la carpeta.
***/
leerCarpeta(carpeta).then(archivos => {
    //procesarArchivos(archivos.filter(archivo => /.\.sql/.test(archivo)));
    procesarArchivos(archivos)
})
