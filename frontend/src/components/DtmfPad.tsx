import React from 'react';
import '../styles/DtmfPad.css';

interface DtmfPadProps {
  onDigitPress: (digit: string) => void;
  disabled?: boolean;
}

const DTMF_BUTTONS = [
  ['1', '2', '3'],
  ['4', '5', '6'],
  ['7', '8', '9'],
  ['*', '0', '#'],
];

export const DtmfPad: React.FC<DtmfPadProps> = ({ onDigitPress, disabled = false }) => {
  const handleClick = (digit: string) => {
    if (!disabled) {
      onDigitPress(digit);
      // Play a short beep sound (optional)
      playTone(digit);
    }
  };

  const playTone = (digit: string) => {
    // Optional: Add audio feedback
    // You can implement DTMF tone generation here
  };

  return (
    <div className="dtmf-pad">
      <div className="dtmf-grid">
        {DTMF_BUTTONS.map((row, rowIndex) => (
          <div key={rowIndex} className="dtmf-row">
            {row.map((digit) => (
              <button
                key={digit}
                className="dtmf-button"
                onClick={() => handleClick(digit)}
                disabled={disabled}
              >
                {digit}
              </button>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
};
