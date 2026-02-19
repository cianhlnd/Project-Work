import React from 'react';
import '../../styles/5-a-side.css';

function FiveASide() {
  return (
    <div className="container">
      <div className="header-container">
        <h1>5-a-side formations (u8s-u9s)</h1>
        <h2>2-1-1 (Christmas Tree)</h2>
        <img src="/images/5-a-side/2-1-1.png" alt="2-1-1" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>2 defenders allows for more defensive solidity</li>
              <li>Having a centre mid gives more options for building out of defensive</li>
              <li>Allows for easier transition to 2-3-1 in 7-a-side</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Hard to press teams up high with only 1 forward player</li>
              <li>Striker can become isolated</li>
              <li>Defenders can sit too deep</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Get both Striker and centre mid to press onto retreat line</li>
              <li>Defenders go wide when team has possession and go tighter when out of possession</li>
            </ul>
          </li>
        </ul>
      </div>
      <div className="header-container">
        <h2>2-2 (Box)</h2>
        <img src="/images/5-a-side/2-2.png" alt="2-2" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Easy to explain to kids</li>
              <li>Easy to maintain width</li>
              <li>Easier to press teams high with 2 attackers</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Can be hard to build out from goal kicks</li>
              <li>No central players means kids don't get experience playing central positions</li>
              <li>May end up with too big a gap between defenders and attackers</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Get both wingers to press onto retreat line</li>
              <li>Team goes wide in possession (big box) and narrow and compact out of possession (small box)</li>
            </ul>
          </li>
        </ul>
      </div>
      <div className="header-container">
        <h2>1-2-1 (Diamond)</h2>
        <img src="/images/5-a-side/1-2-1.png" alt="1-2-1" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Easy to explain to kids</li>
              <li>Easy to maintain width</li>
              <li>Very attacking</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Can be hard to build out from goal kicks with only one defender and no centre mid</li>
              <li>Dependent on wingers to get up and help attacker and back to help defender</li>
              <li>Due to it being so attacking can get count on the counter-attack</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Get on the striker to press onto retreat line to be defensively responsible</li>
              <li>Team goes wide in possession (big diamond) and narrow and compact out of possession (small diamond)</li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
  );
}

export default FiveASide;