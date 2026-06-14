//
// Page for displaying the games summary
// Also allows to play the songs from each round
//

import React, { useState } from 'react'
import { Link, useLocation } from 'react-router-dom';
import '../styles/summary.css';
import SummaryTrack from '../components/GameStuff/SummaryStuff/SummaryTrack';
import Cookies from 'js-cookie';

import SpotifyWebPlayer from '../services/SpotifyWebPlayer';

function GameSummary() {
    const location = useLocation()
    const [gameData, setGameData] = useState(location.state.stats)
    const [playerReady, setPlayerReady] = useState(false)

    const playerIsReady = () => {
        setPlayerReady(true)
    }

    //Imports functions for web player, passes function to web player component so that we know when audio can be played without errors
    const { playTrack, setPlayerVolume, pauseTrack } = SpotifyWebPlayer({ playerIsReady:playerIsReady})

    //function for saving the stats via cookies, it retrieves the the currenlty saved stats and updates one by one
    function saveStatsInCookie(correct, score, totalTime, outOfTime, roundData) {
        const savedData = Cookies.get('playerStats')
        const roundTime = location.state.roundTime
        const currentDate = new Date();
        const expirationDate = new Date(currentDate.getFullYear() + 10, currentDate.getMonth(), currentDate.getDate());
        if (!savedData) {
            Cookies.set('playerStats', null, { expires: expirationDate })
        }

        const parsedSavedData = JSON.parse(savedData)

        var gamesPlayed = parsedSavedData.GamesPlayed + 1
        var roundsPlayed = parsedSavedData.RoundsPlayed + roundData.length
        var correctGuesses = parsedSavedData.CorrectGuesses + correct
        var wrongGuesses = parsedSavedData.WrongGuesses + (roundData.length - correct)
        var accuracy = Math.round((correctGuesses / (correctGuesses + wrongGuesses)) * 10000) / 100
        var totalScore = parsedSavedData.TotalScore + score
        var averageScorePerRound = Math.round(totalScore / roundsPlayed)
        var timePlayed = parsedSavedData.TimePlayed + ((roundTime * roundData.length) - totalTime)
        var averageRoundTime = Math.round(timePlayed / roundsPlayed)
        var timesOutOfTime = parsedSavedData.TimesOutOfTime + outOfTime

        const data = {
            "GamesPlayed": gamesPlayed,
            "RoundsPlayed": roundsPlayed,
            "CorrectGuesses": correctGuesses,
            "WrongGuesses": wrongGuesses,
            "Accuracy": accuracy,
            "TotalScore": totalScore,
            "AverageScorePerRound": averageScorePerRound,
            "TimePlayed": timePlayed,
            "AverageRoundTime": averageRoundTime,
            "TimesOutOfTime": timesOutOfTime
        }
        const dataString = JSON.stringify(data)
        Cookies.set('playerStats', dataString, { expires: expirationDate })
    }

    //Function for playing a track, unmutes volume as it is muted by default (needs to be muted for game)
    const playGivenTrack = (track) => {
        playTrack(track)
        setPlayerVolume(0.5)
    }

    //UI function for displaying the game summary and each round summary which is displayed in a list
    const summaryStuff = () => {
        const roundData = gameData

        const summaryTracks = roundData.map(item => (
            <SummaryTrack
                key={item.round}
                track={item.track}
                isCorrect={item.isCorrect}
                time={item.time}
                score={item.score}
                round={item.round + 1}
                playerReady={playerReady}
                playGivenTrack={playGivenTrack}
            ></SummaryTrack>
        ))

        let totalScore = 0;
        let correct = 0;
        let totalTime = 0;
        let outOfTime = 0;
        roundData.forEach(item => {
            if (item.time <= 0) {
                outOfTime++
            }
            totalTime += item.time
            if (item.isCorrect) {
                correct++;
            }
            totalScore = totalScore + item.score
        })

        saveStatsInCookie(correct, totalScore, totalTime, outOfTime, roundData)
        
        return (
            <div>
                <div className = "final-score">
                Final Score: {totalScore}
                </div><br />
                <div className = "correct-songs">
                You got {correct} out of {roundData.length} songs correct<br />
                </div>
                {summaryTracks}
            </div>
        )
    }

    return (
        <div>
            <header className="h1">
            <h1>Summary</h1>
            </header>
            <Link to="/home" className="home-button">Home</Link>
            <Link to="/choose-playlist" className = "play-again-button">Play Again</Link>
            {summaryStuff()}
            <button className="stop-button" onClick={pauseTrack}>Stop Audio</button>
        </div>
    )
}

export default GameSummary;