import React, { useEffect, useState } from 'react';
import axios from 'axios';

function ReviewsDisplay({ imageName }) {
  const [averageRating, setAverageRating] = useState(0);

  useEffect(() => {
    const fetchReviews = async () => {
      try {
        const response = await axios.get(`http://localhost:3001/api/v1/reviews/reviews/${imageName}`, { withCredentials: true });
        setAverageRating(response.data.averageRating);
      } catch (error) {
        console.error('Error fetching reviews:', error);
      }
    };

    fetchReviews();
  }, [imageName]);

  return (
    <div>
      <h3>Average Rating: {averageRating.toFixed(1)}</h3>
    </div>
  );
}

export default ReviewsDisplay;