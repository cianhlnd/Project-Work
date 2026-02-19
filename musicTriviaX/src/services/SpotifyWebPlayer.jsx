//
// Component that implements the spotify web player, allows for playing, pausing, volume control and skipping to specific time in song.
//
// References: 
// Web Player Docs - https://developer.spotify.com/documentation/web-playback-sdk/howtos/web-app-player 
// Spotify web api js docs - https://jmperezperez.com/spotify-web-api-js/#src-spotify-web-api.js-constr.prototype.play
//

import React, { useState, useEffect } from 'react';
import SpotifyWebApi from 'spotify-web-api-js';

function SpotifyWebPlayer({ playerIsReady }) {
    const [deviceId, setDeviceId] = useState(undefined)

    const spotifyApi = new SpotifyWebApi();

    const token = window.localStorage.token

    //Calls api and gets the device id ready for playing tracks, default volume is 0 muted
    useEffect(() => {
        spotifyApi.setAccessToken(token);
        const script = document.createElement("script");
        script.src = "https://sdk.scdn.co/spotify-player.js";
        script.async = true;

        document.body.appendChild(script);

        window.onSpotifyWebPlaybackSDKReady = () => {
            const player = new window.Spotify.Player({
                name: 'Web Playback SDK',
                getOAuthToken: cb => { cb(token); },
                volume: 0
            });

            player.addListener('ready', ({ device_id }) => {
                console.log('Ready with Device ID', device_id);
                setDeviceId(device_id);
                playerIsReady()
            });

            player.addListener('not_ready', ({ device_id }) => {
                console.log('Device ID has gone offline', device_id);
            });
            player.connect();
        };
    }, []);

    //Function for playing a specific track
    const playTrack = async (track) => {
        console.log(track)
        const trackUri = track.track.uri
        spotifyApi.play({
            uris: [trackUri],
            device_id: deviceId,
        })
    }

    //function for setting the playback volume range is 1-100 as per documentation, needs to be integer
    const setPlayerVolume = (volume) => {
        let volumeInteger = Math.round(volume * 100)
        spotifyApi.setVolume(volumeInteger, { device_id: deviceId })
    }

    //function to pause playback
    const pauseTrack = () => {
        spotifyApi.pause()
    }

    //function to skip to specific time in song in milliseconds
    const skipTo = (time) => {
        spotifyApi.seek(time, { device_id: deviceId })
    }

    //returned functions so that they can be used in the Game.jsx and GameSummary.jsx
    return {
        playTrack,
        setPlayerVolume,
        pauseTrack,
        skipTo
    }
}

export default SpotifyWebPlayer