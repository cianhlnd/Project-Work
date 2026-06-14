//
// This is where the rounds are stored, i.e the game is played.
// This contains the spotify web player, logic for randomly selecting the tracks to be played, 
//
// References:
// Shuffling arrays - https://stackoverflow.com/questions/2450954/how-to-randomize-shuffle-a-javascript-array

import React, { useState, useEffect, useRef } from 'react'
import { useLocation, useNavigate } from 'react-router-dom';
import Round from "../components/GameStuff/Round"
import '../styles/game.css'
import Cookies from 'js-cookie';

import SpotifyWebPlayer from '../services/SpotifyWebPlayer';

function Game() {
    const [isPlayerReady, setPlayerReady] = useState(false)
    const [tracks, setTracks] = useState()
    const [chosenTracks, setChosenTracks] = useState() //even index is track, odd index is the options that are not equal
    const [currentRound, setCurrentRound] = useState(0)
    const [volumeUI, setVolumeUI] = useState(0.5)
    const [gameStats, setGameStats] = useState([])
    const didMountTracks = useRef(false)

    const location = useLocation()

    //function for setting the player to be ready for playback
    const playerIsReady = () => {
        setPlayerReady(true)
    }

    //Imports functions for web player, passes function to web player component so that we know when audio can be played without errors
    const { playTrack, setPlayerVolume, pauseTrack, skipTo } = SpotifyWebPlayer({ playerIsReady: playerIsReady })

    //Game settings retrieved from previous page
    const options = location.state.numOptions
    const numOfRounds = location.state.rounds
    const roundTime = location.state.roundLength

    const navigate = useNavigate()

    //Loads volume from cookie, sets tracks and creates/resets roundData to be empty in the local storage so that it can be updated later
    useEffect(() => {
        const savedVolume = Cookies.get('volume')
        if (savedVolume) {
            setVolumeUI(Number(savedVolume))
        }
        setTracks(location.state.tracks)
        window.localStorage.setItem("roundData", [])
    }, [])

    //ensures that the tracks are only filled once, prevents some interesting bugs
    useEffect(() => {
        if (didMountTracks.current) {
            fillChosenTracks()
        }
        else {
            didMountTracks.current = true
        }
    }, [tracks])

    //function to shuffle array
    function shuffleArray(array) {
        let current = array.length

        while (current !== 0) {
            const randomIndex = Math.floor(Math.random() * current)
            current--
            const temp = array[current]
            array[current] = array[randomIndex]
            array[randomIndex] = temp
        }
        return array
    }

    //function to randomly select correct and non correct options, ensures that the options are unique
    //Doesnt take into account if the same song is added multiple times in a playlist, but shouldn't be a problem as the track.id is used for determining correct option
    function fillChosenTracks() {
        let shufflingTracks = [...tracks]
        let result = []
        for (let i = 0; i < numOfRounds; i++) {
            shuffleArray(shufflingTracks)
            result = [...result, shufflingTracks[0], shufflingTracks.slice(1, options)]
        }
        setChosenTracks(result)
    }

    //Function for moving onto next round
    const nextRound = () => {
        setCurrentRound(currentRound + 1)
    }

    //Function that updates the round stats, index is the round number minus 1, so a game of 5 rounds will have a list of 5 json objects
    //index is used to know which to update, this function is passed down to the round component
    const updateRoundStats = (index, roundData) => {
        setGameStats((prevData) => {
            const newData = [...prevData]
            newData[index] = roundData
            return newData
        })
    }

    //Handles the change of volume
    const handleVolumeChange = (event) => {
        const newVolume = parseFloat(event.target.value)
        setVolumeUI(newVolume) //ui
        setPlayerVolume(newVolume) //player
        Cookies.set('volume', newVolume)
    }

    //Volume slider
    const volumeSlider = () => {
        return (
            <input
                type="range"
                min="0"
                max="1"
                step="0.05"
                value={volumeUI}
                onChange={handleVolumeChange}
            />
        )
    }

    //Function that renders the rounds one by one, switches once the 'currentRound' is updated, moves onto summary page once no more rounds are left
    const renderRound = () => {
        if (currentRound < numOfRounds) {
            return (
                chosenTracks ? (
                    <Round key={currentRound}
                        correctTrack={chosenTracks[0 + (currentRound * 2)]} //even = correct track
                        otherTracks={chosenTracks[1 + (currentRound * 2)]} //odd = array of other tracks
                        roundNumber={currentRound}
                        nextRound={nextRound}
                        roundTime={roundTime}
                        updateRoundStats={updateRoundStats}
                        volume={volumeUI}
                        isLastRound={numOfRounds - currentRound == 1}
                        playTrack={playTrack}
                        setVolume={setPlayerVolume}
                        pauseTrack={pauseTrack}
                        skipTo={skipTo}
                    ></Round>
                ) : (
                    <p className="loading">Loading...</p>
                )
            )
        }
        else {
            navigate("/summary", { state: { stats: gameStats, roundTime: roundTime } })
        }

    }

    //Renders the game once the web player is ready
    const renderGame = () => {
        if (isPlayerReady) {
            return (
                <div>
                    {renderRound()}
                    <div className = "volume">
                        Volume: 
                        {volumeSlider()}
                    </div>
                </div>
            )
        }
    }

    return (
        <div>
            {renderGame()}
        </div>
    )
}

export default Game