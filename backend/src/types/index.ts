export interface CallRequest {
  targetPhoneNumber: string;
  sourceCallerId?: string;
}

export interface DtmfRequest {
  callConnectionId: string;
  tones: string;
}

export interface CallResponse {
  callConnectionId: string;
  status: string;
  message?: string;
}

export interface CallStatus {
  callConnectionId: string;
  callState: string;
  startTime?: Date;
  answerTime?: Date;
  endTime?: Date;
}

export interface WebhookEvent {
  type: string;
  callConnectionId: string;
  data: any;
}

export enum CallState {
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  DISCONNECTED = 'disconnected',
  TRANSFERRING = 'transferring',
  FAILED = 'failed'
}

export enum DtmfTone {
  ZERO = '0',
  ONE = '1',
  TWO = '2',
  THREE = '3',
  FOUR = '4',
  FIVE = '5',
  SIX = '6',
  SEVEN = '7',
  EIGHT = '8',
  NINE = '9',
  STAR = '*',
  POUND = '#',
  A = 'A',
  B = 'B',
  C = 'C',
  D = 'D'
}
