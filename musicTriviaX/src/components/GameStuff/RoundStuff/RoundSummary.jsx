//
// Provides a basic summary of round statistics, only shows up once the round is finished
//

function RoundSummary({ data, isVisible }) {
  if (isVisible) {
    return (
      //Added style for each type of answer given (wrong, right, out of time)
      <div>
        <div>
          {data.isCorrect ? (
            <div style={{
              color: 'white',
              border: '1px solid green',
              backgroundColor: 'green',
              textAlign: 'center',
              padding: '5px',
              borderRadius: '5px',
              width: '200px',
              top: '30%',
              position: 'absolute',
              transform: 'translateX(-50%)',
              left: '50%'
            }}>
              Correct
            </div>
          ) : data.time > 0 ? (
            <div style={{
              color: 'white',
              border: '1px solid red',
              backgroundColor: 'red',
              textAlign: 'center',
              padding: '5px',
              borderRadius: '5px',
              width: '200px',
              top: '30%',
              position: 'absolute',
              transform: 'translateX(-50%)',
              left: '50%'
            }}>
              Wrong
            </div>
          ) : (
            <div style={{
              color: 'white',
              border: '1px solid red',
              backgroundColor: 'red',
              textAlign: 'center',
              padding: '5px',
              borderRadius: '5px',
              width: '200px',
              top: '30%',
              position: 'absolute',
              transform: 'translateX(-50%)',
              left: '50%'
            }}>
              Out of time
            </div>
          )}
        </div>
        <div className="score">
          Score: {data.score}
        </div>
        <div className="time-score">
          Time: {data.roundTime - data.time}
        </div>
      </div>
    );
  }
}


export default RoundSummary