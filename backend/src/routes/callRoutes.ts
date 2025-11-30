import { Router } from 'express';
import { callController } from '../controllers/callController';

const router = Router();

// Call management routes
router.post('/calls', (req, res) => callController.initiateCall(req, res));
router.post('/calls/:callConnectionId/dtmf', (req, res) => callController.sendDtmf(req, res));
router.delete('/calls/:callConnectionId', (req, res) => callController.hangupCall(req, res));
router.get('/calls/:callConnectionId/status', (req, res) => callController.getCallStatus(req, res));

export default router;
