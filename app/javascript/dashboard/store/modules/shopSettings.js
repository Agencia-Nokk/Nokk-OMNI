import * as types from '../mutation-types';
import shopAPI from '../../api/shop';

const state = {
  settings: {
    enabled: false,
  },
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

export const getters = {
  getShopSettings(_state) {
    return _state.settings;
  },
  isShopEnabled(_state) {
    return _state.settings?.enabled || false;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  async get({ commit }) {
    commit(types.default.SET_SHOP_SETTINGS_UI_FLAG, { isFetching: true });
    try {
      const response = await shopAPI.getSettings();
      commit(types.default.SET_SHOP_SETTINGS, response.data);
    } catch (error) {
      // Ignore error - shop might not exist yet
    } finally {
      commit(types.default.SET_SHOP_SETTINGS_UI_FLAG, { isFetching: false });
    }
  },

  async update({ commit }, params) {
    commit(types.default.SET_SHOP_SETTINGS_UI_FLAG, { isUpdating: true });
    try {
      const response = await shopAPI.updateSettings({ setting: params });
      commit(types.default.UPDATE_SHOP_SETTINGS, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_SHOP_SETTINGS_UI_FLAG, { isUpdating: false });
    }
  },

  async toggleEnabled({ commit, state: _state }) {
    const newEnabled = !_state.settings.enabled;
    commit(types.default.SET_SHOP_SETTINGS_UI_FLAG, { isUpdating: true });
    try {
      const response = await shopAPI.updateSettings({
        setting: { enabled: newEnabled },
      });
      commit(types.default.UPDATE_SHOP_SETTINGS, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_SHOP_SETTINGS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.default.SET_SHOP_SETTINGS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_SHOP_SETTINGS](_state, data) {
    _state.settings = data;
  },
  [types.default.UPDATE_SHOP_SETTINGS](_state, data) {
    _state.settings = {
      ..._state.settings,
      ...data,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
