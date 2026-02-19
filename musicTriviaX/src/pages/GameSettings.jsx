//
// Page that allows user to change the settings of the game they are about to play, acts as a pregame screen, saves the settings via cookies
//

import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useLocation, useNavigate } from 'react-router-dom';
import '../styles/home.css';
import '../styles/settings.css'
import Cookies from 'js-cookie';


function GameSettings() {
    const [playlistName, setPlaylistName] = useState("")
    const [rounds, setRounds] = useState(5)
    const [roundLength, setRoundLength] = useState(20) //seconds
    const [numOptions, setNumOptions] = useState(4) //number of options

    const location = useLocation()
    const navigate = useNavigate();

    //json for storing the settings, so that it can be saved in a cookie
    var data = {
        rounds: rounds,
        roundLength: roundLength,
        numOptions: numOptions
    }

    const currentDate = new Date();
    const expirationDate = new Date(currentDate.getFullYear() + 10, currentDate.getMonth(), currentDate.getDate()); //10 years from current time

    //loads saved settings if they exist, else the default settings are already initialized
    useEffect(() => {
        setPlaylistName(location.state.playlist.name)
        var savedGameSettings = Cookies.get('gameSettings')
        if (savedGameSettings) {
            const savedData = JSON.parse(savedGameSettings)
            setRounds(savedData.rounds)
            setRoundLength(savedData.roundLength)
            setNumOptions(savedData.numOptions)
        }
    }, [])

    //Updates data once any of the settings are changed
    useEffect(() => {
        data = {
            rounds: rounds,
            roundLength: roundLength,
            numOptions: numOptions
        }
    }, [rounds, roundLength, numOptions])

    //handles rounds change, similar to the other methods, allows for empty value so that the user can enter what they want, but the limit is set
    //in this case the rounds limit range is 1-20 inclusive
    const handleRoundsChange = (event) => {
        if (event.target.value) {
            const value = parseInt(event.target.value, 10)
            setRounds(value)
        }
        else {
            setRounds('')
        }

    }

    //once the user clicks off the field, checks if its a valid, range is 1-20 inclusive for rounds
    const handleRoundsChangeBlur = (event) => {
        const value = parseInt(event.target.value, 10)
        if (value < 1) {
            setRounds(1)
        }
        if (value > 10) {
            setRounds(10)
        }
    }

    //Same as 'handleRoundsChange'
    const handleRoundLengthChange = (event) => {
        if (event.target.value) {
            const value = parseInt(event.target.value, 10)
            setRoundLength(value)
        }
        else {
            setRoundLength('')
        }

    }

    //same as 'handleRoundsChangeBlur' but the limit for round length is 1-240 inclusive in seconds
    const handleRoundsLengthChangeBlur = (event) => {
        const value = parseInt(event.target.value, 10)
        if (value < 1) {
            setRoundLength(1)
        }
        if (value > 240) {
            setRoundLength(240)
        }
    }

    //Same as 'handleRoundsChange'
    const handleNumOptionsChange = (event) => {
        if (event.target.value) {
            const value = parseInt(event.target.value, 10)
            setNumOptions(value)
        }
        else {
            setNumOptions('')
        }

    }

    //same as 'handleRoundsChangeBlur' but the limit for options is 2-5
    const handleNumOptionsChangeBlur = (event) => {
        const value = parseInt(event.target.value, 10)
        if (value < 2) {
            setNumOptions(2)
        }
        if (value > 5) {
            setNumOptions(5)
        }
    }

    //Starts the game, but first saves settings so that user doesn't need to re input favoured settings
    const handleStartGame = () => {
        Cookies.set('gameSettings', JSON.stringify(data), { expires: expirationDate })
        navigate("/game", { state: { tracks: location.state.tracks, rounds: rounds, roundLength: roundLength * 1000, numOptions: numOptions } })
    }
    
    return (
        <div>
            <header className="h1">
                <h1>Settings</h1>
            </header>
            <Link to="/choose-playlist" className="back-button">Back</Link>
            <div className="input-container">
                <div className="label-container">
                <div className = "playlist-name">Playlist Name: {playlistName}</div>
                    <label className="input-label">Rounds:</label>
                    <input
                        type="number"
                        value={rounds}
                        onChange={handleRoundsChange}
                        onBlur={handleRoundsChangeBlur}
                        min="1"
                        max="10"
                        className="input-box"
                    />
                </div>
                <div className="label-container">
                    <label className="input-label">Round Length:</label>
                    <input
                        type="number"
                        value={roundLength}
                        onChange={handleRoundLengthChange}
                        onBlur={handleRoundsLengthChangeBlur}
                        min="1"
                        max="240"
                        className="input-box"
                    />
                </div>
                <div className="label-container">
                    <label className="input-label">Number of Options:</label>
                    <input
                        type="number"
                        value={numOptions}
                        onChange={handleNumOptionsChange}
                        onBlur={handleNumOptionsChangeBlur}
                        min="2"
                        max="5"
                        className="input-box"
                    />
                </div>
            </div>
            <button onClick={handleStartGame} className="start-button">Start</button>
        </div>
    );
}

export default GameSettings;