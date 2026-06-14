const jwt = require('jsonwebtoken');
const UserModel = require('../models/user');
require("dotenv").config();

const authenticate = async (req, res, next) => {
    if (!req.cookies || !req.cookies.appjwt) {
        return res.status(401).json({error: "No authentication token"});
    }
    try {
        const tokenDecoded = jwt.verify(req.cookies.appjwt, process.env.Secret_Key);
        if (!tokenDecoded || !tokenDecoded.username) {
            return res.status(401).json({error: "Malformed or invalid token"});
        }
        const user = await UserModel.findOne({username: tokenDecoded.username});
        if (!user) {
            return res.status(401).json({error: "User does not exist"});
        }
        req.user = user;
        next();
    } catch(err) {
        res.status(401).json({error: "Malformed or invalid token"});
    }
};

module.exports = authenticate;