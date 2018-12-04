const fs = require('fs')
const path = require('path')
const chardet = require('chardet')
const Filequeue = require('filequeue')
const fq = new Filequeue(1000)   // Maximo de numero de archivos abiertos a la vez
const carpeta= 'Archivos/'
const nuevaCarpeta= 'ArchivosNEW/'
//const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100/'
//const nuevaCarpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/NuevoSQL3100/'
let contador = 1

function comprobar (carpeta, archivos) {
  let archivosFiltrados = filtrarExtension(archivos)
  archivosFiltrados.map(function(archivo) {
    return path.join(process.cwd(), carpeta, archivo)
  }).filter(function(archivo) {
    return fs.statSync(archivo).isFile()
  }).forEach(function(archivo) {
    let codificacionFinal = detectarCodificacion(archivo)
    let contenido = leerArchivo(archivo, codificacionFinal)
    remplazarTexto(archivo, transformar(contenido), codificacionFinal)
  })
}

function leerArchivo (archivo, codificacionFinal) {
  let texto = ''
  fq.readFile(archivo, codificacionFinal, function(err, data) {
    if (err) {
      console.log('error: ', err)
    } else {
      texto = data
    }
  })
  return texto
}

function transformar (texto) {
  texto = texto.replace(/\/(\*)+(|\n+.*)([^*]*(?:\*(?!)[^*]*)*(\*+)(\/))/g, '')
  texto = texto.replace(/\/\*([^*]*)(|[*]+|(([*]+[^*]+)*?))\*\//g, '')
  texto = texto.replace(/(\-\-+).*/gm, '')
  texto = texto.replace(/with\(nolock\)|with \(nolock\)/mig, '')
  texto = texto.replace(/with\(rowlock\)|with \(rowlock\)/mig, '')
  texto = texto.replace(/((?=[\ \t])|^\s+|$)+/mg, '')
  texto = texto.replace(/\t/mg, ' ')
  texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
  texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
  return texto
}

function remplazarTexto (archivo, contenido, codificacionFinal) {
  fq.writeFile(nuevaCarpeta+archivo.replace(/.*?(\\\w+)+\\/g, ''), transformar(contenido), codificacionFinal, function(err) {
    if (err) {
      return console.log(err)
    }
    console.log(contador++ +'.- ' + archivo.replace(/.*?(\\\w+)+\\/g, '') + ' - CODIFICACION FINAL: ' + codificacionFinal + ' ...¡Guardado!')
  })
}


function detectarCodificacion (archivo) {
  let codificacionInicial = ''
  codificacionInicial  = chardet.detectFileSync(archivo)
  if (codificacionInicial == 'ISO-8859-1' | codificacionInicial == 'ISO-8859-2' | codificacionInicial == 'ISO-8859-9') {
    return 'ASCII'
  } else if (codificacionInicial == 'UTF-8') {
    return 'UTF-8' 
  } else if (codificacionInicial == 'UTF-16LE') {
    return 'UTF-16LE' 
  } else {
    return codificacionInicial
  }
}

function filtrarExtension (archivos) {
  return archivos.filter(archivo => /.\.txt|\.sql|\.vis|\.frm|\.esp|\.tbl|\.rep|\.dlg$/i.test(archivo))
}

fs.readdir(carpeta, function(error, archivos) {
  if (error) throw error
  comprobar(carpeta, archivos)
})