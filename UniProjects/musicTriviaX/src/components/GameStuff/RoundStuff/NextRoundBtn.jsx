//
// A button that moves onto the next round, it is only visible once certain conditions are met i.e round is over
//

function NextRoundBtn({ nextRound, isVisible, isLastRound }) {
    //Moves onto next round, logic for moving onto next round is provided by parent
    const handleNextRoundClick = () => {
        nextRound()
    }
    //Only visible under conditions
    if (isVisible) {
        return (
            <button 
            data-testid="next-round-button" 
            onClick={handleNextRoundClick}>
                {isLastRound ? "Summary" : "Next Round"}
            </button>
        )
    }
}

export default NextRoundBtn