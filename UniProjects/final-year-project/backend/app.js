const express = require("express");
var bodyParser = require('body-parser')
var cookieParser = require('cookie-parser');
const db = require('./DBConnection')
var app = express();
app.use(bodyParser.json())
const port = 3001;
app.use(cookieParser())
const cors = require('cors');
app.use(cors({
    origin: ['http://localhost:3000'],
    credentials: true
}));
var apiRoutes = require("./routes/apiRoutes");
var authApiRoutes = require("./routes/authApiRoutes");
var reviewRoutes = require("./routes/reviewRoutes");
app.use("/api/v1/public",apiRoutes);
app.use("/api/v1/user",authApiRoutes);
app.use("/api/v1/reviews", reviewRoutes);
app.listen(port, () => { 
    console.log(`App is listening on port ${port}`);
});