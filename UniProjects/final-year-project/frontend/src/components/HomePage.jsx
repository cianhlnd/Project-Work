import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import '../styles/Home.css';

function HomePage() {
  const navigate = useNavigate();
  const [isLoginView, setIsLoginView] = useState(true);
  const [formData, setFormData] = useState({
    username: '',
    email: '',
    password: '',
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const endpoint = isLoginView ? 'http://localhost:3001/api/v1/public/login' : 'http://localhost:3001/api/v1/public/register';
    try {
      const response = await axios.post(endpoint, formData, {
        withCredentials: true,
      });

      if (isLoginView) {
        if (response.status === 200 && response.data.message === 'Authenticated') {
          console.log('User logged-in successfully:', response.data);
          navigate('/profile');
        } else {
          console.error('Login failed:', response.data.message);
        }
      } else {
        if (response.status === 201) {
          console.log('User registered successfully:', response.data);
          navigate('/profile');
        } else {
          console.error('Registration failed:', response.data.message);
        }
      }
    } catch (error) {
      console.error(isLoginView ? 'Login failed:' : 'Registration failed:', error.message);
    }
  };

  const togglePosition = isLoginView ? '0px' : '110px';

  return (
    <div className="form-box">
      <div className="button-box">
        <div id="btn" style={{ left: togglePosition }}></div>
        <button type="button" className="toggle-btn" onClick={() => setIsLoginView(true)}>Log In</button>
        <button type="button" className="toggle-btn" onClick={() => setIsLoginView(false)}>Register</button>
      </div>
      {isLoginView ? (
        <form className="input-group" onSubmit={handleSubmit} style={{ left: isLoginView ? '50px' : '-400px' }}>
        <input type="email" name="email" className="input-field" placeholder="email address" onChange={handleChange} value={formData.email} autoComplete="email" required />
        <input type="password" name="password" className="input-field" placeholder="password" onChange={handleChange} value={formData.password} autoComplete="current-password" required />
        <button type="submit" className="submit-btn">Login</button>
      </form>
      ) : (
      <form className="input-group" onSubmit={handleSubmit} style={{ left: isLoginView ? '450px' : '50px' }}>
        <input type="text" name="username" className="input-field" placeholder="username" onChange={handleChange} value={formData.username} autoComplete="off" required />
        <input type="email" name="email" className="input-field" placeholder="email address" onChange={handleChange} value={formData.email} autoComplete="off" required />
        <input type="password" name="password" className="input-field" placeholder="password" onChange={handleChange} value={formData.password} autoComplete="off" required />
        <button type="submit" className="submit-btn">Register</button>
      </form>
      )}
    </div>
  );
}

export default HomePage;
