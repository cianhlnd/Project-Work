//
// Main index.js of app, defines all the routes and pages that are used
//

import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route } from "react-router-dom";
import HomePage from "./pages/HomePage.jsx"
import ChoosePlaylist from "./pages/ChoosePlaylist.jsx"
import Game from "./pages/Game.jsx"
import GameSummary from './pages/GameSummary.jsx';
import PlayerStats from './pages/PlayerStats.jsx';
import GameSettings from './pages/GameSettings.jsx';

import reportWebVitals from './reportWebVitals';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <BrowserRouter>
    <Routes>
      <Route index element={<HomePage />} />
      <Route path="choose-playlist" element={<ChoosePlaylist />} />
      <Route path="home" element={<HomePage />} />
      <Route path="game" element={<Game />} />
      <Route path="summary" element={<GameSummary />} />
      <Route path="stats" element={<PlayerStats />} />
      <Route path="game-settings" element={<GameSettings />} />
    </Routes>
  </BrowserRouter>
);

reportWebVitals()
