//Utility class for encryption. I am using bcrypt for hashing
const bcrypt = require("bcrypt")

//Synchronous hash generation
function generateHash(password){
    const salt = bcrypt.genSaltSync(6) //Generate salt with a medium level of difficulty (1-15, the higher the more difficult)
    const hashedPassword = bcrypt.hashSync(password, salt) //Hash the password
    return hashedPassword;
}
//Synchronous checking if password and hash matches
function passwordCheck(password, hash ){
    return bcrypt.compareSync(password,hash)
}
module.exports={generateHash,passwordCheck}