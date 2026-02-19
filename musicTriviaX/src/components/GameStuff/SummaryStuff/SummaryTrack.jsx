//
// A single track that is displayed in the summary page. Contains the track info and a button for playing the song.
//
import "../../../styles/summary.css"

function SummaryTrack({ track, isCorrect, time, score, round, playerReady, playGivenTrack }) {

    // Logic for handling playing the song is contained in the parent
    const handlePlayTrackClick = () => {
        playGivenTrack(track);
    }
    //styling for game summary container
    const trackContainerStyle = {
        backgroundColor: 'forestgreen',
        padding: '10px',
        borderRadius: '5px',
        border: '2px solid black',
        textAlign: 'center',
        width: '300px',
        transform: 'translateY(60%)',
        top: '40%',
        position: 'relative',
        height: '75px',
        margin: '10px auto',
        color: 'white',
      };

    return (
        <div style={trackContainerStyle}>
            <p>Round: {round} | Track: {track.track.name} | Correct: {isCorrect ? "Yes" : "No"} | Time: {time} | Score: {score}</p>
            <button className = "play-song-button" disabled={!playerReady} onClick ={handlePlayTrackClick}>Play This Song</button>
        </div>
    );
}

export default SummaryTrack;
