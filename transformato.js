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
    // DrkBx.intls.add.cmpEnterInHead
)

const write = R.curry((cod, pathFile) => {
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

const proccessFile = pathFile => {
    if (path.extname(pathFile) == '.sql') {return write( /*DrkBx.mix.fls.dtcCod(pathFile)*/'utf16le' )( pathFile )}
    else {return write( 'latin1' )( pathFile )}
}

const proccessFiles = R.pipe(
    R.map(proccessFile)
)

/* Usage */
const dir = 'Testing\\'
const files = ['Testing\\dbo.AjusteAnual.StoredProcedure.sql']
const file = 'Testing\\dbo.AjusteAnual.StoredProcedure.sql'

console.log(proccessFiles(DrkBx.mix.fls.getFiltFls(['.sql','.vis','.frm','.esp','.tbl','.rep','.dlg'], dir)))
// console.log(proccessFiles(files))
// console.log(proccessFile(file))