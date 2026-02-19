var mongoose = require('mongoose');
var Schema   = mongoose.Schema;
const {generateHash, passwordCheck} =  require('../encryptUtility.js')
//https://stackoverflow.com/questions/32642130/reference-one-model-to-a-user-model-in-express-using-mongoose Reference
//https://stackoverflow.com/questions/14588032/mongoose-password-hashing

//Schema for a user 
const UserSchema = new Schema({
    username: {
        type: String, 
        required: true, 
        index: {unique: true, dropDups: true}
    },
    email:{
        type: String,
        required: true,
        index: {unique: true, dropDups: true}
    },
    password: {type: String, required: true},
});

//Ensures password is hashed before saving, make sure not to use save for updating
UserSchema.pre('save',function(next){
    if (typeof this.email === 'string' || this.email instanceof String){
        this.email = this.email.toUpperCase();
    }
    if (!this.isModified('password')){ //don't rehash password 
        next();
    };
    if(this.isModified('password')){
        this.password = generateHash(this.password); //hash password prior to saving
    }
    next();
});

module.exports = mongoose.model('Users',UserSchema, 'users')