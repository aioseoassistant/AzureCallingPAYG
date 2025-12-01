import axios from 'axios';
import { CallRequest, CallResponse } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api';

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const callApi = {
  async makeCall(request: CallRequest): Promise<CallResponse> {
    const response = await apiClient.post<CallResponse>('/calls', request);
    return response.data;
  },

  async sendDtmf(callConnectionId: string, tones: string): Promise<CallResponse> {
    const response = await apiClient.post<CallResponse>(
      `/calls/${callConnectionId}/dtmf`,
      { tones }
    );
    return response.data;
  },

  async hangupCall(callConnectionId: string): Promise<CallResponse> {
    const response = await apiClient.delete<CallResponse>(`/calls/${callConnectionId}`);
    return response.data;
  },

  async getCallStatus(callConnectionId: string): Promise<any> {
    const response = await apiClient.get(`/calls/${callConnectionId}/status`);
    return response.data;
  },
};
