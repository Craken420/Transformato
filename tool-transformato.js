var Filequeue = require('filequeue');
var fq = new Filequeue(1000)// max number of files to open at once

const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100/';
const nuevaCarpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/NuevoSQL3100/'

fq.readdir(carpeta, function (err, files) {
  if (err) {
    throw err
  }
  let counter = 0
  files.forEach(function (file) {
    let texto = ''
    fq.readFile(carpeta + file, 'utf-16le', function(err, data) {
      if (err) {
        console.log('error: ', err)
      } else {
        texto = data
      }
      texto= texto.replace(/\/\*([^*]*)(|(([*]+[^*]+)*?))\*\//g, '')
      texto = texto.replace(/(\-\-+).*/gm,'')
      texto = texto.replace(/with\(nolock\)|with \(nolock\)/mig, '')
      texto= texto.replace(/\/(\*)+(|\n+.*)([^*]*(?:\*(?!)[^*]*)*(\*+)(\/))/g, '')
      texto = texto.replace(/with\(rowlock\)|with \(rowlock\)/mig, '')
      texto = texto.replace(/((?=[\ \t])|^\s+|$)+/mg, '')
      texto = texto.replace(/\t/mg, ' ')
      texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
      texto = texto.replace(/((?=\s(\@|\(|\=|\<|\>|\[|\]|\*|\.|\&|\,|\'|\-|\,\@|\]\(|\#|\=\@|\(\@|\/|\+|\s\w+\+|\w+)))|((?=\n)|\s)/gm, '')
      fq.writeFile(nuevaCarpeta+file, texto, 'utf-16le', function (err) {
        if (err) {
          return console.log(err)
        }
        console.log("The file was saved!" + counter++)
      })
    })
  })
})
