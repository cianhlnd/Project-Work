//
// *All tests in one file due to moodle file submission limit*
//
// Unit tests for ChoosePlaylist.jsx
//

import React from 'react'
import { render, screen, fireEvent, waitFor, act } from '@testing-library/react'
import { BrowserRouter as Router } from 'react-router-dom'
import '@testing-library/jest-dom'
import Cookies from 'js-cookie'
import axios from 'axios'

import ChoosePlaylist from '../pages/ChoosePlaylist'
import GameSummary from '../pages/GameSummary'
import Game from '../pages/Game'
import GameSettings from '../pages/GameSettings'
import HomePage from '../pages/HomePage'
import PlayerStats from '../pages/PlayerStats'
import Option from '../components/GameStuff/Option'
import Round from '../components/GameStuff/Round'
import Countdown from '../components/GameStuff/RoundStuff/Countdown'
import NextRoundBtn from '../components/GameStuff/RoundStuff/NextRoundBtn'
import RoundSummary from '../components/GameStuff/RoundStuff/RoundSummary'
import RoundTimer from '../components/GameStuff/RoundStuff/RoundTimer'
import SummaryTrack from '../components/GameStuff/SummaryStuff/SummaryTrack'
import Playlist from '../components/PlaylistStuff/Playlist'
import Playlists from '../components/PlaylistStuff/Playlists'

describe('ChoosePlaylist', () => {
  beforeEach(() => {
    //Mock token in local storahe
    jest.spyOn(window.localStorage.__proto__, 'getItem').mockReturnValue('fakeToken')
  })

  test('renders ChoosePlaylist correctly with token', () => {
    render(
      <Router>
        <ChoosePlaylist />
      </Router>
    )

    //Check that the Playlists component is rendered
    expect(screen.getByText('Choose a Playlist')).toBeInTheDocument()

    //Check that the Back link is rendered
    expect(screen.getByText('Back')).toBeInTheDocument()
  })

  it('renders ChoosePlaylist component without token', () => {
    //Set token in local storage to null
    window.localStorage.getItem.mockReturnValue(null)

    render(
      <Router>
        <ChoosePlaylist />
      </Router>
    )

    //Check that the error message is rendered
    expect(screen.getByText('You need to connect to spotify first')).toBeInTheDocument()

    //Check that the Back link is rendered
    expect(screen.getByText('Back')).toBeInTheDocument()
  })
})


//Unit test for Game.jsx

//Mock data that is required for ensuring Game is rendered
jest.mock('../services/SpotifyWebPlayer', () => {
  return () => ({
      playTrack: jest.fn(),
      setPlayerVolume: jest.fn(),
      pauseTrack: jest.fn(),
      skipTo: jest.fn(),
      playerIsReady: jest.fn(),
  })
})

jest.mock('../components/GameStuff/Round', () => ({
  __esModule: true,
  default: () => <div data-testid="mocked-round" >Round</div>,
}))

jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useLocation: () => ({
      pathname: '/mocked-path',
      state: {
          numOptions: 4,
          rounds: 5,
          roundLength: 30,
          tracks: [],
      },
  }),
}))

describe('Game', () => {
  test('renders the game page without issues or crashes', () => {
      render(<Router><Game /></Router>)
  })
})

//
// Unit test for GameSettings.jsx
//

//Mock location state, with a playlist
jest.mock('react-router-dom', () => ({
    ...jest.requireActual('react-router-dom'),
    useLocation: () => ({
        pathname: '/mocked-path',
        state: {
            playlist: { name: 'Mocked Playlist' },
        },
    }),
}))

