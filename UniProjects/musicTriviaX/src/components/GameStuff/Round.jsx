//
// A single round that is used within a game. Contains logic for handling the countdown, round timers,
// options, manipulating the tracks, starting and stopping the round.
//
// References:
// Shuffling arrays - https://stackoverflow.com/questions/2450954/how-to-randomize-shuffle-a-javascript-array
//

//Required components and imports for the round
import React, { useState, useEffect } from 'react'
import Option from "./Option"
import NextRoundBtn from './RoundStuff/NextRoundBtn'
import RoundSummary from './RoundStuff/RoundSummary'
import RoundTimer from './RoundStuff/RoundTimer'
import Countdown from './RoundStuff/Countdown'
import '../../styles/game.css'

// 'correctTrack' is a single track and 'otherTracks' is an array of non correct tracks used as options 
// 'volume' is used to change the ui and persisted value of the volume, 'setVolume' changes the actual volume of the spotify player
// 'skipTo' skips to a certain position in the track, uses milliseconds as input
function Round({ correctTrack, otherTracks, roundNumber, nextRound, roundTime, updateRoundStats, volume, isLastRound, playTrack, setVolume, pauseTrack, skipTo }) {
    const [currentRound] = useState(roundNumber)
    const [roundOver, setRoundOver] = useState(false)
    const [roundScore, setRoundScore] = useState(0)
    const [optionsDisabled, setOptionsDisabled] = useState(true)
    const [isCorrectChoice, setIsCorrectChoice] = useState(false) //tracks if user selected correct choice
    const [timerActive, setTimerActive] = useState(false)
    const [finalTime, setFinalTime] = useState(roundTime) //the time at which the user finished the round

    //'correctTrack' and 'otherTracks' are combined then shuffled to create a basis for the round options
    const [tracks] = useState(shuffleArray([...combineTracks()]))

    let currentTime = roundTime //need to store time in a non useState to ensure it is updated when needed

    // The player begins playback of the track on mute, this ensures it is fully loaded when needed
    useEffect(() => {
        try {
            playTrack(correctTrack)
        }
        catch (error) {
            console.log("Something went wrong when starting track playback")
        }
    }, [])

    //Updates the round stats everytime round score, final time or if it was correct choice updates.
    useEffect(() => {
        updateRoundStats(currentRound, {
            round: roundNumber,
            track: correctTrack,
            score: roundScore,
            time: finalTime,
            isCorrect: isCorrectChoice
        })
    }, [roundScore, finalTime, isCorrectChoice])

    //Makes sure audio from round stops playing when unmounting
    /*
    useEffect(() => {
        return () => {
            stopAudio()
        }
    }, [correctTrack.track.preview_url])
    */

    //function for stopping audio playback
    const stopAudio = () => {
        try {
            setVolume(0.0)
            pauseTrack()
        }
        catch (error) {
            console.log("Something went wrong when stopping the audio")
        }
    }

    //merges the correct track and the other tracks into one array
    function combineTracks() {
        let allTracks = [...otherTracks, correctTrack]
        return allTracks
    }

    //function for shuffling an array
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

    //Handles the clicking of an option
    const handleOptionClick = (clickedTrack) => {
        endRound()
        if (correctTrack.track.id === clickedTrack.track.id) { //if correct option
            setIsCorrectChoice(true)
            //If more than 10% of the round passed, start losing score, else full score, max score is 5000 in a round
            let score = Math.round((currentTime > roundTime * 0.90 ? 5000 : (currentTime / (roundTime * 0.90) * 5000)))
            setRoundScore(score)
        }
    }

    //simply checks if the time has reached 0, ends round if true
    const handleTimerChange = (time) => {
        currentTime = time
        if (time <= 0) {
            endRound()
        }
    }

    //Gets a random position of the track in milliseconds, ensures it wont stop playing before the round timer finishes
    const randomTimeTrack = () => {
        let trackDuration = correctTrack.track.duration_ms
        let randomTime = Math.floor(Math.random() * trackDuration)
        if (randomTime - roundTime >= 0) {
            return randomTime - roundTime
        }
        else {
            return randomTime
        }
    }

    //Starts the round after a 3 second countdown
    const handleCountdown = (time) => {
        if (time <= 0) {
            startRound()
        }
    }

    //Function to start a round
    function startRound() {
        skipTo(randomTimeTrack())
        setVolume(volume)
        setTimerActive(true)
        setOptionsDisabled(false)
    }

    //Function to end a round
    const endRound = () => {
        stopAudio()
        setTimerActive(false)
        setOptionsDisabled(true)
        setFinalTime(currentTime)
        setRoundOver(true)
    }

    //Option components created from the shuffled track array
    const roundOptions = tracks.map(item => (
        <Option key={item.track.id} track={item} handleOptionClick={handleOptionClick} disabled={optionsDisabled} className="option-button"></Option>
    ))

    //UI for rounds generated
    return (
        <div>
            <header className="round">Round {roundNumber + 1}</header>
            <div>
                <Countdown
                    handleCountdown={handleCountdown}
                ></Countdown>
            </div>
            <div>{roundOptions}</div>

            <div><NextRoundBtn
                nextRound={nextRound}
                isVisible={roundOver}
                isLastRound={isLastRound}
            /></div>
            <RoundTimer
                handleTimerChange={handleTimerChange}
                timerActive={timerActive}
                roundTime={roundTime}
            ></RoundTimer>

            <div><RoundSummary
                data={{
                    score: roundScore,
                    time: finalTime,
                    roundTime: roundTime,
                    isCorrect: isCorrectChoice
                }}
                isVisible={roundOver}
                updateRoundStats={updateRoundStats}
            /></div>

            
        </div>
    )
}

export default Round;