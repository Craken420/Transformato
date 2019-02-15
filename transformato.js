/*** Operadores de archivos ***/
const pcrArchivos = require('./Utilerias/OperadoresArchivos/procesadorArchivos')
const recodificar = require('./Utilerias/Codificacion/contenidoRecodificado')

const { leerCarpetaFiltrada } = require('./Utilerias/OperadoresArchivos/readDirOnlyFile')

/*** Operadores de cadena ***/
const regEx  = require('./Utilerias/RegEx/jsonRgx')

const carpeta = 'Testing\\'

function clsContenidoBasura (texto) {
    texto = regEx.Borrar.clsComentariosSQL(texto)
    texto = regEx.Borrar.clsEspacioEntrePalabras(texto)
    texto = regEx.Borrar.clsPoliticas(texto)
    texto = regEx.Borrar.clsTextoBasura(texto)
    return texto
}

leerCarpetaFiltrada(carpeta, ['.vis','.frm','.esp','.tbl','.rep','.dlg', '.sql'])
    .then(archivos => {
        archivos.forEach(archivo => {
            pcrArchivos.crearArchivo(
                'Testing\\'+ regEx.Borrar.clsRuta(archivo),
                clsContenidoBasura(
                    recodificar.extraerContenidoRecodificado(archivo)
                )
            )
        })
    })
    .catch(e => console.error(e))