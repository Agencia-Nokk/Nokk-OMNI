import ApiClient from './ApiClient';

class ShopAPI extends ApiClient {
  constructor() {
    super('shop', { accountScoped: true });
  }

  // Categories
  getCategories(accountId) {
    return axios.get(`${this.url}/${accountId}/shop/categories`);
  }

  createCategory(accountId, categoryData) {
    return axios.post(`${this.url}/${accountId}/shop/categories`, categoryData);
  }

  updateCategory(accountId, categoryId, categoryData) {
    return axios.patch(
      `${this.url}/${accountId}/shop/categories/${categoryId}`,
      categoryData
    );
  }

  deleteCategory(accountId, categoryId) {
    return axios.delete(`${this.url}/${accountId}/shop/categories/${categoryId}`);
  }

  // Products
  getProducts(accountId, params = {}) {
    return axios.get(`${this.url}/${accountId}/shop/products`, { params });
  }

  getProduct(accountId, productId) {
    return axios.get(`${this.url}/${accountId}/shop/products/${productId}`);
  }

  createProduct(accountId, productData) {
    return axios.post(`${this.url}/${accountId}/shop/products`, productData);
  }

  updateProduct(accountId, productId, productData) {
    return axios.patch(
      `${this.url}/${accountId}/shop/products/${productId}`,
      productData
    );
  }

  deleteProduct(accountId, productId) {
    return axios.delete(`${this.url}/${accountId}/shop/products/${productId}`);
  }

  // Carts
  getCarts(accountId) {
    return axios.get(`${this.url}/${accountId}/shop/carts`);
  }

  getCart(accountId, cartId) {
    return axios.get(`${this.url}/${accountId}/shop/carts/${cartId}`);
  }

  getCartByConversation(accountId, conversationId) {
    return axios.get(
      `${this.url}/${accountId}/shop/carts/conversation/${conversationId}`
    );
  }

  addItemToCart(accountId, cartId, itemData) {
    return axios.post(
      `${this.url}/${accountId}/shop/carts/${cartId}/add_item`,
      itemData
    );
  }

  removeItemFromCart(accountId, cartId, itemId) {
    return axios.delete(
      `${this.url}/${accountId}/shop/carts/${cartId}/items/${itemId}`
    );
  }

  updateCartItem(accountId, cartId, itemId, quantity) {
    return axios.patch(
      `${this.url}/${accountId}/shop/carts/${cartId}/items/${itemId}`,
      { quantity }
    );
  }

  convertCartToOrder(accountId, cartId, orderData) {
    return axios.post(
      `${this.url}/${accountId}/shop/carts/${cartId}/convert_to_order`,
      orderData
    );
  }

  // Orders
  getOrders(accountId, params = {}) {
    return axios.get(`${this.url}/${accountId}/shop/orders`, { params });
  }

  getOrder(accountId, orderId) {
    return axios.get(`${this.url}/${accountId}/shop/orders/${orderId}`);
  }

  updateOrder(accountId, orderId, orderData) {
    return axios.patch(
      `${this.url}/${accountId}/shop/orders/${orderId}`,
      orderData
    );
  }

  confirmOrder(accountId, orderId) {
    return axios.post(`${this.url}/${accountId}/shop/orders/${orderId}/confirm`);
  }

  cancelOrder(accountId, orderId) {
    return axios.post(`${this.url}/${accountId}/shop/orders/${orderId}/cancel`);
  }
}

export default new ShopAPI();

