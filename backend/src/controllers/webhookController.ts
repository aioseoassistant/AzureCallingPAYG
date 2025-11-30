import { Request, Response } from 'express';
import { callService } from '../services/callService';

export class WebhookController {
  /**
   * POST /api/callbacks/events - Handle Azure Communication Services events
   */
  async handleCallEvents(req: Request, res: Response): Promise<void> {
    try {
      const events = req.body;

      console.log('Received webhook events:', JSON.stringify(events, null, 2));

      // Azure sends events as an array
      if (Array.isArray(events)) {
        for (const event of events) {
          await this.processEvent(event);
        }
      } else {
        await this.processEvent(events);
      }

      // Always return 200 OK to acknowledge receipt
      res.status(200).send();
    } catch (error) {
      console.error('Error handling webhook:', error);
      // Still return 200 to prevent Azure from retrying
      res.status(200).send();
    }
  }

  private async processEvent(event: any): Promise<void> {
    const eventType = event.type || event.eventType;
    const callConnectionId = event.data?.callConnectionId || event.callConnectionId;

    console.log(`Processing event: ${eventType} for call ${callConnectionId}`);

    switch (eventType) {
      case 'Microsoft.Communication.CallConnected':
        console.log(`Call ${callConnectionId} connected`);
        break;

      case 'Microsoft.Communication.CallDisconnected':
        console.log(`Call ${callConnectionId} disconnected`);
        if (callConnectionId) {
          callService.removeCall(callConnectionId);
        }
        break;

      case 'Microsoft.Communication.CallTransferAccepted':
        console.log(`Call ${callConnectionId} transfer accepted`);
        break;

      case 'Microsoft.Communication.CallTransferFailed':
        console.log(`Call ${callConnectionId} transfer failed`);
        break;

      case 'Microsoft.Communication.RecognizeCompleted':
        console.log(`DTMF recognition completed for call ${callConnectionId}`);
        if (event.data?.recognitionResult) {
          console.log('Recognized tones:', event.data.recognitionResult);
        }
        break;

      case 'Microsoft.Communication.RecognizeFailed':
        console.log(`DTMF recognition failed for call ${callConnectionId}`);
        break;

      case 'Microsoft.Communication.PlayCompleted':
        console.log(`Audio playback completed for call ${callConnectionId}`);
        break;

      case 'Microsoft.Communication.PlayFailed':
        console.log(`Audio playback failed for call ${callConnectionId}`);
        break;

      default:
        console.log(`Unhandled event type: ${eventType}`);
    }
  }
}

export const webhookController = new WebhookController();
