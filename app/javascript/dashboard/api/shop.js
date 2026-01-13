/* global axios */
import ApiClient from './ApiClient';

class ShopAPI extends ApiClient {
  constructor() {
    super('shop', { accountScoped: true });
  }

  // Settings
  getSettings() {
    return axios.get(`${this.url}/settings`);
  }

  updateSettings(settingsData) {
    return axios.patch(`${this.url}/settings`, settingsData);
  }

  // Categories
  getCategories() {
    return axios.get(`${this.url}/categories`);
  }

  createCategory(categoryData) {
    return axios.post(`${this.url}/categories`, categoryData);
  }

  updateCategory(categoryId, categoryData) {
    return axios.patch(`${this.url}/categories/${categoryId}`, categoryData);
  }

  deleteCategory(categoryId) {
    return axios.delete(`${this.url}/categories/${categoryId}`);
  }

  // Products
  getProducts(params = {}) {
    return axios.get(`${this.url}/products`, { params });
  }

  getProduct(productId) {
    return axios.get(`${this.url}/products/${productId}`);
  }

  createProduct(productData) {
    return axios.post(`${this.url}/products`, productData);
  }

  updateProduct(productId, productData) {
    return axios.patch(`${this.url}/products/${productId}`, productData);
  }

  deleteProduct(productId) {
    return axios.delete(`${this.url}/products/${productId}`);
  }

  // Carts
  getCarts() {
    return axios.get(`${this.url}/carts`);
  }

  getCart(cartId) {
    return axios.get(`${this.url}/carts/${cartId}`);
  }

  getCartByConversation(conversationId) {
    return axios.get(`${this.url}/carts/conversation/${conversationId}`);
  }

  addItemToCart(cartId, itemData) {
    return axios.post(`${this.url}/carts/${cartId}/add_item`, itemData);
  }

  removeItemFromCart(cartId, itemId) {
    return axios.delete(`${this.url}/carts/${cartId}/items/${itemId}`);
  }

  updateCartItem(cartId, itemId, quantity) {
    return axios.patch(`${this.url}/carts/${cartId}/items/${itemId}`, {
      quantity,
    });
  }

  convertCartToOrder(cartId, orderData) {
    return axios.post(
      `${this.url}/carts/${cartId}/convert_to_order`,
      orderData
    );
  }

  // Orders
  getOrders(params = {}) {
    return axios.get(`${this.url}/orders`, { params });
  }

  getOrder(orderId) {
    return axios.get(`${this.url}/orders/${orderId}`);
  }

  updateOrder(orderId, orderData) {
    return axios.patch(`${this.url}/orders/${orderId}`, orderData);
  }

  confirmOrder(orderId) {
    return axios.post(`${this.url}/orders/${orderId}/confirm`);
  }

  cancelOrder(orderId) {
    return axios.post(`${this.url}/orders/${orderId}/cancel`);
  }
}

export default new ShopAPI();
