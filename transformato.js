/*** Archivos ***/
const leerCarpeta = require('./Utilerias/OperadoresArchivos/leerCarpeta')

/*** Operadores de archivos ***/
const filtro = require('./Utilerias/OperadoresArchivos/filtrarArchivos')
const pcrArchivos = require('./Utilerias/OperadoresArchivos/procesadorArchivos')
const recodificar = require('./Utilerias/Codificacion/contenidoRecodificado')

/*** Operadores de cadena ***/
const regEx  = require('./Utilerias/RegEx/jsonRgx')

const carpeta = 'Archivos\\'

function clsContenidoIntelisis (texto) {
    texto = regEx.jsonReplace.clsComentariosSQL(texto)
    texto = regEx.jsonReplace.clsPoliticas(texto)
    texto = regEx.jsonReplace.clsTextoBasura(texto)
    return texto
}

leerCarpeta.obtenerArchivos(carpeta)
    .then(archivos => {
        filtro.filtrarExtension(archivos).forEach(archivo => {
            pcrArchivos.crearArchivo(
                'Testing\\'+ archivo.replace(regEx.expresiones.nomArchivoEnRuta, ''),
                clsContenidoIntelisis(
                    recodificar.extraerContenidoRecodificado(archivo)
                )
            )
        })
    })
    .catch(e => console.error(e))