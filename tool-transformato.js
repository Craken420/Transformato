var Filequeue = require('filequeue');
var fq = new Filequeue(1000)// max number of files to open at once
const chardet = require('chardet')
const carpeta= 'Archivos/'
//const carpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/SQL3100/';
//const nuevaCarpeta = 'C:/Users/lapena/Documents/Luis Angel/Intelisis/NuevoSQL3100/'

fq.readdir(carpeta, function (err, files) {
  if (err) {
    throw err
  }
  let counter = 0
  files.forEach(function (file) {
    let texto = ''
    let codi=''
    let codificacion=chardet.detectFileSync(carpeta+file);
     if(codificacion == 'ISO-8859-1'|codificacion == 'ISO-8859-2'){
      
       codi='ASCII'
       console.log('ASCII Codificacion OBTENIDA:  '+codificacion + '   Codi:  ' + codi)
     }else if(codificacion == 'UTF-8'){
      
        codi='UTF-8' 
        console.log('utf-8 Codificacion:  '+codificacion + '   Codi:  ' + codi)
     } else if (codificacion == 'UTF-16LE'){
     
        codi='UTF-16LE' 
        console.log('utf16Le Codificacion:  '+codificacion + '   Codi:  ' + codi)
     } else {
      
       codi = codificacion
       console.log('El que sea Codificacion:  '+codificacion + '   Codi:  ' + codi)
     }
    fq.readFile(carpeta + file, codi, function(err, data) {
      if (err) {
        console.log('error: ', err)
      } else {
        console.log('Se leeyo el archivo CON LA CODIFICACION:   ' + codi + '  *************')
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
      fq.writeFile(carpeta+file, texto, codi, function (err) {
        if (err) {
          return console.log(err)
        }
        console.log("The file was saved!" + counter++ + ' CON LA CODIFICACION:   ' + codi + '  *************')
      })
    })
  })
})
