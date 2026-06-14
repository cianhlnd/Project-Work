const mongoose = require("mongoose");
//Connect to database
mongoose.connect('mongodb+srv://Cian:Project@footballcoachinghub.dh8i5rt.mongodb.net/test',
  {
    useNewUrlParser: true,
    useUnifiedTopology: true
  }
);
const db = mongoose.connection;
//If database connection fails
db.on("error", console.error.bind(console, "MongoDB failed connection: "));
//If database connects
db.once("open", function () {
  console.log("MongoDB Connected successfully");
});
module.exports = {db}