//Test that page renders with no issues and has the correct values passed in from the state
describe('GameSettings Component', () => {
    test('page renders correctly with no issues, and has correct values', () => {
        const locationState = {
            playlist: { name: 'Mocked Playlist' },
        }

        render(<Router><GameSettings location={{ state: locationState }} /></Router>)

        //Check for back link
        expect(screen.getByText('Back')).toBeInTheDocument()

        //Check for playlist name to be rendered
        expect(screen.getByText(locationState.playlist.name)).toBeInTheDocument()

        //Check that roundsInput is correctly rendered
        const roundsInput = screen.getByLabelText(/rounds/i)
        expect(roundsInput).toBeInTheDocument()
        expect(roundsInput).toHaveAttribute('type', 'number')
        expect(roundsInput).toHaveAttribute('value', '5')
        expect(roundsInput).toHaveAttribute('min', '1')
        expect(roundsInput).toHaveAttribute('max', '20')

        //Check that roundsLengthInput is correctly rendered
        const roundLengthInput = screen.getByLabelText(/round length/i);
        expect(roundLengthInput).toBeInTheDocument();
        expect(roundLengthInput).toHaveAttribute('type', 'number');
        expect(roundLengthInput).toHaveAttribute('value', '20');
        expect(roundLengthInput).toHaveAttribute('min', '1');
        expect(roundLengthInput).toHaveAttribute('max', '240');

        //Check that numOptionsInput is correctly rendered
        const numOptionsInput = screen.getByLabelText(/number of options/i);
        expect(numOptionsInput).toBeInTheDocument();
        expect(numOptionsInput).toHaveAttribute('type', 'number');
        expect(numOptionsInput).toHaveAttribute('value', '4');
        expect(numOptionsInput).toHaveAttribute('min', '2');
        expect(numOptionsInput).toHaveAttribute('max', '10');

        //Check that the start button is rendered
        expect(screen.getByText('Start')).toBeInTheDocument()
    })
})




//
// Unit test for GameSummary.jsx
//

//Mock round data thats stored in location state
jest.mock('react-router-dom', () => ({
    ...jest.requireActual('react-router-dom'),
    useLocation: () => ({
        pathname: '/mocked-path',
        state: {
            stats: [
                { round: 0, track: { track: { name: "Test Song" } }, isCorrect: true, time: 10, score: 20 },
            ],
        },
    }),
}))

describe('GameSummary Component', () => {
    //Mock some cookie data before each test
    beforeEach(() => {
        const mockedData = {
            GamesPlayed: 10,
            RoundsPlayed: 50,
            CorrectGuesses: 35,
            WrongGuesses: 15,
            Accuracy: 60.5,
            TotalScore: 500000,
            AverageScorePerRound: 4000,
            TimePlayed: 120000,
            AverageRoundTime: 1200,
            TimesOutOfTime: 4,
        }
        Cookies.set('playerStats', JSON.stringify(mockedData))
    })

    test('renders correctly with correct information', () => {
        render(
            <Router>
                <GameSummary />
            </Router>
        )

        //Check that all the components have rendered 
        expect(screen.getByText('Summary')).toBeInTheDocument()
        expect(screen.getByText('Play Again')).toBeInTheDocument()
        expect(screen.getByText('Home')).toBeInTheDocument()
        expect(screen.getByText(/Final Score:/i)).toBeInTheDocument()
        expect(screen.getByText('Stop Audio')).toBeInTheDocument()
    })
})

//
// Unit test for HomePage.jsx
//

//Mock the spotify log in button
jest.mock('../services/LoginToSpotify', () => ({
    __esModule: true,
    default: () => <div data-testid="mocked-login">Login</div>,
}))

describe('HomePage Component', () => {
    test('renders correctly', () => {
        render(
            <Router>
                <HomePage />
            </Router>
        )

        //Check for login to be rendered
        expect(screen.getByTestId('mocked-login')).toBeInTheDocument()

        //Check that start game button is rendered with the correct link
        const startGameButton = screen.getByText('Start Game')
        expect(startGameButton).toBeInTheDocument()
        expect(startGameButton.closest('a')).toHaveAttribute('href', '/choose-playlist')

        //Check that stats link is rendered with the correct link
        const statsLink = screen.getByText('Stats')
        expect(statsLink).toBeInTheDocument()
        expect(statsLink.closest('a')).toHaveAttribute('href', '/stats')
    })
})

//
// Unit tests for Player.stats.jsx
//

