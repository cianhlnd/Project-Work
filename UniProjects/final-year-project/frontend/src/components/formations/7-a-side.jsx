import React from 'react';
import '../../styles/5-a-side.css';

function SevenASide() {
  return (
    <div className="container">
      <div className="header-container">
        <h1>7-a-side formations (u8s-u9s)</h1>
        <h2>2-2-2 (Rectangle)</h2>
        <img src="/images/7-a-side/2-2-2.png" alt="2-2-2" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Balanced throughout the whole team</li>
              <li>Is a progression of the 2-2 (box) formation</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Can be hard to build out from the back</li>
              <li>A team with wingers can exploit it easily</li>
              <li>Midfielders may get confused about whether to go wide or stay in the middle</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Have both strikers press onto retreat line</li>
              <li>Team goes wide in possession (big rectanlge) and narrow and compact out of possession (small rectangle)</li>
            </ul>
          </li>
        </ul>
      </div>
      <div className="header-container">
        <h2>2-3-1 (Christmas Tree)</h2>
        <img src="/images/7-a-side/2-3-1.png" alt="2-3-1" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Progression of 2-1-1 formation</li>
              <li>Most balanced formation</li>
              <li>Easier to build up from the back with a centre midfielder and 2 wingers</li>
              <li>Easier to press high with 3 attackers</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>If press is beaten can be exposed</li>
              <li>Centre midfielder has a lot of ground to cover which can be tough for them</li>
              <li>Wingers have to be disciplined which can be tough for young kids</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Defend goal kicks as a 3-3 formation and get players to man mark the opposition if they are also playing a 2-3-1</li>
              <li>When fully transitioned into defence have the wingers be compact acting as 2 extra midfielders, when attacking have them go wide</li>
            </ul>
          </li>
        </ul>
      </div>
      <div className="header-container">
        <h2>3-2-1 (Arrow)</h2>
        <img src="/images/7-a-side/3-2-1.png" alt="3-2-1" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Most defensively solid formation</li>
              <li>Easier to press teams high with 3 attackers</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Hard to pre</li>
              <li>Can be too defensive if full backs don't provide width</li>
              <li>Striker may end up isolated</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Get full backs to give the formation width</li>
              <li>Midfielders need to help the striker out when attacking</li>
              <li>Turn it into a 3-3 when defending goal kicks and get players to man mark opposition team</li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
  );
}

export default SevenASide;