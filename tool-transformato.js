const carpeta = 'Archivos/'
const util = require('util')
const fs = require('fs')
const replaceExt = require('replace-ext')
const leerCarpeta = util.promisify(fs.readdir)
let texto = ''

var readline = require('readline');
var stream = require('stream');

function leerArchivosXLinea (file){
  
  var instream = fs.createReadStream(carpeta+file, {encoding: 'utf-16le'});
  var outstream = new stream;
  var readStream = readline.createInterface(instream, outstream);
  readStream.on('line', function(line){
      texto += line + '\n'
  })
  readStream.on('close', () => {
    transformar (texto, file)
  });
 
}

function remplazar (texto, file) {
  console.log('Se remplazara')
  var nuevaRuta = replaceExt(file, '.txt');
  fs.writeFile(carpeta+'/'+nuevaRuta, texto, {encoding: 'utf-16le'},function (err) { 
    if (err) return console.log(err);
  }); 
}

function transformar (texto, archivo) {
  texto = texto.replace(/\/(\*)+([^*]*(?:\*(?!)[^*]*)*(\*+)(\/))/gm,'')
  texto = texto.replace(/\/(\*)+([^*]*(?:\*(?!)[^*]*)*(\*+)(\/))/gm,'')
  texto = texto.replace(/\-\-+.*/gm,'')
  texto = texto.replace(/with\(nolock\)|with \(nolock\)/mig,'')
  texto = texto.replace(/with\(rowlock\)|with \(rowlock\)/mig,'')
  texto = texto.replace(/((?=[\ \t])|^\s+|$)+/mg,'')
  texto = texto.replace(/\t/mg,' ')
  texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '') 
  remplazar(texto, archivo)
}

/***
 * Funcion asincrona que procesa los archivos.
 * @archivos. - archivos extraidos de la ruta de la carpeta.
***/ 
async function procesarArchivos(archivos) {
  for (let archivo of archivos) {
    console.log(archivo);
    await leerArchivosXLinea(archivo);
  }
}

/***
 * Se ingresa la carpeta de archivos para extraerlos filtrando la terminacion .sql
 * @carpeta. - uta de la carpeta.
***/
leerCarpeta(carpeta).then(archivos => {
  //procesarArchivos(archivos.filter(archivo => /.\.sql/.test(archivo)));
  procesarArchivos(archivos);
})
