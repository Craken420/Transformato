const fs = require('fs')
const util = require('util')
const path = require('path')
var replaceExt = require('replace-ext')
//const chardet = require('chardet')
const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100';
const nuevaCarpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/NuevoSQL3100'
//const carpeta = 'Archivos'
//const nuevaCarpeta = 'ArchivosTransformados'
const leerCarpeta = util.promisify(fs.readdir)

async function leerArchivosXLinea (archivo) {
  return new Promise(resolve => {
    let texto = ''
    const etiqueta = `Se leyo el archivo- ${archivo} y tardo`
    let extension = path.extname(archivo)
    let codificacion;
    if(!extension == '.sql')
    {
      codificacion = 'utf-8'
    }
    else{
      codificacion = 'utf-16le'
    }
    console.time(etiqueta)
    
    //chardet.detectFile(carpeta + '/' + archivo, function(err, encodin) {
    console.log('Codificacion antes de leer el archivo x linea:  ' + codificacion)
    const stream = fs.createReadStream(carpeta + '/' + archivo, {encoding: codificacion})
    stream.on('data', data => {
      texto += data
      stream.destroy()
    })
    stream.on('close', () => {
      transformar (texto, archivo, codificacion)
      console.timeEnd(etiqueta)
      resolve()
    })
    //})
  })
}

function remplazar (texto, archivo, codificacion) {
  console.log('Codifiacion recivida para remplazar el texto: ' + codificacion)
  var nuevaRuta = replaceExt(archivo, '.txt');
  let writeStream = fs.createWriteStream(nuevaCarpeta + '/' + nuevaRuta)
  writeStream.write(texto, codificacion)
  writeStream.on('finish', () => {
    console.log('Se escribio todo el documento')
  })
  writeStream.end()
}

function transformar (texto, archivo, codificacion) {
  texto = texto.replace(/(\/\*((\s+)(\n).*?|(\n).*?|.*?)(|(\s+)(\n).*?|(\n).*?)+(\*\/|\/\*.*?\*\/(.*(\n))+\*\/)|--.*)/gm,'')
  texto = texto.replace(/with\(nolock\)|with \(nolock\)/mig,'')
  texto = texto.replace(/with\(rowlock\)|with \(rowlock\)/mig,'')
  texto = texto.replace(/((?=[\ \t])|^\s+|$)+/mg,'')
  texto = texto.replace(/\t/mg,' ')
  texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '') 
  remplazar(texto, archivo, codificacion)
}

async function procesarArchivos(archivos) {
  for (let archivo of archivos) {
    console.log('Archivo leido en procesar:  ' + archivo);
    await leerArchivosXLinea(archivo)
  }
}

leerCarpeta(carpeta).then(archivos => {
  procesarArchivos(archivos.filter(archivo => /.\.sql|\.vis|\.frm|\.esp|\.tbl|\.rep|\.dlg$/i.test(archivo)))
  //procesarArchivos(archivos)
});
