import { frontendURL } from '../../../../helper/URLHelper';

const SettingsContent = () => import('../Wrapper.vue');
const ProductsIndex = () => import('./pages/ProductsIndex.vue');
const ProductsNew = () => import('./pages/ProductsNew.vue');
const ProductsEdit = () => import('./pages/ProductsEdit.vue');
const CategoriesIndex = () => import('./pages/CategoriesIndex.vue');
const OrdersIndex = () => import('./pages/OrdersIndex.vue');
const OrdersShow = () => import('./pages/OrdersShow.vue');
const SettingsIndex = () => import('./pages/SettingsIndex.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/shop'),
      component: SettingsContent,
      props: {
        headerTitle: 'SHOP.HEADER',
        icon: 'shopping-bag',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'shop_wrapper',
          redirect: 'products',
        },
        {
          path: 'products',
          name: 'shop_products',
          component: ProductsIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'products/new',
          name: 'shop_products_new',
          component: ProductsNew,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'products/:productId/edit',
          name: 'shop_products_edit',
          component: ProductsEdit,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'categories',
          name: 'shop_categories',
          component: CategoriesIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'orders',
          name: 'shop_orders',
          component: OrdersIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'orders/:orderId',
          name: 'shop_orders_show',
          component: OrdersShow,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'settings',
          name: 'shop_settings',
          component: SettingsIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
