import React, { useState } from 'react';
import { DtmfPad } from './DtmfPad';
import { callApi } from '../services/api';
import { CallState } from '../types';
import '../styles/Dialer.css';

export const Dialer: React.FC = () => {
  const [phoneNumber, setPhoneNumber] = useState('');
  const [callState, setCallState] = useState<CallState>({
    isActive: false,
    callConnectionId: null,
    phoneNumber: '',
    status: 'idle',
  });
  const [error, setError] = useState<string | null>(null);

  const handlePhoneNumberChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value.replace(/[^0-9+]/g, '');
    setPhoneNumber(value);
  };

  const handleDigitPress = (digit: string) => {
    if (callState.isActive && callState.callConnectionId) {
      // Send DTMF during active call
      sendDtmf(digit);
    } else {
      // Add digit to phone number
      setPhoneNumber((prev) => prev + digit);
    }
  };

  const makeCall = async () => {
    if (!phoneNumber) {
      setError('Please enter a phone number');
      return;
    }

    if (!phoneNumber.startsWith('+')) {
      setError('Phone number must include country code (e.g., +1234567890)');
      return;
    }

    setError(null);
    setCallState({
      isActive: false,
      callConnectionId: null,
      phoneNumber,
      status: 'calling',
    });

    try {
      const response = await callApi.makeCall({
        targetPhoneNumber: phoneNumber,
      });

      setCallState({
        isActive: true,
        callConnectionId: response.callConnectionId,
        phoneNumber,
        status: 'connected',
        startTime: new Date(),
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to make call';
      setError(errorMessage);
      setCallState({
        isActive: false,
        callConnectionId: null,
        phoneNumber: '',
        status: 'error',
        error: errorMessage,
      });
    }
  };

  const sendDtmf = async (tones: string) => {
    if (!callState.callConnectionId) return;

    try {
      await callApi.sendDtmf(callState.callConnectionId, tones);
    } catch (err) {
      console.error('Failed to send DTMF:', err);
      setError('Failed to send DTMF tones');
    }
  };

  const hangUp = async () => {
    if (!callState.callConnectionId) return;

    try {
      await callApi.hangupCall(callState.callConnectionId);
      setCallState({
        isActive: false,
        callConnectionId: null,
        phoneNumber: '',
        status: 'disconnected',
      });
      setPhoneNumber('');
    } catch (err) {
      console.error('Failed to hang up:', err);
      setError('Failed to hang up call');
    }
  };

  const handleBackspace = () => {
    setPhoneNumber((prev) => prev.slice(0, -1));
  };

  const formatPhoneNumber = (number: string): string => {
    return number;
  };

  return (
    <div className="dialer-container">
      <div className="dialer-card">
        <h1 className="dialer-title">Azure Phone Dialer</h1>

        {error && (
          <div className="error-message">
            {error}
            <button className="error-close" onClick={() => setError(null)}>
              ×
            </button>
          </div>
        )}

        <div className="phone-display">
          <input
            type="tel"
            className="phone-input"
            value={formatPhoneNumber(phoneNumber)}
            onChange={handlePhoneNumberChange}
            placeholder="+1234567890"
            disabled={callState.isActive}
          />
          {!callState.isActive && phoneNumber && (
            <button className="backspace-button" onClick={handleBackspace}>
              ⌫
            </button>
          )}
        </div>

        {callState.status !== 'idle' && (
          <div className={`call-status status-${callState.status}`}>
            {callState.status === 'calling' && 'Calling...'}
            {callState.status === 'connected' && `Connected to ${callState.phoneNumber}`}
            {callState.status === 'disconnected' && 'Call ended'}
            {callState.status === 'error' && 'Call failed'}
          </div>
        )}

        <DtmfPad
          onDigitPress={handleDigitPress}
          disabled={callState.status === 'calling'}
        />

        <div className="call-controls">
          {!callState.isActive ? (
            <button
              className="call-button call-button-primary"
              onClick={makeCall}
              disabled={!phoneNumber || callState.status === 'calling'}
            >
              📞 Call
            </button>
          ) : (
            <button className="call-button call-button-danger" onClick={hangUp}>
              📵 Hang Up
            </button>
          )}
        </div>

        {callState.isActive && (
          <div className="call-info">
            <p>Call ID: {callState.callConnectionId}</p>
            {callState.startTime && (
              <p>
                Started:{' '}
                {new Date(callState.startTime).toLocaleTimeString()}
              </p>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
