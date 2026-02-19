import React from 'react';
import '../../styles/5-a-side.css';

function NineASide() {
  return (
    <div className="container">
      <div className="header-container">
        <h1>9-a-side formations (u8s-u9s)</h1>
        <h2>2-3-3</h2>
        <img src="/images/9-a-side/2-3-3.png" alt="2-3-3" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Very attacking</li>
              <li>Easier to press high with 3 attackers</li>
              <li>Progression of 2-3-1 formation</li>
              <li>Progresses well into 4-3-3 when players go 11-a-side</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Lacks defensive solidity</li>
              <li>If press is beaten can be easily exposed</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Have one of the midfielders drop into defence out of possession if struggling defensively</li>
              <li>Get 3 attackers to press oppostion's defence straight away if aim is to win the ball back quickly</li>
            </ul>
          </li>
        </ul>
      </div>
      <div className="header-container">
        <h2>3-2-3</h2>
        <img src="/images/9-a-side/3-2-3.png" alt="3-2-3" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Very balanced formation</li>
              <li>Can press high with 3 attackers</li>
              <li>Lot of options for building out from the back</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Wingers have to be able to get up and down</li>
              <li>3 defenders means you're losing another attacking player</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Can have central defender step into midield to act as a holding midfielder if you want to dominate possession and press high</li>
              <li>Full backs can give support to wingers when attacking</li>
            </ul>
          </li>
        </ul>
      </div>
      <div className="header-container">
        <h2>3-3-2</h2>
        <img src="/images/9-a-side/3-3-2.png" alt="3-3-2" />
      </div>
      <div className="list-container">
        <ul className="list-item">
          <li><strong>Pros:</strong>
            <ul>
              <li>Very balanced formation</li>
              <li>Easier to dominate midfield with midfielders</li>
              <li>Lot of options for building out from the back</li>
            </ul>
          </li>
          <li><strong>Cons:</strong>
            <ul>
              <li>Lacks width</li>
              <li>Only 2 attackers</li>
              <li>2 attackers makes it harder to press high</li>
            </ul>
          </li>
          <li><strong>Tips:</strong>
            <ul>
              <li>Allow full backs to provide width</li>
              <li>Compact out of possession and wide when in possession (as much as possible with formation restrictions)</li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
  );
}

export default NineASide;