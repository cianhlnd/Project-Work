//
// A simple 3 second countdown component
//

import React, { useState, useEffect } from 'react'
import '../../../styles/game.css'

function Countdown({ handleCountdown }) {
    const [countdown, setCountdown] = useState(3000)

    //Countdown that decrements by 1000 ms every second until reaching 0
    useEffect(() => {
        let interval;
        if (countdown >= 0) {
            interval = setInterval(() => {
                setCountdown(prevTimer => prevTimer - 1000)
            }, 1000)
            handleCountdown(countdown)
        }
        return () => {
            clearInterval(interval)
        }
    }, [countdown, setCountdown])

    return (
        <div className = "countdown">
            Countdown: {countdown > 0 ? countdown : 0}
        </div>
    )
}

export default Countdown