//Mock cookie
jest.mock('js-cookie', () => ({
    __esModule: true,
    default: {
        get: jest.fn(),
        set: jest.fn(),
    },
}))

describe('PlayerStats Component', () => {
    it('renders correctly with empty data from cookie', () => {
        // Mocking Cookies.get to return 0 for each data
        //This is because in PlayerStats.jsx, it updates the cookie with this and then gets it again
        Cookies.get.mockReturnValueOnce('{"GamesPlayed":0,"RoundsPlayed":0,"CorrectGuesses":0,"WrongGuesses":0,"Accuracy":0,"TotalScore":0,"AverageScorePerRound":0,"TimePlayed":0,"AverageRoundTime":0,"TimesOutOfTime":0}')

        render(
            <Router>
                <PlayerStats />
            </Router>
        )

        //Check that home button is rendered with right link
        const homeLink = screen.getByText('Home')
        expect(homeLink).toBeInTheDocument()
        expect(homeLink.closest('a')).toHaveAttribute('href', '/home')

        //get the test json id for checking if any json text is inside
        const preTag = screen.getByTestId('test-json-data')

        //Check that the <pre> tag has nothing inside but renders
        expect(preTag).toHaveTextContent(/.+/)
    })

    it('renders correctly with non-empty data', () => {
        // Mocking Cookies.get to return non-empty data
        Cookies.get.mockReturnValueOnce('{"GamesPlayed":5,"RoundsPlayed":10,"CorrectGuesses":8,"WrongGuesses":2,"Accuracy":80,"TotalScore":100,"AverageScorePerRound":10,"TimePlayed":500,"AverageRoundTime":50,"TimesOutOfTime":1}')
        render(
            <Router>
                <PlayerStats />
            </Router>
        )

        //Check that home button is rendered with link
        const homeLink = screen.getByText('Home')
        expect(homeLink).toBeInTheDocument()
        expect(homeLink.closest('a')).toHaveAttribute('href', '/home')

        //get the test json id for checking if any json text is inside
        const preTag = screen.getByTestId('test-json-data')

        //Check that the <pre> tag has text inside it but renders
        expect(preTag).toHaveTextContent(/.+/)
    })
})

//
//Unit test for Option.jsx
//


describe('Option', () => {
    test('renders option button text', () => {
        const track = { track: { name: 'Song Name' } }
        const handleOptionClick = jest.fn()
        const disabled = false

        render(<Option track={track} handleOptionClick={handleOptionClick} disabled={disabled} />)

        //Verify that the button is rendered with the song name
        const optionButton = screen.getByText('Song Name')
        expect(optionButton).toBeInTheDocument()
    })

    test('check if button function works', () => {
        const track = { track: { name: 'Song Name 2' } }
        const handleOptionClick = jest.fn()
        const disabled = false

        render(<Option track={track} handleOptionClick={handleOptionClick} disabled={disabled} />)

        //click the button and check for correct value in function
        const optionButton = screen.getByText('Song Name 2')
        fireEvent.click(optionButton)
        expect(handleOptionClick).toHaveBeenCalledWith(track)
    })

    test('button is disabled when disabled is true', () => {
        const track = { track: { name: 'Song Name 3' } }
        const handleOptionClick = jest.fn()
        const disabled = true

        render(<Option track={track} handleOptionClick={handleOptionClick} disabled={disabled} />)

        //Verify that button is rendered with correct text and is disabled
        const optionButton = screen.getByText('Song Name 3')
        expect(optionButton).toBeInTheDocument()
        expect(optionButton).toBeDisabled()
    })
})

//
// Unit test fir Round.jsx
//

//Mock all the needed components

jest.mock('../components/GameStuff/Option', () => ({
    __esModule: true,
    default: ({ track, handleOptionClick, disabled }) => <button data-testid="mocked-option" disabled={disabled} onClick={() => handleOptionClick(track)}>{track.track.name}</button>,
}))

jest.mock('../components/GameStuff/RoundStuff/RoundSummary', () => ({
    __esModule: true,
    default: ({ isVisible }) => isVisible ? <div data-testid="mocked-summary">This is a round summary</div> : <></>,
}))

