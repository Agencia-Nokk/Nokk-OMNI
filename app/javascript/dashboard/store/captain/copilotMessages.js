import CopilotMessagesAPI from 'dashboard/api/captain/copilotMessages';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'CopilotMessages',
  API: CopilotMessagesAPI,
  getters: {
    getMessagesByThreadId: state => copilotThreadId => {
      return state.records
        .filter(record => record.copilot_thread?.id === Number(copilotThreadId))
        .sort((a, b) => a.id - b.id);
    },
  },
  actions: mutationTypes => ({
    upsert({ commit }, data) {
      commit(mutationTypes.UPSERT, data);
    },
    async get({ commit }, threadId) {
      commit(mutationTypes.SET_UI_FLAG, { fetchingItem: true });
      try {
        const response = await CopilotMessagesAPI.get(threadId);
        const messages = response.data.payload || [];
        messages.forEach(message => {
          commit(mutationTypes.UPSERT, message);
        });
        return messages;
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { fetchingItem: false });
      }
    },
  }),
});
