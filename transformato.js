const fs = require('fs')
const path = require('path')
const R = require('ramda')

const { DrkBx } = require('./DarkBox/index')

const cleanContnt= R.pipe(
    DrkBx.sql.cls.ansis,
    DrkBx.sql.cls.withNo,
    DrkBx.sql.cls.mLineComments,
    DrkBx.sql.cls.lineComments,
    DrkBx.mix.cls.tab,
    DrkBx.mix.cls.iniEndSpace,
    DrkBx.mix.cls.onlyOneSpace,
    DrkBx.intls.add.cmpEnterInHead
)

const write = R.curry( (cod, pathFile) => {
    fs.writeFileSync(
        'Data\\' + DrkBx.mix.cls.pthRoot(pathFile), cleanContnt(
            DrkBx.mix.fls.recode(cod)(pathFile)
        ),
        cod
    )
    return {
        file: DrkBx.mix.cls.pthRoot(pathFile),
        status: true
    }
})

/*** ¡¡¡ For save in the original file !!! ***/

// const write = R.curry( (cod, pathFile) => {
//     fs.writeFileSync(
//         pathFile, cleanContnt(
//             DrkBx.mix.fls.recode(cod)(pathFile)
//         ),
//         cod
//     )
//     return {
//         file: DrkBx.mix.cls.pthRoot(pathFile),
//         status: true
//     }
// })

const proccessFile = pathFile => {
    if ( path.extname(pathFile) == '.sql' ) { return write( 'utf16le' )( pathFile ) }
    else { return write( 'latin1' )( pathFile ) }
}

const proccessDirFiles = R.pipe(
    DrkBx.mix.fls.getFiltFls,
    R.map(proccessFile)
)

const conctRootEsp = R.curry( (files, root) => R.map( file => root + file, files ) )
const conctAndProcsFls = R.pipe( conctRootEsp, R.map(proccessFile) )

/* Usage */
const dirRep = 'C:\\Users\\lapena\\Documents\\Luis Angel\\Sección Mavi\\Intelisis\\Intelisis5000\\Reportes MAVI\\'
const dirOrig = 'C:\\Users\\lapena\\Documents\\Luis Angel\\Sección Mavi\\Intelisis\\Intelisis5000\\Codigo Original\\'

/* Folder and extentions of the files */
console.log(
    proccessDirFiles(
        ['.sql','.vis','.frm','.esp','.tbl','.rep','.dlg'],
        'Testing\\'
    )
)

/* Array of indicate files */
// console.log(
//     conctAndProcsFls([
//         'dbo.ActClave.Table.sql',
//         'dbo.AnexoCta.Table.sql',
//         'dbo.AjusteAnual.StoredProcedure.sql',
//         'AlmacenesVenta.frm'

//     ], 'Testing\\')
// )

/* One file */
// console.log(proccessFile('Testing\\dbo.AjusteAnual.StoredProcedure.sql'))

module.exports.tranformato = {
    conctRootAndProcsFls: conctAndProcsFls,
    procsDirFiles: proccessDirFiles,
    procsFile: proccessFile
}