jest.mock('../components/GameStuff/RoundStuff/NextRoundBtn', () => ({
    __esModule: true,
    default: ({ isVisible }) => isVisible ? <button data-testid="mocked-next-round-button">Next Round Button</button> : <></>,
}))

jest.mock('../components/GameStuff/RoundStuff/RoundTimer', () => ({
    __esModule: true,
    default: () => <div data-testid="mocked-round-timer">10000</div>,
}))

//Tests 1 checks if everything is rendered correctly when round is beginning
//Test 2 checks if everything is rendered correctly when round is over
describe('Round', () => {
    //Need fake timers for the test, cleanup
    beforeEach(() => {
        jest.useFakeTimers()
    })

    afterEach(() => {
        jest.clearAllTimers()
    })
    //This round has 2 wrong and 1 right option
    test('renders a round correctly', () => {
        const correctTrack = { track: { id: '1', name: 'Correct Song Name', duration_ms: 60000 } }
        const otherTracks = [
            { track: { id: '2', name: 'Wrong Song 1' } },
            { track: { id: '3', name: 'Wrong Song 2' } },
        ]
        const roundNumber = 0
        const roundTime = 30000
        const updateRoundStats = jest.fn()
        const volume = 0.5
        const isLastRound = false

        render(
            <Round
                correctTrack={correctTrack}
                otherTracks={otherTracks}
                roundNumber={roundNumber}
                roundTime={roundTime}
                updateRoundStats={updateRoundStats}
                volume={volume}
                isLastRound={isLastRound}
                playTrack={jest.fn()}
                setVolume={jest.fn()}
                pauseTrack={jest.fn()}
                skipTo={jest.fn()}
            />
        )

        //Check if correct amount of mocked options are rendered, 3 should be present
        const optionsElements = screen.getAllByTestId('mocked-option')
        expect(optionsElements).toHaveLength(3)
        //Check that we cant see the round summary yet
        expect(screen.queryByTestId('mocked-summary')).not.toBeInTheDocument()
        //Check that next round button is not rendered yet
        expect(screen.queryByTestId('mocked-next-round-button')).not.toBeInTheDocument()
        //Check if displays correct round number , should be Round 1
        expect(screen.getByText('Round 1')).toBeInTheDocument()
        //Check if round timer is rendered
        expect(screen.queryByTestId('mocked-round-timer')).toBeInTheDocument()
    })

    //Test when round is over, that correct components rendered
    test('renders a round that is over correctly', async () => {
        const correctTrack = { track: { id: '1', name: 'Correct Song Name', duration_ms: 60000 } }
        const otherTracks = [
            { track: { id: '2', name: 'Wrong Song 1' } },
            { track: { id: '3', name: 'Wrong Song 2' } },
        ]
        const roundNumber = 0
        const roundTime = 30000
        const updateRoundStats = jest.fn()
        const volume = 0.5
        const isLastRound = false

        const handleOptionClick = jest.fn()

        render(
            <Round
                correctTrack={correctTrack}
                otherTracks={otherTracks}
                roundNumber={roundNumber}
                roundTime={roundTime}
                updateRoundStats={updateRoundStats}
                volume={volume}
                isLastRound={isLastRound}
                playTrack={jest.fn()}
                setVolume={jest.fn()}
                pauseTrack={jest.fn()}
                skipTo={jest.fn()}
                handleOptionClick={handleOptionClick}
            />
        )

        //First check if correct number of options loaded
        const optionsElements = screen.getAllByTestId('mocked-option')
        expect(optionsElements).toHaveLength(3)

        //Check that we cant see the round summary yet
        expect(screen.queryByTestId('mocked-summary')).not.toBeInTheDocument()
        //Check that next round button is not rendered yet
        expect(screen.queryByTestId('mocked-next-round-button')).not.toBeInTheDocument()

        //Wait 3.5 seconds to start the round after 3 sec countdown
        act(() => {
            jest.advanceTimersByTime(3500) //3.5 seconds pass
        })

        //Select an option to end the round
        fireEvent.click(optionsElements[0])

        //Check that we can see the round summary
        await waitFor(() => expect(screen.getByTestId('mocked-summary')).toBeInTheDocument())
        //Check that next round button is rendered
        expect(screen.getByTestId('mocked-next-round-button')).toBeInTheDocument()
        //Check if displays correct round number , should be Round 1
        expect(screen.getByText('Round 1')).toBeInTheDocument()
        //Check if round timer is rendered
        expect(screen.queryByTestId('mocked-round-timer')).toBeInTheDocument()
    })
})

