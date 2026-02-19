import React from 'react';
import '../../styles/CourseList.css';

function CourseList ({ courses, searchTerm, onSearch }) {
  const filteredCourses = courses.filter((course) =>
    course.title.toLowerCase().includes(searchTerm.toLowerCase())||
    course.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
    course.date.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="course-list-container">
      <div className="courses-wrapper">
        {filteredCourses.map((course) => (
          <div key={course.id} className="course-container">
            <p>Title: {course.title}</p>
            <p>Location: {course.location}</p>
            <p>Date: {course.date}</p>
            <a href={course.link} target="_blank" rel="noopener noreferrer" className = "book-btn">
              Book Now
            </a>
          </div>
        ))}
      </div>
    </div>
  );
};

export default CourseList;
