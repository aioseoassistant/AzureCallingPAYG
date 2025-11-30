import { Request, Response } from 'express';
import { callService } from '../services/callService';
import { CallRequest, DtmfRequest } from '../types';

export class CallController {
  /**
   * POST /api/calls - Initiate a new call
   */
  async initiateCall(req: Request, res: Response): Promise<void> {
    try {
      const callRequest: CallRequest = req.body;

      // Validate phone number format
      if (!callRequest.targetPhoneNumber || !callRequest.targetPhoneNumber.startsWith('+')) {
        res.status(400).json({
          error: 'Invalid phone number. Must include country code (e.g., +1234567890)',
        });
        return;
      }

      const result = await callService.makeCall(callRequest);
      res.status(200).json(result);
    } catch (error) {
      console.error('Error in initiateCall:', error);
      res.status(500).json({
        error: 'Failed to initiate call',
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * POST /api/calls/:callConnectionId/dtmf - Send DTMF tones
   */
  async sendDtmf(req: Request, res: Response): Promise<void> {
    try {
      const { callConnectionId } = req.params;
      const { tones } = req.body;

      if (!tones || typeof tones !== 'string') {
        res.status(400).json({
          error: 'Invalid DTMF tones. Must be a string of digits, *, #, or A-D',
        });
        return;
      }

      const dtmfRequest: DtmfRequest = {
        callConnectionId,
        tones,
      };

      const result = await callService.sendDtmf(dtmfRequest);
      res.status(200).json(result);
    } catch (error) {
      console.error('Error in sendDtmf:', error);
      res.status(500).json({
        error: 'Failed to send DTMF tones',
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * DELETE /api/calls/:callConnectionId - Hang up a call
   */
  async hangupCall(req: Request, res: Response): Promise<void> {
    try {
      const { callConnectionId } = req.params;
      const result = await callService.hangupCall(callConnectionId);
      res.status(200).json(result);
    } catch (error) {
      console.error('Error in hangupCall:', error);
      res.status(500).json({
        error: 'Failed to hang up call',
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  /**
   * GET /api/calls/:callConnectionId/status - Get call status
   */
  async getCallStatus(req: Request, res: Response): Promise<void> {
    try {
      const { callConnectionId } = req.params;
      const result = await callService.getCallStatus(callConnectionId);
      res.status(200).json(result);
    } catch (error) {
      console.error('Error in getCallStatus:', error);
      res.status(500).json({
        error: 'Failed to get call status',
        message: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }
}

export const callController = new CallController();
