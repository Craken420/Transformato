const fs = require('fs')
const R = require('ramda')

const { DrkBx } = require('./DarkBox/index')

const pathFile = 'Testing\\dbo.AjusteAnual.StoredProcedure.sql'

const proccess = R.pipe(
    DrkBx.mix.fls.getTxtInOrgnCod,
    DrkBx.sql.cls.ansis,
    DrkBx.sql.cls.withNo,
    DrkBx.sql.cls.mLineComments,
    DrkBx.sql.cls.lineComments,
    DrkBx.mix.cls.tab,
    DrkBx.mix.cls.iniEndSpace,
    DrkBx.mix.cls.onlyOneSpace,
    DrkBx.mix.cls.emptyLinesJs

)

fs.writeFileSync('Data\\' + DrkBx.mix.cls.pthRoot(pathFile), proccess(pathFile), 'utf16le')
// 
console.log(proccess(pathFile))