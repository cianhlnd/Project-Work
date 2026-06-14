//
// Home page of app, first thing user sees, user can login to spotify here then play the game by pressing start, user can also go to the stats page from here
//

import { Link } from 'react-router-dom';
import LoginToSpotify from "../services/LoginToSpotify.jsx";
import '../styles/home.css';

function HomePage() {
    return (
        <div className="Home">
            <header className="logo">
                <img src="/SongGuesser.png" alt="Logo" className="logo-img" />
            </header>
            <div className="button-container">
                <LoginToSpotify></LoginToSpotify>
                <button className="start-button">
                    <Link to="/choose-playlist" className="link-style">Choose Playlist</Link>
                </button>
                <button className="stats-button">
                    <Link to="/stats" className="link-style">Stats</Link>
                </button>
            </div> 
        </div>
    )
}

export default HomePage;
