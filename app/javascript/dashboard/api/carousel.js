/* global axios */

class CarouselAPI {
  constructor() {
    this.baseUrl = '/api/v1/accounts';
  }

  getUrl(accountId, conversationId) {
    return `${this.baseUrl}/${accountId}/conversations/${conversationId}/carousel`;
  }

  sendCarousel(accountId, conversationId, { productIds, text }) {
    const url = this.getUrl(accountId, conversationId);
    return axios.post(url, {
      product_ids: productIds,
      text,
    });
  }
}

export default new CarouselAPI();
