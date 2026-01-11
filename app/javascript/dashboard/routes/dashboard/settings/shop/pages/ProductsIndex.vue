<template>
  <div class="flex flex-col h-full">
    <div class="flex items-center justify-between p-4 border-b border-slate-75 dark:border-slate-800">
      <div>
        <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
          {{ $t('SHOP.PRODUCTS.TITLE') }}
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400">
          {{ $t('SHOP.PRODUCTS.DESCRIPTION') }}
        </p>
      </div>
      <woot-button
        color-scheme="primary"
        icon="add"
        @click="$router.push({ name: 'shop_products_new' })"
      >
        {{ $t('SHOP.PRODUCTS.NEW') }}
      </woot-button>
    </div>

    <div v-if="uiFlags.isFetching" class="flex items-center justify-center h-full">
      <spinner />
    </div>

    <div v-else-if="!products.length" class="flex flex-col items-center justify-center h-full p-8">
      <fluent-icon icon="shopping-bag" size="48" class="text-slate-400 mb-4" />
      <h3 class="text-lg font-medium text-slate-700 dark:text-slate-300 mb-2">
        {{ $t('SHOP.PRODUCTS.EMPTY_STATE.TITLE') }}
      </h3>
      <p class="text-sm text-slate-600 dark:text-slate-400 mb-6 text-center max-w-md">
        {{ $t('SHOP.PRODUCTS.EMPTY_STATE.MESSAGE') }}
      </p>
      <woot-button
        color-scheme="primary"
        icon="add"
        @click="$router.push({ name: 'shop_products_new' })"
      >
        {{ $t('SHOP.PRODUCTS.NEW') }}
      </woot-button>
    </div>

    <div v-else class="flex-1 overflow-auto p-4">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        <div
          v-for="product in products"
          :key="product.id"
          class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden hover:shadow-lg transition-shadow cursor-pointer"
          @click="editProduct(product.id)"
        >
          <div class="aspect-square bg-slate-100 dark:bg-slate-800 relative">
            <img
              v-if="product.primary_image"
              :src="product.primary_image"
              :alt="product.name"
              class="w-full h-full object-cover"
            />
            <div v-else class="flex items-center justify-center h-full">
              <fluent-icon icon="image" size="48" class="text-slate-400" />
            </div>
            <div
              v-if="!product.active"
              class="absolute top-2 right-2 px-2 py-1 bg-slate-900/80 text-white text-xs rounded"
            >
              {{ $t('SHOP.PRODUCTS.INACTIVE') }}
            </div>
            <div
              v-if="product.on_sale"
              class="absolute top-2 left-2 px-2 py-1 bg-woot-500 text-white text-xs rounded font-medium"
            >
              -{{ product.discount_percentage }}%
            </div>
          </div>
          
          <div class="p-4">
            <h3 class="font-medium text-slate-900 dark:text-slate-100 truncate mb-1">
              {{ product.name }}
            </h3>
            <p class="text-sm text-slate-600 dark:text-slate-400 line-clamp-2 mb-2">
              {{ product.description }}
            </p>
            
            <div class="flex items-center justify-between">
              <div>
                <span class="text-lg font-semibold text-woot-500">
                  {{ formatCurrency(product.price) }}
                </span>
                <span
                  v-if="product.compare_at_price"
                  class="text-sm text-slate-500 line-through ml-2"
                >
                  {{ formatCurrency(product.compare_at_price) }}
                </span>
              </div>
              
              <div class="text-sm text-slate-600 dark:text-slate-400">
                <span v-if="product.track_inventory">
                  {{ product.stock_quantity }} {{ $t('SHOP.PRODUCTS.IN_STOCK') }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import ShopAPI from 'dashboard/api/shop';
import Spinner from 'shared/components/Spinner.vue';

const router = useRouter();

const products = ref([]);
const uiFlags = ref({
  isFetching: false,
});

const currentAccountId = useMapGetter('getCurrentAccountId');

onMounted(() => {
  fetchProducts();
});

const fetchProducts = async () => {
  uiFlags.value.isFetching = true;
  try {
    const response = await ShopAPI.getProducts(currentAccountId.value);
    products.value = response.data;
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isFetching = false;
  }
};

const editProduct = productId => {
  router.push({ name: 'shop_products_edit', params: { productId } });
};

const formatCurrency = value => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
};
</script>

