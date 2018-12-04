var Filequeue = require('filequeue');
var fs= require('fs')
//var fq = new Filequeue(1000)// max number of files to open at once
const chardet = require('chardet')
const path = require('path')
const carpeta= 'Archivos'
//const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100/';
//const nuevaCarpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/NuevoSQL3100/'
let counter = 1

fs.readdir(carpeta, function (err, files) {
  if (err) {
    throw err
  } files.map(function (file) {
    return path.join(carpeta, file);
}).filter(function (file) {
    return fs.statSync(file).isFile();
}).forEach(function (file) {
 
    let texto = ''
    let codi=''
    let codificacion = ''
      codificacion=chardet.detectFileSync(file)
      if(codificacion == 'ISO-8859-1'|codificacion == 'ISO-8859-2') {
        codi='ASCII'
      }else if(codificacion == 'UTF-8'){
        codi='UTF-8'
      } else if (codificacion == 'UTF-16LE'){
        codi='utf-16le'
      } else {
        codi = codificacion
      }
    fs.readFile(file, codi, function(err, data) {
      if (err) {
        console.log('error: ', err)
      } else {
        texto = data
      }
      texto= texto.replace(/\/(\*)+(|\n+.*)([^*]*(?:\*(?!)[^*]*)*(\*+)(\/))/g, '')
      texto= texto.replace(/\/\*([^*]*)(|[*]+|(([*]+[^*]+)*?))\*\//g, '')
      texto = texto.replace(/(\-\-+).*/gm,'')
      texto = texto.replace(/with\(nolock\)|with \(nolock\)/mig, '')
      texto = texto.replace(/with\(rowlock\)|with \(rowlock\)/mig, '')
      texto = texto.replace(/((?=[\ \t])|^\s+|$)+/mg, '')
      texto = texto.replace(/\t/mg, ' ')
      texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
      texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
    
      fs.writeFile(file, texto, codi, function (err) {
        if (err) {
          return console.log(err)
        }
        console.log("The file was saved!" + counter++ + ' CON LA CODIFICACION:   ' + codificacion + ' y la CODI: '+codi+'*************')
      })
    })
    console.log("%s", file);
   })
  
})
