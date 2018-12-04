// // const { readdir, stat } = require('fs').promises
// // const { join } = require('path')

// // const dirs = async p =>
// //   (await readdir(p)).filter(async f => (await stat(join(p, f))).isDirectory())

// //   console.log(dirs)


var fs = require("fs"),
path = require("path");
//your <MyFolder> path
var p = "Archivos"
fs.readdir(p, function (err, files) {
    if (err) {
        throw err;
    }
    //this can get all folder and file under  <MyFolder>
    files.map(function (file) {
        //return file or folder path, such as **MyFolder/SomeFile.txt**
        return path.join(p, file);
    }).filter(function (file) {
        file => /.\.txt|\.sql|\.vis|\.frm|\.esp|\.tbl|\.rep|\.dlg$/i.test(file).isFile()
        return fs.statSync(file).isFile();
    }).forEach(function (files) {
       
    });
});
