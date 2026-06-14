// Stats page of the player, contains various statistics of the user's games

import '../styles/home.css';
import '../styles/stats.css';
import { Link } from 'react-router-dom';
import Cookies from 'js-cookie';

// Retrieves the data from cookies, if data doesn't exist creates empty data
function PlayerStats() {
    var playerData = Cookies.get('playerStats');
    if (!playerData) {
        const currentDate = new Date();
        const expirationDate = new Date(currentDate.getFullYear() + 10, currentDate.getMonth(), currentDate.getDate());

        const emptyData = {
            "GamesPlayed": 0,
            "RoundsPlayed": 0,
            "CorrectGuesses": 0,
            "WrongGuesses": 0,
            "Accuracy": 0,
            "TotalScore": 0,
            "AverageScorePerRound": 0,
            "TimePlayed": 0,
            "AverageRoundTime": 0,
            "TimesOutOfTime": 0
        };

        const emptyDataString = JSON.stringify(emptyData);
        Cookies.set('playerStats', emptyDataString, { expires: expirationDate });
        playerData = Cookies.get('playerStats');
    }

    // Parse the JSON data
    const stats = JSON.parse(playerData);

    // Create a list of stats with labels, centered on the x-axis, and increased font size
    const statListStyle = {
        listStyleType: 'none',
        textAlign: 'center',
        padding: 0,
    };
    //positioning for stats list
    const statListItemStyle = {
        marginBottom: '10px',
        fontSize: '18px', 
    };
    //stats placed into lists
    const statList = (
        <ul style={statListStyle}>
            <li style={statListItemStyle}>Games Played: {stats.GamesPlayed}</li>
            <li style={statListItemStyle}>Rounds Played: {stats.RoundsPlayed}</li>
            <li style={statListItemStyle}>Correct Guesses: {stats.CorrectGuesses}</li>
            <li style={statListItemStyle}>Wrong Guesses: {stats.WrongGuesses}</li>
            <li style={statListItemStyle}>Accuracy: {stats.Accuracy}%</li>
            <li style={statListItemStyle}>Total Score: {stats.TotalScore}</li>
            <li style={statListItemStyle}>Average Score Per Round: {stats.AverageScorePerRound}</li>
            <li style={statListItemStyle}>Time Played: {stats.TimePlayed} minutes</li>
            <li style={statListItemStyle}>Average Round Time: {stats.AverageRoundTime} seconds</li>
            <li style={statListItemStyle}>Times Out of Time: {stats.TimesOutOfTime}</li>
        </ul>
    );
    // styling for stats container
    const containerStyle = {
        border: '2px solid black',
        backgroundColor: 'forestgreen',
        borderRadius: '8px',
        width: '350px',
        marginTop: '40px',
        position: 'absolute',
        transform: 'translateX(-50%)',
        left: '50%',
        color: 'white'
    };

    return (
        <div>
            <header className="h1">
                <h1>Stats</h1>
            </header>
            <Link to="/home" className="back-button">Back</Link>
            <div className="stats-container" style={containerStyle}>
                {statList}
            </div>
        </div>
    );
}

export default PlayerStats;
