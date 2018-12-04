const fs = require('fs')
const path = require('path')
const chardet = require('chardet')
const Filequeue = require('filequeue')
const fq = new Filequeue(1000)   // Maximo de numero de archivos abiertos a la vez
const carpeta= 'Archivos/'
const nuevaCarpeta= 'ArchivosNEW/'
//const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100/'
//const nuevaCarpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/NuevoSQL3100/'


function comrprobar (carpeta, archivos) {
  archivos.map(function(archivo) {
    return path.join(process.cwd(), carpeta, archivo)
  }).filter(function(archivo) {
    return fs.statSync(archivo).isFile()
  }).forEach(function(archivo) {
    //filtrarExtension(archivos)
    let codificacionFinal = detectarCodificacion(carpeta, archivo)
    let contenido = leerArchivo(carpeta, archivo, codificacionFinal)
    remplazarTexto(nuevaCarpeta, archivo, transformar(contenido), codificacionFinal)
  })
}

function leerArchivo (carpeta, archivo, codificacionFinal) {
  let texto = ''
  fq.readFile(carpeta + archivo, codificacionFinal, function(err, data) {
    if (err) {
      console.log('error: ', err)
    } else {
      texto = data
    }
  })
  return texto
}

function transformar () {
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

function remplazarTexto (nuevaCarpeta, archivo, contenido, codificacionFinal) {
  fq.writeFile(nuevaCarpeta+archivo, transformar(contenido), c, function(err) {
    if (err) {
      return console.log(err)
    }
    console.log(contador++ +'.- ' + archivo + ' - CODIFICACION INICIAL: ' + 
      codificacionInicial + ' - CODIFICACION FINAL: ' + codificacionFinal + ' ...¡Guardado!')
  })
}


function detectarCodificacion (carpeta, archivo) {
  if (comprobar(archivo) == 'Archivo') {
    let codificacionInicial = chardet.detectFileSync(carpeta + archivo)
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
}

function filtrarExtension (archivos) {
  return archivos.filter(archivo => /.\.txt|\.sql|\.vis|\.frm|\.esp|\.tbl|\.rep|\.dlg$/i.test(archivo))
}

fs.readdir(carpeta, function(error, archivos) {
  if (error) throw error
  comrprobar(carpeta, archivos)
})