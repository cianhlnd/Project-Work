//
// This handles the api calls to spotify that allows the user to log in with their account and give necessary permissions.
// This then gets the token
//
// References:
// Spotify Docs - https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow
// Example on Github - https://github.com/spotify/web-api-examples/blob/7c4872d343a6f29838c437cf163012947b4bffb9/authorization/authorization_code_pkce/public/app.js#L96
//

import React from 'react';
import { useEffect, useState } from 'react';
import '../styles/home.css';

const clientId = "5be7a104ede54d80ae4ff7aafd71699e"
const scope = 'user-read-private user-read-email playlist-read-private streaming user-modify-playback-state';
const redirectUrl = "http://localhost:3000/home"
const authorizationEndpoint = "https://accounts.spotify.com/authorize";
const tokenEndpoint = "https://accounts.spotify.com/api/token";

const currentToken = {
  get access_token() { return localStorage.getItem('access_token') || null; },
  get refresh_token() { return localStorage.getItem('refresh_token') || null; },
  get expires_in() { return localStorage.getItem('refresh_in') || null },
  get expires() { return localStorage.getItem('expires') || null },

  save: function (response) {
    const { access_token, refresh_token, expires_in } = response;
    localStorage.setItem('access_token', access_token);
    localStorage.setItem('refresh_token', refresh_token);
    localStorage.setItem('expires_in', expires_in);

    const now = new Date();
    const expiry = new Date(now.getTime() + (expires_in * 1000));
    localStorage.setItem('expires', expiry);
  }
};

function LoginToSpotify() {

  useEffect(() => {
    getCodeFromUrl()
  }, [])

  //Gets the code from url, for decrypting and getting token
  async function getCodeFromUrl() {
    const args = new URLSearchParams(window.location.search);
    const code = args.get('code');

    if (code) {
      const token = await getToken(code);
      currentToken.save(token);

      // Remove code from URL so we can refresh correctly.
      const url = new URL(window.location.href);
      url.searchParams.delete("code");

      const updatedUrl = url.search ? url.href : url.href.replace('?', '');
      window.history.replaceState({}, document.title, updatedUrl);
    }
  }

  //Gets token from encrypted code
  async function getToken(code) {
    const code_verifier = localStorage.getItem('code_verifier');

    const response = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirectUrl,
        code_verifier: code_verifier,
      }),
    });

    return await response.json();
  }



  //redirects to spotify authorization, uses spotify doc supplied encryption
  async function redirectToSpotifyAuthorize() {
    const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const randomValues = crypto.getRandomValues(new Uint8Array(64));
    const randomString = randomValues.reduce((acc, x) => acc + possible[x % possible.length], "");

    const code_verifier = randomString;
    const data = new TextEncoder().encode(code_verifier);
    const hashed = await crypto.subtle.digest('SHA-256', data);

    const code_challenge_base64 = btoa(String.fromCharCode(...new Uint8Array(hashed)))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_');

    window.localStorage.setItem('code_verifier', code_verifier);

    const authUrl = new URL(authorizationEndpoint)
    const params = {
      response_type: 'code',
      client_id: clientId,
      scope: scope,
      code_challenge_method: 'S256',
      code_challenge: code_challenge_base64,
      redirect_uri: redirectUrl,
    };

    authUrl.search = new URLSearchParams(params).toString();
    window.location.href = authUrl.toString(); // Redirect the user to the authorization server for login
  }

  //function for refreshing the acces token
  async function refreshToken() {
    const response = await fetch(tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        client_id: clientId,
        grant_type: 'refresh_token',
        refresh_token: currentToken.refresh_token
      }),
    });

    return await response.json();
  }

  //Handles the button click for authorizing spotify account
  const authorizeSpotifyAccount = async () => {
    await redirectToSpotifyAuthorize();
  }

  //Function to get a new token
  const getNewToken = async () => {
    const token = await refreshToken();
    currentToken.save(token);
    window.localStorage.setItem("token", token.access_token)
  }

  return (
    <div className="button-container">
      <button onClick={authorizeSpotifyAccount} className="connect-button">Connect to Spotify</button>
      <button onClick={getNewToken} className="token-button">Get Token</button>
    </div>
  );
}

export default LoginToSpotify;