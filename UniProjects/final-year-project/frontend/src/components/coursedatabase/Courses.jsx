import React, { useState } from 'react';
import CoursesDatabase from './CoursesDatabase';
import CourseSearch from './CourseSearch';
import CourseList from './CourseList';

function Courses() {
  const [searchTerm, setSearchTerm] = useState('');

  const handleSearch = term => {
    setSearchTerm(term);
  };

  return (
    <div>
      <CourseSearch onSearch={handleSearch} />
      <CourseList courses={CoursesDatabase} searchTerm={searchTerm} />
    </div>
  );
};

export default Courses;
