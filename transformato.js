
const replac = require('replace-in-file');
/*** Sub-modulos ***/

/* Operadores de archivos */
const { leerCarpetaFiltrada } = require('./Utilerias/OperadoresArchivos/readDirOnlyFile')

const regEx  = require('./Utilerias/RegEx/jsonRgx')
const { detectarCodificacion } = require('./Utilerias/Codificacion/procesadorCodificacion')

const carpeta = 'Testing\\'

const options = {
    files: null,
    from: null,
    to: '',
    encoding: '',
}

async function replaceAsync (options) {
    try {
    const changes = await replac(options)
    console.log('Archivos modificados:', regEx.Borrar.clsRuta(changes.join(', ')))
    }
    catch (error) {
    console.error('Error occurrido:', error);
    }
}

function limpiar (archivo, codificacion) {
    options.files = archivo
    options.encoding = codificacion
    options.from = [
       regEx.Expresiones.comentarioSQLVacio,
       regEx.Expresiones.comentarioSQLSencillo, 
       regEx.Crear.comentarioSQLMedio(), 
       regEx.Expresiones.comentarioSQLAvanzado, 
       regEx.Expresiones.comentarioSQLDobleGuion,
       regEx.Crear.ansis(),
       regEx.Crear.witchNolock(),
       regEx.Expresiones.saltoLineaVacio,
       regEx.Expresiones.ampersand
       //regEx.Crear.espaciosEntrePalabras(),
   ]
   options.to = ''

   replaceAsync(options)

   options.files = archivo
   options.from = regEx.Expresiones.tabulador,
   options.to = ' '
   replaceAsync(options)
}

leerCarpetaFiltrada(carpeta, ['.sql','.vis','.frm','.esp','.tbl','.rep','.dlg'])
    .then(archivos => {
        archivos.forEach(archivo => limpiar(archivo, (detectarCodificacion(archivo) == 'ISO-8859-1')  ? 'ascii' : detectarCodificacion(archivo)))
    })