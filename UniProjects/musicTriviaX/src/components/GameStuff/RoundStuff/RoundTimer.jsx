//
// A timer for a round that can be activated and deactivated, 50ms is added to negate the delay when deactivating the timer
//

import React, { useState, useEffect } from 'react';
import '../../../styles/game.css';

function RoundTimer({ handleTimerChange, timerActive, roundTime }) {
  const [timer, setTimer] = useState(roundTime);

  // Counts down in milliseconds, updates every 50ms
  useEffect(() => {
    let interval;
    if (timer >= 0 && timerActive) {
      interval = setInterval(() => {
        setTimer((prevTimer) => prevTimer - 50);
      }, 50);
      handleTimerChange(timer);
    }
    return () => {
      clearInterval(interval);
    };
  }, [timer, setTimer, timerActive, handleTimerChange]);

  const radius = 40; 
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = ((roundTime - timer) / roundTime) * circumference;
  //Custom SVG timer
  return (
    <div className="timer">
      <svg height="100" width="100">
        <circle
          r={radius}
          cx="50"
          cy="50"
          fill="transparent"
          stroke="forestgreen" 
          strokeWidth="5" 
          strokeDasharray={circumference}
          strokeDashoffset={strokeDashoffset}
        />
        <text x="50" y="50" textAnchor="middle" dy="8" fill="forestgreen" fontSize="16">
          {timer > 0 ? Math.ceil(timer / 1000) : 0}
        </text>
      </svg>
    </div>
  );
}

export default RoundTimer;
