import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';
import './styles/Navbar.css';
import HomePage from './components/HomePage';
import reportWebVitals from './reportWebVitals';
import Profile from './components/Profile';
import Courses from './components/coursedatabase/Courses';
import U8sDribblingSession from './components/sessionplans/u8s-u9s/u8sDribblingSession';
import U8sDefendingSession from './components/sessionplans/u8s-u9s/u8sDefendingSession';
import U8sPassingSession from './components/sessionplans/u8s-u9s/u8sPassingSession';
import U8sShootingSession from './components/sessionplans/u8s-u9s/u8sShootingSession';
import U10sDribblingSession from './components/sessionplans/u10s-u11s/u10sDribblingSession';
import U10sDefendingSession from './components/sessionplans/u10s-u11s/u10sDefendingSession';
import U10sPassingSession from './components/sessionplans/u10s-u11s/u10sPassingSession';
import U10sShootingSession from './components/sessionplans/u10s-u11s/u10sShootingSession';
import U12sDribblingSession from './components/sessionplans/u12s/u12sDefendingSession';
import U12sDefendingSession from './components/sessionplans/u12s/u12sDefendingSession';
import U12sPassingSession from './components/sessionplans/u12s/u12sPassingSession';
import U12sShootingSession from './components/sessionplans/u12s/u12sShootingSession';
import FiveASide from './components/formations/5-a-side';
import SevenASide from './components/formations/7-a-side';
import NineASide from './components/formations/9-a-side';
import About from './components/About';

// Navbar component
const menuItems = [
  { name: "Profile", link: "/profile" },
  { name: "Courses", link: "/courses" },
  {
    name: "Coaches Corner",
    submenu: [
      {
        name: "Formations",
        submenu: [
          { name: "5-a-side", link: "/coaches-corner/formations/5-a-side" },
          { name: "7-a-side", link: "/coaches-corner/formations/7-a-side" },
          { name: "9-a-side", link: "/coaches-corner/formations/9-a-side" },
        ],
      },
      {
        name: "Session Plans",
        submenu: [
          {
            name: "u8s-u9s",
            submenu: [
              { name: "Defending", link: "/coaches-corner/session-plans/u8s/defending" },
              { name: "Dribbling", link: "/coaches-corner/session-plans/u8s/dribbling" },
            ]
          },
          {
            name: "u10s-u11s",
            submenu: [
              { name: "Defending", link: "/coaches-corner/session-plans/u10s/defending" },
            ]
          }
        ]
      }
    ],
  },
  { name: "About", link: "/about" },
];

function Navbar() {
  const renderMenuItems = (items) => {
    if (!Array.isArray(items)) {
      console.error('Expected an array, but received:', items);
      return null;
    }

    return items.map((item) => (
      <li key={item.name}>
        {item.link ? <Link to={item.link}>{item.name}</Link> : item.name}
        {item.submenu && Array.isArray(item.submenu) && (
          <ul>
            {renderMenuItems(item.submenu)}
          </ul>
        )}
      </li>
    ));
  };

  return (
    <nav>
      <ul>
        {renderMenuItems(menuItems)}
      </ul>
    </nav>
  );
}

export default Navbar;

// App component
function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Home and registration routes without Navbar */}
        <Route index element={<HomePage />} />
        <Route path="/homepage" element={<HomePage />} />
        <Route
          path="/profile"
          element={
            <div>
              <Navbar />
              <Profile />
            </div>
          }
        />
        <Route
          path="/courses"
          element={
            <div>
              <Navbar />
              <Courses />
            </div>
          }
        />
        <Route
          path="/coaches-corner/*"
          element={
            <div>
              <Navbar />
              <Routes>
                <Route path="formations/5-a-side" element={<FiveASide />} />
                <Route path="formations/7-a-side" element={<SevenASide />} />
                <Route path="formations/9-a-side" element={<NineASide />} />
                <Route path="session-plans/u8s/dribbling" element={<U8sDribblingSession />} />
                <Route path="session-plans/u8s/defending" element={<U8sDefendingSession />} />
                <Route path="session-plans/u8s/shooting" element={<U8sShootingSession />} />
                <Route path="session-plans/u8s/passing" element={<U8sPassingSession />} />
                <Route path="session-plans/u10s/dribbling" element={<U10sDribblingSession />} />
                <Route path="session-plans/u10s/defending" element={<U10sDefendingSession />} />
                <Route path="session-plans/u10s/shooting" element={<U10sShootingSession />} />
                <Route path="session-plans/u10s/passing" element={<U10sPassingSession />} />
                <Route path="session-plans/u12s/dribbling" element={<U12sDribblingSession />} />
                <Route path="session-plans/u12s/defending" element={<U12sDefendingSession />} />
                <Route path="session-plans/u12s/shooting" element={<U12sShootingSession />} />
                <Route path="session-plans/u12s/passing" element={<U12sPassingSession />} />
              </Routes>
            </div>
          }
        />
        <Route
          path="/about"
          element={
            <div>
              <Navbar />
              <About />
            </div>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

// Render the app
const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);
reportWebVitals();