// 
// Unit test for Countdown.jsx
//


jest.useFakeTimers()

describe('Countdown', () => {
  afterEach(() => {
    //Clear and reset all timers after each test
    jest.clearAllTimers()
    //jest.useRealTimers()
  })

  //Test if the countdown has rendered succesfully to 3000 milliseconds
  it('renders the initial countdown value', () => {
    render(<Countdown handleCountdown={() => { }} />)
    expect(screen.getByText('Countdown: 3000')).toBeInTheDocument()
  })

  //Test to see if countdown decrements by 1000 ms succesfully after each second
  it('decrements the countdown every second', async () => {
    const handleCountdownMock = jest.fn()
    render(<Countdown handleCountdown={handleCountdownMock} />)

    act(() => {
      jest.advanceTimersByTime(1000)
    })
    await waitFor(() => expect(screen.getByText('Countdown: 2000')).toBeInTheDocument())

    act(() => {
      jest.advanceTimersByTime(1000)
    })
    await waitFor(() => expect(screen.getByText('Countdown: 1000')).toBeInTheDocument())

    act(() => {
      jest.advanceTimersByTime(1000)
    })
    await waitFor(() => expect(screen.getByText('Countdown: 0')).toBeInTheDocument())

    //Ensure that handleCountdown was called with the correct values
    expect(handleCountdownMock).toHaveBeenCalledWith(3000)
    expect(handleCountdownMock).toHaveBeenCalledWith(2000)
    expect(handleCountdownMock).toHaveBeenCalledWith(1000)
    expect(handleCountdownMock).toHaveBeenCalledWith(0)
  })
})

// 
// Unit test for NextRoundBtn.jsx
//


describe('Countdown', () => {
    //Test if the button is not rendered when shouldn't be
    it('check if button is not rendered when not visible', () => {
      const { queryByTestId } = render(<NextRoundBtn isVisible={false} />)
      const buttonElement = queryByTestId('next-round-button')
      expect(buttonElement).not.toBeInTheDocument()
    })
  
    //Test if button is rendered and has 'Next Round'
    it('check if button is visible and correct text', () => {
      const { queryByTestId } = render(<NextRoundBtn isVisible={true} isLastRound={false} />)
      const buttonElement = queryByTestId('next-round-button')
      expect(buttonElement).toBeInTheDocument()
      expect(buttonElement).toHaveTextContent('Next Round')
    })
  
      //Test if button is rendered and has 'Summary'
    it('check if button is visible and correct text', () => {
      const { queryByTestId } = render(<NextRoundBtn isVisible={true} isLastRound={true} />)
      const buttonElement = queryByTestId('next-round-button')
      expect(buttonElement).toBeInTheDocument()
      expect(buttonElement).toHaveTextContent('Summary')
    })
  })

  //
// Unit test for RoundSummary.jsx
//



