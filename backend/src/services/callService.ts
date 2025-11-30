import { CallAutomationClient, CallConnection } from '@azure/communication-call-automation';
import { PhoneNumberIdentifier } from '@azure/communication-common';
import { config } from '../config';
import { CallRequest, CallResponse, DtmfRequest, CallStatus } from '../types';

export class CallService {
  private client: CallAutomationClient;
  private activeCalls: Map<string, CallConnection>;

  constructor() {
    this.client = new CallAutomationClient(config.acsConnectionString);
    this.activeCalls = new Map();
  }

  /**
   * Initiate an outbound PSTN call
   */
  async makeCall(request: CallRequest): Promise<CallResponse> {
    try {
      const targetPhoneNumber: PhoneNumberIdentifier = {
        phoneNumber: request.targetPhoneNumber,
      };

      const sourceCallerId: PhoneNumberIdentifier = {
        phoneNumber: request.sourceCallerId || config.acsPhoneNumber,
      };

      console.log(`Initiating call to ${request.targetPhoneNumber} from ${sourceCallerId.phoneNumber}`);

      const result = await this.client.createCall(
        targetPhoneNumber,
        `${config.callbackUri}/events`,
        {
          sourceCallerId,
          operationContext: 'outbound-pstn-call',
        }
      );

      const callConnectionId = result.callConnectionProperties.callConnectionId;

      // Store the call connection for later use
      if (result.callConnection) {
        this.activeCalls.set(callConnectionId, result.callConnection);
      }

      console.log(`Call initiated successfully. Connection ID: ${callConnectionId}`);

      return {
        callConnectionId,
        status: 'success',
        message: 'Call initiated successfully',
      };
    } catch (error) {
      console.error('Error making call:', error);
      throw new Error(`Failed to make call: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Send DTMF tones during an active call
   */
  async sendDtmf(request: DtmfRequest): Promise<CallResponse> {
    try {
      const callConnection = this.activeCalls.get(request.callConnectionId);

      if (!callConnection) {
        throw new Error('Call connection not found or call may have ended');
      }

      console.log(`Sending DTMF tones "${request.tones}" to call ${request.callConnectionId}`);

      // Convert string tones to DTMF tone array
      const tones = request.tones.split('').map(tone => {
        const dtmfMap: Record<string, any> = {
          '0': 'zero', '1': 'one', '2': 'two', '3': 'three',
          '4': 'four', '5': 'five', '6': 'six', '7': 'seven',
          '8': 'eight', '9': 'nine', '*': 'star', '#': 'pound',
          'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd'
        };
        return dtmfMap[tone.toUpperCase()] || 'pound';
      });

      await callConnection.getCallMedia().sendDtmf(tones, {
        phoneNumber: config.acsPhoneNumber
      });

      console.log(`DTMF tones sent successfully to call ${request.callConnectionId}`);

      return {
        callConnectionId: request.callConnectionId,
        status: 'success',
        message: 'DTMF tones sent successfully',
      };
    } catch (error) {
      console.error('Error sending DTMF:', error);
      throw new Error(`Failed to send DTMF: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Hang up an active call
   */
  async hangupCall(callConnectionId: string): Promise<CallResponse> {
    try {
      const callConnection = this.activeCalls.get(callConnectionId);

      if (!callConnection) {
        throw new Error('Call connection not found');
      }

      console.log(`Hanging up call ${callConnectionId}`);

      await callConnection.hangUp(true);
      this.activeCalls.delete(callConnectionId);

      console.log(`Call ${callConnectionId} hung up successfully`);

      return {
        callConnectionId,
        status: 'success',
        message: 'Call ended successfully',
      };
    } catch (error) {
      console.error('Error hanging up call:', error);
      throw new Error(`Failed to hang up call: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Get call status
   */
  async getCallStatus(callConnectionId: string): Promise<CallStatus> {
    try {
      const callConnection = this.activeCalls.get(callConnectionId);

      if (!callConnection) {
        return {
          callConnectionId,
          callState: 'disconnected',
        };
      }

      const properties = await callConnection.getCallConnectionProperties();

      return {
        callConnectionId,
        callState: properties.callConnectionState || 'unknown',
      };
    } catch (error) {
      console.error('Error getting call status:', error);
      throw new Error(`Failed to get call status: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Handle call disconnection
   */
  removeCall(callConnectionId: string): void {
    this.activeCalls.delete(callConnectionId);
    console.log(`Call ${callConnectionId} removed from active calls`);
  }
}

export const callService = new CallService();
