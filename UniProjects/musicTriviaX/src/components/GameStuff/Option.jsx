//
// A single option that is used in a round
//

import '../../styles/game.css'

function Option({ track, handleOptionClick, disabled }) {

  //Logic for handling the click of an option is within the parent component
  const handleOptionClickInChild = () => {
    handleOptionClick(track);
  }

  return (
    <div className="game-container">
      <button
        onClick={handleOptionClickInChild}
        disabled={disabled}
        className="option-button"
      >
        {track.track.name}
      </button>
    </div>
  )
}

export default Option
