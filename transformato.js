/*** Archivos ***/
const leerCarpeta = require('./Utilerias/OperadoresArchivos/leerCarpeta')

/*** Operadores de archivos ***/
const filtro = require('./Utilerias/OperadoresArchivos/filtrarArchivos')
const pcrArchivos = require('./Utilerias/OperadoresArchivos/procesadorArchivos')
const recodificar = require('./Utilerias/Codificacion/contenidoRecodificado')

/*** Operadores de cadena ***/
const regEx  = require('./Utilerias/RegEx/jsonRgx')

const carpeta = 'Archivos\\'

function clsContenidoBasura (texto) {
    texto = regEx.Borrar.clsComentariosSQL(texto)
    texto = regEx.Borrar.clsEspacioEntrePalabras(texto)
    texto = regEx.Borrar.clsPoliticas(texto)
    texto = regEx.Borrar.clsTextoBasura(texto)
    return texto
}

leerCarpeta.obtenerArchivos(carpeta)
    .then(archivos => {
        filtro.filtrarExtension(archivos).forEach(archivo => {
            pcrArchivos.crearArchivo(
                'Testing\\'+ regEx.Borrar.clsRuta(archivo),
                clsContenidoBasura(
                    recodificar.extraerContenidoRecodificado(archivo)
                )
            )
        })
    })
    .catch(e => console.error(e))