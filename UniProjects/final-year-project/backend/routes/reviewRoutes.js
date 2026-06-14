const express = require("express");
const ReviewModel = require('../models/review');
const authenticate = require('./authenticate');
var router = express.Router();

router.post("/submit", authenticate, async (req, res) => {
    const username = req.user.username; 
    const { imageName, rating } = req.body;

    try {
        // Check if the user has already submitted a review for the same image
        const existingReview = await ReviewModel.findOne({ username, imageName });
        if (existingReview) {
            return res.status(400).send({ message: "You have already reviewed this image" });
        }

        // If no review exists, proceed to save the new review
        const newReview = new ReviewModel({ username, imageName, rating });
        await newReview.save();
        res.status(201).send({ message: "Review submitted successfully" });
    } catch (error) {
        console.log(error);
        res.status(500).send({ message: "Error submitting review", error });
    }
});


// Get reviews and average rating for an image
router.get("/reviews/:imageName", async (req, res) => {
    const { imageName } = req.params;

    try {
        const reviews = await ReviewModel.find({ imageName });
        const averageRating = reviews.reduce((acc, review) => acc + review.rating, 0) / reviews.length;
        res.status(200).send({ reviews, averageRating: averageRating || 0 });
    } catch (error) {
        console.log(error);
        res.status(400).send({ message: "Error fetching reviews", error });
    }
});

module.exports = router;