//
// Fetches all of the spotify users playlists, then returned/displayed as a list
//

import React, { useState, useEffect } from 'react'
import axios from 'axios'
import Playlist from './Playlist';

function Playlists() {
    const [listOfPlaylists, setListOfPlaylists] = useState([])

    //gets the playlists once component is mounted
    useEffect(() => {
        getPlaylists()
    }, [])

    //Function that makes api call to fetch the users playlists
    const getPlaylists = async () => {
        let token = window.localStorage.getItem("token")
        const { data } = await axios.get("https://api.spotify.com/v1/me/playlists", {
            headers: {
                Authorization: `Bearer ${token}`
            },
            params: {
                limit: "50",
                offset: "0"
            }
        })
        setListOfPlaylists(data.items)
    }

    //UI component that lists all the playlists
    const Playlists = () => {
        return (
            <div>
                {listOfPlaylists.map(playlist => (
                    <div key={playlist.id}>
                        <Playlist playlist={playlist} />
                    </div>
                ))}
            </div>
        )
    }

    return (
        <div>
            <header className="h1">
                <h1>
                    Choose a Playlist
                </h1>
                {Playlists()}
            </header>
        </div>
    )
}

export default Playlists;

//37i9dQZF1DX2vTOtsQ5Isl Top pop 2023