//
// A single playlist in the list of playlists that is displayed on the ChoosePlaylist.jsx page.
// Acts as a button that contains logic for moving forward in the flow of the game, moves onto the difficulty settings page
//

import React, { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom';
import axios from 'axios'
import '../../styles/playlist.css';

function Playlist({ playlist }) {
    //Defaults to kitten as default image
    const [playlistImg, setPlaylistImg] = useState("https://placekitten.com/200/200")

    const navigate = useNavigate()

    // Sets the image of the button that is of the spotify playlist
    useEffect(() => {
        const images = playlist.images
        if (images && images.length > 0) {
            const imageUrl = images[0].url;
            setPlaylistImg(imageUrl)
        }
    }, [])

    //Function for fetching tracks from a playlist
    const fetchTracks = async () => {
        const data = await getTracksFromPlaylistAPI(playlist)
        return data
    }

    //API call that returns all the tracks from a given playlist
    const getTracksFromPlaylistAPI = async (playlist) => {
        let token = window.localStorage.getItem("token")
        const { data } = await axios.get(playlist.tracks.href, {
            headers: {
                Authorization: `Bearer ${token}`
            }
        })
        return data.items
    }

    // Handles the logic of the playlist button
    const handlePlaylistButtonClick = async () => {
        const tracks = await fetchTracks()
        navigate("/game-settings", { state: { playlist: playlist, tracks: tracks } })
    }

    return (
        <div className="playlist-container">
            <button
                className="playlist-button"
                onClick={handlePlaylistButtonClick}
            >
                <img
                    src={playlistImg}
                    alt={playlist.name}
                    className="playlist-image" 
                />
                <div className="playlist-text">
                    {playlist.name}
                </div>
            </button>
        </div>
    );
}

export default Playlist;