// 3 Tests to simply check if the correct text is rendered on the screen based on conditions
describe('Round Summary', () => {
    test('renders summary when isVisible is true and isCorrect is true', () => {
        const data = { isCorrect: true, score: 4000, roundTime: 10000, time: 8000 }
        render(<RoundSummary data={data} isVisible={true} />)
        
        expect(screen.getByText('Correct')).toBeInTheDocument()
        expect(screen.getByText('Score: 4000')).toBeInTheDocument()
        expect(screen.getByText('Time: 2000')).toBeInTheDocument()
    })

    test('renders summary when isVisible is true and isCorrect is false and time is greater than 0', () => {
        const data = { isCorrect: false, score: 4000, roundTime: 10000, time: 8000 }
        render(<RoundSummary data={data} isVisible={true} />)

        expect(screen.getByText('Wrong')).toBeInTheDocument()
        expect(screen.getByText('Score: 4000')).toBeInTheDocument()
        expect(screen.getByText('Time: 2000')).toBeInTheDocument()
    })

    test('renders summary when isVisible is true and time is 0', () => {
        const data = { isCorrect: false, score: 0, roundTime: 10000, time: 0 }
        render(<RoundSummary data={data} isVisible={true} />)

        expect(screen.getByText('Out of time')).toBeInTheDocument()
        expect(screen.getByText('Score: 0')).toBeInTheDocument()
        expect(screen.getByText('Time: 10000')).toBeInTheDocument()
    })

    test('does not render anything when isVisible is false', () => {
        const data = { isCorrect: true, score: 3500, roundTime: 20000, time: 10000 }
        render(<RoundSummary data={data} isVisible={false} />)

        expect(screen.queryByText('Correct')).not.toBeInTheDocument()
        expect(screen.queryByText('Score: 3500')).not.toBeInTheDocument()
        expect(screen.queryByText('Time: 10000')).not.toBeInTheDocument()
    })
})

// 
// Unit test for RoundTimer.jsx
//


jest.useFakeTimers()

//2 Tests to check if the timer updates and doesn't update when conditions met
describe('Round Timer', () => {
    afterEach(() => {
        //Clear and reset all timers after each test
        jest.clearAllTimers()
        //jest.useRealTimers()
    })

    //Test if the timer has rendered succesfully to correct time
    it('renders the initial timer value', () => {
        render(<RoundTimer roundTime={20000} />)
        expect(screen.getByText('Round Timer: 20050')).toBeInTheDocument()
    })

    //Test to see if timer is decreasing when it should
    test('it updates the timer when activated', () => {
        const handleTimerChangeMock = jest.fn()
        render(
            <RoundTimer
                handleTimerChange={handleTimerChangeMock}
                timerActive={true}
                roundTime={3050}
            />
        );

        // Advance the timers by 50ms (dont forget 50ms is added on ui)
        act(() => {
            jest.advanceTimersByTime(50)
        })
        expect(screen.getByText('Round Timer: 3050')).toBeInTheDocument()

        act(() => {
            jest.advanceTimersByTime(50)
        })
        expect(screen.getByText('Round Timer: 3000')).toBeInTheDocument()

        expect(handleTimerChangeMock).toHaveBeenCalledWith(3050)
        expect(handleTimerChangeMock).toHaveBeenCalledWith(3000)
    })

    //Test to see if timer is not decreasing when it shouldnt
    test('it does not updates the timer when deactivated', () => {
        const handleTimerChangeMock = jest.fn()
        render(
            <RoundTimer
                handleTimerChange={handleTimerChangeMock}
                timerActive={false}
                roundTime={2000}
            />
        );

        // Advance the timers by 50ms (dont forget 50ms is added on ui), We dont want to handle timer change if its not active
        act(() => {
            jest.advanceTimersByTime(50)
        })
        expect(screen.getByText('Round Timer: 2050')).toBeInTheDocument()

        act(() => {
            jest.advanceTimersByTime(50)
        })
        expect(screen.getByText('Round Timer: 2050')).toBeInTheDocument()
    })
})

//
// Unit test for SummaryTrack.jsx
///


