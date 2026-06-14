//
// The page that displays all of the playlists that the user can choose to play the game with.
// It displays the users personal and followed playlists
// Each playlist is a button that when clicked, sends them into the GameSettings.jsx or difficulty settings page
//

import { Link } from 'react-router-dom';
import React, { useState } from 'react';
import "../styles/playlist.css";
import Playlists from "../components/PlaylistStuff/Playlists.jsx"

function ChoosePlaylist() {
    let token = window.localStorage.getItem("token")

    //If the user is connected to spotify and has a token retrieved, they may play the game
    if (token) {
        return (
            <div>
                <div>
                    <Playlists></Playlists>
                </div>
                <div>
                    <Link to="/home" className="back-button">Back</Link>
                </div>
            </div>
        )
    }
    else {
        return (
            <div>
                You need to connect to spotify first
                <Link to="/home" className="back-button">Back</Link>
            </div>
        )
    }
}

export default ChoosePlaylist;