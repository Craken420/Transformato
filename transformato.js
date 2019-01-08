const fs = require('fs')
const path = require('path')
const iconvlite = require('iconv-lite')
const Filequeue = require('filequeue')
const fq = new Filequeue(1000) // Maximo de numero de archivos abiertos a la vez


// const carpeta= 'Archivos\\'
// const nuevaCarpeta= 'ArchivosNEW\\'
const carpeta = 'C:\\Users\\lapena\\Documents\\Luis Angel\\Intelisis\\SQL3100\\'
const nuevaCarpeta = 'C:\\Users\\lapena\\Documents\\Luis Angel\\Intelisis\\NuevoSQL3100\\'

let contador = 0
const recodificacion        = 'Latin1'

const jsonRegEx = {
  'clsComentarioVacio':       /\/\*+\*+\//g,
  'clsComentarioSencillo':    /\/\*+([^/]*)\*+\//g,
  'clsComentarioMedio':       /\/(\*+)(|\n+.*)(|[^*]*)(|(?:\*(?!)(|[^*]*)(|[*]+[^*]+))*?)\*+\//g,
  'clsComentarioAvanzado':    /\/(\*+)([^*]*)(|[*]+|(([*]+[^*]+)*?))(\*+)\//g,
  'clsComentariosDobleGuion': /(\-\-+).*/gm,
  'clsAnsis':      /SET(|[\s]+)ANSI(|[\s]+|\_)NULLS(|[\s]+)(ON|OFF)|SET(|[\s]+)QUOTED(|[\s]+|\_)IDENTIFIER(|[\s]+)(ON|OFF)/gi,
  'clsWithNolock': /(\s+|\n+|\s+\n+)with(|\s+|\n+|\s+\n+)\((|\s+|\n+|\s+\n+)(rowlock|nolock)(|\s+|\n+|\s+\n+)\)/mig,
  'clsSaltoLinea': /((?=[\ \t])|^\s+|$)+/mg,
  'clsTabulador':  /\t/mg,
  'clsAmpersand':  /\&/g,
  'clsEspaciosEntrePalabras': /((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm,
  'reducirRuta':    /.*\\/,
  'metodos': {
    'limpiarComentarios': (texto) => {
      texto = texto.replace(jsonRegEx.clsComentarioVacio, '').replace(jsonRegEx.clsComentarioSencillo, '')
      texto = texto.replace(jsonRegEx.clsComentarioMedio, '').replace(jsonRegEx.clsComentarioAvanzado, '')
      texto = texto.replace(jsonRegEx.clsComentariosDobleGuion, '')
      return texto
    },
    'limpiarPoliticas': texto => { return texto.replace(jsonRegEx.clsAnsis, '').replace(jsonRegEx.clsWithNolock, '')},
    'limpiarRuta': ruta => { return ruta.replace(jsonRegEx.reducirRuta, '')},
    'limpiarTexto':     texto => { 
      texto = texto.replace(jsonRegEx.clsSaltoLinea, '').replace(jsonRegEx.clsTabulador, ' ')
      texto = texto.replace(jsonRegEx.clsEspaciosEntrePalabras, '').replace(jsonRegEx.clsAmpersand, '')
      return texto
    }
  }
}

function comprobar (carpeta, archivos) {
  contador = 0
  let contador2 = 0
  filtrarExtension(archivos).map(archivo => {

    console.log(contador++ + ' .- Filtrando --', jsonRegEx.metodos.limpiarRuta(archivo))
    return path.join(carpeta, archivo)

  }).filter(archivo => {
      return fs.statSync(archivo).isFile()

  }).forEach(archivo => {

    remplazarTexto (archivo, transformar(recodificar(archivo, recodificacion, contador2++)))
  })
}

function filtrarExtension (archivos) {
  return archivos.filter(archivo => /\.sql|\.vis|\.frm|\.esp|\.tbl|\.rep|\.dlg$/i.test(archivo))
}

function transformar (texto) {
  texto = jsonRegEx.metodos.limpiarComentarios(texto)
  texto = jsonRegEx.metodos.limpiarPoliticas(texto)
  texto = jsonRegEx.metodos.limpiarTexto(texto)
  return texto
}

function recodificar(archivo, recodificacion, contador2) {
  console.log(contador2 + ' .- Recodificando --', jsonRegEx.metodos.limpiarRuta(archivo))
  return iconvlite.decode(fs.readFileSync(archivo), recodificacion)
}

function remplazarTexto (archivo, texto) {
  contador = 0
  let newPath = nuevaCarpeta + jsonRegEx.metodos.limpiarRuta(archivo)

  fq.writeFile(newPath, texto, err => {
      if (err)  return console.log(err)
      console.log(contador++ + ' .- Guardando --', jsonRegEx.metodos.limpiarRuta(archivo))
  })
}

fs.readdir(carpeta, (error, archivos) => {
  if (error) throw error

  comprobar(carpeta, archivos)
})