// 2 Tests that check if correct information is rendered, the play button works and is enabled when condition is met
describe('Track Summary', () => {
    test('renders track information and button correctly', () => {
        const track = { track: { name: 'Song Name' } }
        const playerReady = true
        const playGivenTrack = jest.fn()
        render(
            <SummaryTrack
                track={track}
                isCorrect={true}
                time={10000}
                score={5000}
                round={1}
                playerReady={playerReady}
                playGivenTrack={playGivenTrack}
            />
        )

        //Verify the round information rendered
        expect(screen.getByText(`Round: 1 | Track: Song Name | Correct: Yes | Time: 10000 | Score: 5000`)).toBeInTheDocument()

        //Verify button is rendered
        const playButton = screen.getByText('Play This Song')
        expect(playButton).toBeInTheDocument()
        expect(playButton).toBeEnabled()

        //click the button and check if correct value passed in
        fireEvent.click(playButton)
        expect(playGivenTrack).toHaveBeenCalledWith(track)
    })

    test('renders button as disabled when playerReady is false', () => {
        const track = { track: { name: 'Song Name 2' } }
        const playerReady = false
        render(
            <SummaryTrack
                track={track}
                isCorrect={true}
                time={15}
                score={25}
                round={3}
                playerReady={playerReady}
                playGivenTrack={jest.fn()}
            />
        )

        //Verify button is rendered and disabled
        const playButton = screen.getByText('Play This Song')
        expect(playButton).toBeInTheDocument()
        expect(playButton).toBeDisabled()
    })
})

//
// Unit test for Playlist.jsx
//


//Mock axios, dont want actual api calls
jest.mock('axios')

describe('Playlist', () => {
  const mockNavigate = jest.fn()
  //Mock data playlist
  const playlist = {
    name: 'Test Playlist',
    images: [{ url: 'https://test-image.com' }],
    tracks: { href: 'https://test-api.com/playlistTracks' },
  }

  beforeAll(() => {
    //Mock the useNavigate hook
    jest.mock('react-router-dom', () => ({
      ...jest.requireActual('react-router-dom'),
      useNavigate: () => mockNavigate,
    }))
  })

  afterEach(() => {
    //Cleanup hooks
    jest.clearAllMocks()
  })

  test('renders playlist button correctly', async () => {
    axios.get.mockResolvedValue({
      data: { items: ['track1', 'track2'] },
    })

    //render button
    render(<Router><Playlist playlist={playlist} /></Router>)

    const playlistButton = screen.getByText(playlist.name)
    expect(playlistButton).toBeInTheDocument()

    //Simulate button click
    fireEvent.click(playlistButton)

    //Wait for navigation to work
    await waitFor(() => {
      expect(window.location.pathname).toBe('/game-settings')
    })

    //Check that api was called
    expect(axios.get).toHaveBeenCalledWith(playlist.tracks.href, {
      headers: { Authorization: 'Bearer null' },
    })
  })
})


//
// Unit tests for Playlists.jsx
//


//Mock axios, dont want actual api calls
jest.mock('axios')

//Mock playlist
jest.mock('../components/PlaylistStuff/Playlist', () => ({
    __esModule: true,
    default: ({ playlist }) => <button data-testid={`mocked-playlist-${playlist.id}`}>{playlist.name}</button>,
}))

describe('Playlists', () => {
    const mockPlaylists = [
        {
            id: 'p1',
            name: 'Playlist 1',
            images: [],
            tracks: { href: 'https://api.spotify.com/v1/playlists/playlist1/tracks' },
        },
        {
            id: 'p2',
            name: 'Playlist 2',
            images: [],
            tracks: { href: 'https://api.spotify.com/v1/playlists/playlist2/tracks' },
        },
    ]

    beforeEach(() => {
        axios.get.mockReset()
    })

    it('renders playlists correctly', async () => {
        axios.get.mockResolvedValue({ data: { items: mockPlaylists } })

        render(<Playlists/>)

        //Wait for playlists to be rendered
        await waitFor(() => {
            expect(screen.getByText('Choose a Playlist')).toBeInTheDocument()
            //For each playlist check that it is rendered properly
            mockPlaylists.forEach((playlist) => {
                expect(screen.getByText(playlist.name)).toBeInTheDocument()
            })
        })

        //Check that the api was called succesfully
        expect(axios.get).toHaveBeenCalledWith("https://api.spotify.com/v1/me/playlists", {
            headers: { Authorization: 'Bearer null' },
            params: {
                limit: "50",
                offset: "0"
            }
        })
    })
})
